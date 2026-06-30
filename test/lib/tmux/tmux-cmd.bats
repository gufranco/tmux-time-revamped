#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _TIME_REVAMPED_TMUX_CMD_LOADED _TIME_REVAMPED_EXTRAS_LOADED \
    _TIME_REVAMPED_DATEMATH_LOADED _TMUX_PLUGIN_HAS_COMMAND_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/tmux/tmux-cmd.sh"
  CAP="${TEST_TMPDIR}/cap"
  export CAP
}

teardown() {
  cleanup_test_environment
}

@test "tmux-cmd.sh - _tmux forwards to the tmux seam" {
  run _tmux display-message hello
  [[ "${status}" -eq 0 ]]
}

@test "tmux-cmd.sh - _clipboard_copy uses pbcopy when present" {
  has_command() { [[ "${1}" == "pbcopy" ]]; }
  pbcopy() { cat > "${CAP}"; }
  _clipboard_copy "from-pbcopy"
  [[ "$(cat "${CAP}")" == "from-pbcopy" ]]
}

@test "tmux-cmd.sh - _clipboard_copy uses wl-copy when present" {
  has_command() { [[ "${1}" == "wl-copy" ]]; }
  wl-copy() { cat > "${CAP}"; }
  _clipboard_copy "from-wl"
  [[ "$(cat "${CAP}")" == "from-wl" ]]
}

@test "tmux-cmd.sh - _clipboard_copy uses xclip when present" {
  has_command() { [[ "${1}" == "xclip" ]]; }
  xclip() { cat > "${CAP}"; }
  _clipboard_copy "from-xclip"
  [[ "$(cat "${CAP}")" == "from-xclip" ]]
}

@test "tmux-cmd.sh - _clipboard_copy is a no-op with no backend" {
  has_command() { return 1; }
  run _clipboard_copy "nowhere"
  [[ "${status}" -eq 0 ]]
}

@test "tmux-cmd.sh - time_set_mark stores the epoch and notifies" {
  _now_epoch() { echo 1234567; }
  _tmux() { printf '%s\n' "$*" >> "${CAP}"; }
  time_set_mark
  [[ "$(get_tmux_option "@time_revamped_mark_epoch")" == "1234567" ]]
  grep -q "display-message" "${CAP}"
}

@test "tmux-cmd.sh - time_copy_timestamp copies the ISO value by default" {
  _now_local() { echo "2026-06-30T14:30:00+0000"; }
  _tmux() { printf 'tmux %s\n' "$*" >> "${CAP}"; }
  _clipboard_copy() { printf 'clip %s\n' "$1" >> "${CAP}"; }
  time_copy_timestamp
  grep -q "tmux set-buffer 2026-06-30T14:30:00+00:00" "${CAP}"
  grep -q "clip 2026-06-30T14:30:00+00:00" "${CAP}"
}

@test "tmux-cmd.sh - time_copy_timestamp copies the epoch on request" {
  _now_epoch() { echo 1000000; }
  _tmux() { printf 'tmux %s\n' "$*" >> "${CAP}"; }
  _clipboard_copy() { printf 'clip %s\n' "$1" >> "${CAP}"; }
  time_copy_timestamp epoch
  grep -q "clip 1000000" "${CAP}"
}

@test "tmux-cmd.sh - time_toggle_format flips both directions" {
  time_toggle_format
  [[ "$(get_tmux_option "@time_revamped_time_format")" == "12H" ]]
  time_toggle_format
  [[ "$(get_tmux_option "@time_revamped_time_format")" == "24H" ]]
}

@test "tmux-cmd.sh - time_calendar_popup opens a popup running cal" {
  _tmux() { printf '%s\n' "$*" > "${CAP}"; }
  time_calendar_popup
  grep -q "display-popup" "${CAP}"
  grep -q "cal" "${CAP}"
}

@test "tmux-cmd.sh - time_menu builds a menu that calls back into the dispatcher" {
  export TIME_DISPATCH="/plugin/src/time.sh"
  _tmux() { printf '%s\n' "$*" > "${CAP}"; }
  time_menu
  grep -q "display-menu" "${CAP}"
  grep -q "time-revamped" "${CAP}"
  grep -q "/plugin/src/time.sh toggle-format" "${CAP}"
}
