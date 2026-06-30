#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_TZOFFSET_LOADED _TIME_REVAMPED_DATEMATH_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/tzoffset.sh"
}

teardown() {
  cleanup_test_environment
}

@test "tzoffset.sh - _date_is_gnu is callable on this host" {
  run _date_is_gnu
  [[ "${status}" -eq 0 || "${status}" -eq 1 ]]
}

@test "tzoffset.sh - _tz_offset_for_epoch reads a real zone offset" {
  run _tz_offset_for_epoch UTC 1000000
  [[ "${output}" == "+0000" ]]
}

@test "tzoffset.sh - _tz_offset_for_epoch reads the local offset" {
  run _tz_offset_for_epoch "" 1000000
  [[ "${output}" =~ ^[+-][0-9]{4}$ ]]
}

@test "tzoffset.sh - read_dst warns when the offset changes within the horizon" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() {
    if (( $2 >= 1000000 + 3 * 86400 )); then echo "-0200"; else echo "-0300"; fi
  }
  [[ "$(read_dst)" == "DST in 3d" ]]
}

@test "tzoffset.sh - read_dst honors a custom label" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() {
    if (( $2 >= 1000000 + 86400 )); then echo "+0100"; else echo "+0000"; fi
  }
  set_tmux_option "@time_revamped_dst_label" "clocks change"
  [[ "$(read_dst)" == "clocks change in 1d" ]]
}

@test "tzoffset.sh - read_dst is empty with no change in the horizon" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() { echo "-0300"; }
  [[ -z "$(read_dst)" ]]
}

@test "tzoffset.sh - read_dst skips a day with no resolvable offset" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() {
    if (( $2 == 1000000 + 86400 )); then echo ""; \
    elif (( $2 >= 1000000 + 2 * 86400 )); then echo "-0200"; else echo "-0300"; fi
  }
  [[ "$(read_dst)" == "DST in 2d" ]]
}

@test "tzoffset.sh - read_dst defaults a non-numeric horizon and bails on a bad clock" {
  _now_epoch() { echo "nope"; }
  _tz_offset_for_epoch() { echo "-0300"; }
  [[ -z "$(read_dst)" ]]
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() { echo ""; }
  set_tmux_option "@time_revamped_dst_horizon" "abc"
  [[ -z "$(read_dst)" ]]
}

@test "tzoffset.sh - _overlap_mask marks the working hours of one zone" {
  [[ "$(_overlap_mask '0' 9 17)" == "000000000111111110000000" ]]
}

@test "tzoffset.sh - _overlap_mask intersects two zones" {
  [[ "$(_overlap_mask '0,-60' 9 17)" == "000000000011111110000000" ]]
}

@test "tzoffset.sh - _overlap_mask wraps a large negative offset" {
  run _overlap_mask '-780' 9 17
  [[ "${#output}" -eq 24 ]]
  [[ "${output}" == *1* ]]
}

@test "tzoffset.sh - _overlap_window finds the longest contiguous run" {
  [[ "$(_overlap_window '000000000111111110000000')" == "9 17" ]]
}

@test "tzoffset.sh - _overlap_window handles all-on and all-off masks" {
  [[ "$(_overlap_window '111111111111111111111111')" == "0 24" ]]
  [[ -z "$(_overlap_window '000000000000000000000000')" ]]
}

@test "tzoffset.sh - _overlap_window wraps past midnight" {
  [[ "$(_overlap_window '110000000000000000000011')" == "22 26" ]]
}

@test "tzoffset.sh - read_overlap reports the local window when zones overlap" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() { echo "+0000"; }
  set_tmux_option "@time_revamped_timezones" "UTC, UTC"
  [[ "$(read_overlap)" == "overlap 09:00-17:00" ]]
}

@test "tzoffset.sh - read_overlap reports no overlap with a custom label" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() { case "$1" in A) echo "+0000" ;; B) echo "+0800" ;; *) echo "+0000" ;; esac; }
  set_tmux_option "@time_revamped_timezones" "A, B"
  set_tmux_option "@time_revamped_overlap_label" "team"
  set_tmux_option "@time_revamped_overlap_none" "none today"
  [[ "$(read_overlap)" == "team none today" ]]
}

@test "tzoffset.sh - read_overlap is empty without zones" {
  [[ -z "$(read_overlap)" ]]
}

@test "tzoffset.sh - read_overlap bails on a bad clock or unresolved offset" {
  _now_epoch() { echo "nope"; }
  set_tmux_option "@time_revamped_timezones" "UTC"
  [[ -z "$(read_overlap)" ]]
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() { echo ""; }
  [[ -z "$(read_overlap)" ]]
}

@test "tzoffset.sh - read_overlap bails when an offset cannot be parsed" {
  _now_epoch() { echo 1000000; }
  _tz_offset_for_epoch() { echo "GMT"; }
  set_tmux_option "@time_revamped_timezones" "UTC"
  [[ -z "$(read_overlap)" ]]
}
