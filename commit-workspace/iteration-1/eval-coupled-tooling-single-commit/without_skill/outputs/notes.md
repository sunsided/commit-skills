# Grouping notes

## Decision: 1 commit

The three changed paths form one atomic feature:

- `benches/bench_parse.py` is the new artifact.
- `Taskfile.dist.yaml` adds a `bench` task whose sole purpose is to
  run that script with the correct `PYTHONPATH`.
- `README.md` adds a `## Benchmarks` section whose only content is
  "run `task bench`" plus a pointer to the new script.

Each piece references the others. Splitting would either:
- introduce a Taskfile target pointing at a non-existent script, or
- introduce a README section telling users to run a non-existent task.

Conventional Commits allows (and the surrounding history uses) a single
`feat:` commit for a self-contained capability. Scope `bench` keeps the
subject narrow and matches the directory name.

## Ambiguities

- Could not run `git status` / `git diff` (bash git was blocked); relied
  on the task description plus `.git/logs/HEAD` (last commit was
  "feat: add token formatter") and file contents to infer the diff.
- Assumed `Taskfile.dist.yaml` and `README.md` pre-existed and were
  modified rather than newly created; their content (only a bench task,
  only a benchmarks section beyond the basic usage) is consistent with
  either, but the wording of the task ("a Taskfile.dist.yaml target",
  "a README section") implies additions to existing files.
- No version bump in `pyproject.toml` was assumed to be part of this
  change.
