#!/usr/bin/env bash
#
# tmux-cmd.sh: interactive actions (mark, copy, calendar, menu, format toggle).
#
# Every tmux invocation routes through the _tmux seam and every clipboard write
# through the _clipboard_copy seam. Tests override both, so no popup is ever
# opened and no real pbcopy/xclip runs. The actions themselves are thin: they
# read values via the same seamed helpers the placeholders use.

[[ -n "${_TIME_REVAMPED_TMUX_CMD_LOADED:-}" ]] && return 0
_TIME_REVAMPED_TMUX_CMD_LOADED=1

_TIME_TMUX_CMD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_TMUX_CMD_DIR}/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_TIME_TMUX_CMD_DIR}/../utils/has-command.sh"
# shellcheck source=/dev/null
source "${_TIME_TMUX_CMD_DIR}/../time/extras.sh"

# Host-probe seam: run a tmux command. Tests override this.
_tmux() { tmux "$@"; }

# Host-probe seam: copy text to the system clipboard. Tests override this so the
# real clipboard tools never run.
_clipboard_copy() {
  if has_command pbcopy; then
    printf '%s' "${1}" | pbcopy
  elif has_command wl-copy; then
    printf '%s' "${1}" | wl-copy
  elif has_command xclip; then
    printf '%s' "${1}" | xclip -selection clipboard
  fi
}

# time_set_mark -> store the current epoch as the stopwatch mark.
time_set_mark() {
  local ep
  ep=$(_now_epoch)
  set_tmux_option "@time_revamped_mark_epoch" "${ep}"
  _tmux display-message "time-revamped: mark set"
}

# time_copy_timestamp [iso|epoch] -> copy the timestamp to the tmux buffer and
# the system clipboard. Defaults to ISO 8601.
time_copy_timestamp() {
  local fmt="${1:-iso}" value
  case "${fmt}" in
    epoch) value=$(read_epoch) ;;
    *)     value=$(read_iso) ;;
  esac
  _tmux set-buffer "${value}"
  _clipboard_copy "${value}"
  _tmux display-message "time-revamped: copied ${value}"
}

# time_toggle_format -> flip the time format between 24H and 12H.
time_toggle_format() {
  local cur
  cur=$(get_tmux_option "@time_revamped_time_format" "24H")
  if [[ "${cur}" == "12H" ]]; then
    set_tmux_option "@time_revamped_time_format" "24H"
  else
    set_tmux_option "@time_revamped_time_format" "12H"
  fi
}

# time_calendar_popup -> show the current month's calendar in a popup. Gated on
# tmux 3.2+ by the caller; the body is a single display-popup.
time_calendar_popup() {
  _tmux display-popup -E "cal; echo; read -rsn1 -p 'press any key to close'"
}

# time_menu -> the prefix menu of time actions. Each entry runs back through the
# dispatcher named by TIME_DISPATCH.
time_menu() {
  local cmd="${TIME_DISPATCH:-}"
  _tmux display-menu -T "time-revamped" \
    "Toggle 12/24h" h "run-shell \"${cmd} toggle-format\"" \
    "Calendar"      c "run-shell \"${cmd} calendar\"" \
    "Copy ISO"      i "run-shell \"${cmd} copy iso\"" \
    "Copy epoch"    e "run-shell \"${cmd} copy epoch\"" \
    "Set mark"      m "run-shell \"${cmd} mark\"" \
    "Doctor"        d "run-shell \"${cmd} doctor\""
}

export -f _tmux
export -f _clipboard_copy
export -f time_set_mark
export -f time_copy_timestamp
export -f time_toggle_format
export -f time_calendar_popup
export -f time_menu
