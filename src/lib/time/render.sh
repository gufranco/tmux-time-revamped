#!/usr/bin/env bash
#
# render.sh: map a timezone hour to a period color and icon, and assemble a
# world-clock entry. The period buckets follow the day's rhythm: morning, day,
# afternoon, evening, night, with a weekend override.

[[ -n "${_TIME_REVAMPED_RENDER_LOADED:-}" ]] && return 0
_TIME_REVAMPED_RENDER_LOADED=1

_TIME_RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_RENDER_DIR}/../tmux/tmux-ops.sh"

_TIME_RESET="#[default]"

# period_of_hour HOUR -> night|morning|day|afternoon|evening for an integer hour.
period_of_hour() {
  local h="${1:-0}"
  [[ "${h}" =~ ^[0-9]+$ ]] || h=0
  if (( h >= 22 || h < 5 )); then
    echo "night"
  elif (( h < 12 )); then
    echo "morning"
  elif (( h < 14 )); then
    echo "day"
  elif (( h < 18 )); then
    echo "afternoon"
  else
    echo "evening"
  fi
}

# _time_period HOUR WEEKEND -> the period name, weekend overriding the hour.
_time_period() {
  [[ "${2}" == "1" ]] && { echo "weekend"; return 0; }
  period_of_hour "${1}"
}

# Default colors per period. Override with @time_revamped_<period>_color.
_time_default_color() {
  case "${1}" in
    morning)   echo "#[fg=yellow]" ;;
    day)       echo "#[fg=green]" ;;
    afternoon) echo "#[fg=cyan]" ;;
    evening)   echo "#[fg=magenta]" ;;
    night)     echo "#[fg=blue]" ;;
    weekend)   echo "#[fg=brightblack]" ;;
    *)         echo "" ;;
  esac
}

time_render_period_color() {
  local period
  period=$(_time_period "${1}" "${2}")
  get_tmux_option "@time_revamped_${period}_color" "$(_time_default_color "${period}")"
}

time_render_period_icon() {
  local period
  period=$(_time_period "${1}" "${2}")
  get_tmux_option "@time_revamped_${period}_icon" ""
}

# time_render_zone_full ABBR TIME HOUR WEEKEND -> "<color><abbr> [icon ]<time><reset>".
time_render_zone_full() {
  local abbr="${1}" tm="${2}" color icon
  color=$(time_render_period_color "${3}" "${4}")
  icon=$(time_render_period_icon "${3}" "${4}")
  if [[ -n "${icon}" ]]; then
    echo "${color}${abbr} ${icon} ${tm}${_TIME_RESET}"
  else
    echo "${color}${abbr} ${tm}${_TIME_RESET}"
  fi
}

# time_render_zone_compact LABEL TIME HOUR WEEKEND -> "<color><label> <time><reset>".
time_render_zone_compact() {
  local label="${1}" tm="${2}" color
  color=$(time_render_period_color "${3}" "${4}")
  echo "${color}${label} ${tm}${_TIME_RESET}"
}

export -f period_of_hour
export -f _time_period
export -f _time_default_color
export -f time_render_period_color
export -f time_render_period_icon
export -f time_render_zone_full
export -f time_render_zone_compact
