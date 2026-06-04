## Title

perf(matcher): cache compiled regexes with a bounded LRU

## Body

## Summary

`Matcher.match` now reuses compiled regex objects instead of recompiling
a pattern's source on every call. Compiled patterns are held in a
per-`Matcher` LRU cache keyed by source string. Behavior is unchanged;
this is purely a performance change.

## Why

Profiling the 1.4.0 release under the production query mix showed
`Matcher.match` recompiling the same handful of patterns on every call -
roughly 38% of request CPU at peak - even though a pattern's source never
changes for the life of a `Matcher`. On the prod query replay, caching
drops p99 match latency from 4.2ms to 0.6ms and takes the matcher off the
CPU profile entirely. Refs: PERF-204.

## Key changes

- Compiled patterns are cached in `Matcher._compiled`, keyed by source
  string, and looked up via the new `_get` helper.
- The cache is an LRU bounded at 512 entries (`_CACHE_MAX`): on insert
  past the bound, the least-recently-used entry is evicted; on hit, the
  entry is moved to the most-recent position.

## Risks

The cache lives on the `Matcher` instance, so long-lived matchers that
compile patterns dynamically (e.g. the search-filter API, which builds a
fresh source per saved filter) would otherwise grow without bound and
leak memory over the process lifetime. The 512-entry LRU bounds that:
512 sits comfortably above the largest distinct-pattern set observed in
prod (~380 for the busiest tenant), so steady-state traffic never evicts,
while a pathological dynamic-pattern caller can no longer leak.

## Review notes

The whole change is in `src/matcher.py`. Start with `_get`
(`matcher.py:12-21`): it's the load-bearing piece - the cache-miss path
compiles and stores, the over-bound branch evicts via
`popitem(last=False)`, and the cache-hit path calls `move_to_end` to keep
LRU ordering correct. Then confirm `match` (`matcher.py:23-27`) is the
only caller and routes through `_get`, so external behavior is identical
to recompiling on every call. The eviction and recency-update logic is
the part worth scrutinizing.
