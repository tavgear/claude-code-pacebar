---
description: Point Claude Code's status line at pacebar
---

Install pacebar as this user's status line.

1. Copy `${CLAUDE_PLUGIN_ROOT}/pacebar.sh` to `~/.claude/pacebar/pacebar.sh`, creating the
   directory and keeping the executable bit. The copy is what the status line runs: a
   plugin lives under a versioned path that moves on every update, and the status line
   would follow it into a directory that is no longer there.
2. In `~/.claude/settings.json`, set `statusLine` to
   `{"type": "command", "command": "~/.claude/pacebar/pacebar.sh"}` and leave every other
   key as it is. When a different status line is already configured, print it and ask
   before replacing it.
3. Say that the line appears on the next redraw; that settings are optional and live in
   `~/.claude/pacebar.conf`, for which `${CLAUDE_PLUGIN_ROOT}/pacebar.conf.example` is the
   annotated template; and that a later `/plugin update pacebar` followed by this command
   again installs the new version.
