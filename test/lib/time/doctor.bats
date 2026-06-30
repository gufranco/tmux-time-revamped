#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_DOCTOR_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/doctor.sh"
}

teardown() {
  cleanup_test_environment
}

@test "doctor.sh - _tz_exists checks the zoneinfo directory" {
  export TIME_ZONEINFO_DIR="${TEST_TMPDIR}/zi"
  mkdir -p "${TIME_ZONEINFO_DIR}"
  : > "${TIME_ZONEINFO_DIR}/Real_Zone"
  run _tz_exists "Real_Zone"
  [[ "${status}" -eq 0 ]]
  run _tz_exists "Bogus_Zone"
  [[ "${status}" -ne 0 ]]
}

@test "doctor.sh - read_doctor reports when nothing is configured" {
  [[ "$(read_doctor)" == "time-revamped: no timezones configured" ]]
}

@test "doctor.sh - read_doctor flags valid and invalid zones" {
  _tz_exists() { [[ "${1}" != "America/Nowhere" ]]; }
  set_tmux_option "@time_revamped_timezones" "America/New_York, America/Nowhere, Asia/Tokyo"
  run read_doctor
  [[ "${lines[0]}" == "OK   America/New_York" ]]
  [[ "${lines[1]}" == "BAD  America/Nowhere" ]]
  [[ "${lines[2]}" == "OK   Asia/Tokyo" ]]
  [[ "${lines[3]}" == "time-revamped: 2 ok, 1 invalid" ]]
}
