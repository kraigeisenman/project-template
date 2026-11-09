#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash): stops git commands that skip the safety rules.
# Exit 2 blocks the command and shows the message to Claude.

input="$(cat)"
# Start of the command text (up to its first quote). No jq: Git Bash doesn't ship it.
cmd="$(printf '%s' "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*' | head -n 1 | sed 's/^"command"[[:space:]]*:[[:space:]]*"//')"
[ -z "$cmd" ] && exit 0

block() { echo "BLOCKED by the repo's GitHub rules: $1" >&2; exit 2; }

case "$input" in
  *--no-verify*) block "--no-verify skips the safety checks. Fix what the check reported instead." ;;
  *core.hooksPath*) block "the safety hooks setting is managed by .claude/hooks/session-start.sh." ;;
esac

if printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$)'; then
  # Making a branch in the same command (git switch -c x && git commit ...) is fine.
  if ! printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(switch[[:space:]]+(-c|--create)|checkout[[:space:]]+-b)'; then
    cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null
    branch="$(git symbolic-ref --short -q HEAD)"
    if [ "$branch" = main ] || [ "$branch" = master ]; then
      block "you're on $branch. Make a branch first (git switch -c short-name), then commit there."
    fi
  fi
fi

exit 0
