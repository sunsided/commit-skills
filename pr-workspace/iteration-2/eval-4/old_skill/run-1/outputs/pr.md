perf(matcher): cache compiled regexes with a bounded LRU

## Summary

`Matcher.match` recompiled a pattern's source on every call. This adds a
per-`Matcher` cache of compiled patterns keyed by source string, so each
distinct pattern is compiled once and reused for the life of the matcher.
The cache is an LRU bounded at 512 entries.

## Why

Under the production query mix, profiling the 1.4.0 release showed
`Matcher.match` spending about 38% of request CPU at peak recompiling the
same handful of patterns. On the prod query replay, caching drops p99 match
latency from 4.2ms to 0.6ms and removes the matcher from the CPU profile
entirely. Refs PERF-204.

## Key changes

- `Matcher` now holds an `OrderedDict` cache of compiled patterns, keyed by
  source string, populated lazily in `_get`.
- `match` resolves patterns through `_get` instead of calling
  `re.compile` inline.
- The cache is an LRU bounded at 512 entries: on overflow the
  least-recently-used entry is evicted, and a cache hit moves the entry to
  the most-recent end.

## Risks

The bound exists to stop unbounded growth from callers that build patterns
dynamically (the search-filter API compiles a fresh source per saved
filter), which would otherwise leak memory over a process lifetime. 512 is
chosen to sit above the largest distinct-pattern set observed in prod (~380
for the busiest tenant), so steady-state traffic never evicts; only a
pathological dynamic-pattern caller hits the bound. No public API or
matching behavior changes.

## Review notes

Start with `_get` in `src/matcher.py`: it is the whole change. Confirm the
hit path (`move_to_end`) and the miss path (compile, insert, evict on
overflow with `popitem(last=False)`) are correct, since the LRU semantics
hinge on those two calls. Then check the one-line swap in `match` that
routes through `_get` rather than `re.compile`, and note the cache is
per-`Matcher` instance, so it shares the matcher's lifetime.
