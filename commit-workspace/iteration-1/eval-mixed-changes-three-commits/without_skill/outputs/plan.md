## Commit 1
**Subject:** Add GET /users/:id endpoint
**Files:** src/users.js, src/index.js, tests/users.test.js
**Body:**
Introduce a users module with an in-memory store and a handler that
returns the user as JSON or 404 when missing. Wire the handler into
the HTTP server in src/index.js so requests matching /users/:id are
routed to it, and add unit tests covering the found and missing
cases.

## Commit 2
**Subject:** Bump CI Node version to 20
**Files:** .github/workflows/ci.yml
**Body:**
Update the setup-node step in the ci workflow to use Node 20 so the
test job runs on a currently supported LTS release.

## Commit 3
**Subject:** Fix typo in README
**Files:** README.md
**Body:**
Correct a typo in the README. Documentation only; no behaviour
change.
