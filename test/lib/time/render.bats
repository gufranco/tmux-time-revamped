#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/time/render.sh"
}

teardown() {
  cleanup_test_environment
}

@test "render.sh - period_of_hour buckets the day" {
  [[ "$(period_of_hour 2)" == "night" ]]
  [[ "$(period_of_hour 23)" == "night" ]]
  [[ "$(period_of_hour 8)" == "morning" ]]
  [[ "$(period_of_hour 13)" == "day" ]]
  [[ "$(period_of_hour 16)" == "afternoon" ]]
  [[ "$(period_of_hour 19)" == "evening" ]]
  [[ "$(period_of_hour bogus)" == "night" ]]
}

@test "render.sh - _time_period lets weekend override the hour" {
  [[ "$(_time_period 13 1)" == "weekend" ]]
  [[ "$(_time_period 13 0)" == "day" ]]
}

@test "render.sh - icon_period_of_hour buckets the day with sunrise and sunset" {
  [[ "$(icon_period_of_hour 2)" == "night" ]]
  [[ "$(icon_period_of_hour 23)" == "night" ]]
  [[ "$(icon_period_of_hour 6)" == "sunrise" ]]
  [[ "$(icon_period_of_hour 9)" == "morning" ]]
  [[ "$(icon_period_of_hour 13)" == "day" ]]
  [[ "$(icon_period_of_hour 16)" == "afternoon" ]]
  [[ "$(icon_period_of_hour 19)" == "sunset" ]]
  [[ "$(icon_period_of_hour 21)" == "evening" ]]
  [[ "$(icon_period_of_hour bogus)" == "night" ]]
}

@test "render.sh - _time_icon_period lets weekend override the hour" {
  [[ "$(_time_icon_period 6 1)" == "weekend" ]]
  [[ "$(_time_icon_period 6 0)" == "sunrise" ]]
  [[ "$(_time_icon_period 19 0)" == "sunset" ]]
}

@test "render.sh - _time_default_color covers every period" {
  [[ "$(_time_default_color morning)" == "#[fg=yellow]" ]]
  [[ "$(_time_default_color day)" == "#[fg=green]" ]]
  [[ "$(_time_default_color afternoon)" == "#[fg=cyan]" ]]
  [[ "$(_time_default_color evening)" == "#[fg=magenta]" ]]
  [[ "$(_time_default_color night)" == "#[fg=blue]" ]]
  [[ "$(_time_default_color weekend)" == "#[fg=brightblack]" ]]
  [[ -z "$(_time_default_color other)" ]]
}

@test "render.sh - time_render_period_color uses default then option" {
  [[ "$(time_render_period_color 8 0)" == "#[fg=yellow]" ]]
  [[ "$(time_render_period_color 8 1)" == "#[fg=brightblack]" ]]
  set_tmux_option "@time_revamped_morning_color" "#[fg=red]"
  [[ "$(time_render_period_color 8 0)" == "#[fg=red]" ]]
}

@test "render.sh - time_render_period_color passes named color spec verbatim" {
  set_tmux_option "@time_revamped_morning_color" "#[fg=red]"
  [[ "$(time_render_period_color 8 0)" == "#[fg=red]" ]]
}

@test "render.sh - time_render_period_color passes 256 color spec verbatim" {
  set_tmux_option "@time_revamped_morning_color" "#[fg=colour203]"
  [[ "$(time_render_period_color 8 0)" == "#[fg=colour203]" ]]
}

@test "render.sh - time_render_period_color passes hex fg spec verbatim" {
  set_tmux_option "@time_revamped_morning_color" "#[fg=#f38ba8]"
  [[ "$(time_render_period_color 8 0)" == "#[fg=#f38ba8]" ]]
}

@test "render.sh - time_render_period_color passes hex fg and bg spec verbatim" {
  set_tmux_option "@time_revamped_morning_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(time_render_period_color 8 0)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - time_render_period_color passes bright color spec verbatim" {
  set_tmux_option "@time_revamped_morning_color" "#[fg=brightred]"
  [[ "$(time_render_period_color 8 0)" == "#[fg=brightred]" ]]
}

@test "render.sh - time_render_period_color passes a hex spec through the weekend override" {
  set_tmux_option "@time_revamped_weekend_color" "#[fg=#a6adc8]"
  [[ "$(time_render_period_color 8 1)" == "#[fg=#a6adc8]" ]]
}

@test "render.sh - time_render_period_icon is empty until configured" {
  [[ -z "$(time_render_period_icon 8 0)" ]]
  set_tmux_option "@time_revamped_morning_icon" "M"
  [[ "$(time_render_period_icon 8 0)" == "M" ]]
}

@test "render.sh - time_render_period_icon selects sunrise and sunset glyphs" {
  [[ -z "$(time_render_period_icon 6 0)" ]]
  [[ -z "$(time_render_period_icon 19 0)" ]]
  set_tmux_option "@time_revamped_sunrise_icon" "up"
  set_tmux_option "@time_revamped_sunset_icon" "down"
  [[ "$(time_render_period_icon 6 0)" == "up" ]]
  [[ "$(time_render_period_icon 19 0)" == "down" ]]
}

@test "render.sh - time_render_zone_full shows abbr and time, icon optional" {
  [[ "$(time_render_zone_full EST 09:30 9 0)" == "#[fg=yellow]EST 09:30#[default]" ]]
  set_tmux_option "@time_revamped_morning_icon" "*"
  [[ "$(time_render_zone_full EST 09:30 9 0)" == "#[fg=yellow]EST * 09:30#[default]" ]]
}

@test "render.sh - time_render_zone_compact shows label and time" {
  set_tmux_option "@time_revamped_evening_color" "#[fg=magenta]"
  [[ "$(time_render_zone_compact NY 19:30 19 0)" == "#[fg=magenta]NY 19:30#[default]" ]]
}

@test "render.sh - time_render_zone_compact shows the period icon too" {
  set_tmux_option "@time_revamped_evening_color" "#[fg=magenta]"
  set_tmux_option "@time_revamped_evening_icon" "M"
  [[ "$(time_render_zone_compact NY 20:30 20 0)" == "#[fg=magenta]NY M 20:30#[default]" ]]
}

@test "render.sh - the reset is configurable for theme integration" {
  set_tmux_option "@time_revamped_evening_color" "#[fg=magenta]"
  set_tmux_option "@time_revamped_reset" "#[fg=default]"
  [[ "$(time_render_zone_compact NY 19:30 19 0)" == "#[fg=magenta]NY 19:30#[fg=default]" ]]
  [[ "$(time_render_zone_full EST 09:30 9 0)" == *"#[fg=default]" ]]
}
