#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_EXTRAS_LOADED _TIME_REVAMPED_DATEMATH_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/extras.sh"
}

teardown() {
  cleanup_test_environment
}

@test "extras.sh - read_epoch returns the clock seam epoch" {
  [[ "$(read_epoch)" == "1000000" ]]
}

@test "extras.sh - read_iso inserts a colon into the offset" {
  _now_local() { echo "2026-06-30T14:30:00-0300"; }
  [[ "$(read_iso)" == "2026-06-30T14:30:00-03:00" ]]
}

@test "extras.sh - read_iso passes a value with no trailing offset through" {
  _now_local() { echo "2026-06-30T14:30:00"; }
  [[ "$(read_iso)" == "2026-06-30T14:30:00" ]]
}

@test "extras.sh - read_offset renders UTC for a zero offset" {
  _now_local() { echo "+0000"; }
  [[ "$(read_offset)" == "UTC" ]]
}

@test "extras.sh - read_offset renders a positive and a negative offset" {
  _now_local() { echo "+0530"; }
  [[ "$(read_offset)" == "UTC+05:30" ]]
  _now_local() { echo "-0300"; }
  [[ "$(read_offset)" == "UTC-03:00" ]]
}

@test "extras.sh - read_week strips the leading zero" {
  _now_local() { echo "07"; }
  [[ "$(read_week)" == "7" ]]
  _now_local() { echo "bad"; }
  [[ -z "$(read_week)" ]]
}

@test "extras.sh - read_doy strips the leading zero" {
  _now_local() { echo "008"; }
  [[ "$(read_doy)" == "8" ]]
  _now_local() { echo "bad"; }
  [[ -z "$(read_doy)" ]]
}

@test "extras.sh - read_until counts down to the target" {
  _now_local() { echo "2026-06-30 12:00:00"; }
  set_tmux_option "@time_revamped_countdown_target" "2026-07-01 12:00:00"
  [[ "$(read_until)" == "1d 0h" ]]
}

@test "extras.sh - read_until prefixes a configured label" {
  _now_local() { echo "2026-06-30 12:00:00"; }
  set_tmux_option "@time_revamped_countdown_target" "2026-06-30 13:30:00"
  set_tmux_option "@time_revamped_countdown_label" "launch"
  [[ "$(read_until)" == "launch 1h 30m" ]]
}

@test "extras.sh - read_until reports the done text once reached" {
  _now_local() { echo "2026-07-02 12:00:00"; }
  set_tmux_option "@time_revamped_countdown_target" "2026-07-01 12:00:00"
  set_tmux_option "@time_revamped_countdown_done" "launched"
  [[ "$(read_until)" == "launched" ]]
}

@test "extras.sh - read_until is empty without a target or on a bad target" {
  _now_local() { echo "2026-06-30 12:00:00"; }
  [[ -z "$(read_until)" ]]
  set_tmux_option "@time_revamped_countdown_target" "garbage"
  [[ -z "$(read_until)" ]]
}

@test "extras.sh - read_until is empty when now cannot be parsed" {
  _now_local() { echo "broken-clock"; }
  set_tmux_option "@time_revamped_countdown_target" "2026-07-01 12:00:00"
  [[ -z "$(read_until)" ]]
}

@test "extras.sh - read_elapsed measures since the mark" {
  _now_epoch() { echo 1000600; }
  set_tmux_option "@time_revamped_mark_epoch" "1000000"
  [[ "$(read_elapsed)" == "10m" ]]
}

@test "extras.sh - read_elapsed clamps a future mark to zero" {
  _now_epoch() { echo 1000000; }
  set_tmux_option "@time_revamped_mark_epoch" "1000600"
  [[ "$(read_elapsed)" == "<1m" ]]
}

@test "extras.sh - read_elapsed is empty without a valid mark" {
  [[ -z "$(read_elapsed)" ]]
  set_tmux_option "@time_revamped_mark_epoch" "notanumber"
  [[ -z "$(read_elapsed)" ]]
}

@test "extras.sh - read_elapsed is empty when the clock seam is bad" {
  _now_epoch() { echo "nope"; }
  set_tmux_option "@time_revamped_mark_epoch" "1000000"
  [[ -z "$(read_elapsed)" ]]
}

@test "extras.sh - relative_day_badge flags the day delta" {
  [[ "$(relative_day_badge 2026 7 1 2026 6 30)" == "+1d" ]]
  [[ "$(relative_day_badge 2026 6 29 2026 6 30)" == "-1d" ]]
  [[ -z "$(relative_day_badge 2026 6 30 2026 6 30)" ]]
}

@test "extras.sh - relative_day_badge is empty on non-numeric input" {
  [[ -z "$(relative_day_badge '' '' '' 2026 6 30)" ]]
}

@test "extras.sh - in_work_hours bounds the window" {
  run in_work_hours 9 9 17
  [[ "${status}" -eq 0 ]]
  run in_work_hours 16 9 17
  [[ "${status}" -eq 0 ]]
  run in_work_hours 17 9 17
  [[ "${status}" -ne 0 ]]
  run in_work_hours 3 9 17
  [[ "${status}" -ne 0 ]]
  run in_work_hours bad 9 17
  [[ "${status}" -ne 0 ]]
}
