---
title: "Mica on Stock Crystal"
section: "guides/fast-from-the-start"
order: 10
description: "Which Mica regex features work with the stock Crystal compiler and which need crystal-alpha"
---

# Mica on Stock Crystal

Mica is Amber's pure-Crystal regex engine. You can use it with the stock
Crystal compiler through the `mica` shard's own API. Running the standard
library's `Regex` on Mica (`-Duse_mica`) needs crystal-alpha.

## Where the examples go

- `shard.yml` entries go in the application's `shard.yml` under
  `dependencies:`.
- `require "mica"` goes in `src/<app>.cr` or the file that uses it.
- Pattern constants go in the class or module that uses them, under `src/`.
- Build commands run from the application root.

## What works where

| Feature | Stock Crystal 1.21 and later | crystal-alpha with `-Duse_mica` |
|---|---|---|
| `Mica::Regex::Expression`: compile and search with explicit limits | Yes | Yes |
| `Mica::Regex.static`: a pattern compiled while the app builds | Yes | Yes |
| `search_span`, `search_groups`, `each_span`: searches that allocate nothing once warm | Yes | Yes |
| `Mica::Regex::Syntax.check` / `error?`: check a pattern without compiling it | Yes | Yes |
| Your existing `Regex`, regex literals, `=~`, `$~`, `String#match`, `gsub`, `scan`, `split` running on Mica | No: they run on PCRE2 | Yes |
| A regex literal Mica cannot run is a compile error, not a runtime exception | No | Yes |
| No `libpcre2-8` linked into the binary | Only when nothing in the app or its shards uses `Regex` | Yes |

The `mica` shard requires Crystal `>= 1.21.0, < 2.0.0`. `-Duse_mica` is on
crystal-alpha's `incremental-compilation` branch from commit `e61119eb`
(November 21, 2026). The tagged release `1.21.0-incremental-4` predates it.

## Add the shard

**File: `shard.yml` — add under `dependencies:`.**

```yaml
dependencies:
  mica:
    github: amberframework/mica
    version: 0.2.0
```

Then run `shards install` (stock Crystal) or `shards-alpha install`
(crystal-alpha). Commit the `shard.lock` it writes.

## Static patterns: the fastest path on any compiler

`Mica::Regex.static` compiles the pattern while the application builds. Its
search tables become read-only data in the binary, so a search has nothing to
compile, nothing to warm and nothing to allocate.

**File: `src/models/slug.cr` (or wherever the pattern is used).**

```crystal
require "mica"

module Slug
  PATTERN = Mica::Regex.static(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)

  def self.valid?(candidate : String) : Bool
    PATTERN.matches?(candidate)
  end
end
```

The argument must be a regex or string literal known at build time; an
interpolated pattern is a compile error.

Measured on Mica 0.2.0 (412 cases, Apple M1 Max, Crystal 1.21.0, against
Crystal's stdlib `Regex` on PCRE2 10.49 with JIT):

| Step | Static pattern | PCRE2 with JIT | Static pattern is |
|---|---:|---:|---:|
| Warm search (geometric mean) | 20.66 µs | 40.64 µs | 1.97× as fast |
| Compile | 159.3 ns | 3.86 µs | 24× as fast |
| First search | 5.44 µs | 61.31 µs | 11× as fast |
| Compile plus first search in a fresh process | 43.68 µs | 269.96 µs | 6.2× as fast |

## The runtime engine on stock Crystal

`Mica::Regex::Expression` follows `Regex` method for method and adds limits.
Use it for patterns that are only known at run time.

**File: any file under `src/` that searches with a runtime pattern.**

```crystal
require "mica"

DATE = Mica::Regex::Expression.new(
  "(?<year>\\d{4})-(?<month>\\d{2})",
  compile_limits: Mica::Regex::CompileLimits::TRUSTED_PATTERN
)

limits = Mica::Regex::SearchLimits::REQUEST
DATE.match("due 2026-11", limits: limits).try(&.["year"]) # => "2026"
```

On the same 479-case benchmark, the runtime engine against PCRE2 with JIT:

| Step | Mica runtime | PCRE2 with JIT | Mica is |
|---|---:|---:|---:|
| Warm search | 29.85 µs | 72.39 µs | 2.4× as fast |
| Compile | 2.58 µs | 4.38 µs | 1.7× as fast |
| First search | 27.70 µs | 82.39 µs | 3.0× as fast |
| Compile plus first search in a fresh process | 134.19 µs | 305.24 µs | 2.3× as fast |

Those are geometric means. Mica was slower than PCRE2 on 73 of the 479
runtime cases; [Fast from the start](../) lists the pattern shapes behind
those losses.

## What needs crystal-alpha

- **`-Duse_mica`.** Every `Regex` in the app and its shards (Amber, Grant,
  your own code) runs on Mica, and the binary links no PCRE2.
- **The literal check.** Under `-Duse_mica` a literal Mica cannot run, such as
  a lookahead, stops the build with
  `invalid regex for -Duse_mica: lookahead (at 7) is not supported by the Mica
  regex engine` (for `/(\d{3})(?=\d)/`). On stock
  Crystal the same pattern runs on PCRE2 and never reaches Mica.

In a production Amber app, `-Duse_mica` left speed and memory where they were
and made the release binary 1.21× as large (5,018,672 bytes against
4,163,632); the measurements are in [Fast from the start](../).

## Sources

- Mica 0.2.0 release notes: benchmark run at Mica `f0bb0f6`, the tree of
  release commit `a3a3fd60`.
- crystal-alpha `doc/regex_mica.md` at `e61119eb`.
- The static-pattern and `Expression` examples were compiled and run with
  Mica 0.2.0 on stock Crystal 1.22.3 and on crystal-alpha 1.21.0.
