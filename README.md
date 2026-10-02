# claude-statusline

A colored status line for [Claude Code](https://claude.com/claude-code).
It shows who you are, your git state, the model and its context size, how long the session has run, and how full the context is.

![preview](assets/preview.png)

```
Mohammed Anfas K P │ ⎇ main +2~1?3 ↑1 │ Opus 5.5 (1M context) │ ⏱ 12m4s │ ● 6% ctx
```

## How it works

```
 Claude Code (every render)
        |
        |  JSON on stdin: model, context_window, transcript_path
        v
 ~/.claude/settings.json   "statusLine" -> bash statusline-command.sh
        |
        v
 statusline-command.sh
   git    -> branch, staged / modified / untracked, ahead / behind
   jq     -> model name, context size, context used %
   stat   -> transcript birth time -> session timer
        |
        v
 one ANSI-colored line on stdout -> drawn under the prompt
```

## Segments

| Segment | Source | Color |
|---|---|---|
| Name | `git config --global user.name`, else `whoami` | cyan |
| `⎇ branch +staged ~modified ?untracked ↑ahead ↓behind` | `git` (hidden outside a repo) | rainbow, shifts every second |
| `Model (1M context)` | `.model.display_name`, `.context_window.context_window_size` | bold magenta, size dim |
| `⏱ 12m4s` | transcript file birth time | blue |
| `● 6% ctx` | `.context_window.used_percentage` | green, orange at 50%, red at 80% |

## Requirements

- macOS or Linux
- `bash`, `git`, `jq`
- A terminal with 256 colors

## Install

One line:

```bash
curl -fsSL https://raw.githubusercontent.com/anfastech/claude-statusline/main/install.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/anfastech/claude-statusline.git
cd claude-statusline
./install.sh
```

The installer:

1. Copies `statusline-command.sh` to `~/.claude/`.
2. Backs up `~/.claude/settings.json` to `settings.json.bak.<timestamp>`.
3. Sets the `statusLine` key and leaves every other key alone.

Restart Claude Code.

### As a Claude Code skill

Copy the skill, then ask Claude to "set up the claude-statusline".

```bash
mkdir -p ~/.claude/skills
cp -r skills/claude-statusline ~/.claude/skills/
```

### By hand

See [docs/RECREATE.md](docs/RECREATE.md) for every step, the full script, and the settings JSON.

## Test

```bash
echo '{"model":{"display_name":"Opus 5.5"},"context_window":{"context_window_size":1000000,"used_percentage":6}}' \
  | bash ~/.claude/statusline-command.sh
```

## Customize

Edit `~/.claude/statusline-command.sh`.

- **Colors:** the `ANSI color codes` block, 256-color values.
- **Context thresholds:** `-ge 80` and `-ge 50` in the `Context usage` block.
- **Remove a segment:** delete its `[ -n "$..._segment" ] && line=...` line at the bottom.

## Uninstall

```bash
./uninstall.sh
```

It removes the script and the `statusLine` key, after a backup.

## Notes

- The second footer line (`bypass permissions on ... ← 1 agent`) is built into Claude Code. This script does not draw it.
- Git calls use `--no-optional-locks` so the status line never blocks your own git commands.
- No cost is shown, on purpose.

## License

MIT
