# Meet Mica: Amber V2 apps no longer link PCRE2

Make a new Amber app, add a model, build it, and ask your computer what the
finished program needs in order to run. Until today, the list included
libpcre2, a C library for regular expressions, whether or not your own code
ever used one.

As of today it does not. Amber `2.0.0-beta.11`, Grant `0.24.0`,
asset_pipeline `0.38.0` and Amber CLI `2.0.11`, all released on November 20,
2026, produce a default application that links no PCRE2. This is also where
we introduce Mica, the member of the crew who made removing it worth doing.

## What changed today

Amber took regular expressions off its request path in beta.10. In beta.11,
Grant and asset_pipeline follow: the fixed patterns they used internally, for
jobs like reading an import map or finding the imports in a JavaScript file,
are now small hand-written checks. Each one reads its input once, from start
to finish, and is tested to accept and reject the same inputs the old pattern
did.

The result is easy to check. An app made with `amber new -d sqlite` shows no
`libpcre2` in `otool -L` or `ldd` and no `pcre2_` symbol in `nm`, before and
after `amber generate scaffold` adds a Grant model. Amber CLI's CI runs that
check on macOS and Linux, next to a small control program that does use
`Regex` and must show PCRE2, so the check cannot pass by looking in the wrong
place.

A freshly generated beta.11 app is 3,948,720 bytes, which is 31,760 bytes
more than beta.10, and it links no PCRE2.

Your own regular expressions still work. Using `Regex` in your code, or a
feature that takes a pattern, links PCRE2 again, and the
[beta.11 release notes](/releases) list each of those features.

## Why Mica exists

I wanted the Amberverse to rely on its own pieces. Mica is the crew member
who reads: she parses what comes into an application, to published
standards, carrying years of lessons learned from real security failures.
She is calm, precise and a little bookish, which is what you want from the
part of your app that meets untrusted input first.

Regular expressions are a good example of why that matters. An engine that
backtracks, as PCRE2 does, can be handed a pattern and a piece of text that
together take an enormous amount of work to search. On a web server, that is
a request that ties up the server far longer than it should, and enough of
them at once can take it down.

## Mica's regex engine

Mica's regex engine is written in pure Crystal, with no C library underneath.
It is built so that the time a search takes grows in step with the length of
the text, however the pattern is written. Every search also carries a work
budget and a deadline. If a hostile pattern or a hostile input reaches either
one, the search stops with an error instead of holding the request open.

To keep that promise, Mica leaves out the few features that require
unbounded backtracking, such as backreferences and lookaround. Its
documentation lists a rewrite for each one.

Patterns written directly in your source code can take a build-time path:
Mica prepares them when the app is compiled. Those static patterns compile
24× as fast as PCRE2 (159.3 ns against 3.86 µs).

## How fast it is

We did not want to trade speed for safety, so the bar was PCRE2 with its JIT
compiler turned on, which is how Crystal runs it.

The number we watch most is Amber's own: 26 patterns from Amber's routes,
logs, markdown, CSV, templates, identifiers and contact fields, each
searching 64 KiB of text in a freshly started program. There Mica is 1.36×
as fast as PCRE2-JIT: 70.38 µs against 95.86 µs, or 0.734 of PCRE2-JIT's
time. None of the 26 measured slower than PCRE2-JIT.

The full benchmark has 479 cases, sorted into groups by where the patterns
come from, and every group is at or under PCRE2-JIT's time on all four
measures. 112 of the cases are patterns built to make a regex engine hang,
and PCRE2 struggles there, so we report everyday patterns on their own.
These are geometric-mean times (a typical case, so no single outlier decides
the result).

The 263 everyday patterns of the rebar benchmark suite:

| Measure | Mica | PCRE2-JIT | Mica is |
|---|---|---|---|
| Search with a compiled pattern | 63.91 µs | 113.32 µs | 1.77× as fast |
| Compile a pattern | 3.16 µs | 4.60 µs | 1.46× as fast |
| First search of a new pattern | 43.97 µs | 101.17 µs | 2.30× as fast |
| First regex work after an app starts | 172.51 µs | 340.34 µs | 1.97× as fast |

The 104 patterns Amber itself uses:

| Measure | Mica | PCRE2-JIT | Mica is |
|---|---|---|---|
| Search with a compiled pattern | 557.03 µs | 741.63 µs | 1.33× as fast |
| Compile a pattern | 2.00 µs | 4.07 µs | 2.0× as fast |
| First search of a new pattern | 49.89 µs | 197.33 µs | 4.0× as fast |
| First regex work after an app starts | 210.91 µs | 552.64 µs | 2.62× as fast |

On the 112 hang-prone patterns, a search is 8.8× as fast (330.1 ns against
2.91 µs), and Mica always stops on time.

## What shipped since

This post first went out on November 20. Two days later, more of the stack
is Crystal of our own.

**Mica runs `Regex` and `YAML` by default.** In crystal-alpha, from
1.21.0-incremental-6 and in 1.21.0-incremental-8, the current release,
Crystal's own `Regex` and `YAML` run on Mica's engines. Your existing
patterns get Mica's speed without a code change, and a program links neither
PCRE2 nor libyaml. A regex literal that needs backtracking stops the build
with a message that names the fix: rewrite the pattern, or build with
`-Duse_pcre2` to keep PCRE2. `-Duse_libyaml` does the same for YAML.

**YAML parsing is 1.5 to 1.9× as fast as libyaml.** On a corpus of 19 real
files (Kubernetes manifests, GitHub Actions workflows, shard files and
Amber's own configuration), reading YAML events is 1.84× as fast as libyaml
through Crystal's standard `YAML` API, and building values is 1.61× as fast.
Mica passes all 402 cases of the YAML test suite, and 6,000,000 generated
documents parsed the same as libyaml, with 0 disagreements. Writing YAML is
1.26× as fast per file, though the largest file, a 2.1 MB manifest, writes
1.16× slower.

**Gzip without libz.** Mica now compresses and decompresses gzip itself.
Over 93 cases, decompressing is 1.09× as fast as zlib in one call and 1.12×
as fast streamed, though 19 single cases are still up to 1.21× slower in one
call. Compressing is 1.29× as fast as zlib at the default level, with output
within 0.03% of zlib's size. Amber's compression pipe, Grant and
asset_pipeline carry pinned copies of Mica's gzip, and an app built with
`-Dwithout_zlib` links no libz at all while still serving gzipped pages.
That work is merged and comes with the next releases. Their copies were
taken just before these last speed gains, which reach them with the next
copy.

**Beryl's cryptography is at least as fast as OpenSSL.** Beryl, the crew
member who decides who gets in, is the other half of security. Her hashes
and MACs (MD5, SHA-1, the SHA-2 family and their HMACs) are at least as fast
as OpenSSL 4.1.0 in all 42 measurements on an Apple M1 Max, from 1.0× to
2.62× as fast. Her authenticated ciphers (ChaCha20-Poly1305,
XChaCha20-Poly1305, AES-128-GCM and AES-256-GCM, sealing and opening) are at
least as fast in all 32 measurements, from 1.035× to 2.01× as fast. Before
this work, the same ciphers were up to 55.64× slower. Amber's signed and
encrypted cookies now run on Beryl, so an app built with `-Dwithout_openssl`
links no OpenSSL; that change is also merged and comes with the next Amber
release. Amber's copy of Beryl was taken before this speed work, which
reaches Amber when it takes a newer copy. Beryl's own repository is not
public yet.

## What is not done yet

The group results are averages, and some single cases are still slower than
PCRE2-JIT. We are working through them one at a time.

Stock Crystal still runs `Regex` on PCRE2. On it, you can use Mica's engine
directly from the `mica` shard.

Mica's code, including the regex engine and its benchmarks, is public at
[github.com/amberframework/mica](https://github.com/amberframework/mica).
The regex engine ships in
[Mica v0.2.0](https://github.com/amberframework/mica/releases/tag/v0.2.0),
released November 21, 2026.

To try the regex-free default app, install Amber CLI 2.0.11 or later and run
`amber new`. Your app is now 31,760 bytes heavier and one C library lighter.

- [See current releases and dates](/releases)
- [Read Mica's code](https://github.com/amberframework/mica)
- [Meet the whole crew](/characters)
