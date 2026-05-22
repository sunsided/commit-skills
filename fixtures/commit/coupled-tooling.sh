#!/usr/bin/env bash
# Scenario: a new benchmark suite landed together with the tooling that
# runs it (Taskfile.dist.yaml target + a README section). These three
# changes share intent — the Taskfile target only exists because the
# benchmark exists — so they should be one commit, not three.
#
# Repo history uses Conventional Commits with no scope.
#
# Usage: coupled-tooling.sh <target_dir>
set -euo pipefail
TARGET="${1:?target dir required}"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cd "$TARGET"

git init -q -b main
git config user.email "dev@example.com"
git config user.name "Dev"
git config commit.gpgsign false

mkdir -p src benches
cat > README.md <<'EOF'
# nibble-parser

A small line-oriented parser.

## Usage

```python
from nibble import parse
parse("hello world")
```
EOF

cat > pyproject.toml <<'EOF'
[project]
name = "nibble-parser"
version = "0.2.0"
EOF

cat > src/nibble.py <<'EOF'
def parse(line: str):
    return line.strip().split()
EOF

git add -A
git commit -q -m "chore: initial commit"

# Conventional Commits history
cat > src/tokens.py <<'EOF'
def tokenize(line: str):
    return [t.lower() for t in line.split()]
EOF
git add src/tokens.py
git commit -q -m "feat: add token normalizer"

sed -i 's/return line.strip().split()/return [t for t in line.strip().split() if t]/' src/nibble.py
git commit -aq -m "fix: drop empty tokens from parse output"

cat > src/format.py <<'EOF'
def format_tokens(tokens):
    return " | ".join(tokens)
EOF
git add src/format.py
git commit -q -m "feat: add token formatter"

# Dirty the tree with one coupled change: benchmark + Taskfile target + README.

cat > benches/bench_parse.py <<'EOF'
import time
from nibble import parse

def bench():
    text = "the quick brown fox jumps over the lazy dog " * 1000
    iterations = 5000
    start = time.perf_counter()
    for _ in range(iterations):
        parse(text)
    elapsed = time.perf_counter() - start
    print(f"parse: {iterations / elapsed:.0f} ops/sec")

if __name__ == "__main__":
    bench()
EOF

cat > Taskfile.dist.yaml <<'EOF'
version: '3'

tasks:
  bench:
    desc: Run parser benchmarks
    cmds:
      - PYTHONPATH=src python benches/bench_parse.py
EOF

cat >> README.md <<'EOF'

## Benchmarks

Run with:

```
task bench
```

See `benches/bench_parse.py` for the parse-throughput benchmark.
EOF

echo "Fixture ready at $TARGET"
git status --short
