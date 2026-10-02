# Instructions for agents

You are installing this status line for a person on their machine.
Follow these steps in order. Do not skip the checks.

## Flow

```
 check OS + tools
      |
      v
 read ~/.claude/settings.json
      |
      +-- statusLine already set to something else? -> ask the person, stop until they answer
      |
      v
 run install.sh   (backs up settings, copies script, sets statusLine)
      |
      v
 verify: settings key, script present, sample render
      |
      v
 report to the person
```

## 1. Check the machine

- OS must be macOS or Linux. On Windows (not WSL), stop and say it is not supported.
- `command -v bash git jq curl` must all succeed.
- If `jq` is missing, ask the person before installing it (`brew install jq` on macOS, `sudo apt install jq` on Debian/Ubuntu). Do not install it silently.
- The config dir is `$CLAUDE_CONFIG_DIR` if set, else `~/.claude`.

## 2. Look before changing anything

```bash
jq '.statusLine // "none"' ~/.claude/settings.json 2>/dev/null || echo "no settings.json yet"
```

- `none`, or no file: continue.
- Already `bash <config dir>/statusline-command.sh`: this is a reinstall or update. Continue.
- Anything else: the person has their own status line. Show it to them and ask whether to replace it. Do not continue without a yes.

## 3. Install

```bash
curl -fsSL https://raw.githubusercontent.com/anfastech/claude-statusline/main/install.sh | bash
```

From a clone, run `./install.sh` instead. Either way it:

1. Copies `statusline-command.sh` to `<config dir>/statusline-command.sh`.
2. Backs up `settings.json` to `settings.json.bak.<timestamp>`.
3. Sets only the `statusLine` key. Every other key stays as it was.

Never edit `settings.json` by hand for this, and never write the whole file from memory. The installer merges with `jq`.

## 4. Verify

Run all three and keep the output for the report.

```bash
jq .statusLine ~/.claude/settings.json
test -x ~/.claude/statusline-command.sh && echo "script ok"
echo '{"model":{"display_name":"Opus 5.5"},"context_window":{"context_window_size":1000000,"used_percentage":6}}' \
  | bash ~/.claude/statusline-command.sh | sed 's/\x1b\[[0-9;]*m//g'
```

The last line should look like:

```
<name> │ Opus 5.5 (1M context) │ ● 6% ctx
```

The timer segment only appears when a real `transcript_path` is passed, so it is missing here. That is expected.

## 5. Optional: install the skill

Only if the person asks for it:

```bash
mkdir -p ~/.claude/skills
cp -r skills/claude-statusline ~/.claude/skills/
```

If `~/.claude/skills/claude-statusline` already exists, ask before replacing it.

## 6. Report

Tell the person, briefly:

- The backup file path.
- The sample render output, pasted as it was printed.
- That they must restart Claude Code to see it.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/anfastech/claude-statusline/main/uninstall.sh | bash
```

It backs up `settings.json`, removes the `statusLine` key and deletes the script.

## Do not

- Do not change any `settings.json` key other than `statusLine`.
- Do not switch the timer to `stat %m`. It resets every turn. Birth time is correct.
- Do not try to change the second footer line (permission mode, agents). Claude Code draws it, not this script.
