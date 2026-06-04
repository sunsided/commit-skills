**Title:** `feat(booking): add explicit slot booking before message exchange`

**Body:**

## Summary

Adds an explicit booking step so a client reserves a therapist slot and
receives a `session_id` before any messages are exchanged. Booking acquires
a per-slot lock with a 5-minute TTL; a second client targeting the same slot
is turned away rather than silently sharing it. A new strict message path
rejects sends that arrive without a valid session instead of creating one
implicitly.

## Why

Today `messages.send` creates a session implicitly on first send, so two
clients hitting the same therapist slot can both proceed and race on the same
reservation. Making the booking explicit and lock-guarded serializes the
reservation and gives one clear winner. Closes MED-481.

## Key changes

- New `src/booking/lock.py`: a `SlotLock` dataclass plus `acquire`/`release`
  over a slot-keyed store (in-memory now, Redis in prod), with a 5-minute
  `TTL_SECONDS`. `acquire` returns `None` when an unexpired lock already holds
  the slot.
- New `src/booking/service.py`: `book(therapist_id, slot_key)` returns
  `{session_id, expires_at}` on success or `{error: "slot_taken"}` when the
  slot is held; `confirm` releases the lock in a `finally`.
- `src/messages.py` gains `send_strict(session_id, body)`, which returns a
  409 `no_session` error when the session is missing instead of creating one
  implicitly. The existing implicit-creation `send` is left in place.
- Race-coverage test in `tests/test_booking_race.py`: two bookings on the
  same slot, exactly one wins.

## Risks

The strict path is additive: `send_strict` exists alongside the old `send`,
so nothing that currently relies on implicit session creation changes yet.
Callers must be migrated to `send_strict` before implicit creation can be
retired. The lock store is in-memory in this change (Redis is the production
backend noted in the module), so locks are not shared across processes until
that backing is wired up.

## Review notes

Start in `src/booking/lock.py` to see the `SlotLock` shape and the
acquire/release flow with TTL expiry - this is the load-bearing piece. Then
read `src/booking/service.py` to see how `book` and `confirm` use it; pay
particular attention to `confirm`, which releases the lock in a `finally`,
so a future persistence step that fails would still free the slot. Finally,
`tests/test_booking_race.py` demonstrates the one-winner guarantee and is
worth running locally. Note that the strict 409 behavior lives in
`send_strict` while the old implicit `send` is untouched - confirm that
matches the intended rollout.
