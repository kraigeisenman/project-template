#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash): stops git commands that skip the safety rules.
# Exit 2 blocks the command and shows the message to Claude.

input="$(cat)"
# No jq: Git Bash doesn't ship it. Pull fields out with grep/sed.
field() { printf '%s' "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*" | head -n 1 | sed "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//"; }
# Start of the command text (up to its first quote).
cmd="$(field command)"
[ -z "$cmd" ] && exit 0

block() { echo "BLOCKED by the repo's GitHub rules: $1" >&2; exit 2; }

case "$input" in
  *--no-verify*) block "--no-verify skips the safety checks. Fix what the check reported instead." ;;
  *core.hooksPath*) block "the safety hooks setting is managed by .claude/hooks/session-start.sh." ;;
esac

if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$)'; then
  # Making a branch in the same command (git switch -c x && git commit ...) is fine.
  if ! printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(switch[[:space:]]+(-c|--create)|checkout[[:space:]]+-b)'; then
    # Check the folder the commit runs in: `git -C <dir>`, else a leading `cd <dir> &&`,
    # else the shell's current folder, else the project folder.
    dir="$(printf '%s' "$cmd" | sed -E -n 's/.*git[[:space:]]+-C[[:space:]]+([^[:space:]]+).*/\1/p')"
    [ -z "$dir" ] && dir="$(printf '%s' "$cmd" | sed -E -n 's/^[[:space:]]*cd[[:space:]]+([^;&|]*[^;&|[:space:]])[[:space:]]*(&&|;).*/\1/p')"
    [ -z "$dir" ] && dir="$(field cwd | sed 's/\\\\/\\/g')"
    [ -z "$dir" ] && dir="${CLAUDE_PROJECT_DIR:-.}"
    dir="${dir#[\'\"]}"; dir="${dir%[\'\"]}"
    case "$dir" in '~'*) dir="$HOME${dir#\~}" ;; esac
    branch="$(git -C "$dir" symbolic-ref --short -q HEAD 2>/dev/null)"
    if [ "$branch" = main ] || [ "$branch" = master ]; then
      block "you're on $branch in $dir. Make a branch first (git switch -c short-name), then commit there."
    fi
  fi
fi

exit 0
