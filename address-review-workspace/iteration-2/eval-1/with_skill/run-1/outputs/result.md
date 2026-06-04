# Address-review result — `feat/cart-totals` (src/pricing.py)

No live PR / no network. Worked from the four pasted comments. Fixed what was valid as
real commits matching the repo's style (plain imperative subject, no body), and drafted
the exact reply text for each thread. Nothing pushed; no `gh` run.

## Repo commit style

Existing history is plain imperative, short subject, no body:
`Add pricing module`, `Add README`, `Add price formatter`. New commits follow that.

## Per-comment triage

| # | Comment | Kind | Verdict | Fixing SHA |
|---|---------|------|---------|------------|
| 1 | `> 5000` charges shipping at exactly $50.00; should be `>=` | Defect | Fix + reply | `f9ff0f5` |
| 2 | loop body duplicates `line_total(item)` | Suggestion (nit) | Fix + reply | `7141b85` |
| 3 | cents or dollars? | Question | Reply-only (no change) | — |
| 4 | rename `cart_total` → `compute_total` | Opinion | Reply-only, declined | — |

### Reasoning

- **#1 — Defect, fixed.** Money is integer cents (file header + README), so 5000 cents =
  $50.00. The reviewer's intended behavior is free shipping *at* $50.00, but `> 5000`
  charged $5.00 on an order of exactly 5000. Changed to `>=` and updated the now-misleading
  inline comment ("over $50.00" → "at $50.00 and up"). Boundary verified: 5000 → no
  shipping, 4999 → +500.
- **#2 — Suggestion, fixed.** `line_total(item)` is exactly `item["price"] * item["qty"]`,
  so the loop body was a verbatim duplicate. Routed it through `line_total`. Cheap, removes
  the duplication the reviewer flagged.
- **#3 — Question, reply-only.** Answered directly: cents. Already documented at the top of
  `src/pricing.py` (`# All money is in integer cents.`) and in the README. No code change.
- **#4 — Opinion, declined with reasoning.** The repo's actual naming convention is
  `*_total` (`line_total`, `cart_total`). There is no `compute_*` symbol anywhere in the
  codebase (verified by grep), so renaming to `compute_total` would *break* consistency with
  `line_total` rather than improve it. Declined and explained; offered to revisit if there's
  a convention I'm not seeing.

## Commits (mine)

```
7141b85 Use line_total in cart_total loop
f9ff0f5 Fix free shipping threshold to include exactly $50
```

(`13e7cbe Add price formatter` also appears in `main..HEAD` — it is the pre-existing
branch commit that the PR already carried, not part of this review pass.)

## Exact replies to post (one per thread)

SHAs are written bare so GitHub auto-links them once the branch is pushed.

**Thread 1 — `shipping = 0 if total > 5000 else 500`:**

> Fixed in f9ff0f5. It's `>=` now, so an order of exactly 5000 cents ($50.00) gets free
> shipping instead of the flat $5.00. Also updated the inline comment to say "at $50.00 and up".

**Thread 2 — `for item in items:` loop body:**

> Fixed in 7141b85. The loop now calls `line_total(item)` instead of repeating the
> `price * qty` expression.

**Thread 3 — "cents or dollars?":**

> Cents — all money in this module is integer cents (noted at the top of pricing.py and in
> the README). So 5000 is $50.00; `format_price` divides by 100 for display.

**Thread 4 — "rename to `compute_total`":**

> I'd keep `cart_total`. The convention here is `<thing>_total` — it sits right next to
> `line_total`, and there's no `compute_*` name elsewhere in the codebase, so `compute_total`
> would actually read inconsistently against `line_total`. Happy to rename if there's a
> wider convention I'm missing.

## Not done (per task)

- No `git push` and no `gh` calls — there's no PR/network. Replies above are hand-back text.
