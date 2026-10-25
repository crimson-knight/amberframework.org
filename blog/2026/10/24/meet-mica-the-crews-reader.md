# Meet Mica: the crew's reader

Amber has a crew: Amber owns the web application, Grant owns records, and
Gemma owns files. Today a fourth member joins them. Mica is the crew's reader,
and she owns the boundary where bytes from the outside world become data the
application can trust.

## Why Mica exists

We want the Amberverse to rely on something that is entirely its own.

Parsing is where that matters most. Every request body, uploaded document,
storage listing, and configuration file passes through a parser before any
application code sees it. A good parser is more than a loop over bytes. It
carries the knowledge that published standards define, such as XML 1.0,
Namespaces, and the formats that come next. It also carries years of
hard-won lessons from real-world CVEs and security testing: entity
expansion bombs, documents that quietly reach out to the network, inputs built
to make a parser do quadratic work.

Mica stands for that knowledge and that wisdom, owned by the Amberverse instead
of borrowed from a C library we cannot steer.

## Who she is

Mica is the crew's reader. A parser reads anything; reading anything means
reading every language; and languages live in books. So Mica is bookish: round
brass reading glasses with a fine crosshair etched into the left lens, her
reading loupe; soft silver hair that fades to ink-blue tips, with a ribbon
bookmark tied in a bow; a short capelet of three pearly layers like fanned
pages; an open ink-blue book held to her chest; and a satchel of spare
volumes with their ribbons hanging out. A brass stylus rides behind her ear.

Her bookishness is the reading of knowledge. Her calm is the steadfast
reliability of an experienced professional. Mica never guesses at what a
document meant. She reads what is there, in order, and when something breaks,
she names the exact place:

> "Line 3, column 17. Everything before it reads clean."

When a document points somewhere else, she does not go and fetch it. She keeps
that page closed, labels it, and tucks it into her satchel:

> "That one points elsewhere. I'll leave it closed and labeled."

She has a place with each of the crew. Amber hands her the messy envelopes that
arrive at the front office, and Mica returns clean rows to route. Grant files
the rows Mica sorts; between the crew's two precise people, nothing is wasted.
When Gemma pops open a crate of S3 storage listings, Mica catches the XML on
her open page before it touches the ground. And Crys, the Crystal language's
crow, likes to perch on the top edge of her book, because Mica is Crystal all
the way down.

## A concrete example: the last C library on the request path

Today's supply-chain audit of the Amber stack started from one goal: an Amber
application that depends on nothing but the Crystal compiler tools, plus SQLite
or another native library that is truly unavoidable.

The audit found libxml2 as one of the last C libraries in an Amber V2
application's runtime path. Two things pulled it in. Amber V2's schema API
parsed `application/xml` request bodies with Crystal's own `XML` module, which
binds libxml2, so any client could hand the server an XML document to parse.
Gemma's S3 storage pulled it in a second way, through the `awscr-s3` shard.

libxml2 has a long CVE history, with more entries in 2026, and its own
README now says it is not recommended for processing untrusted data. XML itself
carries features such as external entities and DTDs that point at other files
and URLs, which can turn a parser into something that fetches from the network.

Three changes answer that:

- **Amber stops parsing XML by default.** Draft pull request
  [amberframework/amber#1414](https://github.com/amberframework/amber/pull/1414)
  removes the libxml2-backed parser and adds
  `ParserRegistry.register_body_parser`, so an application opts in to XML
  bodies with one call at boot. See [Request formats](/docs/v2/guides/schema-api/parsers)
  for the current formats and the pending change.
- **Gemma drops the XML dependency.** Draft pull request
  [crimson-knight/gemma#4](https://github.com/crimson-knight/gemma/pull/4)
  replaces `awscr-s3` with Gemma's own S3 client, built on stdlib OpenSSL and
  HTTP, which parses no XML at all.
- **Mica becomes the Amberverse's own XML parser.** She is a pure-Crystal
  XML 1.0 and Namespaces 1.0 library with a streaming reader, a DOM, a builder,
  and XPath 1.0. She links no C library, fetches nothing from the network or
  disk while parsing, and stops at the first malformed byte with its exact line
  and column. When she ships, she is the planned XML parser for that opt-in hook.

What we measured on Mica's first complete version:

- **Conformance:** on the W3C XML Conformance Test Suite, Mica passes 1,914 of
  the 1,915 scored XML 1.0 and Namespaces 1.0 cases. libxml2, run strictly on
  the same cases, passes 1,889.
- **Fuzzing:** 1,520,000 seeded mutation cases ran with zero crashes.
- **Speed:** Mica was faster than libxml2 on all 11 benchmark workloads, by
  1.2x to 3.2x in median throughput. Streaming a 10 MB S3 ListObjects listing,
  for example, ran at 272.8 MB/s against 110.3 MB/s.
- **Memory:** building a document from the larger inputs peaked 2.2x to 3.1x
  lower; the 50 MB document peaked at 207 MB against 525 MB. The streaming
  reader is the one place Mica trails, peaking 0.1 to 0.3 MB higher on four
  of five inputs.

Those numbers come from release builds on an Apple M1 Max, with libxml2 run
under strict options and matching checksums proving both did the same work. The
machine was heavily loaded during the run, so the medians are noisy; the
slowest result, 1.2x, came from a run hit by load spikes, and its best time put
Mica about 2.2x ahead.

Mica is in development and not yet released. A hardening pass is under way
before her first public version.

## What comes next: the parsing family (planned)

XML is Mica's first book, not her last. Her role is to read and verify
untrusted input exactly as the published standards define it, and to carry the
CVE lessons behind each check. Each new format is held to the same rules as
XML: no C libraries, no regular expressions inside parsers, work that stays
linear in the input, and precise errors on hostile bytes.

**Everything below is planned. Today, only the XML library exists, and it is
not released yet.**

- **HTTP messages:** chunked framing, cookies (RFC 6265), multipart bodies
  (RFC 7578), headers, content types, and request limits. Mica reads every
  request before Amber routes it.
- **URLs and hostnames:** RFC 3986 and WHATWG URL parsing, IDNA and punycode,
  and look-alike characters.
- **Signed and encoded tokens:** JOSE, JWT and JWS, COSE, PEM, ASN.1 DER, and
  X.509. She checks the seal before she reads the payload.
- **Text:** UTF-8 validation, Unicode normalization, and confusable characters.
- **The writing side:** output escaping for HTML, attributes, URLs, and
  headers, plus HTML and Markdown sanitizing. What she writes reads back the
  same.
- **Archives and media headers:** gzip, zip with limits against zip-slip paths
  and decompression bombs, and MIME and image-header sniffing. Gemma stores the
  file; Mica reads what is really inside it.
- **Patterns:** Mica::Regex, a linear-time regular-expression engine in pure
  Crystal.
- **Security testing as a practice:** she keeps the conformance suites
  (xmlconf today, Bowtie for JSON Schema later), the fuzz corpora, and the
  record of the CVE lesson behind each check.

Her boundary stays narrow on purpose. Mica reads and verifies; Amber, Grant,
and Gemma decide what to do with the data. Authorization policy and
cryptographic primitives stay outside her role.

Each format keeps the same book. Only the glyph on the tiles changes: angle
brackets for XML, braces for JSON, two hex digits for CBOR, a wax seal for a
COSE envelope.

> "Signature checks out. Now we read the payload."

So: meet Mica. Then send her something hard to read.

- [Meet Mica](/characters/mica)
- [Meet the whole crew](/characters)
- [Request formats in Amber V2](/docs/v2/guides/schema-api/parsers)
