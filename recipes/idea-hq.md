# Recipe: set up Idea HQ

Instructions for Claude. When the user says "set up my Idea HQ" (or similar), follow these steps. The user may be new to GitHub: before each step, say in one plain sentence what you're doing. Ask before anything not listed here.

Idea HQ is a private repo where the user pastes ideas. Claude files each one, says whether it fits an existing project, scores it against the user's goals, gives an honest opinion, and says what to work on first across all their projects.

## 1. Check the ground

- `gh auth status` must show a signed-in GitHub account. If not, stop and help the user run `gh auth login`.
- Projects folder: the folder that holds the user's other project folders (usually the parent of the current repo, or `~/Documents/GitHub`). Confirm it with the user in one line.
- If an `idea-hq` folder or repo already exists, stop and ask what they want.

## 2. Create the repo from the template

From the projects folder:

```
gh repo create idea-hq --private --template kraigeisenman/project-template --clone
```

If the new folder is empty (GitHub can take a few seconds to copy the template), wait 5 seconds, then `git -C idea-hq pull origin main`.

Then, inside `idea-hq`:

```
bash .claude/hooks/session-start.sh
git switch -c setup-idea-hq
```

The first command turns on the safety checks for this copy.

## 3. Ask about goals (three questions, one message)

1. What's your biggest money goal right now (sales, commission, savings)?
2. What eats the most of your time each week that you'd love to stop doing?
3. About how many hours a week do you have for side projects?

Write the answers into `GOALS.md` (template below).

## 4. Write the files

Write these into `idea-hq`. Fill in the placeholders in angle brackets.

- `CLAUDE.md`: replace the top heading with `# Idea HQ` and the whole "About this project" section with the **Idea HQ instructions** below. Keep the "Working with GitHub" section exactly as it is.
- `GOALS.md`, `IDEAS.md`, `README.md`: from the templates below.
- `PROJECTS.md`: for each git repo in the projects folder (except `idea-hq`), add one row:
  - the folder name;
  - one line on what it is, from its `README.md`;
  - the next unchecked step in its `ROADMAP.md`, or "no roadmap".

  Read only those files. Never copy customer data, keys or `.env` contents.
- Delete the `recipes/` folder.

If the user already pasted ideas while asking for the setup, file them into `IDEAS.md` now, following the instructions.

## 5. Save it and open the pull request

```
git add -A
git commit -m "Set up Idea HQ"
git push -u origin HEAD
gh pr create --fill
```

Then edit the pull request description to follow the template sections (What changed, Why, How it was tested, Safety). Give the user the link and tell them:

1. Review and merge it on GitHub (Files changed, then Squash and merge).
2. From then on, to add ideas: open PowerShell, `cd` into the `idea-hq` folder, run `claude`, and paste the ideas.

If this was a step in another project's `ROADMAP.md`, say it can be ticked off next time they're in that project.

---

## Idea HQ instructions (goes into CLAUDE.md)

```markdown
## About this project

Idea HQ: where the user keeps every idea and decides what to work on next across all their projects. Files:

| File | What it holds |
|---|---|
| `IDEAS.md` | Every idea, newest first, with score, status and opinion. "Now" list at the top |
| `GOALS.md` | The user's goals and how ideas are scored |
| `PROJECTS.md` | The user's projects and where each one stands |

The other projects sit next to this folder (`../<project>`). Read their `README.md` and `ROADMAP.md` when ranking; never change them from here.

## Commands

- **Pasted ideas, or `idea: <text>`**: for each idea:
  1. Check for duplicates: merge into an existing idea instead of adding a new one.
  2. Say where it fits: an existing project (name it), or new.
  3. Score it with `GOALS.md`.
  4. Give an honest opinion in two or three sentences. Say plainly if it's weak, risky, or should wait.
  5. Add it to `IDEAS.md`.
  Then update the "Now" list if the order changed.
- **`what should I work on?`**: read `IDEAS.md`, `GOALS.md` and each project's `ROADMAP.md`. Recommend ONE thing and why, then two runners-up. Prefer finishing in-progress work over starting something new.
- **`weekly review`**:
  - Merge duplicates.
  - Mark ideas older than a month that never moved as "parked".
  - Refresh `PROJECTS.md` from the other projects.
  - Re-rank the "Now" list.
  - Summarize in five lines or fewer.
- **`start <idea>`**: create a new project for it:
  1. `gh repo create <short-name> --private --template kraigeisenman/project-template --clone`, in the projects folder.
  2. Tell the user to open Claude in that folder and describe the idea; the template asks the rest.
  3. Mark the idea "building" and add the project to `PROJECTS.md`.
- **`park <idea>` / `drop <idea>`**: change its status, with a one-line reason.

## Rules

- **One branch and one pull request per session.** Make a branch named `ideas-<date>` when the first change of the session comes in. Keep adding to it, and open the pull request when the user says they're done, or before the session ends. Don't open a pull request per idea.
- **Ideas only.** Never paste customer names, phone numbers, emails, addresses or call notes into this repo. Describe the idea instead ("a quote tool for multi-location customers").
- **Flag company risk.** If an idea uses customer data or company systems (CRM, phone system, company email), say it may need a manager's or IT's OK first.
- **At most two projects at a time.** If two are already "building", say so before recommending a third.
```

## GOALS.md template

```markdown
# Goals

## Right now

- Money: <answer 1>
- Time: <answer 2>
- Hours a week for side projects: <answer 3>

## How ideas are scored

Each idea gets 1–5 on each:

| Score | 1 | 5 |
|---|---|---|
| Money: more sales, commission or savings | Little | A lot |
| Time: hours saved each week | Under 1 | 5 or more |
| Effort: work to get a first version | An afternoon | Several weeks |

Priority = Money + Time − Effort, plus 1 if it builds on an existing project. Claude may move an idea up or down for a reason it states (deadline, risk, fun, a quick win).

Change these whenever goals change; Claude re-ranks at the next weekly review.
```

## IDEAS.md template

```markdown
# Ideas

## Now

The top three, in order, with one line each on why. Updated whenever ideas change.

1. (empty)

## All ideas

Newest first. Status: new, next, building, done, parked, dropped.

<!-- Example layout (delete when the first real idea is added):
### Quote helper for multi-location deals
- Added: 2026-11-09 · Status: new · Fits: an existing sales app
- Score: Money 4 · Time 3 · Effort 2 → Priority 6
- Opinion: Strong. Builds on deal data you already track. Start with one location type.
-->
```

## README.md template

```markdown
# Idea HQ

Every idea in one place, scored against my goals, with an honest opinion on what to do first.

## How to use it

1. Through the day, jot ideas in a phone note.
2. Once a day: open PowerShell, `cd` into this folder, run `claude`, and paste them.
3. Ask "what should I work on?" any time. Ask for a "weekly review" once a week.
4. Merge the day's pull request when you're done.

Ideas only: no customer names, numbers or call notes.
```
