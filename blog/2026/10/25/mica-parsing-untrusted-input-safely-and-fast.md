# Mica: Parsing Untrusted Input Safely, and Fast

Every web application reads bytes that strangers send: request bodies, uploaded
documents, storage listings, feeds. Before your code sees any of it, a parser
decides what those bytes mean. That parser is the front door, and for decades
it has also been one of the most reliable places to find a security bug.

Mica is the Amber crew's reader: a pure-Crystal parsing library that reads
untrusted input exactly as the published standards define it. Her first format
is XML, and she has just finished a long hardening pass. The short version:

- **Faster than libxml2 on every workload we benchmarked.** Building a document
  from an S3 storage listing runs at 281 MB/s against libxml2's 219.
- **Less than half the memory.** That same listing peaks at 81 MiB against
  200 MiB; a 50 MB document peaks at 344 MiB against 942 MiB.
- **Standards first.** On the W3C XML conformance suite she passes 1,914 of
  1,915 XML 1.0 cases and all 237 XML 1.1 cases.
- **Built for hostile input.** 2,000,000 fuzz cases, 0 crashes. 67
  linear-time proofs, the worst at a ratio of 4.41 against a bound of 5,
  where quadratic work would score 16.
- **Nothing borrowed.** No C library and no regular expressions inside the
  parser.

This post covers how fast she is, the security lessons she is built around,
and the crewmate who keeps her supply chain honest.

## Why Mica exists

Seth Tucker, Amber's maintainer, put it this way:

> "I wanted something entirely part of the Amberverse to be what we rely on.
> Mica represents a collection of necessary knowledge and tools that have
> defined standards as well as years of lessons (aka wisdom) learned from
> real-world CVE's and other security testing. She represents the reading of
> knowledge as well as the steadfast reliability of an experienced
> professional."

That is the whole design brief. The *knowledge* half is the standards: XML
1.0, XML 1.1, and Namespaces, read line by line and tested against the official
suites. The *wisdom* half is the long list of ways parsers have been broken in
the wild, turned into rules that every Mica format has to follow. Her calm is
part of the job. She never guesses what a document meant; she reads what is
there, in order, and when something breaks, she names the exact place:

> "Line 3, column 17. Everything before it reads clean."

## Fast: the numbers

We benchmarked three ways of reading XML on four kinds of input:

- **DOM** builds the whole document in memory.
- **Reader** streams through it one node at a time.
- **XPath** builds the document and then queries it.

The inputs are an attribute-heavy document, a deeply nested one, an RSS feed,
and a 10 MB S3 ListObjects listing, the kind of response a storage client reads
all day.

| Workload | Input | Mica (MB/s) | libxml2 (MB/s) |
| --- | --- | ---: | ---: |
| DOM | Attribute-heavy | **173.9** | 103.7 |
| DOM | Deep nesting | **156.5** | 124.6 |
| DOM | RSS feed | **571.9** | 250.8 |
| DOM | S3 listing | **281.2** | 218.8 |
| Reader | Attribute-heavy | **152.9** | 84.4 |
| Reader | Deep nesting | **174.2** | 67.0 |
| Reader | RSS feed | **559.1** | 202.6 |
| Reader | S3 listing | **317.9** | 134.5 |
| XPath | Attribute-heavy | **168.4** | 97.9 |
| XPath | Deep nesting | **143.4** | 104.4 |
| XPath | RSS feed | **532.3** | 246.5 |
| XPath | S3 listing | **237.7** | 140.7 |

Higher is better. Mica leads on all twelve. On the DOM S3 workload, the one we
watch most closely, she runs about 29 percent faster than libxml2.

Memory tells the same story. Peak resident memory for one parse:

| Workload | Mica | libxml2 |
| --- | ---: | ---: |
| DOM, S3 listing | **81 MiB** | 200 MiB |
| DOM, 50 MB synthetic document | **344 MiB** | 942 MiB |
| Reader, either file | 3 to 4 MiB | 4 MiB |

> **How we measured:** best-of throughput across 5 interleaved rounds of 20
> iterations, release builds with Crystal 1.21.0 on macOS arm64. libxml2 ran
> through Crystal's standard `XML` module, which binds it, with strict options:
> no network access and no error recovery. Both sides read the same files in
> the same rounds.

### What safety costs, measured

We set a goal for the hardening pass: no slowdown at all compared with Mica's
own build before it. We missed that goal in one place, and we are telling you
where. The S3 workloads are 5 to 8 percent slower than the earlier build,
because every pass Mica makes over the input is now counted against a work
budget before it runs. We kept the checks. Mica is still well ahead of
libxml2 on those same workloads, and a parser that can prove when it will stop
is worth a few percent.

## Safe: years of CVE lessons, closed by design

Most parser vulnerabilities are not new. They are the same few shapes,
rediscovered in one library after another. Ruby's REXML alone had six of them
in 2024 (CVE-2024-35176, -39908, -41123, -41946, -43398 and -49761), and those
six were the guiding cases for Mica's hardening. Each lesson below is
explained in plain terms first, then given its official name from MITRE's
Common Weakness Enumeration (CWE).

### Documents that multiply themselves

Imagine a note that says "copy this page ten times," where every copy carries
the same instruction. A few levels deep, one sheet of paper has become a
billion pages, and the copier never stops.

That is an **entity expansion bomb**, CWE-776, often called "billion laughs."
XML lets a document define shortcuts that expand into more shortcuts. Mica
caps every expansion: at most 10,000 expansions, 16 MiB of expanded text, and
a depth of 16, and every expanded byte counts against the work budget.

### Documents that send the parser on errands

Picture a letter that says "go to the filing cabinet, read what is in the
third drawer, and copy it here." A careful assistant does not run that errand
just because a stranger's letter asked.

That is an **XML external entity** attack (XXE), CWE-611. XML can point at
files and URLs, and a parser that follows those pointers can leak secrets or
reach into private networks. Mica never fetches anything from the network or
the disk while she parses. An outside reference stays closed and labeled:

> "That one points elsewhere. I'll leave it closed and labeled."

### Reserving space on someone else's say-so

Think of a warehouse that clears shelf space for however many boxes the
delivery slip claims, before a single box arrives. Anyone with a pen can fill
the building with empty shelves.

That is **allocation without limits**, CWE-770. Mica has a ceiling for every
dimension of a document, from element depth (1,024) to token size (10 MiB) to
attributes per element (10,000), and she checks each limit before she does the
work, not after.

### Work that grows faster than the input

Imagine a clerk who rereads the entire stack from the top every time a new
page arrives. At ten pages nobody notices; at ten thousand, the office stops.

That is **uncontrolled resource consumption**, CWE-400, and its quiet form is
quadratic work hiding inside an innocent-looking loop. Mica answers it twice:

- **Proof that the work is linear.** For 67 attack patterns, a spec counts the
  operations Mica performs on an input of size *n* and on one four times
  larger. Linear work scores about 4; quadratic work would score 16. The
  worst of the 67 scores 4.41, against a bound of 5.
- **A budget and a deadline on every parse.** Each parse may spend 64
  operations per unit of input plus a fixed 1,000,000, with a 60-second
  deadline by default. The highest cost across two million fuzz cases was
  5.62 operations per byte, which leaves about 11 times headroom. When a
  budget does trip, the error says where.

### Echoing input back as instructions

Picture a receptionist who reads each visitor's name badge aloud over the
building's intercom. If a badge says "everyone evacuate now," she has made an
announcement nobody intended.

That is **cross-site scripting**, CWE-79: text from a request is shown on a
page and the browser runs it as code. Error pages are a classic place for it,
because they love to repeat the bad input that caused the error. Amber's error
pages now escape everything they print (more on that below).

### Patterns that try every path

Imagine solving a maze by walking every possible route to its end before you
try the next fork. A few dozen forks are enough to keep you walking for years.

That is **regular-expression denial of service** (ReDoS), CWE-1333. A
backtracking regex engine, given the wrong pattern and the wrong input, does
exactly that. Mica's parsers use no regular expressions at all; they read
bytes with explicit state machines. We also audited 1,714 regex uses across
our own stack and found zero backreferences, which makes the next step
practical: a linear-time regex engine of Mica's own.

### The lessons at a glance

| Weakness | MITRE CWE | How it is closed |
| --- | --- | --- |
| Entity expansion bombs | CWE-776 | Entity expansion is off for Amber's request XML; Mica bounds expansion and charges it to the budget |
| External entities (XXE) | CWE-611 | Mica never fetches; outside references stay closed and labeled |
| Allocation without limits | CWE-770 | Every limit is checked before the work or allocation happens |
| Resource exhaustion | CWE-400 | Work budgets, deadlines, and linear-time proofs |
| Cross-site scripting | CWE-79 | Amber's error pages escape everything they print |
| Regex denial of service | CWE-1333 | No regex in Mica's parsers; 1,714 regex uses in our stack audited |

Definitions for every entry are at [cwe.mitre.org](https://cwe.mitre.org).

## Proven, not promised

Claims about parsers are cheap, so here is what backs these up.

- **Conformance.** On the W3C XML Conformance Test Suite (xmlconf), Mica
  scores 1,914 of 1,915 on XML 1.0 and 237 of 237 on XML 1.1.
- **Fuzzing.** 2,000,000 generated cases across 8 seeds: 0 crashes, 0 budget
  overruns, 0 nondeterministic results.
- **Hostile bytes.** A 1,312-cell matrix of malformed encodings, control
  characters, and truncated sequences. Each cell is parsed both from memory and
  one byte at a time, and must match the predicted result down to the error
  and its byte offset.
- **A second opinion from libxml2.** In 20,000 differential runs, both parsers
  accepted 584 documents and rejected 19,339. Where they disagreed, the cases
  were mostly namespace and XML 1.1 rules that libxml2 relaxes or does not
  support.
- **Memory safety.** The only code that skips Crystal's bounds checks is one
  small scanning helper, and it checks its whole window before it reads.
- **Review.** 48 rounds of independent AI code review, every finding fixed or
  answered, and the 48th round found nothing left to fix. The test suite runs
  371 examples with 0 failures and 0 compiler warnings.

## Amber applies the same lessons today

Mica's rules are not only for Mica. Amber V2 has just taken the same lessons
into its own request handling in
[amberframework/amber#1419](https://github.com/amberframework/amber/pull/1419),
"Security: bound request parameter parsing." In short:

- **Bounded parsing.** A request beyond a configured limit gets
  `400 Bad Request`, and parsing never allocates in proportion to a number
  written in the request. Defaults include 1,000 parameters, 32 levels of key
  nesting, 1 MiB per field value, 8 MiB for URL-encoded, JSON, and XML bodies,
  64 MiB per uploaded file, and 2 MiB per WebSocket message. Every limit lives
  in a typed `params:` configuration section.
- **No DTDs in request XML.** A request body containing `<!DOCTYPE ...>` gets
  a 400, so request XML can never define or expand entities.
- **Error pages that escape their output.** The production HTML error page
  escapes the message, and the development exception page escapes the method,
  path, and title.

If your forms use array indices above 100, or very large uploads or document
bodies, read the compatibility notes in the pull request before you upgrade;
each limit can be raised in configuration.

## Meet Beryl, who keeps the supply chain honest

<figure class="post-cover post-figure">
  <img src="/assets/characters/beryl-rooftop-seal-check-codex-ebb0ddac46ed3d1422777d8b815f2a4f.webp" width="1672" height="941" loading="lazy" alt="Beryl in a black riding suit and a helmet with a gold visor leans on a matte-black motorcycle on a rooftop at sunset, her black cat Mo on her shoulder, beside an open case of checked seals.">
  <figcaption>Beryl and Mo on the rooftop, a case of verified seals at her side.</figcaption>
</figure>

A parser can only be as trustworthy as the code it is built from. That is
Beryl's job. She is the crew's security operative: pinned dependencies,
hashes and lockfile checksums, signed releases, secrets and least-privilege
keys, and private disclosure when someone finds a hole.

You will rarely see her face. Beryl rides, and her helmet is her instrument.
When she inspects a dependency, a scan line sweeps her visor and a hash scrolls
past. If it matches, the visor flashes heliodor gold and her seal clicks into
place:

> "Pinned, hashed, verified. Ship it."

If it does not, a padlock engages on the visor and the crate stays shut:

> "That tag moved. The hash didn't lie. Crate stays on the dock."

On her right shoulder rides Mo, a sleek black cat named for morganite, who
inspects every crate alongside her. When the job is done and the helmet comes
off, Beryl gives her the credit:

> "You checked it too, didn't you? Good girl."

Beryl and Mica work as a pair. Beryl brings the intel in from the field: a new
CVE, a moved tag, a dependency that changed under its own version number. Mica
reads it, writes the rule, and is the steady face that says it is handled.
Mica's reading glasses are heliodor gold now, to match her partner. In
practice, that partnership looks like this:

- Mica has no runtime dependencies. A minimal program built on her links
  only the garbage collector, the character-set converter, and the system
  library.
- Mica's rules for adding a format require each conformance runner to check
  its official suite against a pinned SHA-256 before scoring it, so a test
  suite cannot quietly change under her.

## What comes next (planned)

XML is Mica's first book, not her last. **Everything in this section is
planned; today only the XML library exists, and it is not yet released.**
Each new format follows the same contract: no C libraries, no regular
expressions in the parser, linear-time proofs, work budgets and deadlines,
exact error positions, and its official conformance suite.

- **JSON** (RFC 8259, plus I-JSON), **YAML 1.2.2**, and **CBOR** (RFC 8949).
- **URLs** (RFC 3986, with the WHATWG URL rules), **CSV** (RFC 4180), and
  **Markdown** (CommonMark and GitHub Flavored Markdown).
- **JSON Schema 2020-12**, scored against the official test suite and entered
  in [Bowtie](https://bowtie.report) so anyone can compare implementations,
  and **JSON Type Definition** (RFC 8927) with a Crystal code generator.
- **Mica::Regex**, a linear-time regular-expression engine in pure Crystal.

The safety limits will be part of the method call itself. The planned shape
for JSON looks like this, and leaving out `limits:` will be a compile error:

```crystal
Mica::JSON.parse(body, limits: Mica::Limits::REQUEST_BODY)
```

## Use Mica in your own app

Mica is built for Amber, but she is a plain Crystal library: any Crystal
application that reads XML today, and JSON, YAML, CBOR and more tomorrow, can
use her. Her public release is coming. To hear the day she ships:

- Follow this blog's [RSS feed](/blog/feed.xml).
- Watch the [Amber Framework organization on GitHub](https://github.com/amberframework).
- Meet the crew: [Mica](/characters/mica), and [everyone else](/characters).

Then send her something hard to read.
