# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-06-30

### Added

- Developer time formats: `#{time_epoch}` (unix seconds), `#{time_iso}`
  (ISO 8601 with a colon in the offset), and `#{time_offset}` (the local UTC
  offset as `UTC+02:00`).
- Calendar fields: `#{time_week}` (ISO 8601 week number) and `#{time_doy}`
  (day of the year).
- `#{time_until}`: a countdown to `@time_revamped_countdown_target`, with an
  optional label and a "done" message once the target passes.
- `#{time_elapsed}`: a stopwatch since the mark stored by the mark action.
- `#{time_dst}`: a "DST in Nd" warning when a zone's UTC offset is about to
  change within `@time_revamped_dst_horizon` days.
- `#{time_overlap}`: the shared working-hours window across the configured
  zones, expressed in the local zone, or a "no overlap" message.
- World-clock decorations: a relative-day badge per zone
  (`@time_revamped_relative_day`), dimming a zone outside working hours
  (`@time_revamped_work_hours` with `@time_revamped_work_start` and
  `@time_revamped_work_end`), and a highlight on the primary zone
  (`@time_revamped_primary`).
- Interactive actions, bound through a mockable seam: a prefix menu
  (`prefix + T`), a calendar popup, copy the timestamp to the tmux buffer and
  the system clipboard, set a stopwatch mark, and a `doctor` report that
  validates the configured timezone names.

All date arithmetic is pure shell, identical on BSD and GNU `date`, and every
clock read sits behind a seam so the work stays non-blocking and the live model
is unchanged.

## [1.1.1] - 2026-06-23

### Changed

- Self-audit for the family hardening pass. Alongside the clock and date, the
  plugin renders additional time zones for distributed teams, and the colors are
  named colors safe under tmux 3.7 format expansion. No code change needed.

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
