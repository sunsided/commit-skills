## Commit 1
**Subject:** Add user lookup endpoint
**Files:** src/users.js, tests/users.test.js, src/index.js
**Body:**
Before:
- The HTTP server only routed `GET /health`; any other path returned 404.
- There was no user store or per-user lookup path.

After:
- New `src/users.js` exposes `handleGetUser`, backed by an in-memory `Map`.
  Returns the JSON-encoded user on hit and 404 on miss. A `_seed` helper is
  exported for tests to populate the store.
- `src/index.js` matches `GET /users/:id` via a regex on `req.url` and
  dispatches to `handleGetUser` before falling through to the existing 404.
- `tests/users.test.js` covers both the hit (returns the seeded user as
  JSON) and miss (404) paths.

Why:
- First endpoint beyond `/health`; gives the service something to actually
  serve and establishes the pattern for future resource routes.

Findings:
- The route is parsed inline with a regex rather than introducing a router
  dependency, matching the existing minimal `http.createServer` style.
- The user store is an in-memory `Map`, which is fine for the example but
  means state is lost on restart and not shared across processes.

## Commit 2
**Subject:** Bump CI Node version to 20
**Files:** .github/workflows/ci.yml
**Body:**
Node 18 reached end-of-life; move CI onto the current active LTS so we are
not testing against an unsupported runtime.

## Commit 3
**Subject:** Fix typo in README development heading
**Files:** README.md
**Body:**
