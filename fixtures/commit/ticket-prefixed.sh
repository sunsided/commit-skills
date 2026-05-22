#!/usr/bin/env bash
# Scenario: repo uses ticket-prefixed subjects ("MED-481: Add ..."), and
# the working branch name encodes a ticket. The skill should match the
# style and pick up the ticket from the branch name. Two changes:
#   - bug fix (src + test for the regression)  → one commit
#   - unrelated dependency bump                → second commit
#
# Usage: ticket-prefixed.sh <target_dir>
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
cat > Cargo.toml <<'EOF'
[package]
name = "calendar"
version = "0.3.0"
edition = "2021"

[dependencies]
serde = "1.0.190"

[dev-dependencies]
EOF

cat > src/lib.rs <<'EOF'
pub mod reader;
pub mod paginate;
EOF

cat > src/reader.rs <<'EOF'
pub fn read_chunk(buf: &[u8]) -> &[u8] {
    // BUG: stops at first short read; should accumulate until EOF.
    if buf.is_empty() { return &[]; }
    &buf[..buf.len().min(1024)]
}
EOF

cat > src/paginate.rs <<'EOF'
pub fn cursor(page: usize, per_page: usize) -> (usize, usize) {
    let start = page * per_page;
    let end = start + per_page;
    (start, end)
}
EOF

cat > tests/paginate.rs <<'EOF'
use calendar::paginate::cursor;
#[test]
fn page_zero() { assert_eq!(cursor(0, 10), (0, 10)); }
#[test]
fn page_three() { assert_eq!(cursor(3, 10), (30, 40)); }
EOF

git add -A
git commit -q -m "MED-100: Initial calendar crate"

# Ticket-prefixed history.
cat >> src/paginate.rs <<'EOF'

pub fn total_pages(items: usize, per_page: usize) -> usize {
    (items + per_page - 1) / per_page
}
EOF
git commit -aq -m "MED-204: Add total_pages helper"

cat >> tests/paginate.rs <<'EOF'

#[test]
fn total_pages_basic() {
    assert_eq!(calendar::paginate::total_pages(25, 10), 3);
}
EOF
git commit -aq -m "MED-204: Cover total_pages with a test"

# Switch to a ticket-named branch
git checkout -q -b bugfix/MED-842-partial-read

# Dirty changes:
# 1) Bug fix to reader.rs + regression test
cat > src/reader.rs <<'EOF'
pub fn read_chunk(buf: &[u8]) -> Vec<u8> {
    // Accumulate the entire buffer instead of stopping at the first
    // short slice. Previously, callers received truncated chunks
    // when the underlying read returned less than the requested size.
    let mut out = Vec::with_capacity(buf.len());
    let mut i = 0;
    while i < buf.len() {
        let end = (i + 1024).min(buf.len());
        out.extend_from_slice(&buf[i..end]);
        i = end;
    }
    out
}
EOF

cat > tests/reader.rs <<'EOF'
use calendar::reader::read_chunk;

#[test]
fn reads_entire_buffer_across_chunk_boundaries() {
    let input = vec![7u8; 4096];
    let out = read_chunk(&input);
    assert_eq!(out.len(), 4096, "expected full 4096 bytes, got {}", out.len());
}
EOF

# 2) Unrelated dependency bump
sed -i 's/serde = "1.0.190"/serde = "1.0.197"/' Cargo.toml

echo "Fixture ready at $TARGET"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
git status --short
