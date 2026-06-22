#!/usr/bin/env bash
#
# time-revamped.tmux: TPM entry point.
#
# Replaces the #{time_*} placeholders in status-left and status-right with calls
# to the dispatcher, which computes the clock live and never blocks the render.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIME_CMD="${PLUGIN_DIR}/src/time.sh"

placeholders=(
  "\#{time}"
  "\#{time_date}"
  "\#{time_clock}"
  "\#{time_zones}"
  "\#{time_local}"
)

commands=(
  "#(${TIME_CMD} datetime)"
  "#(${TIME_CMD} date)"
  "#(${TIME_CMD} clock)"
  "#(${TIME_CMD} zones)"
  "#(${TIME_CMD} local)"
)

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
  done
  echo "${value}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${TIME_CMD}" 2>/dev/null || true

update_option "status-left"
update_option "status-right"
