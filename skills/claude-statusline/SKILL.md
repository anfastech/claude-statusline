---
name: claude-statusline
description: Install or customize the colored Claude Code status line (user, git branch, model, context size, session timer, context usage). Use when the user wants this status line set up, repaired, or changed.
---

# Claude status line

Sets up a one-line footer under the Claude Code prompt:

```
<git user.name> │ ⎇ <branch> +staged ~modified ?untracked ↑ahead ↓behind │ <Model> (<N>M context) │ ⏱ <m>m<s>s │ ● <pct>% ctx
```

## Install

1. Check `jq` exists (`command -v jq`). If not, ask the user to install it.
2. Fetch the script from `https://raw.githubusercontent.com/anfastech/claude-statusline/main/statusline-command.sh`
   and save it as `~/.claude/statusline-command.sh`. Make it executable.
3. Read `~/.claude/settings.json`, back it up, then set only this key and keep every other key:
   ```json
   "statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
   ```
4. Test with sample input and show the output with ANSI codes stripped:
   ```bash
   echo '{"model":{"display_name":"Opus 5.5"},"context_window":{"context_window_size":1000000,"used_percentage":6}}' \
     | bash ~/.claude/statusline-command.sh | sed 's/\x1b\[[0-9;]*m//g'
   ```
5. Tell the user to restart Claude Code.

## Customize

Edit `~/.claude/statusline-command.sh`. The segments are assembled at the bottom of the file.

| Change | Where |
|---|---|
| Colors | the `ANSI color codes` block, 256-color values |
| Context thresholds | `-ge 80` (red) and `-ge 50` (orange) in `Context usage` |
| Drop a segment | delete its `[ -n "$..._segment" ] && line=...` line |
| Branch rainbow | `rainbow_palette` array |
| Name shown first | `user_name=` line |

## Input fields used

Claude Code sends JSON on stdin each render. The script reads:
`.model.display_name`, `.context_window.context_window_size`,
`.context_window.used_percentage`, `.transcript_path`.

## Notes

- The timer uses the transcript's birth time (`stat -f %B` on macOS, `stat -c %W` on Linux).
  Do not switch it to `%m`: that is the last write time and resets every turn.
- The second footer line (permission mode, running agents) is built into Claude Code. The script cannot change it.
