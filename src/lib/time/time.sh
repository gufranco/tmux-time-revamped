#!/usr/bin/env bash
#
# time.sh: local clock and world-clock data.
#
# Pure formatters map option names to strftime patterns and timezone labels. The
# actual clock reads sit behind seams the tests override, so no real date call
# runs under test. Everything is computed live; date is instant, so there is no
# slow probe to push to a background worker.

[[ -n "${_TIME_REVAMPED_TIME_LOADED:-}" ]] && return 0
_TIME_REVAMPED_TIME_LOADED=1

_TIME_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_LIB_DIR}/../tmux/tmux-ops.sh"

# date_strftime NAME -> a strftime date pattern, empty for "hide".
date_strftime() {
  case "${1}" in
    YMD) echo "%Y-%m-%d" ;;
    MD)  echo "%m-%d" ;;
    DM)  echo "%d-%m" ;;
    MDY) echo "%m-%d-%Y" ;;
    DMY) echo "%d-%m-%Y" ;;
    hide) echo "" ;;
    *)   echo "%Y-%m-%d" ;;
  esac
}

# time_strftime NAME -> a strftime time pattern, empty for "hide".
time_strftime() {
  case "${1}" in
    12H)  echo "%I:%M %p" ;;
    hide) echo "" ;;
    *)    echo "%H:%M" ;;
  esac
}

# compact_tz_label TZ -> a short label from the city, e.g. America/New_York -> NY.
compact_tz_label() {
  local city="${1##*/}"
  if [[ "${city}" == *_* ]]; then
    local initials="" part
    local IFS='_'
    for part in ${city}; do
      initials="${initials}${part:0:1}"
    done
    echo "${initials}"
  else
    echo "${city:0:3}"
  fi
}

# zone_label_at INDEX CSV -> the trimmed label at zero-based INDEX in a comma
# separated list, empty when absent. Labels may contain spaces, so only commas
# separate them, for example "Los Angeles, New York, Tokyo".
zone_label_at() {
  local idx="${1}" item arr=()
  local IFS=','
  read -ra arr <<< "${2}"
  item="${arr[idx]:-}"
  item="${item#"${item%%[![:space:]]*}"}"
  item="${item%"${item##*[![:space:]]}"}"
  printf '%s' "${item}"
}

# tz_is_weekend DOW -> 1 on Saturday (6) or Sunday (7), else 0.
tz_is_weekend() {
  [[ "${1}" == "6" || "${1}" == "7" ]] && { echo 1; return 0; }
  echo 0
}

# local_city_label -> the local timezone city with underscores as spaces, e.g.
# America/Sao_Paulo -> "Sao Paulo". Empty when the zone cannot be resolved.
local_city_label() {
  local zone city
  zone=$(_local_tz_name)
  [[ -z "${zone}" ]] && { echo ""; return 0; }
  city="${zone##*/}"
  echo "${city//_/ }"
}

# Host-probe seams. Tests override these.
_now_local() { date +"${1}" 2>/dev/null; }
_now_tz() { TZ="${1}" date +"${2}" 2>/dev/null; }

# _local_tz_name -> the local IANA timezone, e.g. America/Sao_Paulo. Prefers $TZ,
# then the /etc/localtime symlink target. Empty when neither resolves.
_local_tz_name() {
  if [[ -n "${TZ:-}" ]]; then
    echo "${TZ}"
    return 0
  fi
  local link
  link=$(readlink /etc/localtime 2>/dev/null)
  case "${link}" in
    *zoneinfo/*) echo "${link#*zoneinfo/}" ;;
    *) echo "" ;;
  esac
}

# read_date -> the formatted local date, empty when hidden.
read_date() {
  local fmt pat
  fmt=$(get_tmux_option "@time_revamped_date_format" "YMD")
  pat=$(date_strftime "${fmt}")
  [[ -n "${pat}" ]] && _now_local "${pat}"
}

# read_clock -> the formatted local time, empty when hidden.
read_clock() {
  local fmt pat
  fmt=$(get_tmux_option "@time_revamped_time_format" "24H")
  pat=$(time_strftime "${fmt}")
  [[ -n "${pat}" ]] && _now_local "${pat}"
}

# read_datetime -> "<date> <time>", or whichever part is present.
read_datetime() {
  local d c
  d=$(read_date)
  c=$(read_clock)
  if [[ -n "${d}" && -n "${c}" ]]; then
    echo "${d} ${c}"
  elif [[ -n "${d}" ]]; then
    echo "${d}"
  elif [[ -n "${c}" ]]; then
    echo "${c}"
  fi
}

export -f date_strftime
export -f time_strftime
export -f compact_tz_label
export -f zone_label_at
export -f tz_is_weekend
export -f local_city_label
export -f _local_tz_name
export -f _now_local
export -f _now_tz
export -f read_date
export -f read_clock
export -f read_datetime
