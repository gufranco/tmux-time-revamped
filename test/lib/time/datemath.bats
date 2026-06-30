#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_DATEMATH_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/datemath.sh"
}

teardown() {
  cleanup_test_environment
}

@test "datemath.sh - _now_epoch reads the clock seam" {
  [[ "$(_now_epoch)" == "1000000" ]]
}

@test "datemath.sh - days_from_civil anchors the epoch and counts forward" {
  [[ "$(days_from_civil 1970 1 1)" == "0" ]]
  [[ "$(days_from_civil 1970 1 2)" == "1" ]]
  [[ "$(days_from_civil 2000 1 1)" == "10957" ]]
}

@test "datemath.sh - days_from_civil counts backward before the epoch" {
  [[ "$(days_from_civil 1969 12 31)" == "-1" ]]
}

@test "datemath.sh - days_from_civil handles the pre-zero negative era" {
  run days_from_civil 0 1 1
  [[ "${output}" =~ ^-?[0-9]+$ ]]
}

@test "datemath.sh - days_from_civil takes the month-over-two branch" {
  [[ "$(days_from_civil 2000 3 1)" == "11017" ]]
}

@test "datemath.sh - parse_to_epoch reads a bare date" {
  [[ "$(parse_to_epoch '1970-01-01')" == "0" ]]
  [[ "$(parse_to_epoch '2000-01-01 00:00:00')" == "946684800" ]]
}

@test "datemath.sh - parse_to_epoch reads time with and without seconds" {
  [[ "$(parse_to_epoch '2000-01-01T12:30')" == "946729800" ]]
  [[ "$(parse_to_epoch '2000-01-01 12:30:15')" == "946729815" ]]
}

@test "datemath.sh - parse_to_epoch rejects malformed input" {
  [[ -z "$(parse_to_epoch 'nope')" ]]
  [[ -z "$(parse_to_epoch '2026/06/30')" ]]
  [[ -z "$(parse_to_epoch '')" ]]
}

@test "datemath.sh - fmt_duration scales across every unit" {
  [[ "$(fmt_duration 0)" == "<1m" ]]
  [[ "$(fmt_duration 30)" == "<1m" ]]
  [[ "$(fmt_duration 90)" == "1m" ]]
  [[ "$(fmt_duration 3700)" == "1h 1m" ]]
  [[ "$(fmt_duration 90000)" == "1d 1h" ]]
}

@test "datemath.sh - fmt_duration clamps negatives and bad input to zero" {
  [[ "$(fmt_duration -5)" == "<1m" ]]
  [[ "$(fmt_duration abc)" == "<1m" ]]
}

@test "datemath.sh - offset_minutes converts signed offsets" {
  [[ "$(offset_minutes '+0000')" == "0" ]]
  [[ "$(offset_minutes '-0300')" == "-180" ]]
  [[ "$(offset_minutes '+0530')" == "330" ]]
}

@test "datemath.sh - offset_minutes fails on a malformed offset" {
  run offset_minutes "bad"
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "0" ]]
}
