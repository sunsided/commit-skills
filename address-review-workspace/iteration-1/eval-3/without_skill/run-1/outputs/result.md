# Address-review result: feat/stats-helpers

Repo: `/tmp/eval-ar-q-base1` (branch `feat/stats-helpers`, base `main`)
No live PR, no network, no `gh`, nothing pushed. Commit style: Conventional Commits (`feat(stats):`, `docs:`, `fix(stats):`).

## Per-comment triage

### Comment 1 — `return sum(values) / len(values)` in `average`
> "Question: what happens if `values` is empty here?"

**Verdict: VALID — real bug, fixed with a commit.**

Answer to the question: with an empty input, `sum([])` is `0` and `len([])` is `0`, so the expression is `0 / 0`, which raises a `ZeroDivisionError` ("division by zero"). That is an opaque, non-actionable failure for the caller. Fixed by guarding the empty case and raising a clear `ValueError`, matching the convention used by `statistics.mean()`.

- Commit: `ce87c43` — `fix(stats): guard average against empty input`

Note: `median()` (added earlier on this branch in `7f281e6`) has an analogous empty-input issue (`IndexError`). The review comment scoped the question to `average` only, so it was not changed here; flagged for visibility.

### Comment 2 — module overall
> "Nice, clean little module 👍"

**Verdict: PRAISE — no action, no code change, no commit.**
A short acknowledgement reply is appropriate; nothing to fix.

## Commits made

| Short SHA | Subject |
|-----------|---------|
| `ce87c43` | `fix(stats): guard average against empty input` |

## Exact reply text per thread

**Thread 1 (empty `values` in `average`):**
> Good catch. With an empty sequence this was `sum([]) / len([])`, i.e. `0 / 0`, which raises a bare `ZeroDivisionError` — not great for the caller. Fixed in `ce87c43`: `average()` now raises `ValueError("average() requires at least one value")` for empty input, matching how `statistics.mean()` behaves.

**Thread 2 (praise):**
> Thanks! 🙏
(Pure praise — no code change required.)
