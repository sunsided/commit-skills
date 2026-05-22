# Commit plan

## Commit 1

**Subject:** feat: add parse throughput benchmark

**Files:**
- benches/bench_parse.py
- Taskfile.dist.yaml
- README.md

**Body:**
Adds a small benchmark that measures `parse()` throughput over a
repeated sample input (5000 iterations of a 1000x-repeated pangram) and
prints ops/sec.

The Taskfile gains a `bench` target so the benchmark can be run with
`task bench` without remembering the `PYTHONPATH=src` invocation, and
the README gets a Benchmarks section pointing at both the task and the
script.

Why:
- Gives us a repeatable number to track as the parser changes; future
  fixes/refactors can be checked against it instead of guessing.

The Taskfile target and README section only exist because of the
benchmark script, so they ship together: reverting one without the
others would leave a dangling reference.
