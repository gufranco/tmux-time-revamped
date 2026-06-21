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

@test "time.sh dispatcher - zones use custom labels matched by position" {
  set_tmux_option "@time_revamped_timezones" "America/New_York, Asia/Tokyo"
  set_tmux_option "@time_revamped_compact" "1"
  set_tmux_option "@time_revamped_zone_labels" "NYC, Tokyo"
  run main zones
  [[ "${output}" == *"NYC 09:30"* ]]
  [[ "${output}" == *"Tokyo 09:30"* ]]
}

@test "time.sh dispatcher - a missing custom label falls back to the default" {
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

@test "time.sh dispatcher - local renders the place, icon, and time" {
  _local_tz_name() { echo "America/Sao_Paulo"; }
  _now_local() { echo "14|14:30|5"; }
  set_tmux_option "@time_revamped_afternoon_color" "#[fg=teal]"
  set_tmux_option "@time_revamped_afternoon_icon" "S"
  run main local
  [[ "${output}" == "#[fg=teal]Sao Paulo S 14:30#[default]" ]]
}

@test "time.sh dispatcher - local label can be overridden" {
  _local_tz_name() { echo "America/Sao_Paulo"; }
  _now_local() { echo "14|14:30|5"; }
  set_tmux_option "@time_revamped_local_label" "Rio"
  run main local
  [[ "${output}" == *"Rio 14:30"* ]]
}

@test "time.sh dispatcher - local uses the geoip city when enabled" {
  _now_local() { echo "14|14:30|5"; }
  _read_geoip() { echo "Tokyo"; }
  has_command() { return 0; }
  export CACHE_SYNC=1
  set_tmux_option "@time_revamped_local_source" "geoip"
  run main local
  [[ "${output}" == *"Tokyo 14:30"* ]]
}

@test "time.sh dispatcher - geoip falls back to the timezone city on failure" {
  _local_tz_name() { echo "Asia/Tokyo"; }
  _now_local() { echo "14|14:30|5"; }
  _read_geoip() { echo ""; }
  has_command() { return 0; }
  export CACHE_SYNC=1
  set_tmux_option "@time_revamped_local_source" "geoip"
  run main local
  [[ "${output}" == *"Tokyo 14:30"* ]]
}

@test "time.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}
