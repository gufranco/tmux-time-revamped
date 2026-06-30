#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_DECORATE_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/decorate.sh"
}

teardown() {
  cleanup_test_environment
}

@test "decorate.sh - a plain entry is returned unchanged" {
  [[ "$(zone_decorate '#[fg=yellow]NY 09:30#[default]' '' 0 1)" == "#[fg=yellow]NY 09:30#[default]" ]]
}

@test "decorate.sh - the badge is appended after the entry" {
  [[ "$(zone_decorate 'NY 09:30' '+1d' 0 1)" == "NY 09:30 +1d" ]]
}

@test "decorate.sh - a zone outside work hours is dimmed" {
  [[ "$(zone_decorate 'NY 02:30' '' 0 0)" == "#[dim]NY 02:30" ]]
}

@test "decorate.sh - the dim style is configurable and disables on none" {
  set_tmux_option "@time_revamped_dim_style" "#[fg=brightblack]"
  [[ "$(zone_decorate 'NY 02:30' '' 0 0)" == "#[fg=brightblack]NY 02:30" ]]
  set_tmux_option "@time_revamped_dim_style" "none"
  [[ "$(zone_decorate 'NY 02:30' '' 0 0)" == "NY 02:30" ]]
}

@test "decorate.sh - the primary zone is highlighted" {
  [[ "$(zone_decorate 'NY 09:30' '' 1 1)" == "#[bold]NY 09:30" ]]
}

@test "decorate.sh - the primary style is configurable and disables on none" {
  set_tmux_option "@time_revamped_primary_style" "#[reverse]"
  [[ "$(zone_decorate 'NY 09:30' '' 1 1)" == "#[reverse]NY 09:30" ]]
  set_tmux_option "@time_revamped_primary_style" "none"
  [[ "$(zone_decorate 'NY 09:30' '' 1 1)" == "NY 09:30" ]]
}

@test "decorate.sh - badge, dim, and primary stack together" {
  [[ "$(zone_decorate 'NY 02:30' '+1d' 1 0)" == "#[bold]#[dim]NY 02:30 +1d" ]]
}
