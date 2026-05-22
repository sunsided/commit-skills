# Notes

## Style detected
Plain imperative. All four existing subjects ("Add version test", "Bump
version to 0.1.1", "Add version helper", "Initial commit") are capitalized
verbs with no type/scope prefix. No CONTRIBUTING, .gitmessage, or
commitlint config in the repo. Followed plain imperative; did not impose
Conventional Commits.

## Grouping
Three commits, one per intent (matches the "feature + tooling + drive-by"
scenario in references/splitting.md):

1. `src/users.js` + `tests/users.test.js` + `src/index.js` — the new
   endpoint, its route wiring, and its test. The index.js hunk only exists
   because users.js exists; the test exists because the handler exists.
   One reason to revert.
2. `.github/workflows/ci.yml` — Node 18 -> 20 bump. Independently
   revertable; would have happened regardless of the users endpoint.
3. `README.md` — "Devolopment" -> "Development" typo. Drive-by; unrelated
   to either of the above.

## Issue links
Branch is `main`, no `[A-Z]+-\d+` or `#\d+` token. No TODO/FIXME refs in
the diff. No prior commits on a feature branch to inherit from. No ticket
context from the user. Skipped issue links; per references/issue-links.md
fabricating a placeholder is worse than omitting.

## Body verbosity
- Commit 1: rich body — behavior change, reviewer would want the routing
  detail and the in-memory-store caveat.
- Commit 2: one-sentence lean body — the "why" (Node 18 EOL) is not
  visible in the diff.
- Commit 3: minimal, subject only — pure typo fix, fits the trivial
  template.

## Ambiguity
None significant. The only judgment call was whether the README typo
warranted a body; per the minimal template, typo fixes do not.
