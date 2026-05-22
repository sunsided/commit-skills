## Commit 1

**Subject:** feat(bench): add parse-throughput benchmark with task runner and docs

**Files:**
- `benches/bench_parse.py` (new)
- `Taskfile.dist.yaml` (modified: adds `bench` task)
- `README.md` (modified: adds `## Benchmarks` section)

**Body:**
Introduce a micro-benchmark for `parse()` that measures throughput in
ops/sec over a 1000x repeated sentence across 5000 iterations.

The three pieces are landed together because they are interdependent:
- `benches/bench_parse.py` provides the benchmark script.
- `Taskfile.dist.yaml` exposes it as `task bench`, which is the
  documented entry point (the script needs `PYTHONPATH=src` to import
  the `nibble` module, so it is not meant to be run directly).
- `README.md` documents `task bench` as the way to run it and points
  readers at the script.

Splitting these would leave intermediate commits where the README
or Taskfile reference a file or target that does not yet exist, so
they ship as one atomic change.
