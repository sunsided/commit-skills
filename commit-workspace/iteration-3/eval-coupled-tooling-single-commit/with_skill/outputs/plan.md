## Commit 1

**Subject:** perf: add parse throughput benchmark

**Files:**
- benches/bench_parse.py
- Taskfile.dist.yaml
- README.md

**Body:**
Why:
- Establish a repeatable parse throughput measurement so future changes
  to `nibble.parse` can be compared against a known baseline rather than
  judged by eye.

Before:
- No benchmark suite existed; performance of `parse` was unverified.
- No task runner entry point, so contributors had no documented way to
  measure parser throughput.
- README only described library usage.

After:
- `benches/bench_parse.py` runs 5000 iterations of `parse` over a ~45 KB
  string and prints ops/sec via `time.perf_counter`.
- `Taskfile.dist.yaml` exposes a `bench` target that sets
  `PYTHONPATH=src` and runs the benchmark, so `task bench` works from a
  clean checkout.
- README gains a Benchmarks section pointing at `task bench` and the
  benchmark file.

Findings:
- The benchmark imports `nibble` directly, so `PYTHONPATH=src` is
  required; this is baked into the Taskfile target rather than left to
  the caller.
- No external benchmarking dependency was added; `time.perf_counter`
  keeps the suite dependency-free.
