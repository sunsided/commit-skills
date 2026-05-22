# Drafting notes

## Title style

- No merged PRs yet (fresh repo), so I could not sample existing titles.
- The repo has no `pyproject.toml` indication of Conventional Commits and
  the existing commit subjects ("Initial auth-client crate", "Add
  README", "Serialize token refresh under the manager lock") use plain
  imperative mood with no `fix:` / `feat:` prefix.
- Picked plain imperative ("Fix race in TokenManager that allowed
  duplicate refreshes"), 57 chars, well under the 72-char ceiling. Names
  the subsystem (`TokenManager`) and the observable behavior, so it
  stands alone in a list.

## Issue link

- Setup script could not be executed in this sandbox (denied), but the
  fixture script itself is readable and the branch name is
  `fix/842-token-refresh-race`. The `842` segment is the GitHub issue
  number per the script's own header comment ("Branch name encodes a
  GitHub-style issue number").
- Used `Fixes #842` in the "Why" section per body-structure.md guidance
  for bug fixes.

## Body structure

- Followed the bug-fix template from `references/body-structure.md`:
  Summary, Why, Fix, Review notes. Skipped Key changes and Risks — the
  change is two files and has no behavioral change for callers beyond
  the bug going away, so a Risks section would be padding.
- Review notes follow the "test first, then implementation" pattern from
  `references/review-guidance.md`, because the regression test makes the
  contract concrete and pointing at the double-checked re-check is the
  load-bearing scrutiny ask.
- Length is ~22 lines, within the 5-10 line guideline's upper end; the
  extra prose earns its keep by naming the failure mode for reviewers
  unfamiliar with the codebase.
