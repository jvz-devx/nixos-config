#!/usr/bin/env bash
# Startup hook. In the per-server herdr sessions on localhost (dc101, dc03,
# dc501: the "Work · DC" sidebar machines), make sure a workspace exists whose
# first pane runs gooskens-ad-shell. Does nothing in any other session.
set -euo pipefail
herdr="${HERDR_BIN_PATH:-herdr}"
session="${HERDR_SESSION:-}"
servers="${HERDR_PLUGIN_CONFIG_DIR:?}/servers"
[ -n "$session" ] && [ -s "$servers" ] || exit 0

# Session name = hostname without the "gooskens-" prefix, dashes and case (e.g. PREFIX-DC-03 -> dc03).
server=$(grep -vE '^\s*(#|$)' "$servers" | awk -v s="$session" '
  { n = tolower($1); sub(/^gooskens-/, "", n); gsub(/-/, "", n); if (n == s) { print $1; exit } }')
[ -n "$server" ] || exit 0
short=${server#GOOSKENS-}

pane=$("$herdr" pane list | jq -r '.result.panes[0].pane_id // empty')
if [ -z "$pane" ]; then
  pane=$("$herdr" workspace create --label "$short" --cwd "$HOME" | jq -r '.result.root_pane.pane_id')
else
  "$herdr" workspace rename "${pane%%:*}" "$short" >/dev/null
fi
"$herdr" pane run "$pane" "gooskens-ad-shell --server $server" >/dev/null
