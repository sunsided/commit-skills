# Splitting changes into logical commits

The hard part of commit hygiene is deciding where commit boundaries fall. Two heuristics combined work well: **one commit, one reason to revert** and **group by intent, not by directory.**

## The core question

For each pair of changed files (or hunks within a file), ask:

> If I had to revert one of these tomorrow, would I want to revert both, or just one?

If both: same commit. If just one: separate commits.

A related question, equally useful:

> If a reviewer asked "why did you change X?", would my answer also explain why I changed Y?

If yes: same commit. If no: separate commits.

## What "intent" means in practice

Intent is the user's reason for making the change, not the file's location on disk. Two changes share intent when one *exists because of* the other.

**Same intent — keep together:**

- A new function in `src/foo.rs` and the tests for it in `tests/foo_test.rs`.
- An API signature change in `src/api.rs` and every call site that had to adapt.
- A new benchmark in `benches/parser.rs` and the `Taskfile.dist.yaml` target that runs it. The Taskfile change only exists because the benchmark exists.
- A new CLI flag and the README section documenting it.
- A bug fix and the regression test that proves it.

**Different intent — split:**

- A new API endpoint and a CI workflow change that updates the Node version. The CI change would have happened anyway.
- A refactor of module A and a typo fix in module B's comments. Caught while you were in there, but unrelated.
- A new feature and an unrelated `package.json` lockfile cleanup.
- Adding a `Taskfile.dist.yaml` for the project at large, *while* working on an API change. The Taskfile is its own commit; it'll outlive this feature.

## Mixed scenarios you'll actually see

### Working tree contains feature + tooling + drive-by fix

Typical state: `git status` shows changes to `src/`, `tests/`, `.github/workflows/ci.yml`, and a fixed typo in `README.md`.

Group: (1) src+tests (feature), (2) ci.yml (independent), (3) README typo (independent). Three commits.

### Working tree contains refactor *and* its enabling tooling

Typical state: a new benchmark suite, a Taskfile target to run benchmarks, a README section explaining how. All added in one session, all coupled.

Group: one commit. The Taskfile target and README only exist because of the benchmark suite.

### Working tree contains a feature with a small unrelated bug fix

Typical state: a new feature in `src/auth.rs`, plus a fix to an unrelated off-by-one in `src/calendar.rs`.

Group: two commits. The bug fix is independently revertable and independently useful.

### Working tree contains a partial refactor that broke a test

Typical state: a refactor in progress; one test is now failing because it depended on the old API.

Do not commit the failing state. Either finish the refactor (and update the test in the same commit), or stash the half-done refactor. A commit that doesn't pass tests is worse than a fat commit.

## Order matters

Commits should be ordered so each one passes tests in isolation. The usual ordering:

1. Pure refactors / internal renames first (no behavior change).
2. New abstractions / helpers next.
3. New behavior using those helpers.
4. Documentation and tooling updates last.

If that's not feasible, at minimum: do not split a coupled pair so that the first commit breaks the build.

## Granularity edge cases

**Hunk-level splitting (`git add -p`).** Rarely worth it. The cost is high (manual selection, risk of broken intermediates) and the value is usually small. Only do it when a single file genuinely contains two independent changes that a reviewer should see as separate.

**Squashing your own scratch commits.** If the user's working tree is the result of many small experimental commits they want to combine: that's a rebase task, not a commit task. Mention it, but don't do it without an explicit ask.

**Generated files.** Lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`) belong with the change that caused them—do not commit them separately. Generated code (proto stubs, OpenAPI clients) likewise.

## When you can't tell

Ask the user. A two-line question—"I see these are both touching the API layer; should they be one commit or two?"—is cheaper than guessing wrong.
