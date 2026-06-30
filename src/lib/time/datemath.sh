#!/usr/bin/env bash
#
# datemath.sh: portable, pure date arithmetic.
#
# Every function here is pure shell integer math except the single _now_epoch
# seam, which tests override. No date arithmetic flags are used, so the math is
# identical on BSD (macOS) and GNU date: civil dates convert to a day count with
# Howard Hinnant's algorithm, never with `date -d` or `date -v`. This keeps
# countdowns and durations deterministic and clock-pinnable under test.

[[ -n "${_TIME_REVAMPED_DATEMATH_LOADED:-}" ]] && return 0
_TIME_REVAMPED_DATEMATH_LOADED=1

# Host-probe seam: the current unix epoch. Tests override this.
_now_epoch() { date +%s 2>/dev/null || echo 0; }

# days_from_civil Y M D -> days since 1970-01-01 (may be negative before then).
# Pure integer math, valid for the proleptic Gregorian calendar.
days_from_civil() {
  local y="${1:-1970}" m="${2:-1}" d="${3:-1}"
  y=$(( 10#${y} )); m=$(( 10#${m} )); d=$(( 10#${d} ))
  (( m <= 2 )) && y=$(( y - 1 ))
  local era yoe doy doe mp
  if (( y >= 0 )); then era=$(( y / 400 )); else era=$(( (y - 399) / 400 )); fi
  yoe=$(( y - era * 400 ))
  if (( m > 2 )); then mp=$(( m - 3 )); else mp=$(( m + 9 )); fi
  doy=$(( (153 * mp + 2) / 5 + d - 1 ))
  doe=$(( yoe * 365 + yoe / 4 - yoe / 100 + doy ))
  echo $(( era * 146097 + doe - 719468 ))
}

# parse_to_epoch "YYYY-MM-DD[ HH:MM[:SS]]" -> the epoch (seconds) for that civil
# datetime, with date and time read in the same naive frame. T or space may join
# date and time. Empty output on a malformed string.
parse_to_epoch() {
  local s="${1:-}" Y M D H Mi S days
  if [[ "${s}" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})([T\ ]([0-9]{2}):([0-9]{2})(:([0-9]{2}))?)?$ ]]; then
    Y="${BASH_REMATCH[1]}"; M="${BASH_REMATCH[2]}"; D="${BASH_REMATCH[3]}"
    H="${BASH_REMATCH[5]:-0}"; Mi="${BASH_REMATCH[6]:-0}"; S="${BASH_REMATCH[8]:-0}"
  else
    return 0
  fi
  days=$(days_from_civil "${Y}" "${M}" "${D}")
  echo $(( days * 86400 + 10#${H} * 3600 + 10#${Mi} * 60 + 10#${S} ))
}

# fmt_duration SECONDS -> a compact "Nd Nh" / "Nh Nm" / "Nm" / "<1m" string.
# Negative input is treated as zero.
fmt_duration() {
  local secs="${1:-0}"
  [[ "${secs}" =~ ^-?[0-9]+$ ]] || secs=0
  (( secs < 0 )) && secs=0
  local d h m
  d=$(( secs / 86400 ))
  h=$(( (secs % 86400) / 3600 ))
  m=$(( (secs % 3600) / 60 ))
  if (( d > 0 )); then
    printf '%dd %dh\n' "${d}" "${h}"
  elif (( h > 0 )); then
    printf '%dh %dm\n' "${h}" "${m}"
  elif (( m > 0 )); then
    printf '%dm\n' "${m}"
  else
    printf '<1m\n'
  fi
}

# offset_minutes "+HHMM" -> the signed offset in minutes. Returns 0 and a nonzero
# status on a malformed value, so callers can guard.
offset_minutes() {
  local z="${1:-}" val
  if [[ "${z}" =~ ^([+-])([0-9]{2})([0-9]{2})$ ]]; then
    val=$(( 10#${BASH_REMATCH[2]} * 60 + 10#${BASH_REMATCH[3]} ))
    [[ "${BASH_REMATCH[1]}" == "-" ]] && val=$(( -val ))
    echo "${val}"
    return 0
  fi
  echo 0
  return 1
}

export -f _now_epoch
export -f days_from_civil
export -f parse_to_epoch
export -f fmt_duration
export -f offset_minutes
