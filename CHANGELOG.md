# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-06-20

### Added

- Separate `sunrise` and `sunset` period icons. World-clock icons now use seven
  hour buckets instead of five, so a dawn glyph (`@time_revamped_sunrise_icon`,
  hours 05 to 08) and a dusk glyph (`@time_revamped_sunset_icon`, hours 18 to 20)
  can be configured independently. Color buckets are unchanged, and every icon
  option still defaults to empty.

## [1.0.0] - 2026-06-20

### Added

- Local clock placeholders: `#{time}`, `#{time_date}`, `#{time_clock}`, with
  configurable date and time formats, including a `hide` option for each.
- World clocks via `#{time_zones}`: any number of timezones, each rendered with
  its abbreviation or a compact city label and the local time.
- Time-of-day coloring per timezone: morning, day, afternoon, evening, and night
  buckets, with a weekend override and an optional per-period icon.
- Non-blocking design: the clock is computed live from a single `date` call, with
  no temp files and all configuration in tmux server options.
