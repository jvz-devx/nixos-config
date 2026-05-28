{pkgs, ...}: let
  herdrHook = action: {
    command = "bash '/home/jens/.codex/herdr-agent-state.sh' ${action}";
    timeout = 10;
    type = "command";
  };
  supermemoryHook = {
    command = "bash '/home/jens/.codex/supermemory-recall-hook.sh'";
    timeout = 5;
    type = "command";
  };
  supermemoryStopReviewHook = {
    command = "bash '/home/jens/.codex/supermemory-stop-review-hook.sh'";
    timeout = 5;
    type = "command";
  };
in {
  home.file.".codex/hooks.json" = {
    force = true;
    text = builtins.toJSON {
      hooks = {
        PreToolUse = [
          {
            hooks = [
              (herdrHook "working")
            ];
          }
        ];
        SessionStart = [
          {
            hooks = [
              (herdrHook "idle")
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              (herdrHook "idle")
            ];
          }
          {
            hooks = [
              supermemoryStopReviewHook
            ];
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              (herdrHook "working")
            ];
          }
          {
            hooks = [
              supermemoryHook
            ];
          }
        ];
      };
    };
  };

  home.file.".codex/supermemory-recall-hook.sh" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      input="$(${pkgs.coreutils}/bin/cat)"

      prompt="$(${pkgs.jq}/bin/jq -r '.prompt // empty' <<<"$input" 2>/dev/null || true)"
      cwd="$(${pkgs.jq}/bin/jq -r '.cwd // empty' <<<"$input" 2>/dev/null || true)"
      [ -n "$prompt" ] || exit 0

      prompt_words="$(${pkgs.coreutils}/bin/wc -w <<<"$prompt" | ${pkgs.coreutils}/bin/tr -d ' ')"
      prompt_lower="$(${pkgs.coreutils}/bin/printf '%s' "$prompt" | ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]')"

      useful=0
      case "$prompt_lower" in
        *supermemory*|*memory*|*remember*|*preference*|*prior*|*previous*|*usually*|*workflow*|*deploy*|*push*|*rebuild*|*switch*|*nixos*|*home\ manager*|*mcp*|*plugin*|*hook*|*config*|*repo*|*runtime*|*logs*|*gitops*|*context*|*last\ time*|*have\ we*|*what\ do\ you\ know*) useful=1 ;;
      esac

      if [ "''${prompt_words:-0}" -ge 12 ] &&
        ${pkgs.gnugrep}/bin/grep -Eiq 'add|audit|debug|deploy|fix|implement|investigate|plan|rebuild|review|switch|update|why|how|what|where' <<<"$prompt_lower"; then
        useful=1
      fi

      if [ "$useful" -eq 0 ]; then
        exit 0
      fi

      repo_root=""
      repo=""
      if [ -n "$cwd" ]; then
        repo_root="$(${pkgs.git}/bin/git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)"
        if [ -n "$repo_root" ]; then
          repo="$(${pkgs.git}/bin/git -C "$repo_root" remote get-url origin 2>/dev/null || true)"
        fi
      fi
      active_repo_name=""
      if [ -n "$repo_root" ]; then
        active_repo_name="$(${pkgs.coreutils}/bin/basename "$repo_root")"
      fi

      trimmed_prompt="$(${pkgs.coreutils}/bin/printf '%s' "$prompt" | ${pkgs.coreutils}/bin/head -c 500)"
      query="$(${pkgs.jq}/bin/jq -rn \
        --arg cwd "$cwd" \
        --arg repoRoot "$repo_root" \
        --arg repo "$repo" \
        --arg prompt "$trimmed_prompt" \
        '"Return only durable memories relevant to the active workspace.\ncwd=\($cwd)\nrepo_root=\($repoRoot)\nrepo=\($repo)\nprompt=\($prompt)"'
      )"

      if [ -n "''${CODEX_SUPERMEMORY_RECALL_HOOK_TEST_TEXT:-}" ]; then
        text="$CODEX_SUPERMEMORY_RECALL_HOOK_TEST_TEXT"
      else
        token="''${SUPERMEMORY_API_KEY:-}"
        if [ -z "$token" ] && [ -r "$HOME/.codex/config.toml" ]; then
          token="$(
            ${pkgs.gawk}/bin/awk -F'"' '/Authorization = "Bearer /{print $2}' "$HOME/.codex/config.toml" \
              | ${pkgs.gnused}/bin/sed 's/^Bearer //' \
              | ${pkgs.coreutils}/bin/head -n 1
          )"
        fi
        [ -n "$token" ] || exit 0

        headers="$(${pkgs.coreutils}/bin/mktemp)"
        trap '${pkgs.coreutils}/bin/rm -f "$headers"' EXIT

        init_payload='{"jsonrpc":"2.0","id":"init","method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"codex-supermemory-hook","version":"0.1"}}}'
        ${pkgs.curl}/bin/curl -sS --max-time 2 -D "$headers" -o /dev/null \
          -H "Authorization: Bearer $token" \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json, text/event-stream' \
          -d "$init_payload" \
          https://mcp.supermemory.ai/mcp >/dev/null 2>&1 || exit 0

        session_id="$(${pkgs.gawk}/bin/awk 'BEGIN{IGNORECASE=1}/^mcp-session-id:/{print $2}' "$headers" | ${pkgs.coreutils}/bin/tr -d '\r' | ${pkgs.coreutils}/bin/head -n 1)"
        [ -n "$session_id" ] || exit 0

        recall_payload="$(${pkgs.jq}/bin/jq -cn --arg query "$query" '{
          jsonrpc: "2.0",
          id: "recall",
          method: "tools/call",
          params: {
            name: "recall",
            arguments: {
              query: $query,
              containerTag: "sm_project_default",
              includeProfile: false
            }
          }
        }')"

        response="$(${pkgs.curl}/bin/curl -sS --max-time 3 \
          -H "Authorization: Bearer $token" \
          -H "Mcp-Session-Id: $session_id" \
          -H 'Content-Type: application/json' \
          -H 'Accept: application/json, text/event-stream' \
          -d "$recall_payload" \
          https://mcp.supermemory.ai/mcp 2>/dev/null || true)"

        text="$(
          ${pkgs.coreutils}/bin/printf '%s\n' "$response" \
            | ${pkgs.gnused}/bin/sed -n 's/^data: //p' \
            | while IFS= read -r payload; do
              ${pkgs.coreutils}/bin/printf '%s' "$payload" \
                | ${pkgs.jq}/bin/jq -r '.result.content[]?.text? // empty' 2>/dev/null || true
            done
        )"
      fi

      memories="$(
        ${pkgs.coreutils}/bin/printf '%s\n' "$text" \
          | ${pkgs.gawk}/bin/awk \
            -v cwd="$cwd" \
            -v repo_root="$repo_root" \
            -v repo="$repo" \
            -v active_repo_name="$active_repo_name" \
            -v prompt="$prompt_lower" '
            function lower(value) {
              return tolower(value)
            }
            function is_global_workflow(value) {
              value = lower(value)
              return value ~ /(machine-wide|global|agent|codex|claude|supermemory|memory|nixos|\/etc\/nixos|home manager|tool|workflow|preference|default|always|never|do not|prefer|source of truth|declarative|rebuild)/
            }
            function mentions_active(value) {
              value = lower(value)
              return (cwd != "" && index(value, lower(cwd)) > 0) ||
                (repo_root != "" && index(value, lower(repo_root)) > 0) ||
                (repo != "" && index(value, lower(repo)) > 0) ||
                (active_repo_name != "" && index(value, lower(active_repo_name)) > 0) ||
                index(value, prompt) > 0
            }
            function source_repo_name(value, path, parts, n) {
              if (match(value, /\/home\/jens\/Documents\/source\/[[:alnum:]_.-]+/)) {
                path = substr(value, RSTART, RLENGTH)
                n = split(path, parts, "/")
                return parts[n]
              }
              return ""
            }
            function mentions_foreign_repo(value, repo_name) {
              repo_name = source_repo_name(value)
              if (repo_name != "" && repo_name != active_repo_name && index(prompt, lower(repo_name)) == 0) return 1

              split("homelab-iac termix termixkit teleport-rs border-core nzbget-rs musicbot docs-site rudy-website klavier svelte-mobile", known_repos, " ")
              for (idx in known_repos) {
                repo_name = known_repos[idx]
                if (index(lower(value), repo_name) > 0 && repo_name != lower(active_repo_name) && index(prompt, repo_name) == 0) return 1
              }
              return 0
            }
            BEGIN {
              header = "Supermemory recall (gated, compact):"
              count = 0
              total = length(header)
            }
            /^#/ || /^[[:space:]]*$/ { next }
            {
              line = $0
              sub(/^[-*][[:space:]]*/, "", line)
              if (line == "No memories found.") next
              lower_line = lower(line)
              if (!mentions_active(line) && !is_global_workflow(line)) next
              if (lower_line ~ /^(working directory is|working in )[[:space:]]/ && !mentions_active(line)) next
              if (mentions_foreign_repo(line)) next
              if (lower_line ~ /(flux layer|gitops|homelab-iac)/ &&
                lower(active_repo_name) != "homelab-iac" &&
                prompt !~ /(homelab|flux|gitops|kubernetes deploy|k8s|cluster)/) next
              key = lower_line
              if (seen[key]++) next
              entry = "- " line
              if (count == 0) print header
              if (total + length(entry) + 1 > 1500) exit
              print entry
              total += length(entry) + 1
              count += 1
              if (count >= 6) exit
            }
            END {
              if (count == 0) exit 1
            }
          ' 2>/dev/null || true
      )"

      [ -n "$memories" ] || exit 0

      ${pkgs.jq}/bin/jq -cn --arg context "$memories" '{
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext: $context
        }
      }'
    '';
  };

  home.file.".codex/supermemory-stop-review-hook.sh" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      input="$(${pkgs.coreutils}/bin/cat)"

      stop_hook_active="$(${pkgs.jq}/bin/jq -r '.stop_hook_active // false' <<<"$input" 2>/dev/null || ${pkgs.coreutils}/bin/printf 'false')"
      if [ "$stop_hook_active" = "true" ]; then
        exit 0
      fi

      transcript_path="$(${pkgs.jq}/bin/jq -r '.transcript_path // empty' <<<"$input" 2>/dev/null || true)"
      [ -n "$transcript_path" ] && [ -r "$transcript_path" ] || exit 0

      user_messages="$(
        ${pkgs.jq}/bin/jq -r '
          select(.type == "event_msg" and .payload.type == "user_message")
          | .payload.message // empty
          | select((test("<INSTRUCTIONS>|</INSTRUCTIONS>|<environment_context>|</environment_context>|# AGENTS[.]md instructions|--- project-doc ---|<hook_prompt|</hook_prompt>")) | not)
        ' "$transcript_path" 2>/dev/null \
          | ${pkgs.gawk}/bin/awk '
            NF { print }
          ' \
          | ${pkgs.coreutils}/bin/tail -n 12
      )"

      [ -n "$user_messages" ] || exit 0

      user_messages_lower="$(${pkgs.coreutils}/bin/printf '%s' "$user_messages" | ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]')"

      explicit_memory=0
      workflow_guidance=0

      if ${pkgs.gnugrep}/bin/grep -Eiq 'remember (this|that)|save (this|that|to memory)|save .*to (supermemory|memory)|permanent memory|add .*memory|store .*memory' <<<"$user_messages_lower"; then
        explicit_memory=1
      fi

      if ${pkgs.gnugrep}/bin/grep -Eiq 'preference|preferences|source of truth|workflow|convention|rule|rules|tool choice|agent behavior|memory policy|hook policy' <<<"$user_messages_lower" \
        && ${pkgs.gnugrep}/bin/grep -Eiq "should|must|prefer|default|do not|don't|instead|always|never|from now on|next time" <<<"$user_messages_lower"; then
        workflow_guidance=1
      fi

      if [ "$explicit_memory" -eq 0 ] && [ "$workflow_guidance" -eq 0 ]; then
        exit 0
      fi

      reason="$(${pkgs.coreutils}/bin/printf '%s\n\n' \
        "Before stopping, run a final permanent Supermemory audit for this session because the user explicitly signaled memory intent or durable directive guidance." \
        "Decide whether each candidate should be saved as new, replace an exact obsolete existing memory, or be skipped. It is valid and often correct to save nothing." \
        "Before saving, run one or two targeted Supermemory recall queries against containerTag = \"sm_project_default\" to check for existing duplicate or conflicting memories." \
        "Save only high-confidence durable facts newly introduced, corrected, or explicitly confirmed in this session." \
        "Good candidates are user preferences, workflow conventions, repo or host topology, stable tool choices, and do/don't rules that will help future sessions." \
        "Do not save ordinary task requests or outcomes, UI feature requests, tests/smoke prompts, build results, logs, transient state, volatile versions, secrets, tokens, plaintext credentials, or repetitive summaries." \
        "Do not save AGENTS.md/project instructions, recalled Supermemory context, or generated hook prompts merely because they were present in context." \
        "If a rediscovered config or repo rule seems useful, save it only when this session is explicitly about memory, hooks, tooling, workflow, or the user confirmed the rule is durable." \
        "If an existing memory is clearly obsolete or conflicts with the corrected fact, call the Supermemory MCP tool \`memory\` with \`action = \"save\"\` for the refined replacement and \`action = \"forget\"\` only for the exact obsolete content. If the match is not exact, do not forget it." \
        "Example to save: User prefers Svelte remote functions over +page.server.ts in TermixKit. Example not to save: User asked to add a button to a website. Example not to save: AGENTS.md says never commit or push." \
        "If there is anything worth saving, call the Supermemory MCP tool \`memory\` with \`action = \"save\"\` and \`containerTag = \"sm_project_default\"\`. If there is nothing durable or the update is uncertain, do not save or forget anything. After this audit, continue to the final response and stop normally." \
      )"

      ${pkgs.jq}/bin/jq -cn --arg reason "$reason" '{
        decision: "block",
        reason: $reason,
        suppressOutput: true
      }'
    '';
  };
}
