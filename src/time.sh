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
  local zones compact sep out="" tz hour tm abbr dow weekend entry wk_override tpat
  zones=$(get_tmux_option "@time_revamped_timezones" "")
  [[ -z "${zones}" ]] && return 0
  compact=$(get_tmux_option "@time_revamped_compact" "0")
  sep=$(get_tmux_option "@time_revamped_zone_separator" " ")
  # When off, world clocks keep their time-of-day color and icon on weekends
  # instead of switching to the weekend color.
  wk_override=$(get_tmux_option "@time_revamped_weekend_override" "1")
  # World clocks honor the same 24H/12H option as the local clock. A 12H pattern
  # contains a space, so fields are pipe-delimited. "hide" has no meaning for a
  # clock, so it falls back to 24H.
  tpat=$(time_strftime "$(get_tmux_option "@time_revamped_time_format" "24H")")
  [[ -z "${tpat}" ]] && tpat="%H:%M"

  local list=() IFS=$', '
  read -ra list <<< "${zones}"
  for tz in "${list[@]}"; do
    [[ -z "${tz}" ]] && continue
    IFS='|' read -r hour tm abbr dow < <(_now_tz "${tz}" "%H|${tpat}|%Z|%u") || continue
    [[ -z "${tm}" ]] && continue
    [[ "${hour}" =~ ^[0-9]+$ ]] && hour=$(( 10#${hour} )) || hour=0
    if [[ "${wk_override}" == "1" ]]; then
      weekend=$(tz_is_weekend "${dow}")
    else
      weekend=0
    fi
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

# read_local -> the local clock rendered like a world clock: a place label, a
# time-of-day color and icon, and the time. The label is @time_revamped_local_label
# when set, else the local timezone city (auto-updates when the system zone
# changes while traveling). Honors the 24H/12H and weekend-override options.
read_local() {
  local label compact tpat hour tm dow weekend override
  compact=$(get_tmux_option "@time_revamped_compact" "0")
  tpat=$(time_strftime "$(get_tmux_option "@time_revamped_time_format" "24H")")
  [[ -z "${tpat}" ]] && tpat="%H:%M"
  IFS='|' read -r hour tm dow < <(_now_local "%H|${tpat}|%u")
  [[ -z "${tm}" ]] && return 0
  [[ "${hour}" =~ ^[0-9]+$ ]] && hour=$(( 10#${hour} )) || hour=0
  if [[ "$(get_tmux_option "@time_revamped_weekend_override" "1")" == "1" ]]; then
    weekend=$(tz_is_weekend "${dow}")
  else
    weekend=0
  fi
  override=$(get_tmux_option "@time_revamped_local_label" "")
  label="${override:-$(local_city_label)}"
  time_render_zone_compact "${label}" "${tm}" "${hour}" "${weekend}"
}

main() {
  case "${1:-}" in
    datetime) read_datetime ;;
    date)     read_date ;;
    clock)    read_clock ;;
    zones)    read_zones ;;
    local)    read_local ;;
    *)        return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
