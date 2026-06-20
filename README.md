<div align="center">

<h1>tmux-time-revamped</h1>

**Local clock and world clocks in your tmux status bar, without ever blocking the render.**

[![Tests](https://github.com/gufranco/tmux-time-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/gufranco/tmux-time-revamped/actions/workflows/tests.yml) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

**4** placeholders · **2** platforms · **72** tests · **95%+** coverage

A local date and time plus any number of world clocks, each colored by the time of day at that location. Reading the clock is a single `date` call, so the status line computes it live and returns instantly. No temp files are touched, all configuration lives in tmux options.

Built from [tmux-plugin-template](https://github.com/gufranco/tmux-plugin-template).

<table>
<tr>
<td><strong>Non-blocking</strong><br>A clock read is one instant `date` call, so the status renders without waiting.</td>
<td><strong>No temp files</strong><br>Every setting lives in tmux server options, nothing on disk.</td>
</tr>
<tr>
<td><strong>World clocks</strong><br>List any timezones and each one is colored by morning, day, afternoon, evening, or night.</td>
<td><strong>Tested</strong><br>95%+ line coverage enforced in CI.</td>
</tr>
</table>

## Placeholders

Add any of these to `status-left` or `status-right`:

| Placeholder | Output |
|-------------|--------|
| `#{time}` | local date and time, for example `2026-06-20 14:30` |
| `#{time_date}` | local date only |
| `#{time_clock}` | local time only |
| `#{time_zones}` | one entry per configured timezone, colored by time of day |

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'gufranco/tmux-time-revamped'
set -g @time_revamped_timezones 'America/New_York, Europe/London, Asia/Tokyo'
set -g status-right '#{time} #{time_zones}'
```

Then press `prefix + I` to install.

Manual install:

```bash
git clone https://github.com/gufranco/tmux-time-revamped ~/.tmux/plugins/tmux-time-revamped
run-shell ~/.tmux/plugins/tmux-time-revamped/time-revamped.tmux
```

## Configuration

| Option | Default | Meaning |
|--------|---------|---------|
| `@time_revamped_date_format` | `YMD` | one of `YMD`, `MD`, `DM`, `MDY`, `DMY`, `hide` |
| `@time_revamped_time_format` | `24H` | one of `24H`, `12H`, `hide` |
| `@time_revamped_timezones` | empty | comma or space separated TZ names, for example `America/New_York, Europe/London` |
| `@time_revamped_compact` | `0` | set to `1` to show short city labels instead of timezone abbreviations |
| `@time_revamped_zone_separator` | a space | text placed between world-clock entries |
| `@time_revamped_morning_color` | `#[fg=yellow]` | color for hours 05 to 12 |
| `@time_revamped_day_color` | `#[fg=green]` | color for hours 12 to 14 |
| `@time_revamped_afternoon_color` | `#[fg=cyan]` | color for hours 14 to 18 |
| `@time_revamped_evening_color` | `#[fg=magenta]` | color for hours 18 to 22 |
| `@time_revamped_night_color` | `#[fg=blue]` | color for hours 22 to 05 |
| `@time_revamped_weekend_color` | `#[fg=brightblack]` | color used on Saturday and Sunday, overriding the hour |
| `@time_revamped_{morning,day,afternoon,evening,night,weekend}_icon` | empty | optional glyph shown before the time, for example a Nerd Font sun or moon |

A world clock in full mode renders as the timezone abbreviation, an optional period icon, then the time. Compact mode replaces the abbreviation with short city initials, for example `NY` for `America/New_York`.

## Support by platform and architecture

Works on every supported platform and architecture with built-in tools, no extra package required. The local clock and every world clock use the system `date` and the operating system timezone database, which are present on Linux (x86_64 and arm64) and macOS (Intel and Apple Silicon). Period coloring, weekend detection, and compact labels are computed in shell and behave identically everywhere.

## Development

```bash
make test    # bats suite
make lint    # shellcheck
make coverage  # kcov line coverage on Linux
```

## License

[MIT](LICENSE), copyright Gustavo Franco.
