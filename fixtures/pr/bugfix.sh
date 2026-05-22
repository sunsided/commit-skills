#!/usr/bin/env bash
# Scenario: a short bug-fix branch. One commit fixing a race in token
# refresh, one commit adding a regression test. Base = main. Repo's PR
# title style is plain imperative (no Conventional Commits). Branch name
# encodes a GitHub-style issue number.
#
# Usage: bugfix.sh <target_dir>
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
name = "auth-client"
version = "1.4.0"
EOF

cat > src/token.py <<'EOF'
import time
import threading

class TokenManager:
    def __init__(self, fetcher):
        self._fetcher = fetcher
        self._token = None
        self._expires_at = 0
        self._lock = threading.Lock()

    def get(self):
        # BUG: two threads can both pass the expiry check, then both refresh.
        if time.time() >= self._expires_at:
            self._token, self._expires_at = self._fetcher()
        return self._token
EOF

cat > tests/test_token.py <<'EOF'
import time
from src.token import TokenManager

def test_returns_token_until_expiry():
    calls = {"n": 0}
    def fetch():
        calls["n"] += 1
        return ("tok-%d" % calls["n"], time.time() + 60)
    m = TokenManager(fetch)
    assert m.get() == "tok-1"
    assert m.get() == "tok-1"
EOF

git add -A
git commit -q -m "Initial auth-client crate"

cat > README.md <<'EOF'
# auth-client

Thread-safe token caching for upstream APIs.
EOF
git add README.md
git commit -q -m "Add README"

# Branch named with a GitHub-style issue number.
git checkout -q -b fix/842-token-refresh-race

# Fix: serialize the refresh inside the lock.
cat > src/token.py <<'EOF'
import time
import threading

class TokenManager:
    def __init__(self, fetcher):
        self._fetcher = fetcher
        self._token = None
        self._expires_at = 0
        self._lock = threading.Lock()

    def get(self):
        # Fast path: cache hit outside the lock.
        if time.time() < self._expires_at and self._token is not None:
            return self._token
        # Slow path: re-check under the lock to avoid duplicate refreshes.
        with self._lock:
            if time.time() >= self._expires_at or self._token is None:
                self._token, self._expires_at = self._fetcher()
            return self._token
EOF
git commit -aq -m "Serialize token refresh under the manager lock"

# Regression test
cat >> tests/test_token.py <<'EOF'


import threading

def test_concurrent_refresh_calls_fetcher_once():
    calls = {"n": 0}
    def fetch():
        # Without the fix, multiple threads enter this fetcher.
        calls["n"] += 1
        return ("tok", time.time() + 60)
    m = TokenManager(fetch)
    threads = [threading.Thread(target=m.get) for _ in range(8)]
    for t in threads: t.start()
    for t in threads: t.join()
    assert calls["n"] == 1, f"expected 1 fetcher call, got {calls['n']}"
EOF
git commit -aq -m "Add regression test for concurrent token refresh"

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git log --oneline main..HEAD
