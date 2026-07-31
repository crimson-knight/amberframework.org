# Shards-Alpha: Supply Chain Compliance + AI Tooling for Crystal

Back in the [Amber 2.0 roadmap](https://amberframework.org/blog/2023/04/24/amber-2.0-roadmap), I said AI-powered development should be a first-class citizen in a developer's tooling. Today I'm shipping the first major piece of that vision: **shards-alpha**, a drop-in replacement for the Crystal package manager that adds supply chain compliance tooling and AI assistant integration.

Everything `shards` does, `shards-alpha` does too — plus the new stuff. It's designed to work with Amber v2 and any Crystal project.

## Why This Matters for Amber

Amber 2.0 is about empowering a solo developer to go from idea to enterprise. That means the tooling around the framework has to handle the hard stuff: security audits, license compliance, dependency integrity, and now — making your AI assistant actually understand your dependencies. Shards-alpha brings all of that into the package manager where it belongs.

## Supply Chain Compliance

Crystal projects have had no built-in answer for questions that come up in SOC2 audits, ISO 27001 certifications, and general security hygiene: Are my dependencies vulnerable? What licenses am I pulling in? Has anything been tampered with? What changed since the last release?

Other ecosystems have `npm audit`, `cargo audit`, `pip-audit`. Now Crystal has this:

```sh
shards audit                    # Vulnerability scan against OSV database
shards licenses --check         # License inventory with SPDX validation
shards policy check             # Enforce dependency rules (.shards-policy.yml)
shards diff --from=v1.0.0       # What changed since a release tag?
shards compliance-report --format=html  # Unified report for auditors
shards sbom --format=cyclonedx  # Software Bill of Materials
```

Every `shards install` now records SHA-256 checksums in `shard.lock`. Subsequent installs verify them. If someone tampers with a dependency, you get a clear error instead of silent corruption.

The audit command hits the [OSV database](https://osv.dev/) — the same vulnerability data that powers `osv-scanner`, GitHub's dependency alerts, and Go's `govulncheck`. Output formats include terminal, JSON (for CI), SARIF (for GitHub Code Scanning), and markdown (for PRs).

Policy enforcement is opt-in via `.shards-policy.yml`:

```yaml
rules:
  sources:
    allowed_hosts:
      - github.com
    deny_path_dependencies: true
  dependencies:
    blocked:
      - name: sketchy_shard
        reason: "Unmaintained, use alternative_shard instead"
  security:
    require_license: true
    audit_postinstall: true
```

Policies are checked automatically during `shards install` — violations block the install before anything gets written to disk.

## AI Documentation Distribution

This is the part that ties directly back to the Amber 2.0 vision. Shard authors can now ship AI context alongside their library code:

```
my_shard/
  src/my_shard.cr
  CLAUDE.md                              # "Here's how to use my library"
  .claude/skills/getting-started/SKILL.md  # Step-by-step workflow
  .mcp.json                              # MCP server for AI tool access
```

When a consumer runs `shards install`, these files are automatically installed into their `.claude/` directory with shard-namespaced paths. No configuration needed from the consumer.

This means when you `shards install kemal` (hypothetically, if kemal shipped AI docs), Claude Code would immediately know how to write kemal routes, middleware, and handlers — because the library author told it how, right there in the dependency.

**For Amber v2, this is the delivery mechanism.** As we ship Amber shards with AI documentation, any developer using shards-alpha gets an AI assistant that understands Amber's conventions, routing, domain model structure, background jobs, and the asset pipeline — automatically, as a side effect of `shards install`.

User modifications are tracked with dual checksums. If you customize a skill file, `shards update` won't overwrite it — it saves the upstream version as `.upstream` so you can merge manually.

## MCP Compliance Server

An [MCP](https://modelcontextprotocol.io/) server exposes all six compliance tools to AI agents:

```sh
shards mcp-server init    # Add to .mcp.json
```

Now Claude Code (or any MCP client) can directly invoke audits, license checks, and policy enforcement through natural language. "Audit my dependencies" just works — the agent calls the MCP tool and interprets the structured JSON response.

## Claude Code Assistant Setup

One command sets up your project with compliance-focused Claude Code skills and agents:

```sh
shards assistant init
```

This installs 6 skills (`/audit`, `/licenses`, `/policy-check`, `/diff-deps`, `/compliance-report`, `/sbom`), 2 agents (compliance-checker, security-reviewer), pre-approved command permissions, and project context. Everything is version-tracked so future releases can upgrade your config with `shards assistant update` while preserving your local edits.

Projects can opt into automatic setup:

```yaml
# shard.yml
ai_assistant:
  auto_install: true
```

With this, `shards install` handles everything — your CI clones the repo, runs install, and Claude Code is ready to go with compliance tooling pre-configured.

## How This Was Built

This entire project — the vulnerability scanner, the SPDX license validation (52 identifiers + compound expressions), the policy engine, the lockfile differ, the MCP server with protocol version negotiation, the SBOM generator (both SPDX 2.3 and CycloneDX 1.6), the compliance report system, the AI docs distribution pipeline, the assistant configuration manager with version tracking — was built with Claude Code as a pair programmer.

The compliance features alone span ~15 source files and ~5,000 lines of Crystal. The test suite has 349 unit tests. The `assistant` command uses compile-time macros (`{{ run() }}`) to embed versioned file trees into the binary so that configuration files don't need to exist on disk at runtime — they're baked into the executable.

The experience of building with an AI that understands your codebase, can plan multi-file refactors, writes tests that actually catch bugs, and runs the compiler in a loop until things work — that experience is qualitatively different. Tasks that would have taken days took hours. Not because the code is simpler, but because the iteration speed is just different when your pair programmer has perfect recall of every file in the project.

The AI docs distribution feature is a direct expression of this: if AI assistants are going to be a real part of how we write code, then package managers should distribute the context those assistants need. Your dependencies should make your AI smarter, automatically, as a side effect of `shards install`.

## Getting Started

Install via Homebrew:

```sh
brew tap crimson-knight/tap
brew install shards-alpha
```

Or install from source:

```sh
git clone https://github.com/crimson-knight/shards.git
cd shards && git checkout alpha
crystal build src/shards.cr -o bin/shards-alpha --release
# Copy bin/shards-alpha to your PATH
```

Then in any Crystal project:

```sh
shards-alpha assistant init     # Set up Claude Code integration
shards-alpha audit              # Check for vulnerabilities
shards-alpha licenses           # Review dependency licenses
```

The [repo](https://github.com/crimson-knight/shards) has full documentation including a [compliance guide](https://github.com/crimson-knight/shards/blob/alpha/docs/compliance-guide.md), [MCP server docs](https://github.com/crimson-knight/shards/blob/alpha/docs/mcp-compliance-server.md), and a working [example project](https://github.com/crimson-knight/shards/tree/alpha/examples) showing AI docs distribution end-to-end.

## For Shard Authors

If you want your shard to be AI-friendly, just add a `CLAUDE.md` to your repo root. That's it. When someone installs your shard with shards-alpha, the file gets distributed automatically. For richer integration, add `.claude/skills/` directories with `SKILL.md` files. The [examples directory](https://github.com/crimson-knight/shards/tree/alpha/examples) shows exactly how.

## What's Next

This is the foundation for how Amber v2 will distribute AI context across the framework ecosystem. As Amber shards ship with AI documentation, the entire framework becomes AI-native — your assistant understands your tools because the tools tell it how they work.

We'd love feedback — on the features, the approach, or ideas for what else the package manager should do now that we're thinking about AI-assisted development as a first-class concern. This is all open source under Apache 2.0.

Join us on [Discord](https://discord.gg/vwvP5zakSn) or open an issue on the [shards-alpha repo](https://github.com/crimson-knight/shards).
