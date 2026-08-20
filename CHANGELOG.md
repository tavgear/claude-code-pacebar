# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- A marketplace manifest and a one-command plugin: `/plugin marketplace add
  tavgear/claude-code-pacebar`, `/plugin install pacebar@pacebar` and
  `/pacebar:setup`, which copies the script to `~/.claude/pacebar/pacebar.sh`
  and writes the `statusLine` entry. The clone-and-one-line install is
  unchanged.

## [1.1.0] — 2026-08-20

### Changed
- The status-line JSON is parsed in bash instead of jq, and the model section
  is formatted without sed. pacebar now needs nothing but bash 3.2 or newer.
- Bar cells carry block glyphs painted in their own background colour, so the
  bars read on terminals without colour and look unchanged on those with it.
  `NO_COLOR` is honoured.

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

[1.0.0]: https://github.com/tavgear/claude-code-pacebar/releases/tag/v1.0.0
[1.1.0]: https://github.com/tavgear/claude-code-pacebar/compare/v1.0.0...v1.1.0
