# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
