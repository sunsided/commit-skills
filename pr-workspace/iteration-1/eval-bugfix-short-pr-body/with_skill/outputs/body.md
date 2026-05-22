## Summary

`TokenManager.get()` could call the upstream token fetcher multiple times
for a single expiry event when several threads raced through the cache
check together.

## Why

The existing `self._lock` was constructed but never acquired, so the
expiry check and the refresh were not serialized. Under concurrent load,
N threads that all saw an expired token would each invoke `_fetcher()`,
hammering the upstream auth endpoint and occasionally clobbering the
cached token with a stale value when responses returned out of order.
Fixes #842.

## Fix

Reworked `get()` into a double-checked pattern: a lock-free fast path
returns the cached token when it is present and unexpired, and a slow
path takes `self._lock` and re-checks the expiry before calling
`_fetcher()`. Only the first thread through the slow path performs the
refresh; the rest see the freshly populated cache and return it.

## Review notes

Read the regression test in `tests/test_token.py` first — it launches
eight threads against an empty cache and asserts the fetcher ran exactly
once, which makes the contract obvious. Then look at the slow path in
`src/token.py` and confirm the re-check inside the lock matches the
fast-path condition; a mismatch there is how this class of bug usually
comes back. The existing single-threaded happy-path test still covers
the unchanged cache-hit behavior.
