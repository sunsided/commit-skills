# Writing the "review notes" section

The review-notes section is the part of a PR body that pays off most. Reviewers open dozens of PRs a week; if you tell them where to look first, what to skim, and what to scrutinize, you respect their time and you also get better feedback—because attention lands in the right places.

## What it should contain

A short prose paragraph (2–4 sentences typically; up to ~6 for a complex change). It answers three questions in order:

1. **Where do I start?** Which file or symbol is the load-bearing piece? Read this first.
2. **What do I read next?** The logical reading order through the rest of the change.
3. **What should I scrutinize?** The specific line or function or interaction that has the highest stakes. Be specific—file + line number is ideal.

## Patterns that work

### "Start in X, then Y, careful with Z"

```
Start in `src/sessions/booking.rs` to see the SlotLock shape and the
acquire/release flow—this is the load-bearing piece. Then read the
`POST /sessions/book` handler in `src/api/sessions.rs` to see how it's
wired in. Pay particular attention to the lock-release path on confirm
failure (booking.rs:142)—an early return there would leak locks.
```

### "Skim X, focus on Y"

When most of the diff is mechanical:

```
The bulk of the diff is mechanical call-site updates for the new
`Client::with_retry` signature—skim those. Focus on the new policy
struct in `src/client/retry.rs` and the tests in
`tests/retry_policy_test.rs:45-120` covering 5xx vs network-error
behavior.
```

### "Test first, then implementation"

For bug fixes, especially when the test makes the bug obvious:

```
Read `tests/calendar_partial_read_test.rs` first—the test fails on
the previous behavior and clearly shows what was broken. Then the
fix in `src/calendar/reader.rs:67-78`.
```

### "Cold-read warning"

When the change interacts with something that's not in the diff:

```
The lock TTL interacts with the worker poll interval in
`src/workers/session_gc.rs` (not changed in this PR). If the TTL is
shortened below the poll interval in a future change, the GC worker
will see stale locks and double-clean them. Worth noting for future
context.
```

## Patterns to avoid

- **"LGTM, please review"** — not review notes; that's a message in the wrong channel.
- **Generic instructions** ("please review carefully") — useless. Be specific about *what* to look at carefully.
- **Recapping the diff in prose** ("I added a function called `book_slot` that takes a `SlotRequest`…"). The diff already shows this.
- **Apologies** ("sorry for the big diff"). State neutrally if you must.
- **Tooling chatter** ("I ran the tests and they pass"). The CI checks already say this. If a test scenario requires manual verification, say *that*: "Manual test: open two browser tabs, both POST to /sessions/book within the same second, expect one 200 and one 409."

## When the "review notes" section becomes a checklist

For larger PRs, a numbered review path can replace prose:

```
Suggested review order:
1. `src/booking/lock.rs` — the new SlotLock primitive.
2. `src/booking/service.rs` — the BookingService that uses it.
3. `src/api/sessions.rs:88-140` — the handler wiring.
4. `tests/booking_race_test.rs` — concurrent-attempt coverage.

The most subtle code is the lock-release path on confirm failure
(`service.rs:142`); please scrutinize that.
```

Use this form when there are 3+ distinct components a reviewer needs to read in a specific order. Otherwise prose is friendlier.

## How long this section should be

About as long as the "Summary" section, often shorter. If your review-notes section is longer than your summary, you're probably describing the change instead of guiding the reader. Cut the description; keep the guidance.
