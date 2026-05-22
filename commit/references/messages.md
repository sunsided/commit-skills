# Writing commit messages

A commit message is the only context a reviewer (or future-you, six months later) has when they're reading `git log` and trying to remember why something changed. The subject states the intent; the body answers the questions the diff alone leaves open.

## Subject line

- One line, ≤72 chars hard, aim for ≤50.
- Imperative mood: "Add token refresh", not "Added" or "Adds".
- No trailing period.
- Capitalize the first word of the verb (after any `type(scope):` prefix, the first word is lowercase in Conventional Commits).
- Style: match what `references/styles.md` told you to use.

Good subjects answer "what would this commit do if applied":

- `Add session booking endpoint`
- `feat(parser): support nested code blocks`
- `Fix off-by-one in pagination cursor`
- `Refactor token refresh into a single helper`

Bad subjects:

- `Update files` — what files? what change?
- `Fix bug` — which bug?
- `WIP` — don't commit work in progress.
- `Address review feedback` — what did you change?

## Body

Body is optional for trivial commits (typo fix, lockfile bump). Otherwise, the body should answer: *what changed, why, and anything a reviewer would otherwise have to dig out of the diff.*

Separate subject and body with a blank line. Wrap body lines at 72 chars.

**The body must not repeat the subject line.** Git already shows the subject above the body when rendering a commit (`git show`, `git log`, the GitHub UI). Echoing the subject as the body's first line is redundant noise and pushes the actual content down. The body starts with the first section (Why, or whatever the lean template's opening sentence is)—not with the subject restated.

### Template: rich (use for non-trivial behavior changes)

Lead with **Why** — that is the "what changed" at the level a reviewer cares about. The Before/After section then describes the mechanics. Findings capture incidental observations. Putting Why last buries the lede; reviewers reading `git log -p` should see the motivation before they wade into the diff.

```
<subject>

Why:
- <the motivation; what problem this solves, what it enables>

Before:
- <how the code/system behaved or was structured>
- <one bullet per relevant aspect>

After:
- <how it behaves or is structured now>
- <one bullet per change>

Findings:
- <anything surprising discovered while making the change>
- <constraints you bumped into, versions chosen and why>

Refs: <ticket if any>
```

The `Findings:` section is genuinely useful—it captures the things you'd otherwise lose. Versions chosen and why, edge cases noticed in passing, the count of call sites updated, etc.

Worked example (a real one; verbose end of the spectrum, but illustrative):

```
Replace assert! macros with assert2's check! macro

Why:
- check! continues executing after a failure, surfacing all broken
  assertions in a single test run rather than stopping at the first one
- Descriptive messages make failures self-explanatory without having
  to trace back to the source line

Before:
- All unit and integration tests used assert!, assert_eq! macros
- assert_eq! comparisons had no descriptive failure messages
- assert! boolean checks were similarly message-free

After:
- assert2 added to [dev-dependencies] in Cargo.toml
- All assert! / assert_eq! calls replaced with check! across five files:
  src/parser/heading.rs, src/parser/lines.rs, src/parser/document.rs,
  src/writer/session.rs, tests/integration_tests.rs
- Every check! call includes a human-readable message describing the
  invariant

Findings:
- assert2 0.3.x is the version compatible with the current Rust edition
  (2024)
- No assert_ne! or assert_matches! usages existed; only assert! and
  assert_eq!
- All 47 tests (38 unit + 9 integration) pass after the migration
```

### Template: lean (use for medium changes)

```
<subject>

<one or two sentences on what changed and why, in prose>

<optional: one sentence on a finding worth noting>

Refs: <ticket if any>
```

Example:

```
Move retry logic into RetryingClient wrapper

The HTTP client had ad-hoc retry blocks scattered across three call
sites. RetryingClient centralizes the policy (exponential backoff,
max 3 attempts, retry only on 5xx and network errors) so future
endpoints inherit it for free.

Existing callers keep their behavior—the only change for them is
that 502s are now retried, which matches what we already document.

Refs: MED-512
```

### Template: minimal (use for trivial commits)

Just the subject. Acceptable for:

- Typo fixes in comments / docs.
- Lockfile / dependency version bumps with no behavior change.
- Pure formatting (`cargo fmt`, `prettier --write`).
- Renames where the new name is self-explanatory.

```
Fix typo in CONTRIBUTING.md
```

```
Bump axios from 1.7.0 to 1.7.2
```

## Calibrating verbosity

A useful test: imagine a reviewer reading the diff cold. If everything they'd want to know is visible in the diff (renamed variable, deleted dead code), keep the body short or skip it. If the diff would leave them wondering "but *why*?" or "what changed about the behavior?", write the body.

The rich template above is on the verbose end. Don't pad just to fill it out. If "Findings:" would be empty, drop the section. If "Before/After" would be one bullet each, write a single prose sentence instead.

## What never goes in a commit message

- Tooling attribution: no "written with Claude", no "verified by running cargo test", no `Generated-by:` trailers, no `🤖` emojis—unless the user has explicitly asked for them.
- Apologies or hedges: no "sorry for the mess", no "should be fine but please check".
- Future plans: no "will refactor this later"—that's a TODO in the code or an issue, not a commit message.
- Conversational asides: no "as we discussed in standup", no "@alice asked for this".

The message is durable documentation; treat it that way.
