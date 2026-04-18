#!/usr/bin/env bash
# benchmark-30s.sh
# Sample the main bottleneck signals for a live workload over a short window.
#
# Default behavior:
#   - 30 second capture
#   - tries to find a game process matching cs2/csgo_linux64
#   - samples CPU, memory, IO pressure, top processes, optional target threads,
#     and NVIDIA GPU telemetry when available
#
# Usage:
#   ./benchmark-30s.sh
#   ./benchmark-30s.sh 45
#   ./benchmark-30s.sh 30 "cs2|eldenring.exe|gamescope"

set -euo pipefail

DURATION="${1:-30}"
TARGET_PATTERN="${2:-cs2|csgo_linux64}"
STAMP="$(date +%Y%m%d-%H%M%S)"
HOSTNAME="$(hostname)"
OUT_DIR="${PWD}/benchmark-${HOSTNAME}-${STAMP}"

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [[ "$DURATION" -lt 1 ]]; then
    echo "Duration must be a positive integer number of seconds." >&2
    exit 1
fi

mkdir -p "$OUT_DIR"

log() {
    printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

find_pid_by_comm() {
    local comm_pattern="$1"
    ps -eo pid=,comm= | awk -v pattern="$comm_pattern" '$2 ~ pattern { print $1; exit }'
}

find_target_pid() {
    local self_pid="$$"
    ps -eo pid=,comm=,args= | awk -v pattern="$TARGET_PATTERN" -v self_pid="$self_pid" '
        $1 == self_pid { next }
        $2 == "reaper" { next }
        $2 == "bash" && $0 ~ /benchmark-30s\.sh/ { next }
        $2 == "srt-bwrap" { next }
        $2 == "pv-adverb" { next }
        $2 == "oom_reaper" { next }
        $2 ~ /^(cs2|csgo_linux64|gamescope)$/ {
            found = 1
            print $1
            exit
        }
        $0 ~ pattern && $2 !~ /^(sh|bash)$/ {
            fallback = $1
        }
        END {
            if (!found && fallback != "") {
                print fallback
            }
        }
    '
}

TARGET_PID="$(find_target_pid)"
TARGET_CMD=""
KWIN_PID="$(find_pid_by_comm "^\\.kwin_wayland-w$")"
XWAYLAND_PID="$(find_pid_by_comm "^Xwayland$")"

if [[ -n "$TARGET_PID" ]] && [[ -r "/proc/$TARGET_PID/cmdline" ]]; then
    TARGET_CMD="$(tr '\0' ' ' < "/proc/$TARGET_PID/cmdline" | sed 's/[[:space:]]\+$//')"
fi

cat > "$OUT_DIR/metadata.txt" <<EOF
timestamp=${STAMP}
host=${HOSTNAME}
duration_seconds=${DURATION}
target_pattern=${TARGET_PATTERN}
target_pid=${TARGET_PID}
target_cmd=${TARGET_CMD}
kwin_pid=${KWIN_PID}
xwayland_pid=${XWAYLAND_PID}
kernel=$(uname -r)
EOF

log "Writing samples to $OUT_DIR"
if [[ -n "$TARGET_PID" ]]; then
    log "Target PID: $TARGET_PID"
    printf '%s\n' "$TARGET_CMD" > "$OUT_DIR/target-command.txt"
else
    log "No target process matched '$TARGET_PATTERN'; collecting system-wide samples only"
fi

if [[ -n "$KWIN_PID" ]]; then
    log "KWin PID: $KWIN_PID"
fi

if [[ -n "$XWAYLAND_PID" ]]; then
    log "Xwayland PID: $XWAYLAND_PID"
fi

run_capture() {
    local name="$1"
    shift
    (
        "$@"
    ) > "$OUT_DIR/${name}.log" 2>&1 || true
}

run_loop_capture() {
    local name="$1"
    shift
    (
        for ((i = 1; i <= DURATION; i++)); do
            printf '===== sample %02d @ %s =====\n' "$i" "$(date --iso-8601=seconds)"
            "$@" || true
            printf '\n'
            sleep 1
        done
    ) > "$OUT_DIR/${name}.log" 2>&1 &
}

run_capture "vmstat" vmstat 1 "$DURATION" &

if [[ -r /proc/pressure/cpu ]]; then
    run_loop_capture "pressure" sh -c 'cat /proc/pressure/cpu; printf "\n"; cat /proc/pressure/memory; printf "\n"; cat /proc/pressure/io'
fi

run_loop_capture "top-processes" ps -eo pid,ppid,comm,%cpu,%mem,psr,ni,cls,args --sort=-%cpu

if [[ -n "$TARGET_PID" ]]; then
    run_loop_capture "target-status" ps -p "$TARGET_PID" -o pid,ppid,comm,%cpu,%mem,psr,ni,cls,etimes,args
    run_loop_capture "target-threads" ps -L -p "$TARGET_PID" -o pid,tid,psr,pcpu,stat,comm --sort=-pcpu
fi

COMPOSITOR_PIDS=()
if [[ -n "$KWIN_PID" ]]; then
    COMPOSITOR_PIDS+=("$KWIN_PID")
fi
if [[ -n "$XWAYLAND_PID" ]]; then
    COMPOSITOR_PIDS+=("$XWAYLAND_PID")
fi

if [[ ${#COMPOSITOR_PIDS[@]} -gt 0 ]]; then
    compositor_pid_list="$(IFS=,; echo "${COMPOSITOR_PIDS[*]}")"
    run_loop_capture "compositor-status" ps -p "$compositor_pid_list" -o pid,ppid,comm,%cpu,%mem,psr,ni,cls,etimes,args
    (
        for ((i = 1; i <= DURATION; i++)); do
            printf '===== sample %02d @ %s =====\n' "$i" "$(date --iso-8601=seconds)"
            for p in "${COMPOSITOR_PIDS[@]}"; do
                if [[ -r "/proc/$p/comm" ]]; then
                    printf -- '-- proc %s (%s) --\n' "$p" "$(cat "/proc/$p/comm")"
                    cat "/proc/$p/schedstat" || true
                    awk '/voluntary_ctxt_switches|nonvoluntary_ctxt_switches/ {print}' "/proc/$p/status" || true
                fi
            done
            printf '\n'
            sleep 1
        done
    ) > "$OUT_DIR/compositor-sched.log" 2>&1 &
fi

if have nvidia-smi; then
    run_capture "nvidia-dmon" nvidia-smi dmon -s pucvmet -d 1 -c "$DURATION" &
    (
        for ((i = 1; i <= DURATION; i++)); do
            nvidia-smi --query-gpu=name,driver_version,pci.bus_id,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw,clocks.current.graphics,clocks.current.memory,temperature.gpu --format=csv,noheader || true
            sleep 1
        done
    ) > "$OUT_DIR/nvidia-gpu.csv" 2> "$OUT_DIR/nvidia-gpu.log" &
fi

if [[ -n "$TARGET_PID" ]] && have top; then
    run_capture "target-top" top -H -b -d 1 -n "$DURATION" -p "$TARGET_PID" &
fi

wait

{
    echo "30s benchmark summary"
    echo "host: $HOSTNAME"
    echo "duration_seconds: $DURATION"
    echo "target_pattern: $TARGET_PATTERN"
    if [[ -n "$TARGET_PID" ]]; then
        echo "target_pid: $TARGET_PID"
        echo "target_cmd: $TARGET_CMD"
    else
        echo "target_pid: none"
    fi
    echo

    if [[ -f "$OUT_DIR/vmstat.log" ]]; then
        echo "vmstat_tail:"
        tail -n 5 "$OUT_DIR/vmstat.log"
        echo
    fi

    if [[ -f "$OUT_DIR/pressure.log" ]]; then
        echo "pressure_tail:"
        tail -n 12 "$OUT_DIR/pressure.log"
        echo
    fi

    if [[ -f "$OUT_DIR/top-processes.log" ]]; then
        echo "top_processes_last_sample:"
        awk '
            /^===== sample/ {block=$0; data=""; next}
            {data = data $0 "\n"}
            END {
                printf "%s\n", block
                print data
            }
        ' "$OUT_DIR/top-processes.log" | sed -n '1,20p'
        echo
    fi

    if [[ -f "$OUT_DIR/target-threads.log" ]]; then
        echo "target_threads_last_sample:"
        awk '
            /^===== sample/ {block=$0; data=""; next}
            {data = data $0 "\n"}
            END {
                printf "%s\n", block
                print data
            }
        ' "$OUT_DIR/target-threads.log" | sed -n '1,20p'
        echo
    fi

    if [[ -f "$OUT_DIR/compositor-status.log" ]]; then
        echo "compositor_status_last_sample:"
        awk '
            /^===== sample/ {block=$0; data=""; next}
            {data = data $0 "\n"}
            END {
                printf "%s\n", block
                print data
            }
        ' "$OUT_DIR/compositor-status.log" | sed -n '1,20p'
        echo
    fi

    if [[ -f "$OUT_DIR/compositor-sched.log" ]]; then
        echo "compositor_sched_tail:"
        tail -n 20 "$OUT_DIR/compositor-sched.log"
        echo
    fi

    if [[ -f "$OUT_DIR/nvidia-gpu.csv" ]]; then
        echo "nvidia_gpu_tail:"
        tail -n 5 "$OUT_DIR/nvidia-gpu.csv"
        echo
    fi
} > "$OUT_DIR/summary.txt"

log "Capture complete"
log "Summary: $OUT_DIR/summary.txt"
log "Raw samples: $OUT_DIR"
