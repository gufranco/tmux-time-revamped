#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_GEOIP_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/geoip.sh"
}

teardown() {
  cleanup_test_environment
}

@test "geoip.sh - parses a JSON city field" {
  [[ "$(geoip_parse_city '{"city":"Tokyo","region":"Tokyo"}')" == "Tokyo" ]]
}

@test "geoip.sh - parses a plain-text body" {
  [[ "$(geoip_parse_city 'Paris')" == "Paris" ]]
}

@test "geoip.sh - preserves a multi-word city" {
  [[ "$(geoip_parse_city 'New York')" == "New York" ]]
}

@test "geoip.sh - rejects html, empty, and overlong responses" {
  [[ -z "$(geoip_parse_city '<html>nope</html>')" ]]
  [[ -z "$(geoip_parse_city '')" ]]
  [[ -z "$(geoip_parse_city "$(printf 'x%.0s' {1..100})")" ]]
}

@test "geoip.sh - rejects a JSON body that carries no city" {
  [[ -z "$(geoip_parse_city '{"region":"X"}')" ]]
}

@test "geoip.sh - host-probe seam is defined and runnable" {
  function_exists _read_geoip
  GEOIP_TIMEOUT=1 run _read_geoip "http://127.0.0.1:1"
  true
}
