#!/usr/bin/env bash
# Safety checks shared by the git pre-commit hook and the GitHub checks.
#
#   bash scripts/repo-checks.sh --staged             check what is about to be committed
#   bash scripts/repo-checks.sh --range BASE HEAD    check a pull request's changes
#
# Per-repo settings live in scripts/repo-checks.conf.

set -u

mode="${1:-}"
case "$mode" in
  --staged) diff_args=(--cached) ;;
  --range)
    if [ $# -lt 3 ]; then echo "usage: $0 --range BASE HEAD" >&2; exit 64; fi
    diff_args=("$2...$3") ;;
  *) echo "usage: $0 --staged | --range BASE HEAD" >&2; exit 64 ;;
esac

root="$(git rev-parse --show-toplevel)" || exit 1
cd "$root" || exit 1

# Defaults; scripts/repo-checks.conf can change them.
PII_SCAN=no                        # yes = flag phone numbers and emails
PII_ALLOWED_PATHS='^examples/'     # where fictional sample data may live
[ -f scripts/repo-checks.conf ] && . scripts/repo-checks.conf

problems=0
fail() { problems=$((problems + 1)); printf '  - %s\n' "$1"; }

echo "Running safety checks..."

# 1. Files that must never be in the repo.
blocked_paths='(^|/)\.env($|\.)|(^|/)(Data|Exports|recordings|transcripts|calls)/|(^|/)Data before sync|\.(mp3|wav|m4a|mp4|mov|aac|ogg|wma)$|(^|/)id_(rsa|ed25519|ecdsa)($|\.)|\.(pem|p12|pfx|key)$'
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in .env.example|*/.env.example) continue ;; esac
  if printf '%s\n' "$f" | grep -Eiq "$blocked_paths"; then
    fail "$f: this kind of file never goes on GitHub (secrets, recordings or your saved sales data). Remove it with: git restore --staged \"$f\""
  fi
done < <(git diff "${diff_args[@]}" --name-only --diff-filter=ACMR)

# 2. Secrets and personal details inside the changed lines.
key_pattern='-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9_-]{20,}|sk_live_[A-Za-z0-9]{16,}|xox[abpr]-[A-Za-z0-9-]{10,}|gh[pousr]_[A-Za-z0-9]{30,}|AIza[0-9A-Za-z_-]{35}'
phone_pattern='(\+?1[ .-]?)?\(?[2-9][0-9]{2}\)?[ .-][0-9]{3}[ .-][0-9]{4}'
email_pattern='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
safe_email='@(example\.(com|org|net)|users\.noreply\.github\.com)$'

file=''
while IFS= read -r line; do
  case "$line" in
    '+++ b/'*) file="${line#+++ b/}"; file="${file%$'\t'}"; continue ;;   # git adds a tab after names with spaces
    '+++ '*)   file=''; continue ;;
    '+'*)      ;;
    *)         continue ;;
  esac
  [ -z "$file" ] && continue
  [ "$file" = scripts/repo-checks.sh ] && continue   # this file holds the patterns
  text="${line#+}"

  if printf '%s\n' "$text" | grep -Eq -- "$key_pattern"; then
    fail "$file: a line looks like a password or API key. Keys belong in your local .env file, not on GitHub."
  fi

  if [ "$PII_SCAN" = yes ] && ! printf '%s\n' "$file" | grep -Eq "$PII_ALLOWED_PATHS"; then
    while IFS= read -r num; do
      digits="$(printf '%s' "$num" | tr -cd '0-9')"
      digits="${digits#1}"
      case "$digits" in 555???????|???555????|0000000000|1234567890) continue ;; esac   # 555 = made-up number
      fail "$file: \"$num\" looks like a real phone number. Customer details never go in this repo; use 555-123-4567 in examples."
    done < <(printf '%s\n' "$text" | grep -Eo -- "$phone_pattern")
    while IFS= read -r addr; do
      printf '%s\n' "$addr" | grep -Eiq "$safe_email" && continue
      fail "$file: \"$addr\" looks like a real email address. Use you@example.com in examples."
    done < <(printf '%s\n' "$text" | grep -Eo -- "$email_pattern")
  fi
done < <(git diff "${diff_args[@]}" -U0 --no-color --diff-filter=ACMR)

if [ "$problems" -gt 0 ]; then
  echo
  echo "Stopped: $problems problem(s) above. Fix them, then try again."
  echo "Don't skip this check; it protects customer data and your accounts."
  exit 1
fi
echo "Safety checks passed."
