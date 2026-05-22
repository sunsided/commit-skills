# PR body structure

A complete worked example, plus templates for the three sizes of PR you'll see most often.

## Worked example: feature PR

**Title:** `feat(session): add explicit booking step before message exchange`

**Body:**

```markdown
## Summary

Adds a `POST /sessions/book` endpoint that reserves a therapist slot and
returns a `session_id`. Clients now hold a session before exchanging
messages instead of having a session created implicitly on first send.

## Why

Two clients hitting the same therapist within the same minute could both
get a session created implicitly, then race on writes. The booking step
makes the reservation explicit and serializable. Closes MED-481.

## Key changes

- New `sessions::booking` module with `BookingService` and `SlotLock`.
- `POST /sessions/book` returns `{ session_id, expires_at }`; sessions
  must be confirmed within 5 minutes or the lock releases.
- `POST /messages` now requires a valid `session_id` and rejects
  requests that lack one with 409 instead of creating a session.
- Slot locks live in Redis with a 5-minute TTL; no schema change needed.
- Integration test covering two concurrent booking attempts on the
  same slot.

## Risks

The 409 response on `POST /messages` is a behavior change for any
client that relied on implicit session creation. The mobile app already
sends `session_id`; the web client is being updated in MED-485 and
should land before this PR is enabled in production. Until then, the
endpoint is gated behind the `explicit_booking` feature flag (default
off).

## Review notes

Start in `src/sessions/booking.rs` to see the `SlotLock` shape and the
acquire/release flow—this is the load-bearing piece. Then read the
`POST /sessions/book` handler in `src/api/sessions.rs` to see how the
service is wired in. The integration test in
`tests/booking_race_test.rs` is worth running locally to feel the
race-resolution behavior.

Pay particular attention to the lock-release path on session confirm
failure (`booking.rs:142`)—an early return there would leak locks.
```

## Template: feature PR

```markdown
## Summary

<Two or three sentences. What the PR does, in language a reader unfamiliar
with the change can follow. Lead with the user-visible or system-level
outcome, not the implementation.>

## Why

<One or two sentences on the motivation. The user-reported issue,
compliance ask, perf regression, etc. Issue link at the end of this
section.>

Closes <ISSUE-ID>.

## Key changes

- <Noun phrase. The load-bearing change.>
- <Noun phrase. The second load-bearing change.>
- <…three to seven bullets total.>

## Risks

<Behavioral changes for existing callers. Migration concerns. Feature
flag state. Skip this section if there are no risks worth flagging—do
not pad.>

## Review notes

<A short prose paragraph: where to start, what to inspect next, what to
be careful about. See references/review-guidance.md.>
```

## Template: bug-fix PR

For most bug fixes, the structure compresses. A test that proves the fix is more valuable than long prose.

```markdown
## Summary

<One sentence: what was broken, what's now fixed.>

## Why

<One or two sentences: the bug's impact and how to reproduce. Issue link.>

Fixes <ISSUE-ID>.

## Fix

<One or two sentences on the root cause and the change made.>

## Review notes

<Where the bug lived, where the fix is, and where the regression test
is. Often one or two sentences.>
```

Worked example:

```markdown
## Summary

Calendar buffer reads stopped when a partial chunk arrived, leaving the
remainder of the response unread.

## Why

Long calendars (>4 KB) intermittently returned truncated JSON for users
on slow connections; the parser then errored out as if the server had
sent malformed data. Fixes #842.

## Fix

`CalendarReader::read_chunk` exited early on a short read instead of
looping until EOF. Replaced the single read with a loop that
accumulates until `read` returns 0.

## Review notes

The fix is in `src/calendar/reader.rs:67-78`. The regression test in
`tests/calendar_partial_read_test.rs` simulates a partial-read socket
and was failing before the fix; it passes now. The previous behavior
is still covered by the existing happy-path test.
```

## Template: refactor / chore PR

The hard part of refactor PRs is convincing the reviewer that behavior didn't change. Be explicit about it.

```markdown
## Summary

<What was restructured and what shape it has now. Explicitly mention
that no behavior changed if that's the case.>

## Why

<The pain that motivated the refactor. "Three call sites with duplicated
retry logic" is concrete; "code cleanup" is not.>

## Key changes

- <Structural change 1.>
- <Structural change 2.>
- <…>

## Review notes

<Reassurance about behavioral equivalence: which tests pass, which
public APIs are unchanged, where to look first.>
```

## When the template file dictates the structure

If `.github/pull_request_template.md` defines headings (`## Description`, `## Testing`, etc.), use *those* headings instead of the ones above. Don't invent extra sections the template doesn't have; reviewers expect the same shape as every other PR in the repo. See `references/pr-templates.md`.

## Length calibration

A good PR body is shorter than people expect. Aim for:

- **Bug fix:** 5–10 lines of body, often less.
- **Feature:** 15–30 lines of body.
- **Big refactor / multi-week feature:** up to 50 lines, rarely more.

If you've written more than 60 lines, ask whether the PR itself is too big to review.
