# Commit plan

One commit. The benchmark script, the Taskfile target that runs it, and the
README section documenting how to invoke it are a single coupled change: the
Taskfile target and README section only exist because the benchmark exists.
Splitting them would produce intermediate commits that document or invoke a
file that is not yet in the tree.

## Commit 1

**Subject:** `bench: add parse-throughput benchmark with task runner`

**Files:**
- `benches/bench_parse.py`
- `Taskfile.dist.yaml`
- `README.md`

**Body:**

```
bench: add parse-throughput benchmark with task runner

Why:
- We had no way to measure parse() throughput, so regressions in the
  hot path would have gone unnoticed until someone noticed slow real
  workloads. A repeatable local benchmark closes that gap.

Before:
- No benchmark suite; no task runner entry for performance work.
- README documented usage but said nothing about how to measure
  parser performance.

After:
- benches/bench_parse.py times 5000 iterations of parse() over a
  ~45 KB input and prints ops/sec.
- Taskfile.dist.yaml gains a `bench` target that runs the script with
  PYTHONPATH=src so it picks up the local package.
- README has a new "Benchmarks" section pointing at `task bench` and
  the benchmark file.

Findings:
- Taskfile is the right home for this rather than a Makefile because
  the repo has no existing Make targets and pyproject.toml does not
  define a scripts table; a Taskfile.dist.yaml keeps the entry point
  discoverable without forcing a tooling choice on contributors.
- PYTHONPATH=src is needed because the package is laid out as a src/
  tree but pyproject.toml does not yet declare it as a package, so an
  editable install would be heavier than the benchmark warrants.
```
