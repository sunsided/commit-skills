# address-review — src/config.py (branch feat/config-loader)

No live PR / no network. Comments were supplied directly; fixes made as real
commits matching the repo's plain-imperative commit style. Reply text below is
handed back to paste into each thread (no `gh`, nothing pushed).

## Triage summary

| # | Comment (location) | Verdict | Commit |
|---|---|---|---|
| 1 | `if raw is None:` in `parse_config` — "dead None check, drop the branch + DEFAULT_CONFIG fallback" | Reply-only (won't fix — reviewer wrong on the facts) | — |
| 2 | `return json.loads(raw)` — "malformed JSON raises unhandled JSONDecodeError, takes the service down on boot" | Fix + reply (defect) | 452a0b9 |

## Per-comment detail

### Comment 1 — "This None check looks dead… drop the branch and the DEFAULT_CONFIG fallback."

**Verdict: reply-only, won't fix.** The premise ("callers always hand us a JSON
string") is false. `src/loader.py` `read_optional` returns `None` when the config
file does not exist (`if not os.path.exists(path): return None`), and `load`
passes that value straight through: `return parse_config(read_optional(path))`.
So `parse_config(None)` is a live path whenever the config file is absent.
Dropping the branch and `DEFAULT_CONFIG` would make the no-file case hit
`json.loads(None)` and raise `TypeError`, breaking boot for any deployment
without a config file. Pointing at the code rather than arguing.

**Reply text:**

> This path isn't dead — `loader.read_optional` returns `None` when the config
> file is absent (src/loader.py:7-8), and `load` passes that straight into
> `parse_config` (src/loader.py:15). So `parse_config(None)` runs on every boot
> without a config file. Dropping the branch would send `None` into
> `json.loads` and raise `TypeError`, breaking that path, so I'd keep the guard
> and the `DEFAULT_CONFIG` fallback. Happy to revisit if the no-file case is
> meant to be handled elsewhere.

### Comment 2 — "malformed JSON raises an unhandled JSONDecodeError and takes the service down on boot. Please handle it."

**Verdict: fix + reply (defect).** Correct. A config file with malformed JSON
made `json.loads(raw)` raise `json.JSONDecodeError`, which propagated up through
`load` and crashed the service on boot with an opaque traceback. Wrapped the
parse and re-raise as a `ValueError` that names the problem, so boot still fails
fast on a broken file (rather than silently running on surprise defaults, which
a `DEFAULT_CONFIG` fallback here would have masked) but does so legibly.

Fixed in 452a0b9.

**Reply text:**

> Fixed in 452a0b9. `json.loads` now runs in a `try`/`except json.JSONDecodeError`
> and re-raises as a `ValueError` naming the bad file. Boot still fails fast on a
> malformed config rather than masking it behind `DEFAULT_CONFIG`, but with a
> clear message instead of a raw decode traceback.
