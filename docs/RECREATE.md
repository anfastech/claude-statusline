# Recreate by hand

Every step to rebuild this status line without the installer.

## 1. Install jq

```bash
brew install jq        # macOS (macOS 15+ already ships /usr/bin/jq)
sudo apt install jq    # Debian / Ubuntu
```

## 2. Save the script

Copy [`statusline-command.sh`](../statusline-command.sh) to `~/.claude/statusline-command.sh`, then:

```bash
chmod +x ~/.claude/statusline-command.sh
```

## 3. Point Claude Code at it

Add this key to `~/.claude/settings.json`. Keep your other keys.

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

## 4. Restart Claude Code

## What the script receives

Claude Code pipes JSON to the script on every render. The fields used:

| Field | Example | Used for |
|---|---|---|
| `.model.display_name` | `Opus 5.5` | model segment |
| `.context_window.context_window_size` | `1000000` | `(1M context)` |
| `.context_window.used_percentage` | `6.2` | `● 6% ctx` |
| `.transcript_path` | `~/.claude/projects/.../<id>.jsonl` | session timer |

## Script walkthrough

```
 read stdin
     |
     v
 colors  ->  git info  ->  rainbow branch  ->  model  ->  timer  ->  context %
                                                                       |
                                                                       v
                              name │ git │ model │ timer │ ctx  (empty parts skipped)
```

1. **Colors.** 256-color ANSI codes: cyan 51, green 42, yellow 221, red 203, magenta 213, blue 111, gray 240, orange 215.
2. **Git.** Branch, ahead/behind upstream, and counts of staged, modified and untracked files. Every call uses `--no-optional-locks` and `core.fsmonitor=false`.
3. **Rainbow branch.** Each letter takes a color from a 29-step palette. The start shifts with the current second, so it shimmers between renders.
4. **Model.** Strips any `(... context)` suffix from the name, then adds its own `(1M context)` or `(200k context)` from the window size.
5. **Timer.** Now minus the transcript's birth time. macOS uses `stat -f %B`, Linux uses `stat -c %W`.
6. **Context.** Rounded percentage. Green below 50, orange from 50, red from 80.
7. **Assemble.** Name first, then each non-empty segment behind a gray `│`.

## Why birth time, not mtime

The first version used `stat -f %m`, the last write time. Claude Code writes the transcript every turn, so the timer fell back to about `0m0s` on each message.
Measured on one session: birth time 115s ago, last write 1s ago. Birth time gives the real session length.

## The second line

`▸▸ bypass permissions on (shift+tab to cycle) · ← 1 agent` is drawn by Claude Code itself. It shows the permission mode and running background agents. No setting or script controls it.
