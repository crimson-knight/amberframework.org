# Amber 2.0 Alpha: The Road to a Unified Framework

It's been a while since the last update, and a lot has happened. Amber 2.0 is taking shape, and today I want to walk through the changes that have already landed and explain the thinking behind them. If you read the previous roadmap post, you know the vision: a single, self-contained framework that a solo developer can pick up and use to build a real business. What follows is the first concrete step toward that vision.

Amber 2.0 is currently in alpha. The changes described here are merged and available on the `master` branch of the [crimson-knight/amber](https://github.com/crimson-knight/amber) fork. We're developing in the open, and feedback is welcome.


## Why a V2?

The short answer: maintenance reality.

Open source in the Crystal ecosystem is a small world. When a framework depends on a dozen third-party shards, and the maintainers of those shards move on, the framework inherits a pile of risk. A single abandoned shard can become an emergency overnight when Crystal releases a new version or a behavior changes upstream. We've lived through this, and it's not sustainable.

Amber V2 is a monorepo-first framework. Everything web-framework-related ships as one unit. One repo, one test suite, one release cycle. The only external dependencies will be things that genuinely deserve their own project: Grant as the ORM, the asset pipeline, and a handful of dev-time tools. Everything else comes with Amber.

This is a deliberate trade-off. It's a little anti-modular, but it means that when you install Amber, it works. No chasing down compatible versions of five different shards maintained by five different people on five different schedules.


## What's Already Changed

Five major changes have been merged into the V2 alpha:

<table>
<tr><th>Change</th><th>Impact</th></tr>
<tr><td>Redis dependency removed</td><td>Zero-config sessions and pub/sub out of the box via in-memory adapters</td></tr>
<tr><td>CLI extracted from framework</td><td>~160 files removed, framework is now purely a library</td></tr>
<tr><td>11 dependencies removed</td><td>Went from 18 to 5 runtime shards</td></tr>
<tr><td>YAML.mapping modernized</td><td>Replaced with YAML::Serializable for Crystal compatibility</td></tr>
<tr><td>Schema API added</td><td>Type-safe request params with built-in validation and parsing</td></tr>
</table>

Click any section below for the full details.

<details>
<summary><strong>Redis Is No Longer a Hard Dependency</strong></summary>

**The problem:** Amber V1 required Redis for session storage and WebSocket pub/sub. That meant every Amber app, even a simple prototype, needed a Redis server running. For local development, that's friction. For deployment, that's an extra service to manage and pay for.

**What changed:** We replaced the direct Redis dependency with an adapter pattern. Amber now ships with in-memory adapters for both session storage and pub/sub that work out of the box with zero configuration. The `MemorySessionAdapter` is thread-safe with TTL support and automatic background cleanup. The `MemoryPubSubAdapter` handles in-process pub/sub with async delivery.

**For production:** If you need Redis (and at scale, you probably will), you can register a Redis adapter at runtime through the `AdapterFactory`. The adapter interfaces are clean and well-defined, so plugging in Redis, Memcached, or anything else is straightforward. The key difference is that Redis is now a choice, not a requirement.

```crystal
# The default just works - no Redis needed
Amber::Server.configure do |app|
  # Sessions use in-memory storage by default
end

# When you're ready for Redis, register an adapter
Amber::Adapters::AdapterFactory.register_session_adapter("redis", MyRedisAdapter.new)
```

</details>

<details>
<summary><strong>The CLI Has Been Removed From the Framework</strong></summary>

**The problem:** Amber V1 shipped with a CLI tool (`amber new`, `amber generate`, `amber watch`, etc.) bundled directly in the framework repo. This meant the web framework and the code generation tool shared the same dependency tree, the same release cycle, and the same test suite. Changes to the CLI could break framework tests and vice versa. It also pulled in a large number of dependencies that the framework itself never needed: `teeplate` for templating, `shell-table` for terminal output, `inflector` for string manipulation, and several database drivers.

**What changed:** The entire `src/amber/cli/` directory has been removed, along with all of its generators, recipes, plugins, commands, and templates. That's roughly 160 files deleted. The framework is now purely a library.

**What about scaffolding?** A new, separate CLI tool handles project generation and scaffolding. It's installed via Homebrew and lives in its own repository with its own release cycle. The framework itself is purely a library — it doesn't know or care how your project was created.

The CLI removal is what enabled the massive dependency cleanup described next.

</details>

<details>
<summary><strong>Dependency Cleanup: 18 Shards Down to 5</strong></summary>

**The problem:** Amber V1's `shard.yml` listed 18 dependencies. Many of these existed solely to support the CLI tool. Others, like `yaml_mapping`, were wrappers around deprecated Crystal stdlib APIs.

**What changed:** We went from 18 dependencies down to 5 runtime dependencies and 1 development dependency. Here's what was removed:

<table>
<tr><th>Removed Dependency</th><th>Why It Existed</th><th>Why It's Gone</th></tr>
<tr><td><code>cli</code></td><td>CLI argument parsing</td><td>CLI removed</td></tr>
<tr><td><code>teeplate</code></td><td>File templating for generators</td><td>CLI removed</td></tr>
<tr><td><code>inflector</code></td><td>String inflection (pluralize, etc.)</td><td>CLI removed</td></tr>
<tr><td><code>shell-table</code></td><td>Terminal table formatting</td><td>CLI removed</td></tr>
<tr><td><code>redis</code></td><td>Session storage, pub/sub</td><td>Replaced with adapter pattern</td></tr>
<tr><td><code>micrate</code></td><td>Database migrations</td><td>Extracted with CLI</td></tr>
<tr><td><code>pg</code></td><td>PostgreSQL driver</td><td>Extracted with CLI</td></tr>
<tr><td><code>mysql</code></td><td>MySQL driver</td><td>Extracted with CLI</td></tr>
<tr><td><code>sqlite3</code></td><td>SQLite3 driver</td><td>Extracted with CLI</td></tr>
<tr><td><code>yaml_mapping</code></td><td>Deprecated YAML parsing</td><td>Replaced with YAML::Serializable</td></tr>
<tr><td><code>liquid</code></td><td>Liquid template engine</td><td>Removed</td></tr>
</table>

Since this was written, we've gone further: `kilt` and `slang` have been removed in favor of ECR (Crystal stdlib), and `exception_page` and `backtracer` have been internalized. The framework now has **zero runtime dependencies**. Only `ameba` remains as a dev-only linting tool. The routing engine (`amber_router`) and markdown renderer (`markd`) were internalized earlier — see below.

This isn't just about having a shorter `shard.yml`. Fewer dependencies means faster `shards install`, fewer version conflicts, and less surface area for things to break between Crystal releases.

</details>

<details>
<summary><strong>Modernized YAML Serialization</strong></summary>

A smaller but important change: all usage of `YAML.mapping` (which Crystal deprecated) has been replaced with `YAML::Serializable`. This affects the environment settings and logging configuration. It's the kind of housekeeping that keeps the framework compatible with modern Crystal without deprecation warnings.

</details>

<details>
<summary><strong>The New Schema API</strong></summary>

**The problem:** Handling request parameters in Amber V1 meant working with raw, untyped params. You'd pull values out of `params`, cast them yourself, validate them yourself, and hope you covered all the edge cases. This works for small apps, but it doesn't scale, and it's error-prone.

> **Update — August 13, 2026:** The alpha introduced the schema-definition DSL
> and parsers, but its controller declarations did not yet guarantee automatic
> enforcement. The next-beta candidate in
> [Amber PR #1408](https://github.com/amberframework/amber/pull/1408) completes
> that runtime contract. The deprecated `params.validation` API remains
> functional so applications can upgrade first and migrate action by action.

**What changed:** Amber 2.0 introduced a macro-based Schema API for typed
request data, parsing, validation, coercion, and error reporting. The
next-beta candidate extends the same declaration through automatic controller
enforcement, response validation, content negotiation, and OpenAPI 3.1.

Here's what it includes:

- **Field definitions** with types, defaults, and required/optional flags
- **Seven built-in validators:** required, type, length, range, format (email, URL, UUID, ISO8601, etc.), enum, and pattern
- **Five request parsers:** JSON, XML, form data, multipart (with file uploads), and query string
- **Type coercion** that handles the common conversions automatically (string to int, string to bool, string to UUID, etc.)
- **Request-local typed values** after automatic enforcement in the next-beta candidate
- **Controller integration** that remains backward-compatible with existing params code

```crystal
class CreateUserSchema < Amber::Schema::Definition
  field :name, String, required: true
  field :email, String, required: true, format: "email"
  field :age, Int32, min: 18, max: 150
  field :role, String, enum: ["admin", "user", "moderator"]
end
```

Bind that class with `schema :action, CreateUserSchema` in the controller. On
the release-candidate path, Amber enforces it before the action runs and exposes
the request-local instance with `validated_as(CreateUserSchema)`. Read the
[current schema guide](/docs/v2/guides/schema-api/) instead of treating this
historical alpha post as an API reference.

</details>


## What's Done Since the Alpha

Several major changes have landed since the initial alpha:

<table>
<tr><th>Change</th><th>Impact</th></tr>
<tr><td>Router internalized + optimized</td><td>amber_router brought into the source tree; the historical local results below have now been superseded by a controlled cloud rerun</td></tr>
<tr><td>Built-in Markdown renderer</td><td>Full CommonMark + GFM (tables, strikethrough, task lists) — no external shard needed</td></tr>
<tr><td>Amber LSP for Claude Code</td><td>AI-assisted development with 15 convention rules — the default way to build with Amber</td></tr>
</table>


### Amber LSP — AI-Assisted Development as the Default

Here's the bet we're making with Amber 2.0: **the primary way new developers will build Amber applications is with an AI coding assistant.** Not as a nice-to-have. As the default workflow.

The Amber CLI now ships with a built-in Language Server Protocol (LSP) server designed specifically for [Claude Code](https://claude.ai/claude-code). When you start a new project and run `amber setup:lsp`, the LSP integrates with Claude Code and runs in the background as you develop. It watches every `.cr` file you save and checks it against 15 Amber convention rules — controller naming, inheritance chains, missing methods, file structure, route validity, and more.

What makes this different from a linter is the feedback loop. Claude Code sees the diagnostics from the LSP and self-corrects in real time. If Claude generates a controller that doesn't inherit from `ApplicationController`, the LSP flags it, and Claude fixes it — before you even notice the mistake. The result is that Claude Code goes from being a general-purpose coding assistant to one that writes idiomatic Amber code out of the box.

Setting it up takes one command:

```bash
amber setup:lsp
```

That creates the plugin configuration files in your project directory. Open Claude Code, and the LSP activates automatically.

For teams with their own conventions, the LSP supports custom rules defined in YAML. You can flag `puts` statements in production code, require copyright headers, catch hardcoded URLs — anything expressible as a regex pattern. No recompilation needed. Drop a rule into `.amber-lsp.yml` and it takes effect on the next save.

This is the direction we think web development is heading: frameworks that are designed from the ground up to work with AI assistants, not just tolerate them. The LSP is the first piece of that. We plan to extend it with more sophisticated rules — detecting N+1 queries in templates, flagging missing CSRF protection, suggesting schema validations based on database constraints — as the framework matures.

Full setup instructions are in the [LSP Setup Guide](https://github.com/crimson-knight/amber/blob/master/docs/guides/lsp-setup.md).


## What's Coming Next

That was the roadmap as of the initial alpha announcement. Every single item on it has shipped. What follows is a complete accounting of what got built, how it works, and what it means for Amber developers.


### Faster Routing: Internalizing and Optimizing amber_router

> **Benchmark correction — August 13, 2026:** The figures preserved in this
> section came from an earlier same-machine local microbenchmark. They were not
> measured on DigitalOcean, and the old glob-route generator reused five
> effective URL shapes while describing them as unique routes. That duplicate
> route edge case produced the `55.7x` headline. We have retired that number as
> a current performance claim and rerun the released V2 beta.4 router against
> `amber_router` 0.4.4 with unique route shapes, seven paired trials, and the
> exact $4 DigitalOcean target. Read [the cloud benchmark and its corrections](/blog/2026/08/13/amber-v2-router-on-a-four-dollar-droplet),
> or inspect the [machine-readable summary](/benchmarks/amber-v2-router-digitalocean-2026-08-13-summary.json).

The HTTP routing engine (`amber_router`) has been brought directly into the Amber source tree. We didn't just copy it in — we rethought how it uses Crystal's type system and memory model to make it significantly faster.

The old router used a tree of segment nodes to match URL paths. It worked, but every node stored its children in a single dynamic `Array` of union types, which meant every route lookup did a linear scan with runtime type checks at every level of the tree. Parameters were extracted with heap-allocated `Hash` objects. Path strings were split into temporary arrays on every request.

Here's what changed:

- **Split segment storage by type.** Fixed segments (literal strings like `/users`) go into a `Hash` for O(1) lookup. Variable segments (`:id`) stay in a small array. Glob segments get a single nullable slot. No more linear scan through a mixed bag of types.
- **Use a value type for terminal leaves.** `TerminalSegment`, the leaf node
  that holds a route payload and priority, became a Crystal `struct`.
  `RoutedResult` remains a class in beta.4, so this change does not eliminate
  every lookup allocation.
- **Index-based route registration.** The old insertion path used
  `Array#shift`, which moves the remaining segment references at each level.
  Beta.4 registers routes with an integer index instead. This improves route
  table construction; it is not part of the timed lookup phase below.
- **Pre-allocated path splitting.** Instead of creating two intermediate arrays every time a URL is split, we do a single pass with a pre-sized array.

We benchmarked every change against realistic route tables — from 50 routes (a small app) up to 10,000 (far beyond what most apps need) — measuring isolated routing speed with `Benchmark.ips` in Crystal.

#### Historical local results at a typical scale (100 routes)

For an app with ~100 routes — which covers the vast majority of real-world applications — every route type got faster:

The detailed comparison is preserved in the table below: fixed lookups improved
from 2.55M to 3.36M IPS, variable lookups from 3.54M to 4.44M, glob lookups
from 1.64M to 2.32M, and the not-found path from 3.06M to 5.66M.

The "Not Found" path — what happens when no route matches — got almost 2x faster. This matters because 404s, health checks, and favicon requests hit this path constantly.

#### Why the old glob result looked dramatic

The old data appeared to show a dramatic change in glob routes
(`/files/*path`) as the route table grew:

Across 50 to 10,000 routes, the optimized glob path stayed near 2M IPS while
the baseline fell from roughly 1.7M to 31K IPS—a 55.7x difference at 10,000
routes.

That was a real measurement of the old harness, but it was not a clean
10,000-unique-route comparison. At that tier, 500 declared glob routes
collapsed onto five effective match shapes, leaving 100 terminal entries
behind each shape. The result is useful for understanding that duplicate-route
edge case, but it should not be quoted as Amber V2's general routing speedup.

#### Historical full comparison

<table style="border-collapse: collapse; width: 100%; font-size: 14px;">
<tr>
  <th rowspan="2" style="padding: 10px 12px; border: 1px solid #334155; background: #1e293b; color: #e2e8f0; text-align: center;">Routes</th>
  <th colspan="2" style="padding: 10px 12px; border: 1px solid #334155; background: #1e293b; color: #e2e8f0; text-align: center;">Fixed Segment</th>
  <th colspan="2" style="padding: 10px 12px; border: 1px solid #334155; background: #1e293b; color: #e2e8f0; text-align: center;">Variable Segment</th>
  <th colspan="2" style="padding: 10px 12px; border: 1px solid #334155; background: #1e293b; color: #e2e8f0; text-align: center;">Glob</th>
  <th colspan="2" style="padding: 10px 12px; border: 1px solid #334155; background: #1e293b; color: #e2e8f0; text-align: center;">Not Found</th>
</tr>
<tr>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #94a3b8;">Before</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #f59e0b;">After</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #94a3b8;">Before</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #f59e0b;">After</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #94a3b8;">Before</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #f59e0b;">After</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #94a3b8;">Before</th>
  <th style="padding: 8px 12px; border: 1px solid #334155; background: #1e293b; color: #f59e0b;">After</th>
</tr>
<tr><td style="padding: 8px 12px; border: 1px solid #334155; text-align: center; font-weight: 600;">50</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.48M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>3.39M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">3.52M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>4.83M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.71M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.36M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">3.11M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>5.82M</strong></td></tr>
<tr><td style="padding: 8px 12px; border: 1px solid #334155; text-align: center; font-weight: 600;">100</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.55M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>3.36M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">3.54M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>4.44M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.64M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.32M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">3.06M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>5.66M</strong></td></tr>
<tr><td style="padding: 8px 12px; border: 1px solid #334155; text-align: center; font-weight: 600;">500</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.62M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>3.06M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">3.23M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>4.21M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">618K</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.16M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.86M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>5.30M</strong></td></tr>
<tr><td style="padding: 8px 12px; border: 1px solid #334155; text-align: center; font-weight: 600;">1,000</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.61M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.87M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">3.21M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>3.95M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">359K</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.04M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.84M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>5.00M</strong></td></tr>
<tr><td style="padding: 8px 12px; border: 1px solid #334155; text-align: center; font-weight: 600;">5,000</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.82M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.56M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.16M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>3.58M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">67K</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>1.84M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.45M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>4.56M</strong></td></tr>
<tr><td style="padding: 8px 12px; border: 1px solid #334155; text-align: center; font-weight: 600;">10,000</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.51M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>2.41M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">1.79M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>3.30M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">31K</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>1.74M</strong></td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right; color: #94a3b8;">2.37M</td><td style="padding: 8px 12px; border: 1px solid #334155; text-align: right;"><strong>4.16M</strong></td></tr>
</table>

All values are iterations per second (higher is better), measured with
`Benchmark.ips` in Crystal. This table is retained so the project's published
history remains inspectable; use the August 13 cloud rerun for current claims.

<details>
<summary><strong>Why this matters for your app</strong></summary>

Routing runs on every single HTTP request. It's the first thing that happens after the TCP connection and HTTP parsing. In a framework that handles thousands of requests per second, even small per-request allocations add up. A `Hash` allocation here, an `Array` copy there — multiply that by 10,000 requests/second and you're generating significant GC pressure.

Moving fixed-segment lookups to a hash, separating segment types, and removing
temporary path work reduces the amount of routing work performed for each
request. The microbenchmark measures lookup throughput only. Any claim about
whole-request allocation pressure or GC pauses requires separate application
profiling.

The corrected benchmark now preserves the exact source revisions, compiler,
binary checksums, cloud target, raw paired trials, summary statistic, and
limitations. It is a reproducible release check, but it is not currently a
required pull-request check.

</details>


### Built-in Markdown Renderer

Amber 2.0 includes a full-featured markdown-to-HTML renderer as a built-in module. No external dependency on `markd` or any other shard.

The renderer is based on [markd](https://github.com/icyleaf/markd), a pure Crystal CommonMark implementation. We've ported it into `Amber::Markdown` and added the GFM extensions that the released version was missing:

- **GFM tables** (pipe syntax with alignment)
- **Strikethrough** (`~~deleted~~`)
- **Task lists** (`- [ ]` and `- [x]` checkboxes)
- **Bare URL autolinks** (no angle brackets needed)
- **Footnotes**
- **Table of contents generation**

On the framework integration side, Amber controllers will get a `render_markdown` helper that turns any markdown string or file into an HTML response, with layout support.

```crystal
class DocsController < Amber::Controller::Base
  def show
    content = File.read("docs/#{params["slug"]}.md")
    render_markdown(content)
  end
end
```

This site — amberframework.org — runs on Amber and renders its blog posts from markdown files. Once the built-in renderer ships, we'll be using it ourselves.

<details>
<summary><strong>Why build this in instead of using a shard?</strong></summary>

The markd shard is looking for a maintainer. The GFM table support we need has been merged on their master branch since February 2025, but there's been no release since June 2022. That's exactly the kind of dependency risk we're eliminating with V2.

The codebase is ~1,700 lines of pure Crystal with no external dependencies. It's well-architected (two-phase block/inline parsing, walker-based rendering, extensible rule system) and has a comprehensive test suite based on the CommonMark spec. Maintaining it inside Amber is entirely practical.

Markdown rendering is one of those things nearly every web app needs at some point — blog posts, documentation, user content, README display. Having it built in means one less shard to install, one less version to manage, and a renderer that's tested alongside the framework it runs in.

</details>


## Everything We Said Was Coming — It's Done

Here's the scorecard. Twelve features were planned. Twelve have been merged to master with full spec coverage.

<table>
<tr><th>Change</th><th>Impact</th></tr>
<tr><td>Exception page + backtracer internalized</td><td>Development error pages built-in; two more external deps removed</td></tr>
<tr><td>Kilt/Slang removed, ECR-only</td><td>Zero runtime dependencies achieved</td></tr>
<tr><td>Background jobs with work-stealing</td><td>In-process job queue; idle web instances steal work (76 specs)</td></tr>
<tr><td>Testing framework</td><td>ContextBuilder, request helpers, WebSocket test helpers (84 specs)</td></tr>
<tr><td>Action helpers</td><td>Tag, Form, URL, Asset, Text, Number helpers (155 specs)</td></tr>
<tr><td>Mailer with adapters</td><td>SMTP + memory adapter, MIME builder (72 specs)</td></tr>
<tr><td>Session security overhaul</td><td>SameSite, key rotation, SHA256, sliding expiration (108 specs)</td></tr>
<tr><td>Configuration overhaul</td><td>10 typed config structs, env var overrides, validation (136 specs)</td></tr>
<tr><td>Router enhancements</td><td>Named routes, constraints, API versioning, route introspection</td></tr>
<tr><td>WebSocket improvements</td><td>Decoders, presence tracking, connection recovery (75 specs)</td></tr>
<tr><td>Documentation + migration guide</td><td>13 files, 4,069 lines of guides</td></tr>
<tr><td>CLI V2 generators</td><td>Generators for jobs, mailers, schemas, channels (2,322 lines)</td></tr>
</table>

Across all modules, Amber V2 now has **1,967 specs** passing with zero failures. Click the sections below for the details on each.

<details>
<summary><strong>Exception Page + Backtracer Internalized</strong></summary>

**The problem:** Amber V1 depended on two external shards — `exception_page` and `backtracer` — for development error pages and stack trace formatting. Both were small, single-purpose libraries with unclear maintenance futures.

**What changed:** Both have been brought directly into the Amber source tree. `backtracer` (390 lines of code, 7 source files) lives in `src/amber/support/backtracer/` and keeps the `Backtracer` namespace for compatibility. `exception_page` (128 lines, 3 files plus an ECR template) lives in `src/amber/exceptions/exception_page/`. Both were removed from `shard.yml`. Combined with the Kilt/Slang removal, this brought Amber to **zero runtime dependencies**.

28 backtracer specs pass.

</details>

<details>
<summary><strong>Kilt/Slang Removed — ECR Only</strong></summary>

**The problem:** Amber V1 supported multiple template engines through the `kilt` abstraction layer, with `slang` as an alternative to ECR. This added two runtime dependencies for a feature that most projects never used — and that AI coding assistants handle poorly compared to ECR.

**What changed:** Kilt and Slang were removed from `shard.yml`. All `Kilt.render(...)` calls were replaced with `ECR.render(...)`. Seven `.slang` templates were converted to `.ecr`. The default layout changed from `application.slang` to `application.ecr`.

ECR is part of Crystal's standard library. It compiles to Crystal code at compile time, so there's no runtime overhead and no additional dependency. This is the change that achieved **zero runtime dependencies** for the framework.

</details>

<details>
<summary><strong>Background Jobs with Work-Stealing</strong></summary>

**The problem:** Amber V1 had no built-in job processing. If you needed background work — sending emails, processing uploads, running reports — you had to find a third-party shard or build your own.

**What changed:** Amber 2.0 ships with an in-process job queue in `src/amber/jobs/` (8 source files). The design is built around a work-stealing pattern: when a web instance has no pending HTTP requests, it pulls jobs from the queue. This means your web processes double as job workers during idle time, without a separate process.

The system includes a `Job` base class, `JobEnvelope` for serialization, `MemoryQueueAdapter` for the default in-process queue, a `Worker` with an `idle_only` mode that checks `pending_request_count`, and a `Scheduler` for recurring jobs. The adapter pattern means you can plug in Redis or another backend when you outgrow in-memory.

```crystal
class WelcomeEmailJob < Amber::Jobs::Base
  def perform
    user_id = args["user_id"].as(Int64)
    user = User.find!(user_id)
    WelcomeMailer.new(user).deliver
  end
end

# Enqueue from a controller
WelcomeEmailJob.perform_later(user_id: user.id)

# Or schedule for later
WelcomeEmailJob.perform_in(5.minutes, user_id: user.id)
```

76 new specs cover job lifecycle, queue adapters, work-stealing behavior, retry logic, and scheduling.

</details>

<details>
<summary><strong>Testing Framework</strong></summary>

**The problem:** Testing an Amber V1 app meant cobbling together your own request helpers, building context objects manually, and hoping your WebSocket tests actually tested something. There was no official way to write integration tests.

**What changed:** `src/amber/testing/` (7 source files) provides everything you need. `RequestHelpers` gives you `get`, `post`, `put`, `patch`, and `delete` methods that return a `TestResponse` with status, body, headers, and JSON parsing. `ContextBuilder` constructs realistic request contexts for unit testing controllers. `WebSocketHelpers` lets you test channel subscriptions, message broadcasting, and presence tracking. `Assertions` provides `assert_response`, `assert_redirect`, and `assert_json`.

Opt in with `require "amber/testing"`.

```crystal
require "amber/testing"

describe UsersController do
  include Amber::Testing::RequestHelpers

  it "lists users" do
    response = get("/users")
    response.status_code.should eq(200)
    response.json["users"].as_a.size.should be > 0
  end

  it "creates a user" do
    response = post("/users", body: {
      name: "Jane",
      email: "jane@example.com"
    }.to_json, headers: {"Content-Type" => "application/json"})

    response.status_code.should eq(201)
    response.json["user"]["email"].should eq("jane@example.com")
  end
end
```

84 new specs verify request helpers, response parsing, context building, and WebSocket test utilities.

</details>

<details>
<summary><strong>Action Helpers</strong></summary>

**The problem:** Amber V1 left view-layer utilities to the developer. If you wanted form builders with CSRF protection, URL generation from route names, or asset tag helpers, you built them yourself or found a shard.

**What changed:** Six helper modules in `src/amber/controller/helpers/` are now auto-included in `Amber::Controller::Base`:

- **TagHelpers** — HTML tag generation (`tag`, `content_tag`, `link_to`)
- **FormHelpers** — Form builders with automatic CSRF tokens (`form_for`, `text_field`, `select`, `check_box`)
- **URLHelpers** — URL generation from named routes (`path_for`, `url_for`)
- **AssetHelpers** — Asset tags with digest fingerprinting (`javascript_include_tag`, `stylesheet_link_tag`, `image_tag`)
- **TextHelpers** — String formatting (`truncate`, `highlight`, `pluralize`, `word_wrap`)
- **NumberHelpers** — Numeric formatting (`number_to_currency`, `number_to_percentage`, `number_to_human_size`)

```erb
<!-- In an ECR template -->
<%= form_for("/users", method: "post") do %>
  <%= csrf_tag %>
  <div>
    <%= label("user", "name", "Name") %>
    <%= text_field("user", "name") %>
  </div>
  <div>
    <%= label("user", "email", "Email") %>
    <%= email_field("user", "email") %>
  </div>
  <%= submit_tag("Create User") %>
<% end %>
```

155 new specs cover all six helper modules.

</details>

<details>
<summary><strong>Mailer with Adapters</strong></summary>

**The problem:** Sending email from Amber V1 required a third-party shard. Testing email meant either hitting a real SMTP server or mocking at the transport layer.

**What changed:** `src/amber/mailer/` (8 source files) includes a `Base` mailer class, an `Email` struct, a `MimeBuilder` for RFC 2045 compliant multipart messages, an `SMTPAdapter` using Crystal stdlib sockets, a `MemoryAdapter` for testing, and a `Configuration` module. The memory adapter captures all sent emails in an array, so your tests can assert on email content without any network calls.

```crystal
class WelcomeMailer < Amber::Mailer::Base
  def initialize(@user : User)
  end

  def call
    mail(
      to: @user.email,
      from: "hello@myapp.com",
      subject: "Welcome to MyApp",
      body: render_template("welcome_email")
    )
  end
end

# Send it
WelcomeMailer.new(user).deliver

# Test it
describe WelcomeMailer do
  it "sends a welcome email" do
    Amber::Mailer.config.adapter = Amber::Mailer::MemoryAdapter.new

    WelcomeMailer.new(user).deliver

    emails = Amber::Mailer::MemoryAdapter.deliveries
    emails.size.should eq(1)
    emails.first.to.should eq(user.email)
    emails.first.subject.should contain("Welcome")
  end
end
```

72 new specs cover the mailer base class, MIME building, both adapters, and configuration.

</details>

<details>
<summary><strong>Session Security Overhaul</strong></summary>

**The problem:** Amber V1's session handling used SHA1 for digests, had no SameSite cookie support, no key rotation, and silently swallowed errors during session decryption.

**What changed:** This was a comprehensive security hardening pass. SameSite=Lax is now the default on all session cookies. Session fixation is prevented via `regenerate_id`. Silent error swallowing was replaced with nil returns and logged warnings. Encryption and HMAC now use separate keys derived via HMAC-SHA256. The default digest algorithm was upgraded from SHA1 to SHA256. Secure cookie defaults are enforced in production. Key rotation is supported via `previous_secrets`. Sessions now have sliding expiration. The `changed?` method was fixed to track actual modifications rather than always returning true.

```yaml
# config/amber.yml
session:
  key: "_myapp_session"
  secret: "<%= ENV["AMBER_SESSION_SECRET"] %>"
  previous_secrets:
    - "<%= ENV["AMBER_SESSION_SECRET_OLD"] %>"
  max_age: 86400
  same_site: "lax"
  secure: true
  http_only: true
```

108 new and updated specs verify all security behaviors.

</details>

<details>
<summary><strong>Configuration Overhaul</strong></summary>

**The problem:** Amber V1 had a flat configuration object loaded from YAML. There was no type safety, no validation, no environment variable overrides, and no way for application developers to register their own configuration sections.

**What changed:** 10 typed configuration structs — `ServerConfig`, `DatabaseConfig`, `SessionConfig`, `LoggingConfig`, `JobsConfig`, `MailerConfig`, `SMTPConfig`, `PubSubConfig`, `StaticConfig`, `SSLConfig` — are composed into a single `AppConfig`. Environment variables override any YAML value using the `AMBER_SECTION_KEY` convention (e.g., `AMBER_SESSION_SECRET` overrides `session.secret`). `Amber.settings` provides unified access with subsection accessors. The `validate!` method catches configuration errors at startup. Application developers can register custom configuration via the custom registry. V1 and V2 YAML formats are auto-detected for backward compatibility.

```yaml
# config/amber.yml (V2 format)
server:
  name: "MyApp"
  port: 3000
  host: "0.0.0.0"
  environment: <%= Amber.env %>

session:
  key: "_myapp_session"
  store: "memory"
  max_age: 86400

logging:
  severity: "info"
  colorize: true

jobs:
  workers: 4
  queue_adapter: "memory"
```

```bash
# Override any value with environment variables
AMBER_SERVER_PORT=8080 AMBER_SESSION_STORE=redis ./myapp
```

136 new specs cover all config structs, environment variable overrides, validation, backward compatibility, and the custom registry.

</details>

<details>
<summary><strong>Router Enhancements</strong></summary>

**The problem:** Amber V1's router handled basic route matching but lacked named routes, constraints, API versioning, and introspection tools.

**What changed:** Named routes let you generate URLs from names instead of hardcoding paths. Constraint presets (`:numeric`, `:uuid`, `:slug`, `:alpha`, `:alnum`, `:hex`) validate path parameters at the routing layer. Request-level constraints match on host, subdomain, headers, and accept types. An `api_version` macro and `ApiVersion` pipe give you a clean DSL for API versioning. Route introspection via `RouteInfo`, `route_table`, and `RoutePrinter` makes debugging straightforward. An inflector handles singular/plural resource name generation. 31 files, 1,323 insertions.

```crystal
# Named routes with constraints
Amber::Server.configure do
  routes :web do
    get "/users/:id", UsersController, :show,
      route_name: :user,
      constraints: { id: :uuid }

    get "/posts/:slug", PostsController, :show,
      route_name: :post,
      constraints: { slug: :slug }
  end

  # API versioning
  routes :api do
    api_version "v1" do
      resources "/users", Api::V1::UsersController
    end

    api_version "v2" do
      resources "/users", Api::V2::UsersController
    end
  end
end

# Generate URLs from names
Amber::Router::NamedRoutes.path(:user, id: "550e8400-e29b-41d4-a716-446655440000")
# => "/users/550e8400-e29b-41d4-a716-446655440000"
```

</details>

<details>
<summary><strong>WebSocket Improvements</strong></summary>

**The problem:** Amber V1's WebSocket support handled basic channel subscriptions and broadcasting, but lacked structured message handling, presence tracking, and connection recovery.

**What changed:** Pluggable message decoders (`JsonDecoder`, `TextDecoder`, `BinaryDecoder`) let channels handle different message formats without manual parsing. The channel API gained `after_join` and `after_leave` callbacks, a `broadcast_to` class method, and presence tracking via `presence_list` and `presence_diff`. Structured error handling works at both socket and channel levels. Connection recovery uses a persistent `connection_id`, disconnection tracking, message buffering during disconnection, and an `on_reconnect` callback.

```crystal
class RoomChannel < Amber::WebSockets::Channel
  # Presence tracking
  def on_subscribe
    track_presence(current_user.id, %{
      name: current_user.name,
      online_at: Time.utc.to_unix
    })
  end

  # Lifecycle callbacks
  after_join do
    broadcast("system", {
      event: "user_joined",
      user: current_user.name
    })
  end

  after_leave do
    broadcast("system", {
      event: "user_left",
      user: current_user.name
    })
  end

  # Connection recovery
  on_reconnect do |connection_id|
    buffered_messages(connection_id).each do |msg|
      push(msg)
    end
  end

  def receive(message : JSON::Any)
    broadcast("message", {
      user: current_user.name,
      body: message["body"],
      sent_at: Time.utc
    })
  end
end
```

75 WebSocket specs verify decoders, presence tracking, callbacks, and connection recovery.

</details>

<details>
<summary><strong>Documentation + Migration Guide</strong></summary>

13 documentation files totaling 4,069 lines. Includes a V1-to-V2 migration guide with before/after code examples for all 10 breaking changes. Nine subsystem guides cover routing, configuration, the schema API, action helpers, WebSockets, background jobs, mailer, testing, and markdown. A getting started guide and README index tie everything together.

</details>

<details>
<summary><strong>CLI V2 Generators</strong></summary>

The separate `amber_cli` project received 7 new files and 2,322 lines of insertions. Four new generators — `job`, `mailer`, `schema`, and `channel` — produce V2-compatible code. Existing generators (`controller`, `scaffold`, `auth`, `API`) were updated to emit ECR templates, Schema API validations, `Amber::Testing` test files, and form helpers. The `amber new` template generates the V2 directory structure and configuration format. 156 CLI tests pass.

</details>


## Grant — The ORM for Amber V2

Amber V1 recommended Granite as its ORM. Amber V2 recommends [Grant](https://github.com/crimson-knight/grant).

The reason is straightforward: Granite accumulated design debt that couldn't be resolved without breaking changes. Connection switching barely works. There's no dirty tracking. No encrypted attributes. No horizontal sharding. No secure tokens. No signed IDs. Fixing these issues within Granite's existing architecture would have been a rewrite in all but name.

Grant is that rewrite. It follows the Active Record pattern and targets feature parity with Rails 8+ ActiveRecord. Here's where it stands:

<table>
<tr><th>Category</th><th>Grant</th><th>ActiveRecord</th></tr>
<tr><td>Basic CRUD, timestamps, touch</td><td>Full</td><td>Full</td></tr>
<tr><td>Querying (where, order, limit, joins)</td><td>Full (basic joins partial)</td><td>Full</td></tr>
<tr><td>Scopes, default_scope, query chaining</td><td>Full</td><td>Full</td></tr>
<tr><td>Associations (belongs_to, has_many, has_one, through, polymorphic)</td><td>Full</td><td>Full</td></tr>
<tr><td>Validations (presence, uniqueness, length, format, custom)</td><td>Full</td><td>Full</td></tr>
<tr><td>Callbacks (lifecycle + transaction)</td><td>Full</td><td>Full</td></tr>
<tr><td>Dirty tracking</td><td>Full</td><td>Full</td></tr>
<tr><td>Encrypted attributes</td><td>Full</td><td>Full</td></tr>
<tr><td>Secure tokens, signed IDs, token generation</td><td>Full</td><td>Full</td></tr>
<tr><td>Enum attributes, serialized columns</td><td>Full</td><td>Full</td></tr>
<tr><td>Transactions, nested transactions, isolation levels</td><td>Full</td><td>Full</td></tr>
<tr><td>Optimistic + pessimistic locking</td><td>Full</td><td>Full</td></tr>
<tr><td>Eager loading, query batching</td><td>Full</td><td>Full</td></tr>
<tr><td>Horizontal sharding</td><td>Full</td><td>None</td></tr>
</table>

Three features are worth calling out:

**Horizontal sharding.** Grant has built-in support for distributing data across multiple databases via a `shard_key` declaration. ActiveRecord does not.

**Enumerable query builder.** `Grant::Query::Builder` includes `Enumerable(Model)`. You can call `map`, `select`, `reduce`, and every other standard collection method directly on query chains — no `.all` or `.to_a` conversion needed.

**Crystal compile-time type safety.** Column types, association types, and validation constraints are checked at compile time. An entire class of runtime type errors simply does not exist in Grant.

Here's what a realistic Grant model looks like:

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column first_name : String
  column last_name : String
  column age : Int32?
  column active : Bool = true
  column login_count : Int32 = 0

  # Security
  encrypts :email, deterministic: true
  has_secure_token :auth_token
  has_secure_token :api_key, length: 32, alphabet: :hex

  # Data normalization
  normalizes :email, &.downcase.strip
  normalizes :first_name, &.strip.titleize

  # Associations
  has_many :orders, dependent: :destroy
  has_one :profile, dependent: :destroy

  # Scopes
  scope :active, ->{ where(active: true) }
  scope :recent, ->{ where.gteq(:created_at, 7.days.ago) }

  # Validations
  validates_presence_of :email, :first_name, :last_name
  validates_uniqueness_of :email
  validates_email :email
  validates_numericality_of :age, greater_than: 0, less_than: 150, allow_nil: true

  timestamps
end

# Enumerable query builder
active_emails = User.active.recent.map(&.email)
user_count = User.where(active: true).count
high_value = User.active.select { |u| u.orders.sum(&.total_amount) > 1000.0 }
```

Grant achieves approximately 80-85% feature parity with ActiveRecord while adding Crystal-specific capabilities that ActiveRecord lacks. The remaining gaps are in advanced join operations, connection pooling, and query caching — areas under active development.


## Gemma — File Attachments for Grant

[Gemma](https://github.com/crimson-knight/gemma) handles file attachments. It integrates with Grant through `has_one_attached` and `has_many_attached` macros — the same API style as Rails' ActiveStorage.

Three storage backends ship out of the box: `FileSystem` for local storage, `Memory` for testing, and `S3` for AWS and compatible services (DigitalOcean Spaces, Minio).

```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column id : Int64, primary: true
  column name : String
  column avatar_data : JSON::Any?
  column documents_data : JSON::Any?

  # Single file attachment
  has_one_attached :avatar

  # Multiple file attachments
  has_many_attached :documents

  # Validations
  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png", "image/webp"]
end

# Usage
user = User.new(name: "Jane")
user.avatar = File.open("photo.jpg")
user.documents = [File.open("resume.pdf"), File.open("cover.pdf")]
user.save

# Access
puts user.avatar_url
user.documents.each { |doc| puts doc.url }
```

Gemma also has a plugin system for metadata extraction (MIME type detection, image dimensions) and supports custom uploaders for advanced file path logic.


## Crystal Alpha — The Compiler

Here's the part of the Amber V2 story that no other web framework in any language can tell: **we're building the compiler too.**

The single biggest friction point in Crystal development is compilation speed. A typical Amber application takes 15-30 seconds to compile after a single-file change. That's the full pipeline: parse every file, run all 9 semantic sub-phases, generate LLVM IR for every module, link. Change one line in one controller, wait 20 seconds. It breaks flow.

[Crystal Alpha](https://github.com/crimson-knight/crystal) is a fork of the Crystal compiler that adds two capabilities the upstream compiler does not have: **incremental compilation** and **WebAssembly as a first-class compile target**.

### Incremental Compilation

The incremental compilation system has 7 phases, all complete:

<table>
<tr><th>Phase</th><th>What It Does</th></tr>
<tr><td>1. Watch command</td><td><code>crystal watch</code> — cross-platform file watching with kqueue (macOS), inotify (Linux), and polling fallback</td></tr>
<tr><td>2. Cache foundation</td><td>File fingerprinting and in-memory parse cache — only re-parse files that actually changed</td></tr>
<tr><td>3. Parallel parsing</td><td>Multi-threaded file parsing across available cores</td></tr>
<tr><td>4. Codegen caching</td><td>Skip LLVM IR generation for modules whose source hasn't changed</td></tr>
<tr><td>5. Parallel checks</td><td>Parallelize read-only semantic sub-phases (abstract checks, restrict augmenter, ivar/cvar init)</td></tr>
<tr><td>6. Signature tracking</td><td>Distinguish body-only changes from structural changes — if you change a method body but not its signature, only that module needs recompilation</td></tr>
<tr><td>7. Semantic parallelism</td><td>Research foundation for parallelizing the MainVisitor (the bottleneck that takes 40-50% of compile time alone)</td></tr>
</table>

Phases 1-5 combined deliver approximately 15-30% faster recompilation in watch mode. With Phase 6's signature tracking, body-only changes (which most edits are) see 25-45% improvement.

The `crystal watch` command is the way you develop with Amber V2:

```bash
crystal watch src/my_app.cr
```

It watches every `.cr` file in your project, detects changes, and recompiles only what needs recompiling. No more switching to a terminal to manually rebuild.

### WebAssembly Compilation

Crystal Alpha can compile Crystal programs to `wasm32-wasi`. This is not a toy demo — it handles garbage collection (Boehm GC ported to WASM), exception handling (native WASM EH via `try_table`/`exnref`), and fiber concurrency (Asyncify-based cooperative switching). 74 tests pass across 4 spec suites.

```bash
crystal build app.cr --target wasm32-wasi
wasmtime run --wasm exceptions app.wasm
```

What works today: integers, floats, strings, arrays, hashes, JSON parsing, Base64, CSV, URI handling, random number generation, basic I/O, directory listing, and — critically — exceptions and garbage collection. The full standard library won't be available (some things like raw sockets don't make sense in a WASM sandbox), but the core language works.

**Why this matters for Amber:** WASM compilation means Crystal business logic can run on edge compute platforms (Cloudflare Workers, Fastly Compute, Fermyon Spin). It means you can share validation logic and data models between your server and a WASM module running in the browser. And it opens the door to cross-platform targets: macOS, iOS, Android, WASM, and Linux from a single Crystal codebase.

### Installation

Crystal Alpha builds on Crystal 1.19.1 and targets Crystal 1.20. Install via Homebrew:

```bash
brew tap crimson-knight/crystal-alpha
brew install crystal-alpha
```


## Shards-Alpha — The AI-Aware Package Manager

Package managers distribute code. That was fine when the only consumer of library documentation was a human reading a README. It's not fine when the primary consumer is an AI coding assistant that needs structured context about every library in your project.

[Shards-Alpha](https://github.com/crimson-knight/shards) is a drop-in replacement for Crystal's `shards` binary. It does everything `shards` does — dependency resolution, version locking, building — plus three things `shards` doesn't.

### AI Documentation Distribution

Shard authors ship AI context files alongside their code: `CLAUDE.md`, `.claude/skills/`, `.claude/agents/`, `.claude/commands/`. When you run `shards install`, these files are automatically installed into your project's `.claude/` directory with shard-namespaced paths.

<table>
<tr><th>Shard path</th><th>Installed as</th></tr>
<tr><td><code>.claude/skills/&lt;name&gt;/</code></td><td><code>.claude/skills/&lt;shard&gt;--&lt;name&gt;/</code></td></tr>
<tr><td><code>.claude/agents/&lt;name&gt;.md</code></td><td><code>.claude/agents/&lt;shard&gt;--&lt;name&gt;.md</code></td></tr>
<tr><td><code>CLAUDE.md</code></td><td><code>.claude/skills/&lt;shard&gt;--docs/SKILL.md</code></td></tr>
<tr><td><code>.mcp.json</code></td><td>Merged into <code>.mcp-shards.json</code></td></tr>
</table>

Version tracking uses dual checksums per file (upstream vs. installed). When a dependency updates, unmodified files are silently replaced. Locally modified files are preserved, and the new upstream version is saved as `<file>.upstream` for manual merging.

### MCP Server Distribution and Lifecycle

Shards that ship `.mcp.json` files have their MCP server configurations merged into a project-level `.mcp-shards.json` during install. You manage MCP servers with a single set of commands:

```bash
shards mcp start      # Start all MCP servers
shards mcp stop       # Stop all servers
shards mcp status     # Show server status
shards mcp restart    # Restart servers
shards mcp logs amber # Tail logs for a specific server
```

### Claude Code Assistant Configuration

One command sets up your entire Claude Code environment — skills, agents, settings, and MCP configuration:

```bash
shards-alpha assistant init
```

This installs 6 skills (`/audit`, `/licenses`, `/policy-check`, `/diff-deps`, `/compliance-report`, `/sbom`), 2 agents (`compliance-checker`, `security-reviewer`), pre-approved compliance commands in `.claude/settings.json`, a project context file in `.claude/CLAUDE.md`, and an MCP server entry in `.mcp.json`.

Managing the configuration:

```bash
shards-alpha assistant status     # Show version, components, modified files
shards-alpha assistant update     # Upgrade, preserve local edits
shards-alpha assistant remove     # Remove all tracked files
```

### Supply Chain Compliance

Shards-Alpha includes a suite of supply chain security tools:

- **`shards audit`** — Scan dependencies against the OSV vulnerability database. Supports SARIF output for GitHub Code Scanning, severity filtering, and advisory suppression with expiry dates.
- **`shards licenses`** — List all dependency licenses with SPDX identifiers. Policy enforcement exits non-zero on violations.
- **`shards sbom`** — Generate a Software Bill of Materials in SPDX 2.3 or CycloneDX 1.6 format.
- **`shards policy check`** — Enforce rules about allowed sources, blocked dependencies, and minimum versions.
- **`shards compliance-report`** — Unified report combining SBOM, vulnerabilities, licenses, policy status, integrity verification, and change history. Outputs JSON, HTML, or Markdown. Suitable for SOC2 and ISO 27001 auditors.

### Installation

```bash
brew tap crimson-knight/shards-alpha
brew install shards-alpha
```


## Agent-First Development

Crystal Alpha, Shards-Alpha, and Amber V2 were designed together. Not as three independent projects that happen to work together, but as a single integrated stack where every layer is aware of AI coding assistants.

Here's what that means in practice.

When you run `shards install` in an Amber project, you don't just get library code. You get AI skills, agents, and documentation for every dependency in your project. Amber ships 11 skills and 2 agents. Grant ships its own. Gemma ships its own. Each shard's AI context is installed into your `.claude/` directory, namespaced and version-tracked.

When you open Claude Code in an Amber project, the assistant doesn't just know Crystal syntax. It knows Amber's routing conventions. It knows Grant's query builder. It knows Gemma's attachment macros. It knows the configuration format, the testing helpers, the job system. It has framework-specific expertise for every layer of your stack — not because someone trained a model on Amber code, but because Amber literally distributes the knowledge alongside the code.

This is what no other web framework offers, in any language. Rails doesn't ship Claude skills. Django doesn't distribute MCP servers with pip. Phoenix doesn't install AI agents with mix. They can't, because their package managers weren't designed for it.

Amber is not just a framework. It is a framework that teaches AI assistants how to use it.


## Getting Started

Install the ecosystem tools and create a project:

```bash
# 1. Install Crystal Alpha
brew tap crimson-knight/crystal-alpha
brew install crystal-alpha

# 2. Install Shards-Alpha
brew tap crimson-knight/shards-alpha
brew install shards-alpha

# 3. Install the Amber CLI
brew tap crimson-knight/amber
brew install amber-cli

# 4. Create a new project
amber new my_app
cd my_app

# 5. Install dependencies (also installs AI skills + agents)
shards-alpha install

# 6. Set up Claude Code assistant configuration
shards-alpha assistant init

# 7. Start developing
crystal watch src/my_app.cr
```

After step 7, you have: a running Amber application with zero runtime dependencies, Grant ORM configured and ready, Gemma available for file attachments, a Claude Code environment with framework-specific skills and agents for every layer, supply chain compliance tooling, and a compiler that watches your source files and recompiles incrementally on every save.


## The Philosophy, Restated

Amber 2.0 started with a simple idea: when you install a web framework, it should have everything you need to build a web application. Not pointers to other libraries. Not a list of compatible shards. The actual tools, tested together, released together, maintained together.

That idea has expanded. "Everything you need" now includes the compiler, the package manager, and the AI tooling. When you install Amber, you get a framework with 1,967 passing specs and zero runtime dependencies. When you install Crystal Alpha, you get incremental compilation and WASM support. When you install Shards-Alpha, you get supply chain compliance and AI documentation distribution. When you open Claude Code, you have an assistant that understands every layer of your stack because the framework taught it.

Agent-first development is not a feature bolted onto an existing framework. It is designed into the foundation — from how shards are structured, to how the package manager installs them, to how the compiler watches and rebuilds your code. Every piece was built knowing that an AI assistant would be a first-class participant in the development workflow.

This is a framework for people who want to build things, not assemble toolchains.

We're developing in the open on [GitHub](https://github.com/crimson-knight/amber). If you want to participate, star the repo and join us on [Discord](https://discord.gg/vwvP5zakSn).

Seth Tucker
