# Review response: `src/pricing.py` (branch `feat/cart-totals`)

## Triage summary

| # | Comment | Verdict | Action |
|---|---------|---------|--------|
| 1 | Free-shipping off-by-one (`> 5000` should be `>=`) | **Valid - fix** | Commit `0883fb1` |
| 2 | Loop reinlines `line_total(item)` | **Valid - fix** | Commit `d385cc2` |
| 3 | Cents or dollars? | **Reply only** (question, already documented) | No code change |
| 4 | Rename `cart_total` -> `compute_total` | **Reply only** (subjective; convention not observable in this repo) | No code change |

## Commits made

```
0883fb1 Fix free shipping threshold to include exactly $50.00
d385cc2 Reuse line_total in cart_total loop
```

(Commit style matches the repo: plain imperative subject, no Conventional-Commit prefix, no body - consistent with existing history "Add price formatter", "Add README", "Add pricing module".)

### Verification
- `cart_total([{price:5000, qty:1}])` -> `5000` (free shipping now applies *at* exactly $50.00).
- `cart_total([{price:4999, qty:1}])` -> `5499` (still charges $5.00 below the threshold).
- `cart_total([{price:1000, qty:2}, {price:500, qty:1}])` -> `3000` (multi-item path now goes through `line_total`).

---

## Reply text per thread

### Thread 1 - `shipping = 0 if total > 5000 else 500`
> Good catch, this was a real off-by-one. With `> 5000`, an order of exactly 5000 cents ($50.00) fell through to the `else` and got charged $5.00 shipping, but free shipping is meant to apply *at* $50.00. Changed to `>=` in commit `0883fb1`. Verified that 5000 now returns 5000 (free) while 4999 still adds the $5.00 flat rate.

### Thread 2 - `for item in items:` loop body
> Agreed, that line duplicates `line_total`. Replaced `total += item['price'] * item['qty']` with `total += line_total(item)` so there's a single source of truth for per-line pricing. Done in commit `d385cc2`.

### Thread 3 - "are these prices in cents or dollars?"
> Cents - all money in this module is integer cents. It's noted in the file header comment (`# All money is in integer cents.`) and in the README ("Money is in integer cents throughout"). That's why the free-shipping threshold is `5000` (= $50.00) and the flat rate is `500` (= $5.00). `format_price` does the cents-to-dollars conversion for display.

### Thread 4 - "rename to `compute_total` for consistency"
> Happy to align with the house naming convention, but I couldn't find any other `compute_*` functions in this repo to confirm the pattern - `cart_total` currently sits alongside `line_total`, so `*_total` reads as the local convention here. Could you point me at an example of the `compute_*` naming you'd like me to match? If we do rename, I'd suggest doing it as its own commit (and updating any callers) so it's easy to review separately from the two bug fixes in this PR. Holding off on the rename until we confirm.
