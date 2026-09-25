"""Interactive PowerShell session on a Gooskens Windows server over WinRM.

Uses PowerShell Remoting (PSRP) through pypsrp with a real PowerShell host, so
it behaves like Enter-PSSession: state persists between commands, output is
formatted by PowerShell itself (Out-Default) at the terminal width, and
Read-Host, -Confirm prompts, pause and Clear-Host work. Nothing is installed on
the server; it only needs WinRM on port 5985.

Credentials come from the same sops-rendered config and macOS Keychain item as
gooskens-ad-ps, with a sops-nix password file as fallback where the Keychain
is locked (SSH sessions). The password is never printed or written anywhere.
"""

import argparse
import os
import readline
import shutil
import signal
import socket
import subprocess
import sys
import threading
import time

from pypsrp.complex_objects import (Color, Command, Coordinates, CultureInfo, PipelineResultTypes,
                                    PSInvocationState, Size)
from pypsrp.host import PSHost, PSHostRawUserInterface, PSHostUserInterface
from pypsrp.powershell import PowerShell, RunspacePool
from pypsrp.wsman import WSMan

HISTORY_PATH = os.path.expanduser("~/.local/state/gooskens-ad-shell/history")
RED, YELLOW, CYAN, DIM, RESET = "\033[31m", "\033[33m", "\033[36m", "\033[2m", "\033[0m"
# HTTP.sys drops idle connections after 120 s; with NTLM message encryption the
# next request then fails with HTTP 400. Ping well before that.
KEEPALIVE_SECONDS = 50
# Server-side idle timeout for our shell. The keepalive keeps a live session
# well inside it. If this process dies without closing (herdr closing a tab
# kills it outright, kill -9, lost network) the server removes the shell after
# this, instead of pypsrp's ~25-day default that piles up against
# MaxShellsPerUser. Another client can't delete it sooner: WinRM refuses with
# "connected to a different client" until the timeout.
IDLE_TIMEOUT_SECONDS = 300
# Reachability is checked with a plain TCP connect to WinRM, so a VPN drop shows
# up within PROBE_SECONDS instead of after a 30 s request timeout. The status is
# reported to herdr as workspace metadata ($winrm) with a TTL, so a killed shell
# can never leave "online" behind.
PROBE_SECONDS = 10
STATUS_REFRESH_SECONDS = 45
STATUS_TTL_MS = 120000
CONNECT_TIMEOUT_SECONDS = 10
# ConsoleColor (0-15) to ANSI foreground codes.
ANSI_FG = [30, 34, 32, 36, 31, 35, 33, 37, 90, 94, 92, 96, 91, 95, 93, 97]
DEFAULT_FG, DEFAULT_BG = 7, 0  # Gray on Black, what the host reports
COLOR_NAMES = ["black", "darkblue", "darkgreen", "darkcyan", "darkred", "darkmagenta", "darkyellow", "gray",
               "darkgray", "blue", "green", "cyan", "red", "magenta", "yellow", "white"]


def out(text, stream=None):
    stream = stream or sys.stdout
    stream.write(text)
    stream.flush()


PRINT_LOCK = threading.Lock()
AT_PROMPT = threading.Event()  # main thread is waiting in input()


def notice(text):
    """Print a status line from a background thread without garbling the prompt."""
    with PRINT_LOCK:
        if AT_PROMPT.is_set():
            out(f"\r\033[K{text}\n")
            try:
                readline.redisplay()
            except Exception:
                pass
        else:
            out(f"{text}\n", sys.stderr)


def terminal_size():
    size = shutil.get_terminal_size((160, 50))
    return max(size.columns, 40), max(size.lines, 10)


def color_code(value):
    """ConsoleColor from a pypsrp Color, int or name; None if unknown."""
    value = getattr(value, "value", value)
    if value in (None, ""):
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        name = str(value).replace("_", "").lower()
        return COLOR_NAMES.index(name) if name in COLOR_NAMES else None


def colored(text, code):
    if code is None or code == DEFAULT_FG or not 0 <= code < len(ANSI_FG):
        return text
    return f"\033[{ANSI_FG[code]}m{text}{RESET}"


# Ctrl-C must never interrupt Python in the middle of a WinRM HTTP request: that
# leaves the NTLM-encrypted connection half-read and every later request fails
# with HTTP 400. While a command runs, SIGINT only sets this flag; the poll loop
# then stops the pipeline cleanly between requests.
STOP = threading.Event()


def _flag_interrupt(signum, frame):
    STOP.set()


def ask(prompt=""):
    """input() for host prompts; Ctrl-C cancels the running command cleanly."""
    previous = signal.signal(signal.SIGINT, signal.default_int_handler)
    try:
        return input(prompt)
    except KeyboardInterrupt:
        STOP.set()
        out("\n")
        return ""
    except EOFError:
        return ""
    finally:
        signal.signal(signal.SIGINT, previous)


class NotStarted(Exception):
    """The server never received this command, so it is safe to retry it."""


class ShellExit(Exception):
    """The remote script called exit; leave the shell."""


# --------------------------------------------------------------------------
# PowerShell host: how the server talks to the user (output, prompts, screen)
# --------------------------------------------------------------------------


def props_of(obj):
    props = {}
    for attr in ("adapted_properties", "extended_properties"):
        value = getattr(obj, attr, None)
        if isinstance(value, dict):
            props.update(value)
    return {str(key).lower(): value for key, value in props.items()}


class TerminalUI(PSHostUserInterface):
    """Maps host calls from the server onto this terminal."""

    def __init__(self, raw_ui):
        super().__init__(raw_ui)
        self.error_lines = 0  # errors rendered through the host (Out-Default)

    # Output ---------------------------------------------------------------
    def Write1(self, runspace, pipeline, value):
        out(value)

    def Write2(self, runspace, pipeline, foreground_color, background_color, value):
        out(colored(value, color_code(foreground_color)))

    def WriteLine1(self, runspace, pipeline):
        out("\n")

    def WriteLine2(self, runspace, pipeline, value):
        out(value + "\n")

    def WriteLine3(self, runspace, pipeline, foreground_color, background_color, value):
        out(colored(value, color_code(foreground_color)) + "\n")

    def WriteErrorLine(self, runspace, pipeline, message):
        self.error_lines += 1
        out(f"{RED}{message}{RESET}\n", sys.stderr)

    def WriteWarningLine(self, runspace, pipeline, message):
        out(f"{YELLOW}WARNING: {message}{RESET}\n", sys.stderr)

    def WriteVerboseLine(self, runspace, pipeline, message):
        out(f"{CYAN}VERBOSE: {message}{RESET}\n", sys.stderr)

    def WriteDebugLine(self, runspace, pipeline, message):
        out(f"{CYAN}DEBUG: {message}{RESET}\n", sys.stderr)

    def WriteProgress(self, runspace, pipeline, source_id, record):
        pass  # progress bars don't render over WinRM; $ProgressPreference is off anyway

    # Input ----------------------------------------------------------------
    def ReadLine(self, runspace, pipeline):
        return ask()

    def ReadLineAsSecureString(self, runspace, pipeline):
        raise NotImplementedError("Read-Host -AsSecureString is not supported in gooskens-ad-shell")

    def Prompt(self, runspace, pipeline, caption, message, descriptions):
        if caption:
            out(caption + "\n")
        if message:
            out(message + "\n")
        answers = {}
        for field in descriptions:
            props = props_of(field)
            name = str(props.get("name") or "")
            label = str(props.get("label") or name)
            answers[name] = ask(f"{label}: ")
        return answers

    def PromptForChoice(self, runspace, pipeline, caption, message, choices, default_choice):
        labels = [str(props_of(choice).get("label") or choice) for choice in choices]
        hotkeys = []
        for label in labels:
            index = label.find("&")
            hotkeys.append(label[index + 1].upper() if 0 <= index < len(label) - 1 else label[:1].upper())
        if caption:
            out(caption + "\n")
        if message:
            out(message + "\n")
        options = "  ".join(f"[{key}] {label.replace('&', '')}" for key, label in zip(hotkeys, labels))
        default = hotkeys[default_choice] if 0 <= default_choice < len(hotkeys) else None
        suffix = f' (default is "{default}")' if default else ""
        while True:
            answer = ask(f"{options}{suffix}: ").strip()
            if STOP.is_set():  # Ctrl-C: answer anything, the command is stopped next
                return default_choice if default is not None else 0
            if not answer and default is not None:
                return default_choice
            for index, key in enumerate(hotkeys):
                if answer.upper() == key or answer.lower() == labels[index].replace("&", "").lower():
                    return index

    def PromptForCredential1(self, runspace, pipeline, caption, message, user_name, target_name):
        raise NotImplementedError("Get-Credential is not supported in gooskens-ad-shell")

    def PromptForCredential2(self, runspace, pipeline, caption, message, user_name, target_name,
                             allowed_credential_types, options):
        raise NotImplementedError("Get-Credential is not supported in gooskens-ad-shell")


class TerminalRawUI(PSHostRawUserInterface):
    """Screen geometry follows this terminal; Clear-Host clears it."""

    def __init__(self):
        width, height = terminal_size()
        super().__init__(
            window_title="gooskens-ad-shell",
            cursor_size=25,
            foreground_color=Color(value=DEFAULT_FG),
            background_color=Color(value=DEFAULT_BG),
            cursor_position=Coordinates(x=0, y=0),
            window_position=Coordinates(x=0, y=0),
            buffer_size=Size(width=width, height=9999),
            max_physical_window_size=Size(width=width, height=height),
            max_window_size=Size(width=width, height=height),
            window_size=Size(width=width, height=height),
        )

    def _refresh(self):
        width, height = terminal_size()
        self.buffer_size = Size(width=width, height=9999)
        self.window_size = Size(width=width, height=height)
        self.max_window_size = Size(width=width, height=height)
        self.max_physical_window_size = Size(width=width, height=height)

    def GetBufferSize(self, runspace, pipeline):
        self._refresh()
        return self.buffer_size

    def GetWindowSize(self, runspace, pipeline):
        self._refresh()
        return self.window_size

    def GetMaxWindowSize(self, runspace, pipeline):
        self._refresh()
        return self.max_window_size

    def GetMaxPhysicalWindowSize(self, runspace, pipeline):
        self._refresh()
        return self.max_physical_window_size

    def SetBufferContents1(self, runspace, pipeline, rectangle, fill):
        out("\033[H\033[2J")  # Clear-Host fills the whole buffer

    def SetBufferContents2(self, runspace, pipeline, origin, contents):
        pass

    def SetCursorPosition(self, runspace, pipeline, coordinates):
        pass

    def SetWindowTitle(self, runspace, pipeline, title):
        pass

    def GetKeyAvailable(self, runspace, pipeline):
        return False

    def FlushInputBuffer(self, runspace, pipeline):
        pass


class TerminalHost(PSHost):
    def __init__(self):
        culture = CultureInfo(lcid=1033, name="en-US", display_name="English (United States)",
                              ietf_language_tag="en-US", three_letter_iso_name="eng",
                              three_letter_windows_name="ENU", two_letter_iso_language_name="en")
        super().__init__(current_culture=culture, current_ui_culture=culture, debugger_enabled=False,
                         name="gooskens-ad-shell", private_data=None, ui=TerminalUI(TerminalRawUI()),
                         version="2.0")
        self.should_exit = False

    def SetShouldExit(self, runspace, pipeline, exit_code):
        self.rc = exit_code
        self.should_exit = True

    def EnterNestedPrompt(self, runspace, pipeline):
        raise NotImplementedError("Nested prompts (debugger, Suspend) are not supported")

    def NotifyBeginApplication(self, runspace, pipeline):
        pass

    def NotifyEndApplication(self, runspace, pipeline):
        pass


# --------------------------------------------------------------------------
# Session: one RunspacePool, a lock and a keepalive thread
# --------------------------------------------------------------------------


class Session:
    def __init__(self, wsman):
        self.host = TerminalHost()
        self.pool = RunspacePool(wsman, host=self.host, idle_timeout=IDLE_TIMEOUT_SECONDS)
        self.pool.open()
        self.lock = threading.Lock()
        self.last_used = time.monotonic()
        self.location = "?"
        self.broken = False
        self.closed = threading.Event()
        threading.Thread(target=self._keepalive, daemon=True).start()

    def _keepalive(self):
        while not self.closed.wait(5):
            if time.monotonic() - self.last_used < KEEPALIVE_SECONDS:
                continue
            if not self.lock.acquire(blocking=False):
                continue
            try:
                self._invoke("$null")
            except Exception:
                self.broken = True
                return
            finally:
                self.lock.release()

    def _invoke(self, script, **parameters):
        """Run a small helper script quietly and return its output objects."""
        ps = PowerShell(self.pool)
        ps.add_script(script)
        for name, value in parameters.items():
            ps.add_parameter(name, value)
        result = ps.invoke()
        self.last_used = time.monotonic()
        return result

    def call(self, script, **parameters):
        """Helper round trip; a Ctrl-C during it is delivered only afterwards."""
        in_main = threading.current_thread() is threading.main_thread()
        previous = signal.signal(signal.SIGINT, _flag_interrupt) if in_main else None
        STOP.clear()
        try:
            with self.lock:
                return self._invoke(script, **parameters)
        finally:
            if in_main:
                signal.signal(signal.SIGINT, previous)
                if STOP.is_set():
                    STOP.clear()
                    raise KeyboardInterrupt

    def ping(self):
        """Quick health check from a background thread; None if a command is busy."""
        if not self.lock.acquire(blocking=False):
            return None
        try:
            self._invoke("$null")
            return True
        except Exception:
            self.broken = True
            return False
        finally:
            self.lock.release()

    def close(self):
        self.closed.set()
        try:
            with self.lock:
                self.pool.close()
        except Exception:  # connection gone: the server's idle timeout removes the shell
            pass


class Monitor:
    """Tracks whether the server is really reachable, heals the session, and
    reports the state to herdr's sidebar as the $winrm workspace token.

    States: online (session healthy), offline (WinRM port unreachable, e.g.
    VPN down), reconnecting (reachable again, new session being set up).
    """

    def __init__(self, server, label, connect, holder):
        self.server, self.label, self.connect, self.holder = server, label, connect, holder
        self.reachable = None
        self.state = None
        self.reported_at = 0.0
        self.swap_lock = threading.Lock()  # held by the main thread while it runs a command
        self.stopped = threading.Event()
        self.herdr = os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr")
        self.workspace = os.environ.get("HERDR_WORKSPACE_ID")
        self.enabled = bool(os.environ.get("HERDR_ENV") == "1" and self.herdr and self.workspace)

    def start(self):
        threading.Thread(target=self._loop, daemon=True).start()

    def probe(self):
        try:
            socket.create_connection((self.server, 5985), timeout=3).close()
            return True
        except OSError:
            return False

    def _loop(self):
        while not self.stopped.is_set():
            self.check()
            self.stopped.wait(PROBE_SECONDS)

    def check(self):
        reachable = self.probe()
        was = self.reachable
        self.reachable = reachable
        session = self.holder.get("session")
        if not reachable:
            if was:
                notice(f"{RED}{self.label} is unreachable (VPN off?). Commands are held until it's back.{RESET}")
            self.report("offline")
            return
        if was is False:
            notice(f"{YELLOW}{self.label} is reachable again.{RESET}")
            if session is not None and session.ping() is False:
                pass  # the old connection died while offline; heal below
        if session is None or session.broken:
            self.report("reconnecting")
            self.heal()
            session = self.holder.get("session")
        self.report("online" if session is not None and not session.broken else "reconnecting")

    def heal(self):
        """Replace a broken session in the background while the user is idle."""
        if not self.swap_lock.acquire(blocking=False):
            return  # a command is running; the main loop handles it
        try:
            old = self.holder.get("session")
            if old is not None and not old.broken:
                return
            try:
                new = self.connect()
            except Exception:
                return
            self.holder["session"] = new
            if old is not None:
                old.close()
                notice(f"{YELLOW}Reconnected to {self.label}. Variables and location from before were reset.{RESET}")
        finally:
            self.swap_lock.release()

    def report(self, state, force=False):
        if not self.enabled:
            self.state = state
            return
        now = time.monotonic()
        if not force and state == self.state and now - self.reported_at < STATUS_REFRESH_SECONDS:
            return
        args = [self.herdr, "workspace", "report-metadata", self.workspace, "--source", "gooskens-ad-shell"]
        args += ["--clear-token", "winrm"] if state is None else ["--token", f"winrm={state}", "--ttl-ms", str(STATUS_TTL_MS)]
        try:
            subprocess.run(args, capture_output=True, timeout=5)
        except Exception:
            pass
        self.state, self.reported_at = state, now

    def close(self):
        self.stopped.set()
        self.report(None, force=True)


def error_text(record):
    """Format a terminating ErrorRecord like PowerShell: '<Command> : <message>'."""
    text = str(getattr(record, "exception", None) or "")
    kind, separator, rest = text.partition(": ")
    if separator and kind.startswith("System."):
        text = rest  # drop the .NET exception type prefix
    text = text.split("\r\n   at ")[0].split("\n   at ")[0].strip()  # drop the .NET stack trace
    text = text or getattr(record, "message", None) or str(record)
    name = getattr(record, "invocation_name", None)
    category = getattr(record, "message", None)
    lines = [f"{name} : {text}" if name else text]
    if category and category != text:
        lines.append(f"    + {category}")
    return "\n".join(lines)


def run(session, script):
    """Run user input in the session scope, streaming output; return success.

    The script runs in the session's global scope (use_local_scope=False) with
    its error stream merged into output (2>&1 at protocol level), then through
    Out-Default, so PowerShell formats everything, errors included and in
    order, exactly like a console. Warnings, verbose, debug and Write-Host
    reach the terminal through the host UI. Terminating errors end up in the
    error stream and are printed here.
    """
    ui = session.host.ui
    ui.error_lines = 0
    with session.lock:
        ps = PowerShell(session.pool)
        ps.commands.append(Command(
            script,
            protocol_version=session.pool.protocol_version or "",
            is_script=True,
            use_local_scope=False,
            merge_my_result=PipelineResultTypes(protocol_version_2=True, value=PipelineResultTypes.ERROR),
            merge_to_result=PipelineResultTypes(protocol_version_2=True, value=PipelineResultTypes.OUTPUT),
            merge_error=PipelineResultTypes(value=PipelineResultTypes.OUTPUT),
        ))
        ps.add_cmdlet("Out-Default")
        STOP.clear()
        previous = signal.signal(signal.SIGINT, _flag_interrupt)
        try:
            try:
                ps.begin_invoke()
            except Exception as error:
                raise NotStarted(script) from error
            interrupted = False
            while ps.state == PSInvocationState.RUNNING:
                if STOP.is_set():
                    interrupted = True
                    out(f"{DIM}^C, stopping command...{RESET}\n", sys.stderr)
                    ps.stop()
                    break
                ps.poll_invoke(timeout=1)
                session.last_used = time.monotonic()
            if not interrupted:
                ps.end_invoke()
        finally:
            signal.signal(signal.SIGINT, previous)
            session.last_used = time.monotonic()
        if interrupted:
            return False
        for record in ps.streams.error:
            out(f"{RED}{error_text(record)}{RESET}\n", sys.stderr)
        if session.host.should_exit:
            raise ShellExit(session.host.rc or 0)
        return not (ps.had_errors or ps.streams.error or ui.error_lines)


# --------------------------------------------------------------------------
# Interactive loop: prompt, parser-driven multi-line input, tab completion
# --------------------------------------------------------------------------

PARSE_SCRIPT = """param($Text)
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$null, [ref]$errors)
[bool]($errors | Where-Object { $_.IncompleteInput })"""

COMPLETE_SCRIPT = """param($Line, $Cursor)
$r = TabExpansion2 -inputScript $Line -cursorColumn $Cursor
@($r.ReplacementIndex, $r.ReplacementLength) + @($r.CompletionMatches | Select-Object -First 200 | ForEach-Object CompletionText)"""


def is_incomplete(session, text):
    result = session.call(PARSE_SCRIPT, Text=text)
    return bool(result and result[0])


class Completer:
    """Tab completion through the server's own TabExpansion2."""

    def __init__(self, session_ref, online=lambda: True):
        self.session_ref = session_ref
        self.online = online
        self.matches = []

    def __call__(self, text, state):
        if state == 0:
            self.matches = []
            if not self.online() or self.session_ref() is None:
                return None
            try:
                line = readline.get_line_buffer()
                begin, end = readline.get_begidx(), readline.get_endidx()
                result = self.session_ref().call(COMPLETE_SCRIPT, Line=line[:end], Cursor=end)
                if result and len(result) >= 2:
                    index, length = int(result[0]), int(result[1])
                    for completion in result[2:]:
                        new_line = line[:index] + str(completion) + line[index + length:end]
                        if new_line[:begin].lower() == line[:begin].lower():
                            self.matches.append(new_line[begin:])
            except Exception:
                self.matches = []
        return self.matches[state] if state < len(self.matches) else None


def read_command(holder, monitor, label):
    session = holder["session"]
    if monitor.reachable is not False:
        try:
            location = session.call("(Get-Location).Path")
            session.location = str(location[0]) if location else session.location
        except KeyboardInterrupt:
            raise
        except Exception:
            pass
    tag = label if monitor.reachable is not False else f"{label} {RED}offline{RESET}"
    AT_PROMPT.set()
    try:
        text = input(f"PS [{tag}] {holder['session'].location}> ")
        while text.strip() and monitor.reachable is not False and is_incomplete(holder["session"], text):
            try:
                text += "\n" + input(">> ")
            except KeyboardInterrupt:
                out("\n")
                return ""
    finally:
        AT_PROMPT.clear()
    return text


def interactive(holder, monitor, label, pending=None, banner=True):
    if banner:
        out(f"{DIM}Connected to {label}. Windows PowerShell over WinRM; 'exit' or Ctrl-D to leave, "
            f"Ctrl-C stops a command.{RESET}\n")
    if pending is not None:
        with monitor.swap_lock:
            run(holder["session"], pending)  # the command the old connection never received
    while True:
        try:
            text = read_command(holder, monitor, label)
        except KeyboardInterrupt:
            out("\n")
            continue
        except EOFError:
            out("\n")
            return
        stripped = text.strip()
        if not stripped:
            continue
        if stripped.lower() in ("exit", "quit", "exit-pssession"):
            return
        if stripped.lower() in ("clear", "cls", "clear-host"):
            out("\033[H\033[2J")
            continue
        if not monitor.probe():
            monitor.reachable = False
            monitor.report("offline")
            out(f"{RED}{label} is unreachable (VPN off?); command not sent.{RESET}\n", sys.stderr)
            continue
        with monitor.swap_lock:
            session = holder["session"]
            if session.broken:
                raise NotStarted(text)
            run(session, text)


# --------------------------------------------------------------------------
# Credentials, connection and entry point
# --------------------------------------------------------------------------


def load_config(path):
    config = {}
    try:
        with open(path, encoding="utf-8") as config_file:
            for line in config_file:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                key, separator, value = line.partition("=")
                if separator:
                    config[key.strip()] = value.strip()
    except FileNotFoundError:
        sys.exit(f"Missing config {path}. Run darwin-rebuild switch so sops-nix can render it.")
    missing = [key for key in ("server", "service", "account") if not config.get(key)]
    if missing:
        sys.exit(f"Missing key(s) in {path}: {', '.join(missing)}")
    return config


def get_password(service, account, password_file):
    """Read the password from the login Keychain, or from the sops-nix file.

    SSH-started processes (herdr's localhost machines) can't read the login
    Keychain (security exits 36), so they fall back to the sops-nix secret.
    """
    result = subprocess.run(
        ["/usr/bin/security", "find-generic-password", "-w", "-s", service, "-a", account],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return result.stdout.rstrip("\n")
    if password_file and os.path.exists(password_file):
        with open(password_file, encoding="utf-8") as secret:
            return secret.read().rstrip("\n")
    sys.exit(f"Keychain lookup failed (exit {result.returncode}) and no password file at {password_file}.")


def setup_readline(session_ref, online=lambda: True):
    os.makedirs(os.path.dirname(HISTORY_PATH), exist_ok=True)
    try:
        readline.read_history_file(HISTORY_PATH)
    except OSError:
        pass
    readline.set_history_length(5000)
    readline.set_completer_delims(" \t\n;|(){}")
    readline.set_completer(Completer(session_ref, online))
    if "libedit" in (readline.__doc__ or ""):
        readline.parse_and_bind("bind ^I rl_complete")
    else:
        readline.parse_and_bind("tab: complete")


def main():
    parser = argparse.ArgumentParser(
        prog="gooskens-ad-shell",
        description="Interactive PowerShell on a Gooskens Windows server over WinRM (no install on the server).",
    )
    parser.add_argument("--config", required=True, help=argparse.SUPPRESS)
    parser.add_argument("--password-file", help=argparse.SUPPRESS)
    parser.add_argument("-s", "--server", help="target server (default: the DC from the gooskens-ad-ps config)")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("-c", "--command", help="run one command and exit (exit code 1 on errors)")
    group.add_argument("-f", "--file", help="run a local .ps1 file on the server and exit")
    args = parser.parse_args()

    config = load_config(args.config)
    server = args.server or config["server"]
    label = server.split(".")[0].upper()
    password = get_password(config["service"], config["account"], args.password_file)

    def make_wsman():
        return WSMan(
            server,
            port=5985,
            ssl=False,
            auth="ntlm",
            encryption="always",
            username=config["account"],
            password=password,
            operation_timeout=20,
            read_timeout=30,
            connection_timeout=CONNECT_TIMEOUT_SECONDS,
        )

    def connect():
        session = Session(make_wsman())
        session.call("$ProgressPreference = 'SilentlyContinue'")
        return session

    # Close the remote shell on kill or when the pane/terminal goes away, so
    # WinRM shells don't pile up on the server (MaxShellsPerUser).
    def terminate(signum, frame):
        raise SystemExit(128 + signum)

    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, terminate)

    def reachable():
        try:
            socket.create_connection((server, 5985), timeout=3).close()
            return True
        except OSError:
            return False

    if args.command or args.file:
        if not reachable():
            out(f"{RED}{label} is unreachable on WinRM port 5985 (VPN off?).{RESET}\n", sys.stderr)
            sys.exit(1)
        script = args.command
        if args.file:
            with open(args.file, encoding="utf-8-sig") as script_file:
                script = script_file.read()
        session = connect()
        code = 1
        try:
            session.call("$global:LASTEXITCODE = 0")
            ok = run(session, script)
            if STOP.is_set():
                sys.exit(130)
            native = session.call("$global:LASTEXITCODE")
            native = int(native[0]) if native and native[0] not in (None, "") else 0
            code = native if native else (0 if ok else 1)
        except ShellExit as shell_exit:
            code = int(shell_exit.args[0] or 0)
        except KeyboardInterrupt:
            code = 130
        finally:
            session.close()
        sys.exit(code)

    holder = {"session": None}
    monitor = Monitor(server, label, connect, holder)
    setup_readline(lambda: holder["session"], lambda: monitor.reachable is not False)

    # A dropped WinRM connection must not dump the user into the local shell.
    # While the server is unreachable (VPN off) the shell waits and says so; a
    # command the old connection never received is sent again on the new one.
    first, pending, code, waiting_said = True, None, 0, False
    monitor.report("reconnecting", force=True)
    try:
        while True:
            try:
                with monitor.swap_lock:  # never race the background healer
                    holder["session"] = connect()
            except KeyboardInterrupt:
                break
            except Exception as error:
                if reachable():
                    out(f"{RED}Can't connect to {label}: {type(error).__name__}: {error}{RESET}\n", sys.stderr)
                    if first:
                        code = 1
                        break
                else:
                    monitor.reachable = False
                    monitor.report("offline")
                    if not waiting_said:
                        out(f"{YELLOW}{label} is unreachable (VPN off?). Waiting for it; Ctrl-C to quit.{RESET}\n",
                            sys.stderr)
                        waiting_said = True
                try:
                    time.sleep(5)
                except KeyboardInterrupt:
                    break
                continue
            waiting_said = False
            if not first:
                out(f"{YELLOW}Reconnected to {label}. Variables and location from before were reset.{RESET}\n")
            first_session, first = first, False
            monitor.reachable = True
            monitor.report("online", force=True)
            if first_session:
                monitor.start()
            try:
                interactive(holder, monitor, label, pending, banner=first_session)
                break
            except ShellExit as shell_exit:
                code = int(shell_exit.args[0] or 0)
                break
            except NotStarted as not_started:
                pending = not_started.args[0]
                monitor.report("reconnecting", force=True)
                out(f"{YELLOW}Connection to {label} dropped before the command was sent; "
                    f"reconnecting and sending it again.{RESET}\n", sys.stderr)
            except Exception as error:
                pending = None
                monitor.report("reconnecting", force=True)
                out(f"{RED}Connection to {label} lost ({type(error).__name__}: {error}); reconnecting...{RESET}\n",
                    sys.stderr)
                time.sleep(2)
            finally:
                if holder["session"] is not None:
                    holder["session"].close()
                holder["session"] = None
    finally:
        monitor.close()
        if holder["session"] is not None:
            holder["session"].close()
        try:
            readline.write_history_file(HISTORY_PATH)
        except OSError:
            pass
    sys.exit(code)


if __name__ == "__main__":
    main()
