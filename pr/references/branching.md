# Branch naming

Agents left to themselves invent a type prefix per change—`fix/`, `chore/`, `bug/`, `docs/`, `refactor/`—and a repo ends up with a wild mix of branch names that no human chose. Counteract that: **detect the repo's branching pattern and follow it; when there is no clear pattern, use `feature/<slug>` for everything.**

## Detect

Look at what the repo already does, cheapest first:

1. **Written rules.** `CONTRIBUTING.md`, `.github/CONTRIBUTING.md`, `docs/`, `README.md`—search for "branch". A documented convention wins outright.
2. **Recent PR head branches** (the best signal—these are the names that actually got merged):
   `gh pr list --state all --limit 50 --json headRefName -q '.[].headRefName'`
3. **Remote branches:** `git branch -r --format='%(refname:short)'`
4. **Merge commits in history:** `git log --merges --oneline -50` (`Merge branch 'feature/x'`, `Merge pull request #12 from org/feature/x`).
5. **Long-lived branches:** does `develop` (or `dev`) exist next to `main`/`master`? That's Git Flow.

## Decide

- **A clear, consistent pattern exists** (most branches share one shape): follow it exactly—prefix, separator, ticket placement, casing. Examples: `RETHERA-123-short-slug`, `username/short-slug`, `feature/MED-481-booking`.
- **The repo already uses type prefixes consistently** (most branches are `fix/…`, `feat/…`, `chore/…` and they clearly map to change types): follow that. This is a pattern, not agent noise—but require a clear majority, not two stray branches.
- **GitHub Flow or Git Flow signals** (`main` + `feature/*`; `develop` + `feature/*`/`release/*`/`hotfix/*`), **or nothing evident at all** (fresh repo, only `main`, mixed names with no majority): use **`feature/<slug>` for every change**—bug fixes, chores, and docs included. Do not pick `fix/`, `bug/`, `chore/`, `docs/` because the change "is a fix"; the prefix names the workflow lane, not the change type.

Git Flow specifics:

- Branch features from `develop`, not `main`, and target the PR at `develop`.
- `hotfix/<slug>` only when the repo already has `hotfix/*` branches and the change is an urgent fix off `main`. Never create `release/*` branches on your own.

## Slug

- Lowercase kebab-case, ≤ ~40 chars, describing the change: `feature/pr-skill-ask-user-confirm`.
- Include a ticket ID only if the repo's pattern does, or the user names one and the pattern has room for it: `feature/MED-481-session-booking`.
- No dates, usernames, or agent names unless the pattern calls for them.

When you propose a branch, name it in the confirmation (the plan, or the `AskUserQuestion` prompt) so the user can override it via "Other".
