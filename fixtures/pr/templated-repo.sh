#!/usr/bin/env bash
# Scenario: repo has a .github/pull_request_template.md with specific
# headings and a checklist. The skill must structure the PR body to
# match those headings and tick honest checklist items only.
#
# Change: refactor that consolidates three retry blocks into a single
# RetryingClient wrapper. Behavior unchanged. Two commits.
#
# Usage: templated-repo.sh <target_dir>
set -euo pipefail
TARGET="${1:?target dir required}"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cd "$TARGET"

git init -q -b main
git config user.email "dev@example.com"
git config user.name "Dev"
git config commit.gpgsign false

mkdir -p src tests .github
cat > .github/pull_request_template.md <<'EOF'
## Description

<!-- What does this PR do? Keep this user/system focused, not file-level. -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor (no behavior change)
- [ ] Documentation
- [ ] CI / tooling

## Testing

<!-- How did you validate this change? Include manual repro steps if any. -->

## Reviewer notes

<!-- Where should the reviewer start? What deserves extra attention? -->

## Checklist

- [ ] Tests updated or added where appropriate
- [ ] Documentation updated where appropriate
- [ ] CHANGELOG.md updated
EOF

cat > src/client.py <<'EOF'
import time, requests

class Client:
    def get_user(self, user_id):
        for attempt in range(3):
            try:
                return requests.get(f"/users/{user_id}").json()
            except requests.exceptions.RequestException:
                if attempt == 2: raise
                time.sleep(0.5 * (2 ** attempt))

    def get_order(self, order_id):
        for attempt in range(3):
            try:
                return requests.get(f"/orders/{order_id}").json()
            except requests.exceptions.RequestException:
                if attempt == 2: raise
                time.sleep(0.5 * (2 ** attempt))

    def get_invoice(self, invoice_id):
        for attempt in range(3):
            try:
                return requests.get(f"/invoices/{invoice_id}").json()
            except requests.exceptions.RequestException:
                if attempt == 2: raise
                time.sleep(0.5 * (2 ** attempt))
EOF

cat > CHANGELOG.md <<'EOF'
# Changelog

## Unreleased

## 0.4.0

- Initial release.
EOF

git add -A
git commit -q -m "Initial commit"

# Build a small history of "Refactor X" / "Add Y" style titles.
cat > tests/test_client.py <<'EOF'
def test_placeholder():
    assert True
EOF
git add tests/test_client.py
git commit -q -m "Add placeholder client test"

git checkout -q -b refactor/consolidate-retry

# Commit 1: introduce RetryingClient wrapper
cat > src/retry.py <<'EOF'
"""Single retry policy used by every outbound HTTP call."""
import time
from typing import Callable, TypeVar
import requests

T = TypeVar("T")
MAX_ATTEMPTS = 3
BASE_BACKOFF = 0.5

def with_retry(fn: Callable[[], T]) -> T:
    for attempt in range(MAX_ATTEMPTS):
        try:
            return fn()
        except requests.exceptions.RequestException:
            if attempt == MAX_ATTEMPTS - 1:
                raise
            time.sleep(BASE_BACKOFF * (2 ** attempt))
    raise RuntimeError("unreachable")
EOF
git add src/retry.py
git commit -q -m "Add with_retry helper centralizing retry policy"

# Commit 2: migrate call sites
cat > src/client.py <<'EOF'
import requests
from .retry import with_retry

class Client:
    def get_user(self, user_id):
        return with_retry(lambda: requests.get(f"/users/{user_id}").json())

    def get_order(self, order_id):
        return with_retry(lambda: requests.get(f"/orders/{order_id}").json())

    def get_invoice(self, invoice_id):
        return with_retry(lambda: requests.get(f"/invoices/{invoice_id}").json())
EOF
git commit -aq -m "Replace inline retry loops with with_retry"

cat >> CHANGELOG.md <<'EOF'

## Unreleased (added in this branch)

- Internal: consolidate per-method retry loops into a single helper.
EOF

# Note: changelog edit is unstaged; intentional, to see whether the
# skill notices and includes it.
echo "Fixture ready at $TARGET"
git status --short
git log --oneline main..HEAD
