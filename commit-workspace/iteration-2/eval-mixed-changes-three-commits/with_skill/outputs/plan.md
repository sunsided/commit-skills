# Commit plan

Three commits. The user endpoint + its test + the dispatch wiring in
`src/index.js` belong together (one revert reason). The CI bump and the
README typo are independent drive-bys; each gets its own commit. Order
follows "feature first, tooling/docs last" so each commit passes tests
in isolation.

## Commit 1

**Subject:** Add GET /users/:id endpoint

**Files:**
- src/users.js
- src/index.js
- tests/users.test.js

**Body:**
```
Why:
- The service only exposed /health; clients need to look up a user
  record by id.

Before:
- The HTTP dispatcher in src/index.js only routed /health; any other
  path returned 404.
- No users module existed.

After:
- src/users.js holds an in-memory user store with handleGetUser, which
  returns the user as JSON or 404 when missing. A `_seed` helper is
  exported for tests to populate the store.
- src/index.js matches `/users/:id` with a small regex and dispatches
  to handleGetUser, falling through to 404 for anything else.
- tests/users.test.js covers the hit path (seeded user is returned as
  JSON) and the miss path (404 when the id is unknown).

Findings:
- The store is intentionally in-memory; persistence is out of scope for
  this change.
```

## Commit 2

**Subject:** Bump CI Node version to 20

**Files:**
- .github/workflows/ci.yml

**Body:**
```
Node 18 reaches end-of-life soon; move the CI matrix to Node 20 so we
keep running on a supported LTS. No application code depends on a
Node-18-specific API, so this is a CI-only change.
```

## Commit 3

**Subject:** Fix typo in README

**Files:**
- README.md

**Body:** *(omitted — trivial doc fix)*
