#!/usr/bin/env bash
# Claude Code status line — colored, no cost display
input=$(cat)

# --- ANSI color codes ---
RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
CYAN=$'\033[38;5;51m'
GREEN=$'\033[38;5;42m'
YELLOW=$'\033[38;5;221m'
RED=$'\033[38;5;203m'
MAGENTA=$'\033[38;5;213m'
BLUE=$'\033[38;5;111m'
GRAY=$'\033[38;5;240m'
ORANGE=$'\033[38;5;215m'

# --- Git info (skip optional locks) ---
git_branch=$(git -c core.fsmonitor=false --no-optional-locks branch --show-current 2>/dev/null)
git_ahead=$(git -c core.fsmonitor=false --no-optional-locks rev-list --count "@{u}..HEAD" 2>/dev/null)
git_behind=$(git -c core.fsmonitor=false --no-optional-locks rev-list --count "HEAD..@{u}" 2>/dev/null)
git_staged=$(git -c core.fsmonitor=false --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
git_modified=$(git -c core.fsmonitor=false --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')
git_untracked=$(git -c core.fsmonitor=false --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

# Build git status string (colored)
git_stats=""
[ "${git_staged:-0}" -gt 0 ] 2>/dev/null && git_stats="${git_stats}${GREEN}+${git_staged}${RESET}"
[ "${git_modified:-0}" -gt 0 ] 2>/dev/null && git_stats="${git_stats}${YELLOW}~${git_modified}${RESET}"
[ "${git_untracked:-0}" -gt 0 ] 2>/dev/null && git_stats="${git_stats}${RED}?${git_untracked}${RESET}"

git_arrows=""
[ "${git_ahead:-0}" -gt 0 ] 2>/dev/null && git_arrows="${git_arrows} ${MAGENTA}↑${git_ahead}${RESET}"
[ "${git_behind:-0}" -gt 0 ] 2>/dev/null && git_arrows="${git_arrows} ${MAGENTA}↓${git_behind}${RESET}"

# Rainbow shimmer for branch name — phase shifts with each render
rainbow_palette=(196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51 45 39 33 27 57 93 129 165 201 200 199 198 197)
palette_len=${#rainbow_palette[@]}
phase=$(( $(date +%s) % palette_len ))

rainbow_text() {
  local text="$1"
  local out=""
  local i=0
  local len=${#text}
  while [ $i -lt $len ]; do
    local ch="${text:$i:1}"
    local idx=$(( (i + phase) % palette_len ))
    local color="${rainbow_palette[$idx]}"
    out="${out}"$'\033[38;5;'"${color}"'m'"${ch}"
    i=$(( i + 1 ))
  done
  printf '%s%s' "$out" "$RESET"
}

if [ -n "$git_branch" ]; then
  glyph_idx=$(( phase % palette_len ))
  glyph_color="${rainbow_palette[$glyph_idx]}"
  branch_rainbow=$(rainbow_text "$git_branch")
  git_segment=$'\033[38;5;'"${glyph_color}"'m⎇'"${RESET} ${branch_rainbow}"
  [ -n "$git_stats" ] && git_segment="${git_segment} ${git_stats}"
  git_segment="${git_segment}${git_arrows}"
else
  git_segment=""
fi

# --- Model info ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)

if [ -n "$context_size" ]; then
  if [ "$context_size" -ge 1000000 ] 2>/dev/null; then
    ctx_label="$(( context_size / 1000000 ))M context"
  else
    ctx_label="$(( context_size / 1000 ))k context"
  fi
  model_clean=$(printf '%s' "$model_name" | sed -E 's/[[:space:]]*\([^)]*context\)[[:space:]]*$//')
  model_segment="${MAGENTA}${BOLD}${model_clean}${RESET} ${DIM}(${ctx_label})${RESET}"
else
  model_segment="${MAGENTA}${BOLD}${model_name}${RESET}"
fi

# --- Session elapsed time ---
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
elapsed_segment=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # Birth time of the transcript = session start. %m (mtime) resets every turn.
  if [ "$(uname)" = "Darwin" ]; then
    start_ts=$(stat -f "%B" "$transcript_path" 2>/dev/null)
  else
    start_ts=$(stat -c "%W" "$transcript_path" 2>/dev/null)
    # %W is 0 when the filesystem does not record birth time
    [ "$start_ts" = "0" ] && start_ts=""
  fi
  if [ -n "$start_ts" ]; then
    now_ts=$(date +%s)
    elapsed=$(( now_ts - start_ts ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))
    elapsed_segment="${BLUE}⏱ ${mins}m${secs}s${RESET}"
  fi
fi

# --- Context usage ---
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
ctx_segment=""
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf '%.0f' "$ctx_pct")
  if [ "$ctx_int" -ge 80 ] 2>/dev/null; then
    ctx_color="$RED"
  elif [ "$ctx_int" -ge 50 ] 2>/dev/null; then
    ctx_color="$ORANGE"
  else
    ctx_color="$GREEN"
  fi
  ctx_segment="${ctx_color}● ${ctx_int}% ctx${RESET}"
fi

# --- Assemble line ---
user_name="$(git config --global user.name 2>/dev/null || whoami)"
line="${CYAN}${user_name}${RESET}"
sep="${GRAY}│${RESET}"

[ -n "$git_segment" ] && line="${line} ${sep} ${git_segment}"
[ -n "$model_segment" ] && line="${line} ${sep} ${model_segment}"
[ -n "$elapsed_segment" ] && line="${line} ${sep} ${elapsed_segment}"
[ -n "$ctx_segment" ] && line="${line} ${sep} ${ctx_segment}"

printf '%s\n' "$line"
