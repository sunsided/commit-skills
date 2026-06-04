refactor: consolidate per-method retry loops into a single with_retry helper

## Description

Every outbound HTTP method on `Client` (`get_user`, `get_order`, `get_invoice`) carried its own copy of the same retry loop: three attempts with exponential backoff, retrying on `requests.exceptions.RequestException` and re-raising on the final attempt. This PR extracts that policy into a single `with_retry` helper in a new `src/retry.py` and rewrites the three methods to call it. The retry behavior is unchanged; the policy now lives in one place instead of three.

## Type of change

- [ ] Bug fix
- [ ] New feature
- [x] Refactor (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Testing

No behavior change, so no new tests were added. Equivalence is verifiable by inspection: `with_retry` uses the same attempt count (`MAX_ATTEMPTS = 3`), the same base backoff (`BASE_BACKOFF = 0.5`), the same `0.5 * (2 ** attempt)` schedule, the same caught exception type, and the same re-raise on the last attempt that each inline loop previously used.

## Reviewer notes

Start in `src/retry.py` and confirm the helper reproduces the old loop exactly: attempt count, backoff schedule, the exception caught, and the re-raise on the final attempt. Then read `src/client.py` to confirm each of the three methods now delegates to `with_retry` and nothing else about the request changed (note the now-unused `import time` is correctly dropped). The single thing to scrutinize is that the request call is passed as a thunk (`lambda: ...`) so it is re-invoked on each attempt rather than evaluated once up front.

## Checklist

- [ ] Tests updated or added where appropriate
- [ ] Documentation updated where appropriate
- [x] CHANGELOG.md updated
