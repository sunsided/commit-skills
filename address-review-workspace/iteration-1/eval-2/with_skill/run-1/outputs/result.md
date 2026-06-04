# Address-review result — `src/config.py` (branch `feat/config-loader`)

No live PR / no network. Worked from the two pasted comments. One real fix
committed; one comment declined with a reasoned reply backed by the code.

## Triage

| # | Comment (location) | Kind | Verdict | SHA |
|---|---|---|---|---|
| 1 | `if raw is None:` in `parse_config` — "None check looks dead, drop the branch and DEFAULT_CONFIG fallback" | Defect report that is **factually wrong** | **Reply-only (decline)** | — |
| 2 | `return json.loads(raw)` — "malformed JSON raises unhandled JSONDecodeError, takes service down on boot" | Defect | **Fix + reply** | 6b5765b |

## Reasoning

**Comment 1 — decline.** The premise ("callers always hand us a JSON string")
is false. The only caller, `loader.load`, routes through
`loader.read_optional`, which returns `None` when the config file does not
exist (`src/loader.py:8`), and `load` passes that `None` straight through to
`parse_config` (`src/loader.py:13-15`, with a comment saying exactly that).
The `None` branch is the live "missing config file -> defaults" path, not dead
code. Dropping it would make a missing config file raise
`TypeError: the JSON object must be str... not NoneType` from `json.loads(None)`
— turning a graceful default into a crash. So this is a reply-only decline,
pointing at the lines that demonstrate the current behavior.

**Comment 2 — fix.** Correct and important: `json.loads(raw)` on a malformed
config file raises `json.JSONDecodeError` (a `ValueError` subclass) that nothing
catches, crashing the service on boot. Fixed by wrapping the parse and raising a
typed `ConfigError` with a clear message, so the failure is explicit at the
config boundary instead of an opaque stack trace. Verified: `None` -> defaults,
valid JSON -> parsed dict, malformed JSON -> `ConfigError`, and
`loader.load` of a missing path still returns defaults.

## Commits

- `6b5765b` — Handle malformed config JSON (Comment 2)

## Exact reply text to post

**Thread 1 — `if raw is None:`**

> The `None` branch isn't dead — it's the missing-config path. `load` calls
> `read_optional`, which returns `None` when the file doesn't exist
> (`src/loader.py:8`), and passes that straight into `parse_config`
> (`src/loader.py:15`). Dropping the branch would make a missing config file
> raise `TypeError` from `json.loads(None)` instead of returning
> `DEFAULT_CONFIG`. Keeping it as-is — happy to revisit if there's a caller I'm
> not seeing that guarantees a non-None string.

**Thread 2 — `return json.loads(raw)`**

> Right, malformed JSON would crash boot with an uncaught `JSONDecodeError`.
> Now wrapped: the parse raises a typed `ConfigError` with a clear message so the
> failure surfaces at the config boundary instead of taking the service down.
> Fixed in 6b5765b.
