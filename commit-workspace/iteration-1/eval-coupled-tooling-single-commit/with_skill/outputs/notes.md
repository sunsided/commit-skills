# Notes

## Style detected
Conventional Commits, no scope. History (4 commits):
- `chore: initial commit`
- `feat: add token normalizer`
- `fix: drop empty tokens from parse output`
- `feat: add token formatter`
No CONTRIBUTING.md or commitlint config; observed history is consistent
enough to pick CC unambiguously. Chose `feat:` over `chore:`/`test:`
because the dominant additive pattern in history uses `feat:` and the
benchmark adds a new (dev-facing) capability rather than a chore tweak.

## Grouping reasoning
Textbook coupled change per references/splitting.md "Working tree
contains a refactor and its enabling tooling": benchmark script,
Taskfile target running it, and README documenting it were added in
one session and only exist because of each other.
- Reverting any one in isolation would leave a dangling reference
  (Taskfile points at the script; README points at both).
- "One reason to revert" test: the single reason is "add a parse
  benchmark"; splitting would create broken intermediates (a Taskfile
  target whose script does not exist; a README pointing at nothing).
=> One commit.

## Issue links
None. Branch is `main`; no ticket pattern in history; no TODO/FIXME
markers in the diff. No footer.

## Ambiguities
- Type choice `feat:` vs `chore:`/`test:` is judgement; history is too
  small to be definitive. Worth a one-line check with the user if they
  prefer `chore:` for dev tooling.
- Could not run `git -C <path> status/diff` from this sandbox; verified
  working-tree contents and history via direct filesystem reads of the
  worktree and `.git/logs/HEAD`. Assumed the three files named in the
  task brief are the only working-tree changes.
