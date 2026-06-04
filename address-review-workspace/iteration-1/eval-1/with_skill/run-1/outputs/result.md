# Address-review: `src/pricing.py` on `feat/cart-totals`

No live PR and no network, so I worked from the four pasted comments: fixed the
valid ones as real commits in the repo's plain-imperative commit style, and
drafted the exact in-thread reply text for each (to be pasted, since these
comments carry no API IDs to reply to programmatically).

## Triage

| # | Comment | Kind | Verdict | Commit |
|---|---|---|---|---|
| 1 | `> 5000` charges shipping at exactly $50.00; should be `>=` | Defect | **Fix + reply** | `5d17ead` |
| 2 | nit: loop body duplicates `line_total(item)` | Suggestion (nit) | **Fix + reply** | `249f1a7` |
| 3 | Question: prices in cents or dollars? | Question | **Reply-only** (already documented) | - |
| 4 | Rename `cart_total` to `compute_total` for codebase consistency | Opinion / naming | **Reply-only** (can't verify the claim; local convention points the other way) | - |

## Commits made

```
5d17ead Apply free shipping at exactly $50.00
249f1a7 Reuse line_total in cart_total
```

- `5d17ead` — changed the shipping threshold from `total > 5000` to
  `total >= 5000` so an order of exactly 5000 cents ($50.00) ships free, as the
  comment on the line intends.
- `249f1a7` — replaced the inlined `item["price"] * item["qty"]` in the loop
  with a call to `line_total(item)`, so the per-line calculation lives in one
  place.

(The branch also carries a pre-existing `6469c25 Add price formatter` commit
that was already there before this review work; it is unrelated to these
comments and untouched.)

## Reasoning on the two reply-only verdicts

- **#3 (cents/dollars):** Not a defect or a change request, just a question.
  The code already answers it: the module header says "All money is in integer
  cents" and the inline comment reads "$50.00 ... $5.00". No code change needed;
  point the reviewer at those lines.
- **#4 (rename):** This is a naming/opinion call justified by "consistency with
  the rest of our codebase," but nothing in this repo uses a `compute_*`
  convention — the two existing functions are `line_total` and `cart_total`, a
  `*_total` convention that a `compute_total` rename would actually break.
  Renaming a public function is also a breaking change for any caller. Per the
  skill, I don't cave on an unverifiable change just to close the thread; I reply
  asking for the specific reference and note the local convention, leaving the
  decision to the reviewer.

## Exact replies to post

**Thread 1 — shipping boundary (`shipping = 0 if total > 5000 else 500`):**

> Right - free shipping should include the $50.00 order itself, so `>=` now and a 5000-cent cart ships free. Fixed in 5d17ead.

**Thread 2 — loop body nit (`for item in items:`):**

> Done - the loop now calls `line_total(item)` instead of repeating the `price * qty` math. Fixed in 249f1a7.

**Thread 3 — cents or dollars (`cart_total`):**

> Cents. Everything in this module is integer cents - the header comment on line 1 ("All money is in integer cents") and the inline note on line 11 ("$50.00 ... $5.00") spell out the thresholds. `format_price` is the only place that divides by 100 to render dollars.

**Thread 4 — rename `cart_total` to `compute_total` (`cart_total`):**

> Which functions is `compute_*` the convention for? In this module the two functions are `line_total` and `cart_total`, so a `*_total` suffix reads as the local pattern, and `cart_total` is a public entry point so renaming it would break existing callers. Happy to rename if there's a broader `compute_*` convention I'm not seeing - can you point me at an example?
