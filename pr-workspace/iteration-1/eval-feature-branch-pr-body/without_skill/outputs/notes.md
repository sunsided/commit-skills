# Decision notes

## Title style

- The repo's commit history uses Conventional Commits
  (`chore:`, `feat:`, `feat(booking):`, `test(booking):`), and the
  fixture comment notes that PR titles historically follow the same
  convention. So the title uses `feat(booking): ...`.
- All three branch commits are `feat(booking)` / `test(booking)`, so
  `feat(booking)` is the correct scope for the umbrella PR (the test
  is supporting the same feature, not a standalone change).
- Kept the title under 80 chars and front-loaded the user-visible
  behavior ("require explicit session booking before message send")
  rather than the implementation detail (SlotLock, 409).
- Appended `[MED-481]` so the ticket shows up in the PR list view
  without having to open the body.

## Issue link

- Found the ticket ID in the branch name:
  `feat/MED-481-explicit-booking`. No issue references in commit
  bodies or files, and there is no PR template in the repo, so the
  branch name is the only source. Surfaced it both in the title
  (`[MED-481]`) and in a dedicated `Ticket:` line in the Summary.

## Body structure

- No PR template exists in the fixture, so I used a conventional
  layout: Summary -> Changes -> Why this shape -> Test plan ->
  Follow-ups.
- "Summary" explains the *why* (prevent double-booking, give the API
  a clean "no session" failure mode) instead of restating the diff.
- "Changes" is grouped by file/module and matches the three commits
  one-to-one so a reviewer can map body bullets to commits.
- "Why this shape" captures non-obvious design choices (separate
  module, additive `send_strict` instead of replacing `send`) since
  those are the questions a reviewer would otherwise ask inline.
- "Test plan" mixes the automated test from commit 3 with two manual
  checks for the new 409 path and the happy path, because the
  automated suite does not yet exercise `send_strict`.
- "Follow-ups" lists known gaps (HTTP wiring, Redis backend, real
  persistence in `confirm`, deprecating `send`) so reviewers know
  what is intentionally out of scope.
