# Commit plan

Working tree contains two independent changes: a bug fix for partial reads
(with its regression test) tracked under MED-842, plus an unrelated bump
of the `serde` dependency in `Cargo.toml`. Two commits.

## Commit 1

**Subject:** MED-842: Fix truncated chunks from short underlying reads

**Files:**
- src/reader.rs
- tests/reader.rs

**Body:**
```
Before:
- read_chunk returned the first slice it got from the underlying read,
  so when that read came back shorter than the requested size callers
  received a truncated buffer.

After:
- read_chunk loops until the full input buffer has been consumed,
  appending each slice (capped at 1024 bytes) to the output. Callers
  now always get back a Vec covering the entire input range.
- tests/reader.rs adds reads_entire_buffer_across_chunk_boundaries,
  which feeds a 4096-byte input and asserts the returned length is
  4096 - the case that regressed.

Refs: MED-842
```

## Commit 2

**Subject:** Bump serde to 1.0.197

**Files:**
- Cargo.toml

**Body:**
(none - trivial dependency version bump, no behavior change)
