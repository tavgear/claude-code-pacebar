# pacebar

A status line for [Claude Code](https://claude.com/claude-code): how fast you are
burning your rate limits, whether today is ahead of or behind an even weekly
pace, and all of it still legible on a phone.

![pacebar](demo/pacebar.png)

## Today, not just the week

Claude Code reports two windows, 5-hour and 7-day. The weekly number on its own
says little: 50% on Monday is trouble, 50% on Friday is money in the bank.

So pacebar adds a gauge for **today**. The week is split into seven equal days
worth 100/7 % each, counted from the start of the weekly window rather than from
local midnight, and the gauge shows how much of today's share is gone:

```
today% = 7 × week% − 100 × whole_days_elapsed
```

Read it as a speedometer rather than a fuel gauge:

| | |
|---|---|
| `40%` | less than half of today's allowance spent |
| `100%` | exactly on pace |
| `164%` | today ran well past its share — you are borrowing from tomorrow |
| `+58%` | an empty gauge: yesterday underspent, today starts with a surplus |

The second row of the picture above is the case worth having it for: the weekly
gauge sits green at 38% while today is already amber at 66%. The week says
you are fine, today says slow down, and only one of them is actionable.

None of this is stored anywhere — no history file, no daemon, no midnight
rollover to get wrong. It falls out of the two numbers Claude Code already sends.

## Narrow terminals

Claude Code also runs on a phone, where a row of 12-cell gauges with labels
simply does not fit. Every single setting has a `PB_M_*` twin that replaces it
below `PB_WIDE_MIN` columns — that is the entire mechanism. No second code path,
no separate mobile config format, nothing to keep in sync.

The shipped narrow defaults drop the 24h gauge, drop the labels, shorten the
gauges to 9 cells, hide the `%` signs and cut the model down to a single letter.
The `narrow` rows in the picture above are exactly that.

Disagree with any of it? It is one line. Keep today's gauge on the phone and
drop the context one instead:

```bash
PB_M_24H=on
PB_M_CTX=off
```

## Install

Needs `bash`, `jq` and a 256-colour terminal.

```bash
git clone https://github.com/tvg/claude-code-pacebar ~/.claude/pacebar
```

Then in `~/.claude/settings.json`:

```json
{
  "statusLine": { "type": "command", "command": "~/.claude/pacebar/pacebar.sh" }
}
```

To see it without waiting to burn a limit: `./preview.sh`, or `./preview.sh 42 55 30`
for your own 5h / week / context numbers.

## Configuration

Copy [`pacebar.conf.example`](pacebar.conf.example) to `~/.claude/pacebar.conf`
and uncomment what you want. It is sourced as plain bash. The same numbers under
a handful of different settings — `./preview.sh --configs`:

![configuration examples](demo/configs.png)

**Layout**

| Name | Default | |
|---|---|---|
| `PB_WIDE_MIN` | `125` | columns; below this the mobile preset applies |
| `PB_ORDER` | `model 5h 24h 7d ctx` | sections to print, in order |
| `PB_SEP` | `' │ '` | printed between sections; `'  '` for plain spaces |
| `PB_MODEL` `PB_5H` `PB_24H` `PB_7D` `PB_CTX` | `on` | each section on or off |

**Model**

| Name | Default | |
|---|---|---|
| `PB_MODEL_FMT` | `%n (%e)` | `%n` name, `%e` effort level |
| `PB_MODEL_SHORT` | `off` | `on` → a single letter: `O`, `S`, `H` |
| `PB_MODEL_STRIP` | `on` | drop a trailing parenthetical: `Opus 5 (1M)` → `Opus 5` |

**Gauges** — `X` is `5H`, `24H`, `7D` or `CTX`

| Name | Default | |
|---|---|---|
| `PB_X_LABEL` | `5h:` `24h:` `7d:` `ctx:` | printed verbatim; empty for none |
| `PB_X_WIDTH` | `12` | cells |
| `PB_X_PCT` | `pct` | `pct` → `46%`, `num` → `46`, `off` → nothing |
| `PB_X_LEFT` | `on` (`off` for `CTX`) | time until the window resets |
| `PB_X_WARN` | `50` | amber from here |
| `PB_X_CRIT` | `80` | red from here |

**Colours** — 256-colour palette indices

| Name | Default | |
|---|---|---|
| `PB_COLOR_OK` / `_WARN` / `_CRIT` | `22` / `94` / `88` | fill, by severity |
| `PB_COLOR_EMPTY` | `236` | unfilled cells |
| `PB_COLOR_TEXT` / `_TEXT_EMPTY` | `97` / `37` | caption over filled / unfilled cells |
| `PB_COLOR_DIM` | `90` | labels |

## Time formats

One template per magnitude, so the leading zero unit drops out by itself.

| Name | Applies when | `compact` | `clock` | `long` |
|---|---|---|---|---|
| `PB_TIME_D` | ≥ 1 day | `%dd%hh` → `3d4h` | `%d-%H:%M` → `3-04:56` | `%dd %hh` → `3d 4h` |
| `PB_TIME_H` | < 1 day | `%hh%mm` → `4h56m` | `%H:%M` → `04:56` | `%hh %mm` → `4h 56m` |
| `PB_TIME_M` | < 1 hour | `%mm` → `56m` | `00:%M` → `00:56` | `%mm` → `56m` |

`PB_TIME_PRESET` (default `compact`) fills all three; an explicit template wins
over the preset.

| Specifier | | Specifier | |
|---|---|---|---|
| `%d` | days | `%tH` | total hours |
| `%h` `%H` | hours in day, plain / zero-padded | `%tM` | total minutes |
| `%m` `%M` | minutes in hour, plain / zero-padded | `%tS` | total seconds |
| `%s` `%S` | seconds in minute, plain / zero-padded | `%%` | a literal `%` |

So `PB_TIME_M='%m:%S'` gives `56:07`, and `PB_TIME_D='%dd %hh %mm'` gives `3d 4h 56m`.

## License

[MIT](LICENSE)
