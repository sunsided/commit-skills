#!/usr/bin/env bash
# Scenario: a clean feature branch with 3 well-described commits, ready
# to open as a PR. Base = main. Repo uses Conventional Commits in PR
# titles (`gh pr list` history would show this). No PR template.
#
# Usage: feature-branch.sh <target_dir>
set -euo pipefail
TARGET="${1:?target dir required}"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cd "$TARGET"

git init -q -b main
git config user.email "dev@example.com"
git config user.name "Dev"
git config commit.gpgsign false

mkdir -p src tests
cat > pyproject.toml <<'EOF'
[project]
name = "session-api"
version = "0.5.0"
EOF

cat > src/sessions.py <<'EOF'
from dataclasses import dataclass

@dataclass
class Session:
    id: str
    therapist_id: str

_store: dict[str, Session] = {}

def create_implicit(therapist_id: str, session_id: str) -> Session:
    s = Session(id=session_id, therapist_id=therapist_id)
    _store[session_id] = s
    return s

def get(session_id: str) -> Session | None:
    return _store.get(session_id)
EOF

cat > src/messages.py <<'EOF'
from . import sessions

def send(therapist_id: str, session_id: str, body: str) -> dict:
    s = sessions.get(session_id)
    if s is None:
        s = sessions.create_implicit(therapist_id, session_id)
    return {"session_id": s.id, "body": body}
EOF

cat > tests/test_messages.py <<'EOF'
from src.messages import send
def test_send_creates_session_implicitly():
    out = send("t1", "s1", "hello")
    assert out["session_id"] == "s1"
EOF

git add -A
git commit -q -m "chore: initial commit"

# A bit of history with Conventional Commits.
echo "EXPIRY_MINUTES = 30" >> src/sessions.py
git commit -aq -m "feat: add session expiry constant"

# Branch off main for the feature.
git checkout -q -b feat/MED-481-explicit-booking

# Commit 1: introduce SlotLock primitive
mkdir -p src/booking
cat > src/booking/__init__.py <<'EOF'
EOF
cat > src/booking/lock.py <<'EOF'
"""Slot-level locks backed by an in-memory store (Redis in prod)."""
from dataclasses import dataclass
from time import monotonic
from typing import Dict

@dataclass
class SlotLock:
    therapist_id: str
    slot_key: str
    expires_at: float

_locks: Dict[str, SlotLock] = {}
TTL_SECONDS = 5 * 60

def acquire(therapist_id: str, slot_key: str) -> SlotLock | None:
    existing = _locks.get(slot_key)
    if existing and existing.expires_at > monotonic():
        return None
    lock = SlotLock(therapist_id, slot_key, monotonic() + TTL_SECONDS)
    _locks[slot_key] = lock
    return lock

def release(slot_key: str) -> None:
    _locks.pop(slot_key, None)
EOF
git add src/booking/
git commit -q -m "feat(booking): add SlotLock primitive with TTL"

# Commit 2: BookingService and handler
cat > src/booking/service.py <<'EOF'
from uuid import uuid4
from . import lock as _lock

def book(therapist_id: str, slot_key: str) -> dict:
    held = _lock.acquire(therapist_id, slot_key)
    if held is None:
        return {"error": "slot_taken"}
    session_id = uuid4().hex
    return {"session_id": session_id, "expires_at": held.expires_at}

def confirm(session_id: str, slot_key: str) -> bool:
    # Production code would persist the session here; release on failure.
    try:
        return True
    finally:
        _lock.release(slot_key)
EOF

cat >> src/messages.py <<'EOF'


def send_strict(session_id: str, body: str) -> dict:
    s = sessions.get(session_id)
    if s is None:
        return {"error": "no_session", "status": 409}
    return {"session_id": s.id, "body": body}
EOF

git add src/booking/service.py src/messages.py
git commit -q -m "feat(booking): add BookingService and 409 on missing session"

# Commit 3: regression / race test
cat > tests/test_booking_race.py <<'EOF'
from src.booking.service import book

def test_two_bookings_on_same_slot_only_one_wins():
    a = book("t1", "slot-A")
    b = book("t1", "slot-A")
    assert "session_id" in a
    assert b.get("error") == "slot_taken"
EOF
git add tests/test_booking_race.py
git commit -q -m "test(booking): cover concurrent attempts on the same slot"

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Commits ahead of main:"
git log --oneline main..HEAD
