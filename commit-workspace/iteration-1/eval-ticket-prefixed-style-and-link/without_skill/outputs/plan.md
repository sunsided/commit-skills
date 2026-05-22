# Commit Plan

Branch: `bugfix/MED-842-partial-read`

Two logical changes are present in the working tree:
1. A bug fix in `src/reader.rs` with a regression test in `tests/reader.rs` (the reason this branch exists, ticket MED-842).
2. An unrelated `serde` dependency bump in `Cargo.toml`.

These are split into two commits so the bug fix is reviewable and revertable on its own, and the dependency change is not hidden inside an unrelated bug fix.

## Commit 1

**Subject:** MED-842: Read full buffer across chunk boundaries

**Files:**
- `src/reader.rs`
- `tests/reader.rs`

**Body:**
`read_chunk` previously returned truncated output when the underlying
read produced less than the requested size on the first slice, because
the loop bailed out after the first short read instead of continuing
until the buffer was exhausted.

Accumulate the entire input by advancing the cursor in fixed 1024-byte
steps (clamped to the remaining length) and copying each slice into the
output, so callers always receive every byte they passed in.

Add a regression test that feeds a 4096-byte buffer and asserts the
returned `Vec` has the full length, so this partial-read regression
cannot return silently.

Refs MED-842

## Commit 2

**Subject:** Bump serde to 1.0.197

**Files:**
- `Cargo.toml`

**Body:**
Routine dependency refresh, unrelated to the MED-842 fix. Kept in its
own commit so the bug fix on this branch stays a single, isolated
change that is easy to review and revert.
