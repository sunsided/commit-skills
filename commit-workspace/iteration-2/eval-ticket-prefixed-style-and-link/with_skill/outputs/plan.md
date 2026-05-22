# Commit plan

Working tree contains two independent changes; split into two commits.

## Commit 1

**Subject:** MED-842: Fix truncated reads in read_chunk

**Files:**
- src/reader.rs
- tests/reader.rs

**Body:**
```
Why:
- read_chunk was returning truncated output when the underlying read
  returned a slice shorter than the requested size, so callers saw
  partial data on the first short read instead of the full buffer.

Before:
- The reader stopped accumulating at the first short slice and
  returned whatever had been copied so far.
- No regression test covered the multi-chunk path; the bug could
  reappear silently.

After:
- read_chunk loops until the entire input buffer is consumed,
  appending up to 1024 bytes per iteration, and returns a Vec sized
  to the full input length.
- tests/reader.rs adds reads_entire_buffer_across_chunk_boundaries,
  which feeds a 4096-byte input and asserts the output is the full
  4096 bytes, locking in the fix.

Refs: MED-842
```

## Commit 2

**Subject:** Bump serde to 1.0.197

**Files:**
- Cargo.toml

**Body:**
_(none — trivial dependency bump, no behavior change)_
