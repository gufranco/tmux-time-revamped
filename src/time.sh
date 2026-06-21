#!/usr/bin/env bash
#
# time.sh: command dispatcher for tmux-time-revamped.
#
# Usage: time.sh datetime | date | clock | zones
#
# The clock is computed live on every call. A date read is instant, so there is
# no slow probe to cache and no temp file is touched.

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="time_revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/has-command.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/time/time.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/time/render.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/time/geoip.sh"

# read_zones -> the configured world clocks, formatted and joined.
read_zones() {
  local zones compact sep out="" tz hour tm abbr dow weekend entry wk_override tpat
  local labels_csv custom label i
  zones=$(get_tmux_option "@time_revamped_timezones" "")
  [[ -z "${zones}" ]] && return 0
  compact=$(get_tmux_option "@time_revamped_compact" "0")
  sep=$(get_tmux_option "@time_revamped_zone_separator" " ")
  # Optional per-zone labels, comma separated and matched to the timezones by
  # position, for example "Los Angeles, New York, Tokyo".
  labels_csv=$(get_tmux_option "@time_revamped_zone_labels" "")
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
  for (( i = 0; i < ${#list[@]}; i++ )); do
    tz="${list[i]}"
    [[ -z "${tz}" ]] && continue
    IFS='|' read -r hour tm abbr dow < <(_now_tz "${tz}" "%H|${tpat}|%Z|%u") || continue
    [[ -z "${tm}" ]] && continue
    [[ "${hour}" =~ ^[0-9]+$ ]] && hour=$(( 10#${hour} )) || hour=0
    if [[ "${wk_override}" == "1" ]]; then
      weekend=$(tz_is_weekend "${dow}")
    else
      weekend=0
    fi
    custom=$(zone_label_at "${i}" "${labels_csv}")
    if [[ "${compact}" == "1" ]]; then
      label="${custom:-$(compact_tz_label "${tz}")}"
      entry=$(time_render_zone_compact "${label}" "${tm}" "${hour}" "${weekend}")
    else
      label="${custom:-${abbr}}"
      entry=$(time_render_zone_full "${label}" "${tm}" "${hour}" "${weekend}")
    fi
    [[ -n "${out}" ]] && out="${out}${sep}"
    out="${out}${entry}"
  done
  echo "${out}"
}

# _geoip_max_age -> the geoip cache lifetime in seconds, from a minutes option.
_geoip_max_age() {
  local m
  m=$(get_tmux_option "@time_revamped_geoip_interval" "30")
  [[ "${m}" =~ ^[0-9]+$ ]] || m=30
  echo $(( m * 60 ))
}

# geoip_refresh -> the cache worker: fetch the city once and store it. A failed
# fetch keeps the last good value, so a brief outage does not blank the label.
geoip_refresh() {
  local endpoint body city
  endpoint=$(get_tmux_option "@time_revamped_geoip_endpoint" "https://ipinfo.io/city")
  body=$(_read_geoip "${endpoint}")
  city=$(geoip_parse_city "${body}")
  if [[ -n "${city}" ]]; then
    cache_set geoip_city "${city}"
  else
    cache_set geoip_city "$(cache_get geoip_city)"
  fi
}

# _local_label_auto -> the auto-detected place label. With geoip enabled and curl
# present, the cached city wins, refreshed in the background so the render never
# waits on the network. Otherwise it falls back to the system timezone city.
_local_label_auto() {
  local city
  if [[ "$(get_tmux_option "@time_revamped_local_source" "timezone")" == "geoip" ]] && has_command curl; then
    city=$(cache_render geoip_city "$(_geoip_max_age)" geoip_refresh)
    [[ -n "${city}" ]] && { printf '%s' "${city}"; return 0; }
  fi
  local_city_label
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
  label="${override:-$(_local_label_auto)}"
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
