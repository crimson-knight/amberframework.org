---
title: "Memory budget contracts"
section: "guides"
order: 91
description: "Choose a memory owner and measurement window, prove regression detection, and carry the same contract into specs, CI, and agent workflows"
---

# Memory budget contracts

A memory budget turns an application requirement into an executable check.
For example: loading a page of records must return the correct records and
stay within a declared allocation allowance. The functional result and the
memory result belong to the same scenario.

The MemoryBudget SDK is a prerelease source candidate. The references below
are pinned to commit `08c30535c60b9097a5da664dc7072e89ec02cad7`.
Its [capability reference](https://github.com/amberframework/memory_budget/blob/08c30535c60b9097a5da664dc7072e89ec02cad7/docs/0.1.1/capabilities.md)
records the admitted profiles and remaining qualification work. Ordinary
installation, real Linux native loading, clean-account use, and additional
devices retain their own acceptance gates. Check the
[candidate PR](https://github.com/amberframework/memory_budget/pull/1)
for the current release state before adopting it.

## Start with the owner and window

Describe the operation, its input, the memory owner, and the measurement
window before choosing a limit. Different measurements answer different
questions and often observe overlapping memory.

| Scenario | Owner and window | What the check establishes |
| --- | --- | --- |
| Construct one value or serialize one response | Current Crystal fiber inside a synchronous block | Allocation calls and requested bytes attributable to that fiber |
| Run an operation with worker fibers | Isolated process window, with every worker joined before it ends | Total Crystal allocation traffic during the operation, including any concurrent work |
| Load pages of different sizes | Explicit, nonempty input sizes; one operation per size | A fixed allowance plus an allowance per item for the exercised sizes |
| Fill and reuse a database cache | One live SQLite connection and declared cold or warm phase | The verified connection cache counter for that connection |
| Open and close a native screen | Fresh application lifetime plus named journey checkpoints | Qualified process memory and peak, including host frameworks and caches |
| Compile a Grant application | Exact model workload, compiler, dependencies, build mode, and complete build tree | Compiler peak and separately qualified complete-build memory |

Crystal requested bytes describe allocation traffic. A native application's
physical memory also includes C libraries, mapped pages, graphics, and
platform frameworks. Keep those views distinct when interpreting a result.
Darwin physical footprint and Linux reported RSS have different meanings.
Linux `/proc/PID/status` RSS counters also have a precision limitation; see
the [kernel's process documentation](https://docs.kernel.org/filesystems/proc.html).
A compiler-only RSS reading requires separate complete-build accounting for
linkers and other owned children.

## Put the contract beside the behavior

For an existing application, keep the policy in
`performance/memory_budget.json`, scenarios under `spec/performance/`, and
the installed runner at `performance/run_memory_budgets.rb`. Extend the
existing spec helper so the application's setup, dedicated test database,
and compiler flags remain part of the test environment. Package dependencies
belong in `shard.yml`; application budget values belong to the performance
policy and the SDK's configuration API.

The [one-record executable example](https://github.com/amberframework/memory_budget/blob/08c30535c60b9097a5da664dc7072e89ec02cad7/docs/0.1.1/examples/fiber_budget_spec.cr)
shows the smallest useful contract: construct the policy and collection
outside the window, create a record inside it, and assert the record's value.
Its regression switch adds an actual buffer allocation to that operation.
The ordinary and regression runs use the same named program.

For a collection workload, exercise several explicit sizes and require a
nonempty size roster. A policy of `fixed_bytes + bytes_per_item * count`
expresses the intended scaling rule. Choose its constants from repeatable
measurements and the product's requirement; attach the exercised sizes and
repetitions to the result.

## Examples at each layer

**Library:** measure one parser, encoder, or record construction while
asserting the returned value. This gives a focused diagnostic for a library
change. An input-dependent collection spec adds the scaling contract.

**Web application:** assert the real request's status and response contents.
Choose a synchronous fiber window when it covers the operation; choose an
isolated, joined-process window when work moves to other fibers. Give the
whole server process a separate policy when infrastructure and caches are
part of the product requirement.

**Database:** use a verified live SQLite connection counter and explicitly
name the cold or warm phase. Atlas observed a successful global zero while
a connection retained cache memory. Connection-level behavior needs its
own positive control and functional query result.

**Native application:** keep focused Crystal logic specs and add the real
screen or application journey. Launch a fresh process when claiming an
independent lifetime peak. Attribute host-framework and mapped memory at
named checkpoints, and preserve any tracing coverage limitations. A small
Crystal allocation result describes that scope within the larger app.

**Grant compilation:** exercise queries and hydration for every declared
model and the intended association edges, finish code generation and
linking, then run the resulting program. The current research target is
strictly below **2,000,000,000 bytes** for representative default-feature
300- and 500-model applications, for both compiler peak and qualified
complete-build memory. That target remains unmet. Optional feature
compositions require source-verified opt-in APIs, paired measurements, and
their own feature labels and compatibility results.

## Prove the check can fail

Run the functional workload with sufficient allowance. Then run the same
executable with a real added allocation or an intentionally tight limit and
require the expected scenario and metric to fail. Restore the normal input
and require it to pass again. Record the executable identity for every run.

Require complete scenario, metric, and capability rosters. Missing evidence,
duplicate observations, unsupported profiles, source drift, and lost tracing
coverage must fail acceptance. Independently compare measured values with
the limits; a report's label or its successful reporting exit is only part
of the evidence. Preserve failed observations alongside successful ones.

The original Atlas comparison table retained nine failed comparisons: six
used incompatible cold SQLite scopes, and three lost the original source
frame for optimized CoreFoundation frees. These locate limits in the
comparison method. The supported checks use matching cold scopes, verified
connection cache counters, and allocation-owned release records. Read the
[capability reference](https://github.com/amberframework/memory_budget/blob/08c30535c60b9097a5da664dc7072e89ec02cad7/docs/0.1.1/capabilities.md)
before selecting a measurement for a new app or platform.

## Carry the same contract into CI

Use the [CI integration guide](https://github.com/amberframework/memory_budget/blob/08c30535c60b9097a5da664dc7072e89ec02cad7/docs/0.1.1/ci.md)
and [workflow template](https://github.com/amberframework/memory_budget/blob/08c30535c60b9097a5da664dc7072e89ec02cad7/templates/memory-budgets.yml)
with the matching installed kit. The template identifies a qualified
self-hosted runner; each new runner needs its own admitted toolchain,
standard library, native libraries, and measurement profile. Keep required
status checks tied to an actually exercised runner.

The CI result should bind source, dependencies, policy, compiler profile,
and executable by hash. Retain raw observations and independently verified
verdicts, including deliberate regression detection. Normal suite behavior,
instrumented behavior, and release installation each carry their own
evidence. The guide's runner command applies after that kit is installed.

## Use the docs with an agent

Connect to the existing [Amber documentation MCP](/docs/v2/guides/ai-assistants/mcp).
Search for `memory budget contracts`, then read
`guides/memory-contracts`. The page's Markdown, JSON, and knowledge-bundle
forms carry the same guidance for tools that consume documentation directly.

The [versioned agent skill](https://github.com/amberframework/memory_budget/blob/08c30535c60b9097a5da664dc7072e89ec02cad7/skills/crystal-memory-budgets/SKILL.md)
guides an agent through choosing a scope, preserving the project's setup,
adding functional assertions, and diagnosing an actual budget failure.
Record the installed skill and SDK identities, then evaluate an agent on a
real passing and failing consumer task. A packaged skill and a successful
installed-agent evaluation are separate deliverables.
