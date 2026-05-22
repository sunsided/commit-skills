# Grouping notes

Three commits, one per logical change, matching the three unrelated
concerns described in the task.

## Commit 1 — users endpoint
- `src/users.js` (new): defines `handleGetUser` and the in-memory store.
- `tests/users.test.js` (new): exercises both branches of that handler.
- `src/index.js` (modified): adds the `/users/:id` route that dispatches
  to `handleGetUser`. Grouped with the endpoint because the handler is
  unreachable without this routing edit — splitting them would leave
  one commit with dead code and another that won't compile against
  the prior tree.

## Commit 2 — CI Node bump
- `.github/workflows/ci.yml` only. Pure infra change, isolated from
  source and docs.

## Commit 3 — README typo
- `README.md` only. Docs-only fix, kept separate so it can be reverted
  or cherry-picked independently.

## Ambiguities
- Could not run `git status` / `git diff` in this sandbox (git
  commands were denied), so the exact diff hunks weren't inspected;
  grouping relies on the task description plus file contents. If
  `src/index.js` also contains an unrelated edit, it would need to be
  split out.
- README typo location not verified against HEAD; subject kept generic.
