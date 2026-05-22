# Notes

## Style detected
Ticket-prefixed: `MED-XXX: <Imperative subject>`. All three commits on main
match this shape (`MED-100: Initial calendar crate`, `MED-204: Add
total_pages helper`, `MED-204: Cover total_pages with a test`). No
CONTRIBUTING, .gitmessage, or commitlint config present, so detection
relies on observed history. Subjects use capitalized first word after the
colon and stay under 50 chars; bodies are not visible in the reflog
sample but the skill permits adding one for non-trivial behavior changes
without imposing a new style.

## Ticket-link reasoning
Branch name is `bugfix/MED-842-partial-read` (read from
`.git/refs/heads/bugfix/MED-842-partial-read`), which yields `MED-842`
per the `[A-Z]+-\d+` heuristic in references/issue-links.md. Since the
repo already puts the ticket in the subject prefix, MED-842 goes there
for commit 1 rather than in a `Refs:` footer alone; the footer is kept
as an additional anchor matching the rich-template convention.

The serde bump is not part of the MED-842 fix - it is a drive-by
maintenance change with no ticket. Per issue-links.md ("When there is no
ticket... do not fabricate a placeholder"), commit 2 carries no prefix
and no Refs line; its subject reads as a plain imperative, which the
repo also tolerates for chore-style work.

## Grouping decisions
Two commits:
1. `src/reader.rs` + `tests/reader.rs` together. The test is the
   regression proof for the same bug - splitting.md explicitly groups
   "a bug fix and the regression test that proves it".
2. `Cargo.toml` alone. The serde version bump is independently
   revertable and shares no intent with the partial-read fix. Reverting
   the dep should not also revert the bug fix, and vice versa.
