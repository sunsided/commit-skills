## Description

Replaces three copies of the same retry loop in `Client` with a single
`with_retry` helper. Every outbound HTTP call now goes through one
attempt/backoff policy instead of three near-identical inlined ones.
No behavior change: the new helper preserves the existing 3-attempt
limit, 0.5s base backoff with exponential growth, and `RequestException`
catch.

## Type of change

- [ ] Bug fix
- [ ] New feature
- [x] Refactor (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Testing

The existing `tests/test_client.py` still passes. No new tests were
added — the refactor is a structural extraction with byte-for-byte
equivalent retry semantics, and the existing suite does not cover
retry behavior on either side of the change.

## Reviewer notes

Start in `src/retry.py` — the `with_retry` helper is the only new
logic in the PR, and it should read as a literal lift of the loop
that previously lived in `Client`. Then look at `src/client.py` to
confirm the three call sites now delegate to it and that nothing
else moved. The thing to scrutinize is the `if attempt == MAX_ATTEMPTS - 1: raise`
branch in `retry.py` — the original code raised on the third attempt
specifically; make sure the indexing is equivalent (it is: `range(3)`
yields `0, 1, 2` and the original compared `attempt == 2`).

## Checklist

- [ ] Tests updated or added where appropriate
- [ ] Documentation updated where appropriate
- [ ] CHANGELOG.md updated
