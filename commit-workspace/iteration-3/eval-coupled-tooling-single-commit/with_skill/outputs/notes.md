# Notes

## Style detected
Conventional Commits, no scope. All four existing commits on `main`
follow `<type>: <subject>` (`chore:`, `feat:`, `fix:`, `feat:`). No
CONTRIBUTING.md or commit template; history is the source of truth.

## Type choice
`perf:` over `test:` or `chore:`. The benchmark exists to measure
runtime performance of `parse`, which is the canonical use of `perf:`
per Conventional Commits. `test:` would imply correctness coverage;
`chore:` would understate that this adds a measurable signal about the
library's behavior. styles.md explicitly calls out benchmarks as
`perf:` or `test:`; `perf:` is the better fit here. Did not invent a
`bench:` type — that would break commitlint-style tooling.

## Grouping reasoning
One commit. The three changes are textbook same-intent coupling
straight out of `references/splitting.md`:

- `benches/bench_parse.py` is the new benchmark.
- `Taskfile.dist.yaml` only adds a `bench` target — it exists *because*
  the benchmark exists.
- The README "Benchmarks" section only exists to document the new
  `task bench` entry point.

Reverting any one in isolation would leave the other two referring to
something that no longer makes sense (orphan task target, README
pointing at a missing file, or a benchmark with no runner / docs). One
reason to revert, therefore one commit.

## Issue link
None. Branch is `main`; no ticket pattern in branch name or prior
commits, and user gave no ticket. Per issue-links.md, do not fabricate
a `Refs:` footer.
