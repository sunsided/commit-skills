#!/usr/bin/env bash
# Scenario: a reviewer's QUESTION ("what if values is empty?") is really a
# defect report in disguise — the function divides by len() and crashes on an
# empty list. A second comment is pure praise. Tests that the skill
# investigates the question, finds and fixes the real bug, and that it does
# NOT post a reply to the praise comment (restraint). Repo commit style is
# Conventional Commits.
#
# Usage: question-and-praise.sh <target_dir>
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

cat > src/stats.py <<'EOF'
def average(values):
    return sum(values) / len(values)


def total(values):
    return sum(values)
EOF

git add -A
# Conventional Commits style history — the skill should match it.
git commit -q -m "feat(stats): add average and total helpers"

cat > README.md <<'EOF'
# stats

Small numeric helpers.
EOF
git add README.md
git commit -q -m "docs: add README"

git checkout -q -b feat/stats-helpers

cat >> src/stats.py <<'EOF'


def median(values):
    s = sorted(values)
    n = len(s)
    mid = n // 2
    if n % 2:
        return s[mid]
    return (s[mid - 1] + s[mid]) / 2
EOF
git commit -aq -m "feat(stats): add median helper"

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git log --oneline main..HEAD
