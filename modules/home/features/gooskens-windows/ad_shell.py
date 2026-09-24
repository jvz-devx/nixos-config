"""Interactive PowerShell session on a Gooskens Windows server over WinRM.

Uses PowerShell Remoting (PSRP) through pypsrp, so the session keeps state
between commands like Enter-PSSession: variables, functions, imported modules
and the current location all persist. Nothing is installed on the server; it
only needs WinRM on port 5985, which the domain controllers already expose.

Credentials come from the same sops-rendered config and macOS Keychain item as
gooskens-ad-ps, with a sops-nix password file as fallback where the Keychain
is locked (SSH sessions). The password is never printed or written anywhere.
"""

import argparse
import os
import readline
import shutil
import subprocess
import sys
import time

from pypsrp.complex_objects import PSInvocationState
from pypsrp.powershell import PowerShell, RunspacePool
from pypsrp.wsman import WSMan

HISTORY_PATH = os.path.expanduser("~/.local/state/gooskens-ad-shell/history")
RED, YELLOW, DIM, RESET = "\033[31m", "\033[33m", "\033[2m", "\033[0m"


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


def error_text(record):
    """Format an ErrorRecord like PowerShell does: '<Command> : <message>'."""
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


def print_streams(ps):
    """Print everything except regular output, which is streamed separately."""
    for record in ps.streams.error:
        print(f"{RED}{error_text(record)}{RESET}", file=sys.stderr)
    for record in ps.streams.warning:
        print(f"{YELLOW}WARNING: {getattr(record, 'message', None) or record}{RESET}", file=sys.stderr)
    for record in ps.streams.information:
        data = getattr(record, "message_data", None)
        print(data if data is not None else record)


def run(pool, script, stream=True):
    """Run a script in the session's scope and stream its output as text."""
    width = max(shutil.get_terminal_size((200, 40)).columns - 1, 80)
    ps = PowerShell(pool)
    # Dot-sourcing keeps variables and functions in the session scope.
    ps.add_script(f". {{\n{script}\n}} | Out-String -Stream -Width {width}")
    ps.begin_invoke()
    printed = 0
    try:
        while ps.state == PSInvocationState.RUNNING:
            ps.poll_invoke(timeout=2)
            if stream:
                for line in ps.output[printed:]:
                    print(line)
                printed = len(ps.output)
    except KeyboardInterrupt:
        print(f"{DIM}^C, stopping command{RESET}", file=sys.stderr)
        ps.stop()
        return False
    ps.end_invoke()
    if stream:
        for line in ps.output[printed:]:
            print(line)
    print_streams(ps)
    return not (ps.had_errors or ps.streams.error)


def current_location(pool):
    ps = PowerShell(pool)
    ps.add_script("(Get-Location).Path")
    output = ps.invoke()
    return str(output[0]) if output else "?"


def needs_more(text):
    """Keep reading lines for open blocks, pipes and backtick continuations."""
    stripped = text.rstrip()
    if stripped.endswith(("`", "|", "{", "(", ",")):
        return True
    return text.count("{") > text.count("}") or text.count("(") > text.count(")")


def interactive(pool, label):
    os.makedirs(os.path.dirname(HISTORY_PATH), exist_ok=True)
    try:
        readline.read_history_file(HISTORY_PATH)
    except (FileNotFoundError, OSError):
        pass
    readline.set_history_length(5000)
    print(f"{DIM}Connected to {label}. PowerShell 5.1 over WinRM; type 'exit' or press Ctrl-D to leave.{RESET}")
    print(f"{DIM}Interactive prompts (Read-Host, -Confirm) are not supported in this session.{RESET}")
    try:
        while True:
            try:
                prompt = f"PS [{label}] {current_location(pool)}> "
                text = input(prompt)
                while needs_more(text):
                    text += "\n" + input(">> ")
            except KeyboardInterrupt:
                print()
                continue
            except EOFError:
                print()
                break
            if not text.strip():
                continue
            if text.strip().lower() in ("exit", "quit", "exit-pssession"):
                break
            run(pool, text)
    finally:
        try:
            readline.write_history_file(HISTORY_PATH)
        except OSError:
            pass


def main():
    parser = argparse.ArgumentParser(
        prog="gooskens-ad-shell",
        description="Interactive PowerShell on a Gooskens Windows server over WinRM (no install on the server).",
    )
    parser.add_argument("--config", required=True, help=argparse.SUPPRESS)
    parser.add_argument("--password-file", help=argparse.SUPPRESS)
    parser.add_argument("-s", "--server", help="target server (default: the DC from the gooskens-ad-ps config)")
    parser.add_argument("-c", "--command", help="run one command and exit instead of opening a session")
    args = parser.parse_args()

    config = load_config(args.config)
    server = args.server or config["server"]
    label = server.split(".")[0].upper()

    password = get_password(config["service"], config["account"], args.password_file)

    def connect():
        wsman = WSMan(
            server,
            port=5985,
            ssl=False,
            auth="ntlm",
            encryption="always",
            username=config["account"],
            password=password,
            operation_timeout=20,
            read_timeout=30,
        )
        pool = RunspacePool(wsman)
        pool.open()
        run(pool, "$ProgressPreference = 'SilentlyContinue'", stream=False)
        return pool

    def close(pool):
        try:
            pool.close()
        except Exception:  # the connection may already be gone
            pass

    if args.command:
        pool = connect()
        try:
            ok = run(pool, args.command)
        finally:
            close(pool)
        sys.exit(0 if ok else 1)

    # Interactive: a dropped WinRM connection must not dump the user into the
    # local shell. Reconnect with a fresh session and keep the prompt.
    first = True
    while True:
        try:
            pool = connect()
        except Exception as error:
            print(f"{RED}Can't connect to {label}: {type(error).__name__}: {error}{RESET}", file=sys.stderr)
            if first:
                sys.exit(1)
            time.sleep(5)
            continue
        if not first:
            print(f"{YELLOW}Reconnected to {label}. Variables and location from before were reset.{RESET}")
        first = False
        try:
            interactive(pool, label)
            close(pool)
            break
        except KeyboardInterrupt:
            close(pool)
            print()
            break
        except Exception as error:
            close(pool)
            print(f"{RED}Connection to {label} lost ({type(error).__name__}: {error}); reconnecting...{RESET}", file=sys.stderr)
            time.sleep(2)

if __name__ == "__main__":
    main()
