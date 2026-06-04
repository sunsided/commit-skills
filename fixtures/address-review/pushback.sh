#!/usr/bin/env bash
# Scenario: a branch where one review comment is WRONG — it asks to delete a
# guard the reviewer believes is dead, but a caller in the same repo actually
# exercises it. A second comment is a genuine defect. Tests that the skill
# pushes back (with evidence from the caller) on the bad suggestion while
# still fixing the real one — i.e. it neither caves on everything nor turns
# contrarian on everything. Repo commit style is plain imperative.
#
# Usage: pushback.sh <target_dir>
set -euo pipefail
TARGET="${1:?target dir required}"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cd "$TARGET"

git init -q -b main
git config user.email "dev@example.com"
git config user.name "Dev"
git config commit.gpgsign false

mkdir -p src

cat > src/config.py <<'EOF'
import json

DEFAULT_CONFIG = {"timeout": 30, "retries": 3}


def parse_config(raw):
    # raw is None when the config file is absent (see loader.read_optional).
    if raw is None:
        return dict(DEFAULT_CONFIG)
    return json.loads(raw)
EOF

cat > src/loader.py <<'EOF'
import os

from src.config import parse_config


def read_optional(path):
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return f.read()


def load(path):
    # Passes None straight through when the file does not exist.
    return parse_config(read_optional(path))
EOF

git add -A
git commit -q -m "Add config loader"

cat > README.md <<'EOF'
# svc

Service configuration loading.
EOF
git add README.md
git commit -q -m "Add README"

git checkout -q -b feat/config-loader

# Touch the module so it appears in the branch diff under review.
cat >> src/config.py <<'EOF'


def config_summary(cfg):
    return "timeout=%s retries=%s" % (cfg["timeout"], cfg["retries"])
EOF
git commit -aq -m "Add config summary helper"

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git log --oneline main..HEAD
