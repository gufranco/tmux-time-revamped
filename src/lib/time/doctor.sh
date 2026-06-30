#!/usr/bin/env bash
#
# doctor.sh: validate the configured timezone names and report typos.
#
# A zone is valid when its zoneinfo file exists, which is the same check on macOS
# and Linux. The filesystem probe sits behind the _tz_exists seam so the report
# logic is tested with a pinned set of valid and invalid zones.

[[ -n "${_TIME_REVAMPED_DOCTOR_LOADED:-}" ]] && return 0
_TIME_REVAMPED_DOCTOR_LOADED=1

_TIME_DOCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_DOCTOR_DIR}/../tmux/tmux-ops.sh"

# Where the system keeps the zoneinfo database.
TIME_ZONEINFO_DIR="${TIME_ZONEINFO_DIR:-/usr/share/zoneinfo}"

# _tz_exists ZONE -> 0 when the zoneinfo file for ZONE exists. Host-probe seam.
_tz_exists() {
  [[ -f "${TIME_ZONEINFO_DIR}/${1}" ]]
}

# read_doctor -> a per-zone OK/BAD report plus a one-line summary.
read_doctor() {
  local zones list=() i tz ok=0 bad=0 out=""
  zones=$(get_tmux_option "@time_revamped_timezones" "")
  if [[ -z "${zones}" ]]; then
    echo "time-revamped: no timezones configured"
    return 0
  fi
  local IFS=$', '
  read -ra list <<< "${zones}"
  for (( i = 0; i < ${#list[@]}; i++ )); do
    tz="${list[i]}"
    [[ -z "${tz}" ]] && continue
    if _tz_exists "${tz}"; then
      out="${out}OK   ${tz}"$'\n'
      ok=$(( ok + 1 ))
    else
      out="${out}BAD  ${tz}"$'\n'
      bad=$(( bad + 1 ))
    fi
  done
  printf '%s' "${out}"
  printf 'time-revamped: %d ok, %d invalid\n' "${ok}" "${bad}"
}

export -f _tz_exists
export -f read_doctor
