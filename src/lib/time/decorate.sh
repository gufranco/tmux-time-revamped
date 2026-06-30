#!/usr/bin/env bash
#
# decorate.sh: pure decoration of a rendered world-clock entry.
#
# Adds an optional relative-day badge after the time, a dim style around a zone
# outside working hours, and a highlight style around the primary zone. The base
# entry already ends in the configured reset, which also clears the prepended
# styles, so no extra reset is needed.

[[ -n "${_TIME_REVAMPED_DECORATE_LOADED:-}" ]] && return 0
_TIME_REVAMPED_DECORATE_LOADED=1

_TIME_DECORATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_DECORATE_DIR}/../tmux/tmux-ops.sh"

# zone_decorate ENTRY BADGE PRIMARY IN_WORK -> the entry with badge appended and
# dim/highlight styles prepended. PRIMARY and IN_WORK are "1"/"0" flags.
zone_decorate() {
  local entry="${1}" badge="${2:-}" primary="${3:-0}" in_work="${4:-1}"
  local out="${entry}" dim ps
  if [[ -n "${badge}" ]]; then
    out="${out} ${badge}"
  fi
  if [[ "${in_work}" == "0" ]]; then
    dim=$(get_tmux_option "@time_revamped_dim_style" "#[dim]")
    [[ "${dim}" != "none" ]] && out="${dim}${out}"
  fi
  if [[ "${primary}" == "1" ]]; then
    ps=$(get_tmux_option "@time_revamped_primary_style" "#[bold]")
    [[ "${ps}" != "none" ]] && out="${ps}${out}"
  fi
  printf '%s\n' "${out}"
}

export -f zone_decorate
