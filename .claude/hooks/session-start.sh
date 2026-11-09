#!/usr/bin/env bash
# Claude Code SessionStart hook: turn on the git safety hooks and report where the repo stands.
# What it prints is shown to Claude at the start of the session.

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Turn on .githooks for this copy of the repo (git doesn't do this by itself).
if [ "$(git config --get core.hooksPath)" != .githooks ]; then
  git config core.hooksPath .githooks
  echo "Turned on the safety checks in .githooks for this copy of the repo."
fi

# Catch up with GitHub without ever waiting on a password prompt.
GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5" \
  git fetch --quiet --prune origin >/dev/null 2>&1 || echo "Couldn't reach GitHub just now; the status below may be out of date."

branch="$(git symbolic-ref --short -q HEAD || echo '(no branch)')"
echo "Git status at session start:"
echo "- Current branch: $branch"

changes="$(git status --porcelain | wc -l | tr -d ' ')"
[ "$changes" -gt 0 ] && echo "- $changes file(s) changed and not committed yet."

if git rev-parse --verify -q origin/main >/dev/null; then
  if [ "$branch" = main ]; then
    behind="$(git rev-list --count main..origin/main 2>/dev/null || echo 0)"
    [ "$behind" -gt 0 ] && echo "- main is $behind commit(s) behind GitHub. Run 'git pull' before starting new work."
    echo "- You're on main. Before changing files, make a branch: git switch -c short-name-for-the-change"
  else
    track="$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch")"
    if [ "$track" = "[gone]" ]; then
      echo "- This branch's copy on GitHub is gone (its pull request was probably merged). Switch to main, pull, and delete this branch."
    fi
    ahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)"
    echo "- This branch has $ahead commit(s) that aren't in main yet."
  fi
fi

echo "Follow the 'Working with GitHub' rules in CLAUDE.md."
exit 0
