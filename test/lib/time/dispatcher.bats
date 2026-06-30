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

@test "time.sh dispatcher - epoch subcommand reads the clock seam" {
  run main epoch
  [[ "${output}" == "1000000" ]]
}

@test "time.sh dispatcher - iso subcommand formats ISO 8601" {
  _now_local() { echo "2026-06-30T14:30:00+0000"; }
  run main iso
  [[ "${output}" == "2026-06-30T14:30:00+00:00" ]]
}

@test "time.sh dispatcher - offset subcommand renders the UTC offset" {
  _now_local() { echo "+0000"; }
  run main offset
  [[ "${output}" == "UTC" ]]
}

@test "time.sh dispatcher - week and doy subcommands strip leading zeros" {
  _now_local() { case "$1" in %V) echo "07" ;; %j) echo "181" ;; esac; }
  run main week
  [[ "${output}" == "7" ]]
  run main doy
  [[ "${output}" == "181" ]]
}

@test "time.sh dispatcher - until counts down to a target" {
  _now_local() { echo "2026-06-30 12:00:00"; }
  set_tmux_option "@time_revamped_countdown_target" "2026-07-01 12:00:00"
  run main until
  [[ "${output}" == "1d 0h" ]]
}

@test "time.sh dispatcher - elapsed measures since the mark" {
  set_tmux_option "@time_revamped_mark_epoch" "999000"
  run main elapsed
  [[ "${output}" == "16m" ]]
}

@test "time.sh dispatcher - dst warns of an upcoming change" {
  _tz_offset_for_epoch() { if (( $2 >= 1000000 + 2 * 86400 )); then echo "-0200"; else echo "-0300"; fi; }
  run main dst
  [[ "${output}" == "DST in 2d" ]]
}

@test "time.sh dispatcher - overlap reports the shared window" {
  _tz_offset_for_epoch() { echo "+0000"; }
  set_tmux_option "@time_revamped_timezones" "UTC, UTC"
  run main overlap
  [[ "${output}" == "overlap 09:00-17:00" ]]
}

@test "time.sh dispatcher - doctor validates the configured zones" {
  _tz_exists() { return 0; }
  set_tmux_option "@time_revamped_timezones" "UTC"
  run main doctor
  [[ "${output}" == *"OK   UTC"* ]]
  [[ "${output}" == *"1 ok, 0 invalid"* ]]
}

@test "time.sh dispatcher - mark stores the current epoch" {
  _tmux() { :; }
  run main mark
  [[ "$(get_tmux_option "@time_revamped_mark_epoch")" == "1000000" ]]
}

@test "time.sh dispatcher - toggle-format flips the time format" {
  run main toggle-format
  [[ "$(get_tmux_option "@time_revamped_time_format")" == "12H" ]]
}

@test "time.sh dispatcher - copy sends the timestamp through the seams" {
  local cap="${TEST_TMPDIR}/cap"
  _now_local() { echo "2026-06-30T14:30:00+0000"; }
  _tmux() { printf 'tmux %s\n' "$*" >> "${cap}"; }
  _clipboard_copy() { printf 'clip %s\n' "$1" >> "${cap}"; }
  main copy iso
  grep -q "tmux set-buffer 2026-06-30T14:30:00+00:00" "${cap}"
  grep -q "clip 2026-06-30T14:30:00+00:00" "${cap}"
}

@test "time.sh dispatcher - calendar opens a popup without launching one" {
  local cap="${TEST_TMPDIR}/cap"
  _tmux() { printf '%s\n' "$*" > "${cap}"; }
  main calendar
  grep -q "display-popup" "${cap}"
}

@test "time.sh dispatcher - menu builds the prefix menu" {
  local cap="${TEST_TMPDIR}/cap"
  _tmux() { printf '%s\n' "$*" > "${cap}"; }
  main menu
  grep -q "display-menu" "${cap}"
}

@test "time.sh dispatcher - zones show a relative-day badge" {
  _now_local() { case "$1" in "%Y|%m|%d") echo "2026|06|30" ;; *) echo "X" ;; esac; }
  _now_tz() { echo "09|09:30|EDT|5|2026|07|01"; }
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  set_tmux_option "@time_revamped_compact" "1"
  set_tmux_option "@time_revamped_relative_day" "1"
  run main zones
  [[ "${output}" == *"+1d"* ]]
}

@test "time.sh dispatcher - zones dim a zone outside working hours" {
  _now_tz() { echo "02|02:30|EST|5|2026|06|30"; }
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  set_tmux_option "@time_revamped_compact" "1"
  set_tmux_option "@time_revamped_work_hours" "1"
  run main zones
  [[ "${output}" == "#[dim]"* ]]
}

@test "time.sh dispatcher - zones keep a zone inside working hours undimmed" {
  _now_tz() { echo "09|09:30|EST|5|2026|06|30"; }
  set_tmux_option "@time_revamped_timezones" "America/New_York"
  set_tmux_option "@time_revamped_compact" "1"
  set_tmux_option "@time_revamped_work_hours" "1"
  run main zones
  [[ "${output}" != "#[dim]"* ]]
}

@test "time.sh dispatcher - zones highlight the primary zone" {
  _now_tz() { echo "09|09:30|EDT|5|2026|06|30"; }
  set_tmux_option "@time_revamped_timezones" "America/New_York, Europe/London"
  set_tmux_option "@time_revamped_compact" "1"
  set_tmux_option "@time_revamped_primary" "0"
  run main zones
  [[ "${output}" == "#[bold]"* ]]
}
