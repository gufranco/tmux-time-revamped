#!/usr/bin/env bash
#
# extras.sh: extra time placeholders built on the clock seams and pure math.
#
# Developer formats (epoch, ISO 8601, UTC offset), the ISO week and day-of-year,
# a countdown to a target datetime, and a stopwatch since a mark. Every clock
# read goes through the _now_local / _now_epoch seams so tests pin a fixed clock,
# and all arithmetic is the portable pure math from datemath.sh. Also holds the
# pure per-zone helpers the dispatcher uses to decorate world clocks.

[[ -n "${_TIME_REVAMPED_EXTRAS_LOADED:-}" ]] && return 0
_TIME_REVAMPED_EXTRAS_LOADED=1

_TIME_EXTRAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_EXTRAS_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_TIME_EXTRAS_DIR}/datemath.sh"

# read_epoch -> the current unix epoch.
read_epoch() { _now_epoch; }

# read_iso -> the local time in ISO 8601 with a colon in the offset, for example
# 2026-06-30T14:30:00-03:00.
read_iso() {
  local s
  s=$(_now_local "%Y-%m-%dT%H:%M:%S%z")
  if [[ "${s}" =~ ^(.*)([+-][0-9]{2})([0-9]{2})$ ]]; then
    printf '%s%s:%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
  else
    printf '%s\n' "${s}"
  fi
}

# read_offset -> the local UTC offset as "UTC", "UTC+02:00", or "UTC-03:00".
read_offset() {
  local z m total sign hh mm
  z=$(_now_local "%z")
  m=$(offset_minutes "${z}") || true
  if (( m == 0 )); then
    echo "UTC"
    return 0
  fi
  total="${m}"; sign="+"
  if (( total < 0 )); then sign="-"; total=$(( -total )); fi
  hh=$(( total / 60 )); mm=$(( total % 60 ))
  printf 'UTC%s%02d:%02d\n' "${sign}" "${hh}" "${mm}"
}

# read_week -> the ISO 8601 week number with no leading zero.
read_week() {
  local w
  w=$(_now_local "%V")
  [[ "${w}" =~ ^[0-9]+$ ]] || return 0
  echo $(( 10#${w} ))
}

# read_doy -> the day of the year with no leading zero.
read_doy() {
  local j
  j=$(_now_local "%j")
  [[ "${j}" =~ ^[0-9]+$ ]] || return 0
  echo $(( 10#${j} ))
}

# read_until -> the countdown to @time_revamped_countdown_target, optionally
# prefixed by @time_revamped_countdown_label. The target and "now" are parsed in
# the same naive frame, so the local offset cancels and no timezone DB is needed.
read_until() {
  local target label tep now nep diff text done_txt
  target=$(get_tmux_option "@time_revamped_countdown_target" "")
  [[ -z "${target}" ]] && return 0
  tep=$(parse_to_epoch "${target}")
  [[ -z "${tep}" ]] && return 0
  now=$(_now_local "%Y-%m-%d %H:%M:%S")
  nep=$(parse_to_epoch "${now}")
  [[ -z "${nep}" ]] && return 0
  label=$(get_tmux_option "@time_revamped_countdown_label" "")
  diff=$(( tep - nep ))
  if (( diff <= 0 )); then
    done_txt=$(get_tmux_option "@time_revamped_countdown_done" "now")
    text="${done_txt}"
  else
    text=$(fmt_duration "${diff}")
  fi
  if [[ -n "${label}" ]]; then
    printf '%s %s\n' "${label}" "${text}"
  else
    printf '%s\n' "${text}"
  fi
}

# read_elapsed -> the stopwatch since the mark stored in @time_revamped_mark_epoch,
# empty when no mark is set.
read_elapsed() {
  local mark now diff
  mark=$(get_tmux_option "@time_revamped_mark_epoch" "")
  [[ "${mark}" =~ ^[0-9]+$ ]] || return 0
  now=$(_now_epoch)
  [[ "${now}" =~ ^[0-9]+$ ]] || return 0
  diff=$(( now - mark ))
  (( diff < 0 )) && diff=0
  fmt_duration "${diff}"
}

# relative_day_badge ZY ZM ZD LY LM LD -> "+1d" or "-1d" style badge when the
# zone's calendar day differs from the local day, empty when they match.
relative_day_badge() {
  local zd ld delta
  [[ "${1:-}" =~ ^[0-9]+$ && "${4:-}" =~ ^[0-9]+$ ]] || return 0
  zd=$(days_from_civil "${1}" "${2}" "${3}")
  ld=$(days_from_civil "${4}" "${5}" "${6}")
  delta=$(( zd - ld ))
  if (( delta > 0 )); then
    printf '+%dd\n' "${delta}"
  elif (( delta < 0 )); then
    printf '%dd\n' "${delta}"
  fi
}

# in_work_hours HOUR START END -> 0 when START <= HOUR < END.
in_work_hours() {
  local h="${1:-0}" s="${2:-0}" e="${3:-0}"
  [[ "${h}" =~ ^[0-9]+$ ]] || h=0
  (( h >= s && h < e ))
}

export -f read_epoch
export -f read_iso
export -f read_offset
export -f read_week
export -f read_doy
export -f read_until
export -f read_elapsed
export -f relative_day_badge
export -f in_work_hours
