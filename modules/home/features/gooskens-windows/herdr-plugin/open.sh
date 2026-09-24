#!/usr/bin/env bash
# Action entrypoint: show the server picker as a popup.
set -euo pipefail
exec "${HERDR_BIN_PATH:-herdr}" plugin pane open --plugin gooskens.windows --entrypoint picker >/dev/null
