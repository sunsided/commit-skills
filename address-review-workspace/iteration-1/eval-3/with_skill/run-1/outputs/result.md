# address-review result — `feat/stats-helpers`

Mode: offline, working from pasted comments. No live PR, no `gh`, nothing pushed.
The comments carry no programmatic IDs, so replies are handed back as text to paste.

## Per-comment triage

| # | Location | Comment | Verdict | Action |
|---|----------|---------|---------|--------|
| 1 | `src/stats.py` — `return sum(values) / len(values)` in `average` | "Question: what happens if `values` is empty here?" | **Question exposing a defect** | Fix + reply |
| 2 | module overall | "Nice, clean little module 👍" | **Praise / non-actionable** | No reply, no fix |

### Comment 1 — reasoning
A genuine question, but the answer reveals a real bug: when `values` is empty,
`len(values)` is `0`, so `sum(values) / len(values)` raises an uncaught
`ZeroDivisionError`. Per the triage guide, a "what happens if this is empty?"
question is a defect report in disguise — so I both answered it and fixed the gap.

Fix: added an explicit empty-input guard that raises `ValueError`. The mean of an
empty sequence is undefined; raising surfaces the caller's mistake clearly instead
of leaking a bare `ZeroDivisionError` or silently inventing a value. This mirrors
the stdlib `statistics.mean`, which raises `StatisticsError` on empty input.

### Comment 2 — reasoning
Pure praise with no actionable content. The skill says praise gets no reply —
an empty thread beats a reflexive "thanks!". No code change, no reply.

## Commits made

| Short SHA | Subject |
|-----------|---------|
| `c391cbb` | `fix(stats): raise ValueError on empty input in average` |

Matches the repo's existing style: Conventional Commits, subject-only (no body),
since the "why" is self-evident from the subject.

## Exact reply text per thread

**Thread 1** (`average`, empty-input question) — reply with:

> Good question — as written it would have raised `ZeroDivisionError` on an empty
> list, since `len(values)` is 0. Added an explicit guard that raises `ValueError`
> for empty input instead (matching `statistics.mean`'s behavior). Fixed in c391cbb.

**Thread 2** (module praise) — no reply needed.
Non-actionable praise; replying would just clutter the thread.

## Sequencing note
Push must precede posting replies so the bare SHA `c391cbb` auto-links to the
commit on GitHub. In this offline run nothing is pushed and no replies are posted;
the reply above is text for the user to paste once the branch is pushed.
