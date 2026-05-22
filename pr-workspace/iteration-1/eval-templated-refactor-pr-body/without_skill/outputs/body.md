## Description

Every outbound HTTP call in `Client` had its own copy of the same 3-attempt exponential-backoff retry loop. This PR collapses the three duplicated blocks (`get_user`, `get_order`, `get_invoice`) into a single `with_retry` helper so the retry policy lives in one place. Behavior is unchanged: same max attempts (3), same base backoff (0.5s), same exception scope (`requests.exceptions.RequestException`).

## Type of change

- [ ] Bug fix
- [ ] New feature
- [x] Refactor (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Testing

- Existing test suite (`tests/test_client.py`) still passes.
- No behavior change, so no new tests were added. The retry parameters (`MAX_ATTEMPTS=3`, `BASE_BACKOFF=0.5`) were chosen to match the previous inline values exactly; verified by diffing the old and new sleep/raise paths.
- Manual repro: not applicable — no user-visible surface changes.

## Reviewer notes

- Start in `src/retry.py` — the new helper is small (one function, `with_retry`) and captures the policy that used to be inlined.
- Then look at `src/client.py` to confirm the three call sites were migrated to `with_retry(lambda: ...)` and that no method kept a stray inline loop.
- Worth double-checking: the `raise RuntimeError("unreachable")` tail in `with_retry` — it exists only to satisfy the type checker since the `for` loop always either returns or re-raises on the last attempt.
- The lambda wrappers preserve lazy evaluation so the request is re-issued on each attempt (not just retried against a cached call).

## Checklist

- [ ] Tests updated or added where appropriate <!-- N/A: pure refactor, existing tests cover the call sites -->
- [ ] Documentation updated where appropriate <!-- N/A: no public API change -->
- [ ] CHANGELOG.md updated <!-- N/A in this PR: a draft entry exists locally under "Unreleased (added in this branch)" but is intentionally not committed yet -->
