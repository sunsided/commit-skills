#!/usr/bin/env bash
# Scenario: a two-commit perf-fix branch whose COMMIT BODIES carry the load-
# bearing rationale - profiling findings, measured before/after numbers, a
# cache-size justification, and the issue ID (PERF-204) - none of which is
# visible in the diff or the one-line subjects. The branch name has no ticket,
# so the only place PERF-204 lives is the commit bodies. A PR skill that reads
# full commit messages can lift all of this into the body; one that reads only
# `--oneline` + the diff cannot. Repo PR/commit style is plain imperative; no
# PR template, so no Testing/Verification section should be invented.
#
# Usage: body-rich.sh <target_dir>
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

cat > src/matcher.py <<'EOF'
import re


class Matcher:
    def __init__(self, patterns):
        # patterns: list of (name, source) tuples.
        self._patterns = patterns

    def match(self, name, text):
        for pname, source in self._patterns:
            if pname == name:
                return re.compile(source).search(text) is not None
        return False
EOF

cat > tests/test_matcher.py <<'EOF'
from src.matcher import Matcher


def test_match_hits_named_pattern():
    m = Matcher([("digits", r"\d+"), ("word", r"[a-z]+")])
    assert m.match("digits", "abc123") is True
    assert m.match("word", "123") is False
EOF

git add -A
git commit -q -m "Add pattern matcher"

cat > README.md <<'EOF'
# matchkit

Named-pattern matching over text.
EOF
git add README.md
git commit -q -m "Add README"

# Branch name intentionally carries NO ticket id.
git checkout -q -b perf/regex-cache

# Commit 1: cache compiled patterns. The WHY (profiling, the regression, the
# measured win, the ticket) lives only in the body.
cat > src/matcher.py <<'EOF'
import re


class Matcher:
    def __init__(self, patterns):
        self._patterns = patterns
        self._compiled = {}

    def _get(self, source):
        cached = self._compiled.get(source)
        if cached is None:
            cached = re.compile(source)
            self._compiled[source] = cached
        return cached

    def match(self, name, text):
        for pname, source in self._patterns:
            if pname == name:
                return self._get(source).search(text) is not None
        return False
EOF
git commit -aq -F - <<'EOF'
Cache compiled regexes in the matcher

Profiling the 1.4.0 release under the production query mix showed
Matcher.match recompiling the same handful of patterns on every call -
about 38% of request CPU at peak. re.compile is not free and these
sources never change for the life of a Matcher.

Cache compiled patterns keyed by their source string. Measured on the
prod query replay: p99 match latency drops from 4.2ms to 0.6ms, and the
matcher falls off the CPU profile entirely.

Refs: PERF-204
EOF

# Commit 2: bound the cache. Again, the justification is body-only.
cat > src/matcher.py <<'EOF'
import re
from collections import OrderedDict

_CACHE_MAX = 512


class Matcher:
    def __init__(self, patterns):
        self._patterns = patterns
        self._compiled = OrderedDict()

    def _get(self, source):
        cached = self._compiled.get(source)
        if cached is None:
            cached = re.compile(source)
            self._compiled[source] = cached
            if len(self._compiled) > _CACHE_MAX:
                self._compiled.popitem(last=False)
        else:
            self._compiled.move_to_end(source)
        return cached

    def match(self, name, text):
        for pname, source in self._patterns:
            if pname == name:
                return self._get(source).search(text) is not None
        return False
EOF
git commit -aq -F - <<'EOF'
Bound the compiled-regex cache at 512 entries

The plain-dict cache from the previous commit is an unbounded-growth
risk: endpoints that build patterns dynamically (the search-filter API
compiles a fresh source per saved filter) would let it grow without
limit and leak memory over a process lifetime.

Make it an LRU bounded at 512 entries. 512 is comfortably above the
largest distinct-pattern set we have actually observed in prod (~380
for the busiest tenant), so steady-state traffic never evicts, while a
pathological dynamic-pattern caller can no longer leak.

Refs: PERF-204
EOF

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git log --oneline main..HEAD
