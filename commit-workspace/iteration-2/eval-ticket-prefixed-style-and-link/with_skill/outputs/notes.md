# Notes

## Style detected
Ticket-prefixed plain imperative: `MED-<num>: <Capitalized verb phrase>`.
Evidence from history (`.git/logs/HEAD`):
- `MED-100: Initial calendar crate`
- `MED-204: Add total_pages helper`
- `MED-204: Cover total_pages with a test`
No Conventional Commits prefix, no scope, no trailing period. Ticket
sits in the subject (not as a `Refs:` footer), so the subject must
carry it. Because the subject already names the ticket, a duplicate
`Refs:` footer is arguably redundant — but the rich-body template's
`Refs:` line is harmless and useful for grep/tooling, so I kept it on
the non-trivial commit.

## Ticket-link reasoning
- Branch is `bugfix/MED-842-partial-read` → MED-842 owns the bug-fix
  commit (matches `[A-Z]+-\d+` heuristic from issue-links.md).
- The serde bump is unrelated to MED-842 and no other ticket is hinted
  at in the branch, diff, or recent commits. Per issue-links.md,
  don't fabricate one; leave the bump's subject ticketless. The repo's
  prior history only shows ticketed subjects, but a dep bump is a
  legitimate exception — alternatively the user may want it filed
  under a chore ticket; flag at confirmation time.

## Grouping decisions
- src/reader.rs (fix) + tests/reader.rs (regression test) → one commit:
  per splitting.md "a bug fix and the regression test that proves it"
  share intent and must land together or the test would be dead code
  in an intermediate commit.
- Cargo.toml serde 1.0.197 bump → separate commit: independently
  revertable, no causal link to the reader fix, task description
  explicitly flags it as unrelated. Trivial body (minimal template).
- Order: fix first (carries the ticket and the behavior change), dep
  bump second (incidental).
