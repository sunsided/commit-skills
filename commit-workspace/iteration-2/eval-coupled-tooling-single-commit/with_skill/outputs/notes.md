# Notes

## Style detected

Conventional Commits, no scope. Reflog shows:
- `chore: initial commit`
- `feat: add token normalizer`
- `fix: drop empty tokens from parse output`
- `feat: add token formatter`

All four use lowercase `type: subject` with no scope and no body. No
CONTRIBUTING / .gitmessage / commitlint config present, so observed
history is the source of truth. Used `bench:` as the type because the
change is purely a benchmark + its tooling; `chore:` would understate
it and `feat:` would overstate it (no library code changes). `bench`
is a recognized Conventional Commits extension; if the reviewer
prefers strict core types this could swap to `chore:` or `test:`
without changing the grouping.

## Grouping reasoning

One commit. This is the textbook coupled-tooling case from
`references/splitting.md`: a benchmark, the task-runner target that
runs it, and the README section documenting how. The Taskfile target
and README paragraph have no reason to exist without the benchmark
file. Reverting any one of the three alone would leave the repo in a
worse state than reverting all three (orphaned target pointing at a
missing script, or docs pointing at a missing task).

## Ambiguities

- No branch name was readable (git commands against the scratch path
  were blocked by sandbox permissions), so no issue-link footer is
  proposed. The reflog showed no `Refs:` trailers either, so leaving
  the footer out matches house style.
- Could not run `git status` / `git diff` directly; inferred the
  working-tree contents from the on-disk files plus the task prompt
  ("new benchmark, Taskfile target, README section"). If the working
  tree actually contains additional unrelated changes, the plan would
  need a second commit for those.
