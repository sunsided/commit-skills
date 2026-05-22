# Notes on PR drafting

## Title style

The repo's existing commit messages on `main` ("Initial auth-client
crate", "Add README") and on the branch ("Serialize token refresh under
the manager lock", "Add regression test for concurrent token refresh")
are plain imperative — no Conventional Commits prefix (no `fix:`,
`feat:`, etc.). I matched that style: "Fix race condition in
TokenManager refresh" — imperative verb first, no prefix, 43 chars (well
under the 70-char guideline).

I considered "Serialize token refresh under the manager lock" (reusing
the first commit's subject) but the PR contains two commits and the
user-facing framing is the bug being fixed, not the implementation
detail. A title that names the *bug* reads better in a PR list.

## Issue link

The branch name `fix/842-token-refresh-race` encodes a GitHub-style
issue number (`842`). I surfaced it as `Closes #842` in the body so
merging the PR auto-closes the tracking issue. No issue link in the
commit messages themselves.

## Body structure

Three sections:

1. **Summary** — explains the *bug* (two threads both passing the
   expiry check), then the *fix* (double-checked locking with a fast
   path). Emphasizes the fast path because keeping the hot path
   lock-free matters for a token cache.
2. **Changes** — file-by-file bullet list so a reviewer knows where to
   look. Two files, two bullets.
3. **Test plan** — checklist matching the PR template hint in my
   instructions. The "fails on main, passes on branch" item is the key
   regression-test guarantee.

I did not run `gh` per the constraints, and I drafted from the fixture
script (which is fully deterministic) since `bash` was denied for the
setup invocation.
