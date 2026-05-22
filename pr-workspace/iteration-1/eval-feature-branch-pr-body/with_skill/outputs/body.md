## Summary

Introduces an explicit booking step that reserves a therapist slot before
any message can be sent. Clients now call `book(therapist_id, slot_key)`
to obtain a `session_id` tied to a held slot, and `send_strict` rejects
message attempts that arrive without a valid session instead of creating
one implicitly.

## Why

Two clients hitting the same therapist slot could both succeed under the
old implicit-session flow in `messages.send`, racing on writes against
the same session. Making the reservation explicit serialises the
contended step on a slot-level lock. Closes MED-481.

## Key changes

- New `src/booking/lock.py` with the `SlotLock` primitive: a 5-minute
  TTL lock keyed by slot, acquired atomically and released on confirm.
- New `src/booking/service.py` exposing `book()` (returns
  `{session_id, expires_at}` or `{error: "slot_taken"}`) and `confirm()`
  (releases the slot lock in a `finally` so failures don't leak it).
- `src/messages.py` gains `send_strict(session_id, body)`, which
  returns a 409 `no_session` error when the session is missing rather
  than calling `create_implicit`.
- Race-coverage test in `tests/test_booking_race.py` asserts that two
  concurrent `book()` calls on the same slot resolve to one winner and
  one `slot_taken`.

## Risks

`send_strict` is a behaviour change relative to `send`: callers that
relied on implicit session creation will now see a 409. The original
`send` is left in place, so this lands additively—the cutover happens
when callers move to `send_strict`. The lock store is in-memory in this
PR; the production Redis backing is unchanged from the existing
deployment shape (same key/TTL semantics).

## Review notes

Start in `src/booking/lock.py` — the `acquire`/`release` pair and the
`TTL_SECONDS` constant are the load-bearing piece, and everything else
is wired around them. Then read `src/booking/service.py` to see how
`book` and `confirm` use the lock, paying particular attention to the
`finally: _lock.release(slot_key)` in `confirm` (this is what stops a
failed confirm from leaking a held slot). Finish with the new
`send_strict` branch in `src/messages.py` and the race test in
`tests/test_booking_race.py`, which exercises the contended path.
