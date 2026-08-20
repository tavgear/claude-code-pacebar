# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-08-20

First public release.

### Added
- Gauges for the 5-hour and 7-day rate-limit windows and the context window.
- A synthetic 24h gauge: today's spending as a share of an even weekly pace,
  which can read above 100% (borrowing from tomorrow) or below zero (yesterday
  left a surplus).
- Configuration through `~/.claude/pacebar.conf`: sections on/off and in any
  order, the divider between them, per-gauge label, width, percentage style and
  colour thresholds, the palette, and templated time formats with `compact`,
  `clock` and `long` presets.
- Mobile preset: any `PB_M_*` name replaces its `PB_*` twin below
  `PB_WIDE_MIN` columns.
- `preview.sh` for rendering made-up states, and `demo/render.py` to turn that
  into the image in the README.

[1.0.0]: https://github.com/tvg/claude-code-pacebar/releases/tag/v1.0.0
