## Summary

Two threads calling `TokenManager.get()` near the cache expiry could both
pass the `time.time() >= self._expires_at` check and then both invoke
`self._fetcher()`, producing duplicate refresh requests against the
upstream auth service.

This PR serializes the refresh path with the existing `self._lock` using
a double-checked locking pattern:

- **Fast path:** if the cached token is still valid, return it without
  taking the lock (no regression on the hot path).
- **Slow path:** acquire `self._lock`, re-check the expiry and token
  presence, and only call `self._fetcher()` if the token is still stale.
  Concurrent callers that lost the race observe the freshly refreshed
  token instead of re-fetching.

Closes #842.

## Changes

- `src/token.py` — rewrite `TokenManager.get()` with fast-path cache
  hit + double-checked locking around the fetcher call.
- `tests/test_token.py` — add `test_concurrent_refresh_calls_fetcher_once`,
  a regression test that spawns 8 threads against a fresh `TokenManager`
  and asserts the fetcher is called exactly once.

## Test plan

- [x] Existing `test_returns_token_until_expiry` still passes.
- [x] New `test_concurrent_refresh_calls_fetcher_once` fails on `main`
  and passes on this branch.
- [ ] Run the full test suite in CI.
