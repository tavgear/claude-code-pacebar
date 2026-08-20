# pacebar

## Language

Documentation, code comments and commit messages are written in English.

## Commits

`area: imperative summary`, lowercase, no trailing period — `readme: lead with
the 24h gauge`, `demo: say where to point the font path`. Changes to the script
itself take no prefix: `collapse the separator into a single string`.

## Adding a setting

Defaults live in one block at the top of `pacebar.sh`. `cfg` resolves every
`PB_<NAME>` against its `PB_M_<NAME>` twin on narrow terminals, so a new setting
needs no second code path — only the default, plus the twin where the narrow
layout differs.

A new or changed setting lands in three places at once: the Defaults block,
`pacebar.conf.example`, and the README tables.

## Constraints

- `bash` 3.2 or newer, and nothing else: installing pacebar is a clone and one
  settings line, and a dependency would undo that.
- 3.2 being the floor rules out `declare -A`, `${var,,}`, `mapfile`, `local -n`
  and bare `EPOCHSECONDS`.
- A missing or unreadable field skips its section rather than failing.
- The version lives in `PB_VERSION` and `CHANGELOG.md` (Keep a Changelog,
  SemVer).

## Checking a change

```bash
./preview.sh            # a gallery of typical states, wide and narrow
./preview.sh --configs  # the same numbers under different settings
```

Both widths matter — the gallery renders each state at `COLUMNS=140` and `80`.
Regenerate the README images only when the output actually changed:

```bash
./preview.sh | python3 demo/render.py demo/pacebar.png
```
