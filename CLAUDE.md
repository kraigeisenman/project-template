# New project

## About this project

TODO: not written yet.

If this section still says TODO, this is a brand-new project. Before anything else:

1. Ask Colby in two or three short questions what he wants to build, who it's for, and where it will run (Windows PC, browser, Claude).
2. Suggest the simplest way to build a first version, in plain words, and wait for his yes.
3. On a branch, replace this section with a short description, rename the heading at the top to the project's name, rewrite `README.md` to match, delete the `recipes/` folder, and open a pull request.

Keep the first version small. Plenty of ideas can wait for the next pull request.

## Working with GitHub

Colby is new to Git and GitHub. Keep him safe and teach as you go.

- Before any git or GitHub action, say in one plain sentence what you're about to do and why.
- Start new work from an up-to-date main: `git switch main`, `git pull`, then `git switch -c short-name-for-the-change`.
- Never commit on main. Every change goes on its own branch and into a pull request.
- Commit in small steps with a plain one-line summary of what changed (example: `Add appointment overview rules`).
- When the change is ready: `git push -u origin HEAD`, then `gh pr create` using the pull request template. Fill in every section, then stop. Colby reviews and merges on GitHub; never merge for him.
- If the pull request's Checks fail, tell Colby what failed and fix it on the same branch before he merges.
- After Colby merges: `git switch main`, `git pull`, `git branch -d <old-branch>`.
- Never force-push, rewrite history, reset --hard, or skip a check (`--no-verify`). If a safety check blocks you, explain why in plain words and fix the cause.
- If something about git is unclear or looks risky, stop and ask Colby before going further.
- The safety rules live in `.githooks/`, `scripts/repo-checks.sh` and `.claude/settings.json`. Change them only through a pull request that says so in its title.
