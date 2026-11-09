# Recipe: set up a Windows PC for GitHub projects with Claude

Instructions for Claude. The user has just installed Claude Code and is new to Git and GitHub. Take them from nothing to working projects with safety checks on.

How to work:

- Before each step, say in one plain sentence what you're doing and why. Keep messages short.
- This recipe can be restarted. Every time you start (or the user says "continue"), check each step's state and skip what's already done.
- You run in PowerShell until Git is installed, and in Git Bash after. The commands below work in both unless noted.
- Ask before anything not in this recipe. Never merge a pull request for the user. Never delete anything without a yes.

## 0. Before you start

Tell the user, in three lines:
- It takes about 20 minutes.
- They'll restart Claude once, and sign in to GitHub in their browser once.
- They can say "stop" any time and "continue" later.

Claude will ask permission for many commands. Suggest "Yes, and don't ask again" for `git`, `gh` and `winget` commands.

## 1. Install Git and the GitHub tool

Check `git --version` and `gh --version`. For each one missing:

```
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
winget install --id GitHub.cli -e --accept-source-agreements --accept-package-agreements
```

A Windows "allow changes" prompt may appear; the user clicks Yes.

If you installed anything, Claude can't see it until it restarts. Tell the user exactly:

1. Close this window.
2. Open a new PowerShell window.
3. Type `cd $HOME\Documents\GitHub` then `claude --continue`.
4. Say "continue".

Then stop and wait.

## 2. Sign in to GitHub

Check `gh auth status`. If not signed in, ask the user to do this in a **second** PowerShell window (it needs their keyboard):

```
gh auth login --hostname github.com --git-protocol https --web
```

- Answer **Y** to "Authenticate Git with your GitHub credentials?".
- Copy the one-time code, press Enter, and paste the code in the browser.

When they say done, check `gh auth status` again, then run `gh auth setup-git`.

## 3. Tell Git who they are

Check `git config --global user.name` and `git config --global user.email`. If either is empty:

- Name: ask for it.
- Email: offer their private GitHub address, so their real email isn't shown on public work:

  ```
  gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'
  ```

Then set both:

```
git config --global user.name "<name>"
git config --global user.email "<email>"
```

## 4. Make the projects folder

Use `~/Documents/GitHub` (Windows: `$HOME\Documents\GitHub`). Create it if missing, and work from there.

## 5. Download their projects

1. List the user's repos: `gh repo list --limit 50`.
2. Show the names, and ask which to download. Suggest all, except archived ones and any a pull request says are being retired.
3. Clone each one not already there: `gh repo clone <owner>/<name>`.

## 6. Go through open pull requests

For each downloaded repo, run `gh pr list --repo <owner>/<name>`. Take open pull requests oldest first. For each one:

1. Explain it in three plain sentences. Use `gh pr view <n> --repo <owner>/<name>`, plus `gh pr diff <n> --repo <owner>/<name> --name-only` for the files.
2. Check `gh pr checks <n> --repo <owner>/<name>`. If something failed, say what, and don't suggest merging yet.
3. If the description asks for a test before merging, help with it. For example, to try a branch's apps without touching the main copy:
   - Clone the branch into a separate test folder outside the projects folder: `git clone --branch <branch> --single-branch https://github.com/<owner>/<name>.git $HOME\Desktop\<name>-test`.
   - Tell the user exactly what to open or double-click.
   - Afterwards, offer to delete the test folder.
4. Open it in the browser: `gh pr view <n> --repo <owner>/<name> --web`.
5. Walk the user through reviewing it:
   - **Files changed** tab: green lines added, red removed.
   - The Checks.
   - **Squash and merge**, then **Confirm**.

   The user clicks Merge, not you.
6. When they say it's merged: `git -C <name> pull`.

## 7. Repo settings (owner only)

Ask once for a yes to apply this to every downloaded repo. It makes each merge one tidy entry and removes finished branches automatically.

```
gh repo edit <owner>/<name> --enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false --delete-branch-on-merge
```

If a merged pull request's description asks for a rename or an archive, offer each one separately and wait for a yes:

- Rename:
  1. `gh repo rename <new> --repo <owner>/<old> --yes`
  2. Rename the local folder to match.
  3. In it, `git remote set-url origin https://github.com/<owner>/<new>.git`.
- Archive: `gh repo archive <owner>/<name> --yes`. Then offer to delete that repo's local folder.

## 8. Turn on the safety checks

In each repo that has `.claude/hooks/session-start.sh`, run `bash .claude/hooks/session-start.sh` from inside the repo.

Then prove they work in one repo, on `main`:

```
git commit --allow-empty -m "safety test"
```

It must be refused with "Stopped: you're on main". If it was NOT refused:
1. Undo it with `git reset --soft HEAD~1` (it was never pushed).
2. Tell the user to let the person who set up their projects know.

## 9. Which Claude model

Tell the user in a few lines:
- **Sonnet** for everyday work.
- **Opus** for hard problems, if their plan has it.
- **Not Fable**: on Pro and Max it bills extra usage credits.
- `/model` switches, and `/usage` shows how much is left.

## 10. Finish

Give a short checklist of what was done. Then name the next step:

- If a project has a `ROADMAP.md`: "Open PowerShell, `cd $HOME\Documents\GitHub\<project>`, run `claude`, and say **what's next?**".
- Otherwise: "Open Claude in any project folder and describe what you want to change."
