# Notes

## Title style

Plain imperative, no Conventional Commits prefix. Mirrors the repo's
existing commit/PR titles ("Initial commit", "Add placeholder client
test", "Add with_retry helper centralizing retry policy", "Replace
inline retry loops with with_retry") — none use a `feat:` / `refactor:`
prefix, so adding one here would be out of place. 65 chars, under the
72-char ceiling.

## Template handling

Followed the template's exact headings (Description, Type of change,
Testing, Reviewer notes, Checklist) in the order given. Did not add or
rename sections. Removed the `<!-- ... -->` placeholder comments per
`references/pr-templates.md` (most teams expect them removed once the
section is filled).

## Type of change checkbox

Ticked "Refactor (no behavior change)". The two commits extract an
inline loop into a helper with identical attempt count, backoff, and
exception scope.

## Checklist boxes — all left unticked, honestly

- Tests updated/added: not ticked. The only test file is a placeholder
  (`assert True`); no retry-behavior test was added in this branch and
  the existing test wasn't modified.
- Documentation updated: not ticked. No docs changed in the diff.
- CHANGELOG.md updated: not ticked. The two commits on this branch
  touch `src/retry.py` and `src/client.py` only. (The fixture's
  unstaged CHANGELOG edit is not part of the PR diff, so claiming the
  changelog was updated would be dishonest.)

## Nothing skipped / no N/A

Every template heading is filled. Per the skill's pr-templates guidance,
I did not invent a "Risks" or "Why now" section — the template does not
call for them, and motivation fits comfortably inside Description.
