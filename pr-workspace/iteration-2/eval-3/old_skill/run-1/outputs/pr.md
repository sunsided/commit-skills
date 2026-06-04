Title: Consolidate per-method retry loops into a single with_retry helper

Body:

## Description

`Client.get_user`, `get_order`, and `get_invoice` each carried their own
copy of the same retry loop. This extracts that logic into one
`with_retry` helper in `src/retry.py` and has all three methods call it,
so the retry policy lives in exactly one place. Behavior is unchanged:
still three attempts, still exponential backoff (`0.5 * 2 ** attempt`),
still retrying only on `requests.exceptions.RequestException`.

## Type of change

- [ ] Bug fix
- [ ] New feature
- [x] Refactor (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Testing

No behavior change, so no new tests. Verified equivalence by reading the
three original loops against the extracted helper: `MAX_ATTEMPTS = 3` and
`BASE_BACKOFF = 0.5` reproduce the prior `range(3)` and `0.5 * (2 ** attempt)`
backoff, and the same exception type is caught and re-raised on the final
attempt.

## Reviewer notes

Start in `src/retry.py` to confirm the extracted `with_retry` matches the
original loop exactly: the attempt count, the backoff formula, and that the
final attempt re-raises rather than swallowing the error. Then skim
`src/client.py`, where each method collapses to a single
`with_retry(lambda: ...)` call wrapping its original request. The whole
change hinges on that equivalence, so the helper is the one piece worth
reading closely.

## Checklist

- [ ] Tests updated or added where appropriate
- [ ] Documentation updated where appropriate
- [x] CHANGELOG.md updated
