## Summary

Adds an explicit session-booking step in front of message exchange so a
therapist must reserve a slot before any messages can flow. Previously
`messages.send` would lazily create a session on the first message,
which made it impossible to prevent double-booking of the same slot and
left the API with no clean "no session yet" failure mode.

Ticket: MED-481

## Changes

- **New `src/booking/lock.py`** — `SlotLock` primitive with a 5-minute
  TTL, plus `acquire` / `release`. In-memory today (Redis in prod),
  intentionally behind a small surface so the backend can be swapped
  without touching callers.
- **New `src/booking/service.py`** — `BookingService` with `book` and
  `confirm`. `book` acquires the slot lock and mints a `session_id`;
  `confirm` releases the lock (and, in the production wiring, will
  persist the session). Returns `{"error": "slot_taken"}` when the slot
  is already held.
- **`src/messages.py`** — adds `send_strict(session_id, body)` which
  returns `{"error": "no_session", "status": 409}` when the caller did
  not book first. The legacy `send` (implicit-create) is kept untouched
  for backwards compatibility; callers should migrate to `send_strict`.
- **Test** — `tests/test_booking_race.py` covers the case where two
  bookings race for the same slot and asserts only one wins.

## Why this shape

- Booking and messaging are split into separate modules so the lock
  story stays isolated and easy to swap (in-memory → Redis) without
  pulling `messages` into the change.
- `send_strict` is added alongside the existing `send` rather than
  replacing it; this lets clients migrate incrementally and lets us
  flip the default in a follow-up once all callers are updated.

## Test plan

- [x] `pytest tests/test_booking_race.py` — two `book()` calls on the
  same `slot_key` yield one success and one `slot_taken`.
- [x] `pytest tests/test_messages.py` — existing implicit-create path
  still green (no regression for legacy `send`).
- [ ] Manual: call `send_strict` without booking → expect
  `{"error": "no_session", "status": 409}`.
- [ ] Manual: `book` → `send_strict` with the returned `session_id` →
  expect normal `{"session_id", "body"}` response.

## Follow-ups (not in this PR)

- Wire `BookingService` into the HTTP handler / router.
- Replace the in-memory `_locks` dict with the Redis-backed
  implementation.
- Persist the session inside `confirm` (currently a no-op placeholder).
- Deprecate `messages.send` once all callers are on `send_strict`.
