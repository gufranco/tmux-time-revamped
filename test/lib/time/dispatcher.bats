#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_TIME_LOADED _TIME_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/time.sh"
  _now_local() { case "$1" in %Y-%m-%d) echo "2026-06-20" ;; %H:%M) echo "14:30" ;; *) echo "X" ;; esac; }
  _now_tz() { case "$2" in *"%I:%M %p"*) echo "09|09:30 AM|EDT|5" ;; *) echo "09|09:30|EDT|5" ;; esac; }
}

teardown() {
  cleanup_test_environment
}

@test "time.sh dispatcher - functions are defined" {
  function_exists main
  function_exists read_zones
  function_exists read_datetime
}

@test "time.sh dispatcher - datetime joins date and clock" {
  run main datetime
  [[ "${output}" == "2026-06-20 14:30" ]]
}

@test "time.sh dispatcher - date and clock subcommands" {
  run main date
  [[ "${output}" == "2026-06-20" ]]
  run main clock
  [[ "${output}" == "14:30" ]]
}

@test "time.sh dispatcher - zones is empty without a timezone list" {
  run main zones
  [[ -z "${output}" ]]
}

@test "time.sh dispatcher - zones renders a full entry" {
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  run main zones
  [[ "${output}" == "#[fg=yellow]EDT 09:30#[default]" ]]
}

@test "time.sh dispatcher - zones renders compact entries" {
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  set_tmux_option "@time_revamped_compact" "1"
  run main zones
  [[ "${output}" == "#[fg=yellow]NY 09:30#[default]" ]]
}

@test "time.sh dispatcher - zones honor the 24H/12H time format" {
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  run main zones
  [[ "${output}" == "#[fg=yellow]EDT 09:30#[default]" ]]
  set_tmux_option "@time_revamped_time_format" "12H"
  run main zones
  [[ "${output}" == "#[fg=yellow]EDT 09:30 AM#[default]" ]]
}

@test "time.sh dispatcher - weekend override can be disabled for world clocks" {
  _now_tz() { echo "09|09:30|EDT|6"; }
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  set_tmux_option "@time_revamped_compact" "1"
  run main zones
  [[ "${output}" == "#[fg=brightblack]NY 09:30#[default]" ]]
  set_tmux_option "@time_revamped_weekend_override" "0"
  run main zones
  [[ "${output}" == "#[fg=yellow]NY 09:30#[default]" ]]
}

@test "time.sh dispatcher - zones joins multiple entries with the separator" {
  set_tmux_option "@time_revamped_timezones" "America/New_York, Europe/London"
  set_tmux_option "@time_revamped_zone_separator" " | "
  run main zones
  [[ "${output}" == *" | "* ]]
}

@test "time.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}
