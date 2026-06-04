# Title

feat(booking): add explicit session booking before message exchange

# Body

## Summary

Adds an explicit booking step that reserves a therapist slot and returns a
`session_id` before any messages are exchanged. A client now holds a session
up front instead of having one created implicitly on its first send, so two
clients can no longer end up claiming the same therapist slot.

## Why

Today `messages.send` creates a session implicitly whenever one is missing, so
two clients hitting the same therapist around the same time can both succeed
and then race on the same slot. The booking step makes the reservation explicit
and serializable: the first caller wins the slot, the second is rejected.
Closes MED-481.

## Key changes

- New `src/booking/lock.py` with a `SlotLock` primitive: `acquire` grants a
  lock only when no live lock exists for the slot, `release` drops it. Locks
  carry a 5-minute TTL (`TTL_SECONDS`) and are stored in-memory for now, backed
  by Redis in production.
- New `src/booking/service.py`: `book(therapist_id, slot_key)` returns
  `{session_id, expires_at}` on success or `{error: "slot_taken"}` when the slot
  is already held; `confirm()` releases the lock once the session is persisted.
- `messages.send_strict()` returns a 409 `no_session` instead of creating a
  session implicitly, so the message path requires a booked session.
- Race test in `tests/test_booking_race.py` covering two bookings on the same
  slot, asserting exactly one wins.

## Risks

The strict message path is additive: `send_strict()` rejects sessionless
requests with 409, but the existing `send()` still creates sessions implicitly,
so callers must be migrated to the strict path before implicit creation can be
removed. The slot lock is held by `book()` and only freed by `confirm()` (or the
TTL); `confirm()` currently always returns success with a placeholder persist
step, so the release-on-persist-failure path is not yet exercised.

## Review notes

Start in `src/booking/lock.py` to see the `SlotLock` shape and the
acquire/release contract: the liveness check (`expires_at > monotonic()`) is
what makes a second caller lose the slot. Then read `src/booking/service.py` to
see how `book` turns a held lock into a `session_id` and how `confirm` releases
it in a `finally`. Scrutinize `confirm()` (`service.py`): the persist step is a
placeholder that always returns `True`, so confirm the intended behavior is that
a real persistence failure still releases the lock and surfaces an error rather
than leaving the slot locked until the TTL expires. Finally, `messages.send_strict`
shows the 409 contract, and `tests/test_booking_race.py` exercises the
two-callers-one-slot case.
