#!/usr/bin/env bash
# Popup: pick a server from the local list, then open a tab in the current
# workspace that runs gooskens-ad-shell against it.
set -euo pipefail
herdr="${HERDR_BIN_PATH:-herdr}"
servers="${HERDR_PLUGIN_CONFIG_DIR:?}/servers"

if [ ! -s "$servers" ]; then
  echo "No servers configured yet. Add one per line to:"
  echo "  $servers"
  echo "Format: <hostname>  <description>, e.g. SERVER01  DC Hoogeloon"
  read -r -n1 -p "Press any key to close."
  exit 0
fi

choice=$(grep -vE '^\s*(#|$)' "$servers" | fzf --prompt "Windows server > " --height 100% --reverse --no-multi) || exit 0
server=$(awk '{print $1}' <<<"$choice")
short=${server#GOOSKENS-}

workspace=$(jq -r '.workspace.workspace_id // .workspace.id // .workspace_id // empty' <<<"${HERDR_PLUGIN_CONTEXT_JSON:-{\}}")
workspace=${workspace:-${HERDR_WORKSPACE_ID:-}}
args=(tab create --label "$short · PowerShell" --focus)
[ -n "$workspace" ] && args+=(--workspace "$workspace")

pane=$("$herdr" "${args[@]}" | jq -r '.result.root_pane.pane_id')
"$herdr" pane run "$pane" "gooskens-ad-shell --server $server" >/dev/null
