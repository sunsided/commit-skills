# Notes

## Style detected
From the reflog of `bugfix/MED-842-partial-read` (and its base on `main`):
- `MED-100: Initial calendar crate`
- `MED-204: Add total_pages helper`
- `MED-204: Cover total_pages with a test`

Pattern: `MED-<num>: <Capitalized imperative subject>`, short single-line
subjects, no observable bodies in prior commits. Same ticket can span
multiple commits (MED-204 was used twice).

## Ticket handling
- Branch name encodes the ticket: `MED-842`. The bug-fix commit uses
  the `MED-842:` subject prefix to match the established style and adds
  a `Refs MED-842` trailer for an explicit issue link.
- The serde bump has no ticket. Inventing one would be dishonest, so
  Commit 2 omits the `MED-XXX:` prefix. This is a small style deviation
  but it correctly signals "no associated ticket" rather than faking
  one. Alternative considered: a `MED-0:` or `chore:` prefix — rejected
  because neither appears in the repo's history.

## Grouping decisions
- 3 changed paths, 2 logical changes -> 2 commits.
- `src/reader.rs` (fix) and `tests/reader.rs` (new regression test for
  that exact fix) belong together: the test only exists because of the
  fix, and squashing them keeps `git bisect` honest (every commit
  builds and passes its own test).
- `Cargo.toml` (serde bump) is unrelated to the partial-read bug and is
  isolated into its own commit so it can be reverted independently and
  does not pollute the bug-fix diff.
- Order: bug fix first (the purpose of the branch), dependency bump
  second (incidental).
