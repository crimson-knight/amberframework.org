---
title: "Fast from the Start"
section: "guides"
order: 88
is_section: true
description: "The compiler, regex patterns, settings and build flags that give an Amber V2 app its best speed and memory from day one"
---

# Fast from the Start

This page lists what to do on day one so an Amber V2 app is fast and small
from its first deploy. Every recommendation comes with the measurement behind
it. Most of them are already the default in an app from Amber CLI 2.0.12; the
page says what each default does, so you keep it when you change things.

## The checklist

| Step | What to do | Measured effect |
|---|---|---|
| 1 | Build with crystal-alpha and `-Duse_mica` | No PCRE2 linked and linear-time searches; a production app ran at the same speed and memory, with a binary 1.21× as large |
| 2 | Write regex patterns that hit Mica's fast paths | Static patterns compile 24× as fast as PCRE2 and search 1.97× as fast |
| 3 | Keep `session.store: signed_cookie` | 875 MiB after 90 s with server-side sessions on beta.11, 14.9 MiB with cookie sessions |
| 4 | Compress through `Amber::Pipe::Compression` | 299,887 bytes per compressed page down to 23,050 |
| 5 | Keep the 8 MiB starting heap, and raise it per environment only when CPU matters more than memory | Every route at 15.0 to 16.8 MiB peak; 16 MiB costs 8.2 to 8.8 MiB more |
| 6 | Run production at the `info` log level | GET / at 27,007 req/s, against 18,307 req/s at `debug` |
| 7 | Use the asset tag helpers with logical paths | 6,640 fewer bytes per rendered page, 24.6 µs down to 17.7 µs of CPU |
| 8 | Keep the request-body limits and the compressed-body refusal | A 1 MiB gzip body is refused in 0.001 s instead of inflating to 1 GiB |
| 9 | Build releases with `--release --no-debug` | A page route 2.9× as fast as a development build; 2.5% smaller binary without debug info |

## Where the examples go

- Environment settings go in `config/environments/<env>.yml` under the
  section each example names. Each one also has an `AMBER_*` environment
  variable for a one-off override.
- Pipes go in `config/routes.cr`, inside the existing `pipeline` blocks.
- Pattern constants go in the class or module under `src/` that uses them.
- Build commands run from the application root.

## How these numbers were measured

Unless a section says otherwise: an app from `amber new -d sqlite` with a
`Post` scaffold and 50 seeded rows, built with `crystal-alpha build --release`
(Crystal 1.21.0, LLVM 21.1.8) on an arm64 Mac, served in production mode by
one process, and loaded with `oha` at 32 connections for 15 to 30 seconds.
Variants ran interleaved (A, B, B, A) so a busy machine slowed both sides
alike. Requests per second moved with the machine's load; bytes per request,
CPU time per request and peak memory are the steadier figures.

## 1. Build with crystal-alpha and `-Duse_mica`

**Run from: the application root.**

```bash
crystal-alpha build --release --no-debug -Duse_mica src/my_app.cr -o bin/my_app
```

`-Duse_mica` runs Crystal's standard `Regex` on Mica, Amber's pure-Crystal
regex engine. Regex literals, `=~`, `$~`, `String#match`, `gsub`, `scan` and
`split` keep their API. Every search runs in time linear in its input, and
the binary links no PCRE2. On the 13 catastrophic-backtracking pattern
families in Mica's ReDoS set, Mica finished every input size up to 1 MiB
within the 1 s deadline, growing linearly; PCRE2 with JIT hit its match or
stack limit on 10 of the 13 and timed out on one.

### What it changed in a real app

We built a production Amber V2 app both ways: the license and checkout
server behind Scribe Pro (Amber 2.0.0-beta.7 with Grant and SQLite; forms
with CSRF and sessions, a JSON API that verifies and signs Ed25519 tokens and
writes audit rows, static files). Same compiler (crystal-alpha `e61119eb`),
same flags (`--release --no-debug`), six interleaved pairs per route at 32
connections. CPU time per request is the steadiest figure on a shared machine:

| Route | CPU per request, PCRE2 | CPU per request, Mica | Mica is |
|---|---:|---:|---|
| GET / (home page with forms) | 56.1 µs | 53.3 µs | the same: 0.99× the time (95% interval 0.91 to 1.10) |
| GET /?ref=… (link tag checked by a regex) | 55.4 µs | 58.3 µs | the same: 1.05× the time (0.96 to 1.15, 3 pairs) |
| GET /checkout/cancel (page plus an audit row) | 626.8 µs | 611.0 µs | the same: 0.99× the time (0.94 to 1.04) |
| GET /css/app.css (static file) | 47.5 µs | 50.2 µs | the same: 1.00× the time (0.96 to 1.09) |
| POST /licenses/activate (JSON, Ed25519, SQLite writes) | 1,290 µs | 1,333 µs | the same: 1.04× the time (0.98 to 1.17) |
| POST /licenses/refresh (JSON, Ed25519, SQLite writes) | 1,509 µs | 1,497 µs | the same: 0.99× the time (0.91 to 1.12) |

| Whole app | PCRE2 | Mica | Mica is |
|---|---:|---:|---|
| Bytes allocated per request | 3,780 to 61,510 by route | within 0.1% on every route | the same |
| Peak memory under load (medians) | 18.4 to 82.1 MiB by route | within 1% on every route | the same |
| Memory at idle | 11.09 MiB | 11.16 MiB | the same |
| Start to first answered request (20 starts each) | 18.1 ms | 16.1 ms | the same, within the 2 ms polling step |
| Release binary | 4,163,632 bytes | 5,018,672 bytes | 1.21× as large (+835 KiB) |
| `libpcre2-8` linked | yes | no | |

Regex work is a small part of this app's requests, so the engine does not
show in its throughput. What changes is the guarantee: every pattern in the
app and its shards searches in linear time, and the binary carries its own
engine instead of linking PCRE2. The app's own spec suite passed on both
engines: 370 examples, 0 failures.

`-Duse_mica` needs crystal-alpha built from the `incremental-compilation`
branch at commit `e61119eb` (November 21, 2026) or later. On the stock Crystal
compiler, use the `mica` shard directly: see
[Mica on stock Crystal](mica-on-stock-crystal/).

## 2. Regex patterns that hit Mica's fast paths

### Write patterns as literals

A regex literal is parsed once, and under `-Duse_mica` the compiler checks it
against Mica while it builds. A pattern Mica cannot run stops the build
instead of raising the first time a request reaches it; for
`/(\d{3})(?=\d)/` the compiler says:

```text
Error: invalid regex for -Duse_mica: lookahead (at 7) is not supported by the Mica regex engine; see doc/regex_mica.md for rewrites
```

**File: any file under `src/`.**

```crystal
struct LicenseTokenPayload
  MACHINE_ID_DIGEST = /\A[0-9a-f]{64}\z/

  getter machine_id_digest : String

  def initialize(@machine_id_digest : String)
  end

  def has_a_valid_machine_id_digest? : Bool
    MACHINE_ID_DIGEST.matches?(machine_id_digest)
  end
end
```

Mica keeps the 256 most recently compiled patterns and reuses them, so a
pattern built at run time from the same text is compiled once. A pattern
built from a different string on every request (`/#{params["name"]}:/`) is
compiled every time. With that cache switched off, `crystal docs` took about
twice as long on Mica (66.4 s against 34.3 s), because the doc generator
rebuilds interpolated patterns for every item. Keep request data out of
pattern source and compare it in Crystal instead (`==`, `starts_with?`,
`includes?`).

### Use `Mica::Regex.static` on the hottest patterns

For a pattern on every request (a route constraint, a token format), compile
it while the app builds. Its searches allocate nothing and have nothing to
warm.

**File: the class that validates the value, under `src/`.**

```crystal
require "mica"

module Downloads
  BUILD_ID = Mica::Regex.static(/\A[0-9]+\z/)

  def self.build_id?(candidate : String) : Bool
    BUILD_ID.matches?(candidate)
  end
end
```

Against PCRE2 with JIT, over 412 cases: compile 24× as fast (159.3 ns
against 3.86 µs), first search 11× as fast (5.44 µs against 61.31 µs), warm
search 1.97× as fast (20.66 µs against 40.64 µs). This works on stock
Crystal too.

### Shapes Mica searches fastest

| Pattern shape | Why it is fast |
|---|---|
| Starts with literal text: `/ERROR \d+/`, `/\/api\/v1\//` | A byte scan jumps to each place the literal starts |
| Anchored at the start: `/\A[a-z0-9-]+\z/` | One forward pass, no reverse scan |
| A fixed list of words joined by alternation, such as HTTP method names | Searched as literals, no automaton at all |
| Anchored at the end: `/\.json\z/` | Searched backward from the end of the text |
| One way to match each group: `/(\d{4})-(\d{2})-(\d{2})/` | Captures come from one pass |

On Amber's own pattern groups (routes, logs, markdown, templates, identifiers,
CSV, contacts), measured in two runs, the runtime engine's warm search ranged
from 1.007× slower (contacts, in one run) to 1.56× as fast as PCRE2 with JIT,
and compile plus first search in a fresh process from 1.46× to 2.29× as fast.

### Shapes that are slower than PCRE2

These measured slower than PCRE2 with JIT in Mica's benchmark (both runs of
round 9, November 20, 2026):

| Shape | Example | Mica is |
|---|---|---|
| Captures over long free text | extracting fields from unstructured logs | 7.3× slower (656.17 µs against 89.50 µs) |
| Many captures on a short line | a backtrace-frame pattern on 1 KiB | 3.9× slower (12.88 µs against 3.33 µs) |
| Counting single Unicode letters, `\p{L}` one at a time | | 3.7× slower (31.26 ms against 8.48 ms) |
| Overlapping `\b\w+\b` words in Cyrillic text | | 2.2× slower (3.82 ms against 1.71 ms) |

For each one, match the smallest span that decides the question: a literal
prefix, a `\A` anchor or an ASCII class (`[A-Za-z0-9_]` in place of `\w`) when
the input is ASCII.

### Rewrites for syntax Mica does not run

Backreferences and lookaround need backtracking, which Mica does not do. Under
`-Duse_mica` a literal that uses one stops the build; `Regex.new` with one
raises `Regex::UnsupportedSyntaxError`. Each has a rewrite:

**Lookahead.** Amber's number helper used to group digits with
`/(\d{3})(?=\d)/`. Match the groups and decide in Crystal:

```crystal
# Before (needs lookahead):
#   digits.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse
def with_delimiters(digits : String) : String
  digits.reverse.scan(/\d{1,3}/).map(&.[0]).join(",").reverse
end
```

**Negative lookahead.** `/^(?!admin)\w+$/` becomes a plain match plus a check:

```crystal
def ordinary_username?(name : String) : Bool
  name.matches?(/\A\w+\z/) && !name.starts_with?("admin")
end
```

**Lookbehind.** `/(?<=\$)\d+/` becomes a capture of the context:

```crystal
if price = "total: $42".match(/\$(\d+)/)
  price[1] # => "42"
end
```

**Backreference.** `/\b(\w+) \1\b/` (a doubled word) becomes a split and a
comparison of neighbors:

```crystal
def doubled_word?(text : String) : Bool
  text.split(/\s+/).each_cons(2).any? { |pair| pair[0] == pair[1] }
end
```

**`\K`.** `/price=\K\d+/` becomes a group: `/price=(\d+)/`, then use `[1]`.

**Atomic groups and possessive quantifiers** (`(?>…)`, `a++`): drop them.
Mica never backtracks, so they have nothing to prevent.

## 3. Sessions: keep them in the cookie

**File: `config/environments/production.yml` — the generated `session:` section.**

```yaml
session:
  key: "my_app.session"
  store: "signed_cookie"
```

From Amber 2.0.0-beta.12, `signed_cookie` and `encrypted_cookie` keep the
session in the visitor's cookie and nothing on the server. Through beta.11,
every store kept sessions in server memory, and the flash pipe wrote one for
every visitor, so each cookieless request (crawlers, monitors, load
generators) left about 413 bytes behind for two weeks.

| `:web` route, 32 connections, cookieless clients | Req/s | Peak memory | Live after a forced collection |
|---|---:|---:|---:|
| beta.11, 30 s | 25,904 | 448.6 MiB | 308.7 MiB |
| beta.11, 90 s | 21,528 | 875.1 MiB | 709.0 MiB |
| beta.12, `store: signed_cookie`, 30 s | 32,782 | 13.8 MiB | 4.1 MiB |
| beta.12, `store: signed_cookie`, 90 s | 32,550 | 14.9 MiB | 4.2 MiB |
| beta.12, `store: adapter`, 30 s | 28,985 | 15.6 MiB | 4.2 MiB |

Cookie sessions must fit in 4,096 bytes and the visitor can read (not change)
a `signed_cookie` session. When you need sessions on the server, set
`store: adapter`; the memory adapter then keeps at most
`session.max_memory_sessions` (10,000 by default) and drops the one used
longest ago. Several processes or servers need a shared adapter: see
[Session adapters](../adapters/sessions/).

Public read pages do better still without a session at all. In an app from
Amber CLI 2.0.11, GET / served from the page cache on the session-free
`:lean_read` pipeline peaked at 23.9 MiB at 65,529 req/s, against 441 MiB at
25,206 req/s on beta.10's `:web` pipeline: 2.6× as fast and 1/18 of the memory.

## 4. Compress through `Amber::Pipe::Compression`

**File: `src/pipes/compressed_response_pipe.cr` — the generated pipe.**

```crystal
# Gzips a pipeline's responses for clients that accept it.
class CompressedResponsePipe < Amber::Pipe::Compression
end
```

Crystal's `HTTP::CompressHandler` builds a new zlib stream for each
response, about 270 KB from the collected heap. `Amber::Pipe::Compression`
(beta.12) writes the same bytes from a small pool of streams allocated outside
that heap.

| Route, 16 MiB heap | Metric | `HTTP::CompressHandler` | `Amber::Pipe::Compression` |
|---|---|---:|---:|
| GET full page, gzipped | Bytes allocated per request | 299,887 | 23,050 (1/13) |
| | CPU per request | 62.1 µs | 55.7 µs |
| | p50 latency | 2.05 ms | 1.86 ms |
| POST /posts (form, CSRF, 302) | Bytes allocated per request | 309,965 | 33,112 (1/9) |
| | CPU per request | 84.7 µs | 74.7 µs |

An app made before Amber CLI 2.0.12 changes its generated
`CompressedResponsePipe` to the subclass above.

## 5. The starting heap: 8 MiB, tuned per environment

**File: `config/environments/production.yml` — under `server:`.**

```yaml
server:
  gc_initial_heap_mib: 8
```

The garbage collector fills its starting heap before it collects, so this one
number trades memory against CPU. Apps from Amber CLI 2.0.12 start at 8 MiB.
Measured at 32 connections, the same app at 8 and 16 MiB:

| Route | Peak memory, 8 / 16 MiB | CPU per request, 8 / 16 MiB | p50, 8 / 16 MiB |
|---|---:|---:|---:|
| GET / (page cache) | 15.22 / 23.45 MiB | 16.0 / 15.4 µs | 0.54 / 0.53 ms |
| GET /api/posts (JSON, 50 rows) | 15.45 / 24.00 MiB | 98.1 / 82.5 µs | 3.91 / 3.09 ms |
| POST /posts (form, CSRF) | 16.81 / 25.59 MiB | 101.3 / 85.8 µs | 4.10 / 3.33 ms |
| GET /posts/new (form, gzip) | 15.03 / 23.67 MiB | 64.8 / 63.0 µs | 2.33 / 2.40 ms |

- **Small server, memory first:** keep 8 MiB. Every route stays under 17 MiB.
- **Allocation-heavy JSON or form routes, CPU first:** at 16 MiB the JSON and
  POST routes used 15 to 16% less CPU per request (98.1 to 82.5 µs, 101.3 to
  85.8 µs) for 8.2 to 8.8 MiB more memory.
- **Below 8 MiB:** at one connection the JSON route used 204 µs (0 MiB) and
  188 µs (4 MiB) of CPU per request against 178 µs at 8 MiB, and at 32
  connections memory was no lower: POST peaked at 17.1 MiB (0 MiB) and
  15.9 MiB (4 MiB) against 16.7 MiB at 8 MiB.

Set a different value per environment in each `config/environments/<env>.yml`,
or for one process with `AMBER_SERVER_GC_INITIAL_HEAP_MIB=16`.

## 6. Log at `info` in production

Keep the production process at Crystal's default log level, `info`.
`Amber::Pipe::Logger` writes its request lines at `debug`, so at `info` they
are filtered out, and from beta.12 the pipe then allocates nothing: before, it
built every line anyway, about 11.8 KB per request.

| Same page through the Logger pipe | Before beta.12 | beta.12 |
|---|---:|---:|
| Bytes allocated per request | 34,610 | 22,752 |
| Req/s, 32 connections | 14,284 | 19,188 |
| p50 latency | 1.12 ms | 0.79 ms |

Turning `debug` on costs real throughput: in the Post app, GET / served 27,007
req/s at `info` and 18,307 req/s at `debug` (1.48× slower), and each 30-second
run wrote 20 to 40 MB of log lines. Crystal binds every log source at `info`
unless the app calls `Log.setup`, and Amber V2 does not bind
`logging.severity` from the environment file to it. To debug one deploy, add
the initializer below and start that process with `LOG_LEVEL=DEBUG`.

**File: `config/initializers/log_level.cr` — create it only when you need debug lines.**

```crystal
Log.setup_from_env
```

## 7. Asset tags

**File: `src/views/layouts/application.ecr`.**

```erb
<%= stylesheet_link_tag "stylesheets/app.css" %>
<%= javascript_importmap_tag({"app" => "javascript/app.js"}, preload: ["javascript/app.js"]) %>
<%= favicon_tag "images/favicon.svg" %>
```

From beta.12 these helpers render each tag once per asset manifest and return
the stored HTML on later calls. A tag with extra attributes, or a public URL
(`/…`, `https:`, `data:`), is rendered every time, so pass logical paths for
the tags on every page.

| Full page render (view, layout, three tags), 16 MiB heap | Before | beta.12 |
|---|---:|---:|
| Bytes allocated per request | 22,752 | 16,112 |
| CPU per request | 24.6 µs | 17.7 µs |
| Req/s, 32 connections | 20,082 | 25,046 |

## 8. Request-body limits

**File: `config/environments/production.yml` — add a `params:` section only to change a default.**

```yaml
params:
  max_form_body_bytes: 8388608        # 8 MiB, the default
  max_document_body_bytes: 8388608    # JSON, CBOR and COSE bodies; 8 MiB
  max_multipart_body_bytes: 134217728 # 128 MiB
  max_file_bytes: 67108864            # one upload, 64 MiB
```

Every limit has a default, so an app that never mentions `params:` is
covered. A body over its limit gets `400 Bad Request` before Amber allocates
for it. Lower the limits to what your forms and APIs really accept; each one
also has an `AMBER_PARAMS_<KEY>` override.

From beta.12, a request with a compressed body (`Content-Encoding: gzip`) gets
`415 Unsupported Media Type` before routing, because Crystal before 1.21.1
inflates such bodies with no size limit. Measured: a 1,043,656-byte gzip body
inflated to 1,073,741,824 bytes inside the server in 0.196 s; with the
refusal, on the same compiler, it was answered 415 in 0.001 s and the
handler never read a byte. Leave
`params.accepts_encoded_request_bodies` off unless clients really upload
compressed bodies, and then bound the body yourself.

## Build flags for release

**Run from: the application root, on the build machine or in the release image.**

```bash
crystal-alpha build --release --no-debug -Duse_mica src/my_app.cr -o bin/my_app
```

Measured on the same license-server app, all three builds with `-Duse_mica`:

| Build | Binary | CPU per request, GET / | CPU per request, POST /licenses/activate |
|---|---:|---:|---:|
| `--release --no-debug` | 5,018,672 bytes | 53.1 µs | 1,383 µs |
| `--release` (debug info kept) | 5,149,696 bytes, plus an 8,393,202-byte `.dwarf` file | | |
| no `--release` (a development build) | 16,966,560 bytes | 154.3 µs | 1,579 µs |

- **`--release`** made the page route 2.9× as fast in CPU per request and
  the database-bound JSON route 1.14× as fast, with a binary 1/3.4 the size.
  A development build is for development: it compiled in 10 s here against
  73 to 137 s for a release build on the same busy machine.
- **`--no-debug`** leaves out debug information: 131,024 bytes (2.5%) off the
  binary and no 8 MiB `.dwarf` file beside it on macOS. Keep debug info only
  when you need symbolized crash traces from production.
- Keep the flags the app already passes everywhere (this app's
  `.crystal-flags` holds `-Dwithout_mt`) the same in development, specs and
  release, so the binary you test is the binary you ship.

## Sources

Every number on this page comes from a measured run with its harness and raw
results kept beside the report:

- Real-app `-Duse_mica` results: the Scribe license server benchmark of
  November 22, 2026 (app commit `768b51d`, crystal-alpha `e61119eb`, six
  interleaved pairs per route, 95% bootstrap intervals of the paired ratios).
- Mica 0.2.0 regex benchmark (Mica release notes, harness at Mica `f0bb0f6`)
  and Mica round 9 (November 20, 2026) for the per-case losses.
- Sessions: amberframework/amber#1455. Compression: #1457. Logger: #1456.
  Asset tags: #1458. Starting heap: amberframework/amber_cli#60.
- The `:lean_read` page cache and the beta.10 `:web` comparison: Amber's
  November 20, 2026 home-page memory diagnosis.
- Debug logging cost: the beta.10 and beta.11 full-stack comparison of
  November 19, 2026.
- Compressed request bodies: the crystal-alpha security backport verification
  of November 20, 2026 (Amber at `db598ff4` with PR #1454).
