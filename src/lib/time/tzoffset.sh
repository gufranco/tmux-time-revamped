#!/usr/bin/env bash
#
# tzoffset.sh: DST-change warning and shared business-hours overlap.
#
# Both features need the UTC offset of a zone at a given epoch. That single read
# lives behind the _tz_offset_for_epoch seam, which hides the only BSD/GNU date
# difference (an epoch is formatted with `date -r` on BSD and `date -d @` on GNU).
# Everything above the seam is pure: the future epochs are plain arithmetic and
# the overlap mask is integer math, so tests pin the clock and the seam to cover
# every branch without a real date call.

[[ -n "${_TIME_REVAMPED_TZOFFSET_LOADED:-}" ]] && return 0
_TIME_REVAMPED_TZOFFSET_LOADED=1

_TIME_TZOFFSET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_TIME_TZOFFSET_DIR}/../tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${_TIME_TZOFFSET_DIR}/datemath.sh"

# _date_is_gnu -> 0 when the date binary is GNU coreutils (supports --version).
_date_is_gnu() { date --version >/dev/null 2>&1; }

# _tz_offset_for_epoch TZ EPOCH -> the "%z" offset of TZ at EPOCH. An empty TZ
# means the local zone. Host-probe seam; tests override this.
_tz_offset_for_epoch() {
  local tz="${1:-}" ep="${2:-0}" flag
  if _date_is_gnu; then flag="-d@${ep}"; else flag="-r${ep}"; fi
  if [[ -n "${tz}" ]]; then
    TZ="${tz}" date "${flag}" +%z 2>/dev/null
  else
    date "${flag}" +%z 2>/dev/null
  fi
}

# read_dst -> "DST in Nd" when the zone's UTC offset changes within the horizon,
# empty otherwise. The zone is @time_revamped_dst_zone (empty means local).
read_dst() {
  local zone horizon now base off d label
  zone=$(get_tmux_option "@time_revamped_dst_zone" "")
  horizon=$(get_tmux_option "@time_revamped_dst_horizon" "14")
  [[ "${horizon}" =~ ^[0-9]+$ ]] || horizon=14
  now=$(_now_epoch)
  [[ "${now}" =~ ^[0-9]+$ ]] || return 0
  base=$(_tz_offset_for_epoch "${zone}" "${now}")
  [[ -n "${base}" ]] || return 0
  label=$(get_tmux_option "@time_revamped_dst_label" "DST")
  for (( d = 1; d <= horizon; d++ )); do
    off=$(_tz_offset_for_epoch "${zone}" "$(( now + d * 86400 ))")
    [[ -n "${off}" ]] || continue
    if [[ "${off}" != "${base}" ]]; then
      printf '%s in %dd\n' "${label}" "${d}"
      return 0
    fi
  done
}

# _overlap_mask "OFF1,OFF2,..." START END -> a 24-char string of 1/0, one per UTC
# hour, where every zone (given as signed offset minutes) is within [START,END).
_overlap_mask() {
  local offsets_csv="${1}" start="${2}" end="${3}"
  local offs=() IFS=','
  read -ra offs <<< "${offsets_csv}"
  local h mask="" all off lm lh
  for (( h = 0; h < 24; h++ )); do
    all=1
    for off in "${offs[@]}"; do
      lm=$(( h * 60 + off ))
      lm=$(( ((lm % 1440) + 1440) % 1440 ))
      lh=$(( lm / 60 ))
      if (( lh < start || lh >= end )); then all=0; break; fi
    done
    mask="${mask}${all}"
  done
  printf '%s\n' "${mask}"
}

# _overlap_window MASK -> "START END" for the longest run of 1s, treating the day
# as circular so a window may wrap past midnight (END can exceed 24). Empty when
# there is no overlap.
_overlap_window() {
  local mask="${1}" i c
  local n="${#mask}"
  local ones=0 best_len=0 best_start=-1 cur_len=0 cur_start=0
  for (( i = 0; i < n; i++ )); do
    [[ "${mask:i:1}" == "1" ]] && ones=$(( ones + 1 ))
  done
  (( ones == 0 )) && return 0
  if (( ones == n )); then
    printf '0 %d\n' "${n}"
    return 0
  fi
  for (( i = 0; i < 2 * n; i++ )); do
    c="${mask:i%n:1}"
    if [[ "${c}" == "1" ]]; then
      (( cur_len == 0 )) && cur_start=$(( i % n ))
      cur_len=$(( cur_len + 1 ))
      if (( cur_len > best_len )); then best_len="${cur_len}"; best_start="${cur_start}"; fi
    else
      cur_len=0
    fi
  done
  (( best_len > n )) && best_len="${n}"
  printf '%d %d\n' "${best_start}" "$(( best_start + best_len ))"
}

# read_overlap -> the shared working-hours window across @time_revamped_timezones,
# expressed in the local zone, or a "no overlap" message. Empty when no zones are
# configured or an offset cannot be resolved.
read_overlap() {
  local zones ws we now tz off m offsets="" mask win start end localoff lm lstart lend
  local prefix none
  zones=$(get_tmux_option "@time_revamped_timezones" "")
  [[ -z "${zones}" ]] && return 0
  ws=$(get_tmux_option "@time_revamped_work_start" "9")
  we=$(get_tmux_option "@time_revamped_work_end" "17")
  now=$(_now_epoch)
  [[ "${now}" =~ ^[0-9]+$ ]] || return 0
  local list=() i IFS=$', '
  read -ra list <<< "${zones}"
  for (( i = 0; i < ${#list[@]}; i++ )); do
    tz="${list[i]}"
    [[ -z "${tz}" ]] && continue
    off=$(_tz_offset_for_epoch "${tz}" "${now}")
    [[ -n "${off}" ]] || return 0
    m=$(offset_minutes "${off}") || return 0
    if [[ -z "${offsets}" ]]; then offsets="${m}"; else offsets="${offsets},${m}"; fi
  done
  [[ -z "${offsets}" ]] && return 0
  prefix=$(get_tmux_option "@time_revamped_overlap_label" "overlap")
  mask=$(_overlap_mask "${offsets}" "${ws}" "${we}")
  win=$(_overlap_window "${mask}")
  if [[ -z "${win}" ]]; then
    none=$(get_tmux_option "@time_revamped_overlap_none" "no overlap")
    printf '%s %s\n' "${prefix}" "${none}"
    return 0
  fi
  localoff=$(_tz_offset_for_epoch "" "${now}")
  lm=$(offset_minutes "${localoff}") || lm=0
  read -r start end <<< "${win}"
  lstart=$(( (((start * 60 + lm) % 1440) + 1440) % 1440 / 60 ))
  lend=$(( (((end * 60 + lm) % 1440) + 1440) % 1440 / 60 ))
  printf '%s %02d:00-%02d:00\n' "${prefix}" "${lstart}" "${lend}"
}

export -f _date_is_gnu
export -f _tz_offset_for_epoch
export -f read_dst
export -f _overlap_mask
export -f _overlap_window
export -f read_overlap
