#!/usr/bin/env bash
# Scenario: working tree contains three unrelated changes that should
# become three separate commits.
# - new API endpoint (src + matching test)  → feature commit
# - unrelated CI workflow update (Node bump) → ci commit
# - README typo fix                           → docs commit
#
# Repo history uses plain imperative subjects.
#
# Usage: mixed-changes.sh <target_dir>
set -euo pipefail
TARGET="${1:?target dir required}"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cd "$TARGET"

git init -q -b main
git config user.email "dev@example.com"
git config user.name "Dev"
git config commit.gpgsign false

mkdir -p src tests .github/workflows
cat > README.md <<'EOF'
# example-api

A small example service.

## Endpoints

- `GET /health` — liveness check.

## Devolopment

Run with `npm start`.
EOF

cat > package.json <<'EOF'
{
  "name": "example-api",
  "version": "0.1.0",
  "scripts": { "start": "node src/index.js" }
}
EOF

cat > src/index.js <<'EOF'
const http = require('http');
const { handleHealth } = require('./health');

const server = http.createServer((req, res) => {
  if (req.url === '/health') return handleHealth(req, res);
  res.statusCode = 404;
  res.end();
});
server.listen(3000);
EOF

cat > src/health.js <<'EOF'
function handleHealth(req, res) {
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({ ok: true }));
}
module.exports = { handleHealth };
EOF

cat > tests/health.test.js <<'EOF'
const { handleHealth } = require('../src/health');
test('health returns ok', () => {
  let body = '';
  const res = { setHeader() {}, end(b) { body = b; } };
  handleHealth({}, res);
  expect(JSON.parse(body)).toEqual({ ok: true });
});
EOF

cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '18' }
      - run: npm ci
      - run: npm test
EOF

git add -A
git commit -q -m "Initial commit"

# Build a small history of plain-imperative commits so the skill detects style.
cat > src/version.js <<'EOF'
module.exports = { version: '0.1.0' };
EOF
git add src/version.js
git commit -q -m "Add version helper"

sed -i 's/version: '\''0.1.0'\''/version: '\''0.1.1'\''/' src/version.js
git commit -aq -m "Bump version to 0.1.1"

cat > tests/version.test.js <<'EOF'
const { version } = require('../src/version');
test('version is set', () => { expect(version).toMatch(/^\d/); });
EOF
git add tests/version.test.js
git commit -q -m "Add version test"

# Now dirty the tree with three unrelated changes:

# 1) New API endpoint (feature)
cat > src/users.js <<'EOF'
const users = new Map();

function handleGetUser(req, res, id) {
  const u = users.get(id);
  if (!u) { res.statusCode = 404; return res.end(); }
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(u));
}

function _seed(id, data) { users.set(id, data); }

module.exports = { handleGetUser, _seed };
EOF

cat > tests/users.test.js <<'EOF'
const { handleGetUser, _seed } = require('../src/users');
test('returns user when present', () => {
  _seed('u1', { id: 'u1', name: 'Ada' });
  let body = '';
  const res = { setHeader() {}, end(b) { body = b; } };
  handleGetUser({}, res, 'u1');
  expect(JSON.parse(body)).toEqual({ id: 'u1', name: 'Ada' });
});
test('returns 404 when missing', () => {
  let status = 200;
  const res = { setHeader() {}, statusCode: 200, end() {} };
  Object.defineProperty(res, 'statusCode', { set(v) { status = v; }, get() { return status; } });
  handleGetUser({}, res, 'missing');
  expect(status).toBe(404);
});
EOF

# wire it in
cat > src/index.js <<'EOF'
const http = require('http');
const { handleHealth } = require('./health');
const { handleGetUser } = require('./users');

const server = http.createServer((req, res) => {
  if (req.url === '/health') return handleHealth(req, res);
  const userMatch = req.url && req.url.match(/^\/users\/([^/]+)$/);
  if (userMatch) return handleGetUser(req, res, userMatch[1]);
  res.statusCode = 404;
  res.end();
});
server.listen(3000);
EOF

# 2) Unrelated CI bump (node 18 → 20)
sed -i "s/node-version: '18'/node-version: '20'/" .github/workflows/ci.yml

# 3) README typo
sed -i 's/Devolopment/Development/' README.md

# Leave everything UNSTAGED.
echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git status --short
