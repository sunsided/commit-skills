#!/usr/bin/env bash
# Scenario: a feature branch with a spread of review comments covering every
# triage kind at once — a real defect, an agreeable nit, a question that is
# genuinely fine, and a pure-taste opinion. Tests that the skill fixes the
# right things, replies to all of them, and doesn't manufacture changes for
# the question or the opinion. Repo commit style is plain imperative.
#
# Usage: mixed-feedback.sh <target_dir>
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

cat > src/pricing.py <<'EOF'
# All money is in integer cents.

def line_total(item):
    return item["price"] * item["qty"]


def cart_total(items):
    total = 0
    for item in items:
        total += item["price"] * item["qty"]
    # Free shipping over $50.00; otherwise a flat $5.00.
    shipping = 0 if total > 5000 else 500
    return total + shipping
EOF

git add -A
git commit -q -m "Add pricing module"

cat > README.md <<'EOF'
# shop

Cart pricing helpers. Money is in integer cents throughout.
EOF
git add README.md
git commit -q -m "Add README"

git checkout -q -b feat/cart-totals

# (The branch is what's under review; the diff vs main is the pricing module.)
# Re-touch the file so it shows up in the branch diff cleanly.
cat >> src/pricing.py <<'EOF'


def format_price(cents):
    return "$%0.2f" % (cents / 100)
EOF
git commit -aq -m "Add price formatter"

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git log --oneline main..HEAD
