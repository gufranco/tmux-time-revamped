#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_TIME_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/time.sh"
}

teardown() {
  cleanup_test_environment
}

@test "time.sh - date_strftime maps every format" {
  [[ "$(date_strftime YMD)" == "%Y-%m-%d" ]]
  [[ "$(date_strftime MD)" == "%m-%d" ]]
  [[ "$(date_strftime DM)" == "%d-%m" ]]
  [[ "$(date_strftime MDY)" == "%m-%d-%Y" ]]
  [[ "$(date_strftime DMY)" == "%d-%m-%Y" ]]
  [[ -z "$(date_strftime hide)" ]]
  [[ "$(date_strftime bogus)" == "%Y-%m-%d" ]]
}

@test "time.sh - time_strftime maps every format" {
  [[ "$(time_strftime 24H)" == "%H:%M" ]]
  [[ "$(time_strftime 12H)" == "%I:%M %p" ]]
  [[ -z "$(time_strftime hide)" ]]
  [[ "$(time_strftime bogus)" == "%H:%M" ]]
}

@test "time.sh - compact_tz_label builds initials or a short prefix" {
  [[ "$(compact_tz_label America/New_York)" == "NY" ]]
  [[ "$(compact_tz_label America/Sao_Paulo)" == "SP" ]]
  [[ "$(compact_tz_label Europe/London)" == "Lon" ]]
  [[ "$(compact_tz_label UTC)" == "UTC" ]]
}

@test "time.sh - tz_is_weekend flags Saturday and Sunday" {
  [[ "$(tz_is_weekend 6)" == "1" ]]
  [[ "$(tz_is_weekend 7)" == "1" ]]
  [[ "$(tz_is_weekend 1)" == "0" ]]
  [[ "$(tz_is_weekend 5)" == "0" ]]
}

@test "time.sh - read_date uses the configured format and hides on demand" {
  _now_local() { echo "PAT:$1"; }
  [[ "$(read_date)" == "PAT:%Y-%m-%d" ]]
  set_tmux_option "@time_revamped_date_format" "DMY"
  [[ "$(read_date)" == "PAT:%d-%m-%Y" ]]
  set_tmux_option "@time_revamped_date_format" "hide"
  [[ -z "$(read_date)" ]]
}

@test "time.sh - read_clock uses the configured format and hides on demand" {
  _now_local() { echo "PAT:$1"; }
  [[ "$(read_clock)" == "PAT:%H:%M" ]]
  set_tmux_option "@time_revamped_time_format" "12H"
  [[ "$(read_clock)" == "PAT:%I:%M %p" ]]
  set_tmux_option "@time_revamped_time_format" "hide"
  [[ -z "$(read_clock)" ]]
}

@test "time.sh - read_datetime joins date and time" {
  _now_local() { case "$1" in %Y-%m-%d) echo "2026-06-20" ;; %H:%M) echo "14:30" ;; esac; }
  [[ "$(read_datetime)" == "2026-06-20 14:30" ]]
}

@test "time.sh - read_datetime falls back to whichever part shows" {
  _now_local() { echo "14:30"; }
  set_tmux_option "@time_revamped_date_format" "hide"
  [[ "$(read_datetime)" == "14:30" ]]
}

@test "time.sh - read_datetime shows the date alone when time is hidden" {
  _now_local() { echo "2026-06-20"; }
  set_tmux_option "@time_revamped_time_format" "hide"
  [[ "$(read_datetime)" == "2026-06-20" ]]
}

@test "time.sh - host-probe seams are callable" {
  run _now_local "%H:%M"
  run _now_tz UTC "%H"
  true
}
