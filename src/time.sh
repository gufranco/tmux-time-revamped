#!/usr/bin/env bash
#
# time.sh: command dispatcher for tmux-time-revamped.
#
# Usage: time.sh datetime | date | clock | zones
#
# The clock is computed live on every call. A date read is instant, so there is
# no slow probe to cache and no temp file is touched.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/time/time.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/time/render.sh"

# read_zones -> the configured world clocks, formatted and joined.
read_zones() {
  local zones compact sep out="" tz hour tm abbr dow weekend entry
  zones=$(get_tmux_option "@time_revamped_timezones" "")
  [[ -z "${zones}" ]] && return 0
  compact=$(get_tmux_option "@time_revamped_compact" "0")
  sep=$(get_tmux_option "@time_revamped_zone_separator" " ")

  local list=() IFS=$', '
  read -ra list <<< "${zones}"
  for tz in "${list[@]}"; do
    [[ -z "${tz}" ]] && continue
    read -r hour tm abbr dow < <(_now_tz "${tz}" "%H %H:%M %Z %u") || continue
    [[ -z "${tm}" ]] && continue
    [[ "${hour}" =~ ^[0-9]+$ ]] && hour=$(( 10#${hour} )) || hour=0
    weekend=$(tz_is_weekend "${dow}")
    if [[ "${compact}" == "1" ]]; then
      entry=$(time_render_zone_compact "$(compact_tz_label "${tz}")" "${tm}" "${hour}" "${weekend}")
    else
      entry=$(time_render_zone_full "${abbr}" "${tm}" "${hour}" "${weekend}")
    fi
    [[ -n "${out}" ]] && out="${out}${sep}"
    out="${out}${entry}"
  done
  echo "${out}"
}

main() {
  case "${1:-}" in
    datetime) read_datetime ;;
    date)     read_date ;;
    clock)    read_clock ;;
    zones)    read_zones ;;
    *)        return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
