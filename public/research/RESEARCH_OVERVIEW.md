# Amber V2 components and performance research draft

Amber V2 has a usable component foundation and a substantial performance research program. The roadmap should show both the implementation people can use and the experiments that explain how it got there. This overview reconciles the source and retained evidence on October 5, 2026. The measurements retain their original dates and workload scopes.

## A component trail people can follow

Asset Pipeline v0.37.0 includes the web design-system corpus and reusable component primitives. FrontLoader provides import maps, module preloads, script generation, framework integration, and dependency analysis. Its companion StaticAssets compiler provides content-addressed assets, rewritten local references, integrity manifests, and runtime lookup. The modern design-system proof uses semantic HTML, token-backed CSS, and vanilla JavaScript helpers.

Frontloader Studio is the demonstration product built with that system. Its seven generated pages cover the overview, pricing/payment, auth/forms, dashboard/data, timeline, collaboration/search/chat, and interaction patterns. The reusable surface includes buttons, cards, form fields, dialogs, tabs, tables, charts, page shells, layout and feedback primitives, theme controls, and font delivery choices. Neutral `Components::DesignSystem`, `--ap-*`, and `data-ap-*` APIs coexist with compatibility aliases.

These capabilities are implemented, rather than simply a future component-library target. A fresh October 5 run passed 134 component primitive, example, enhanced FrontLoader, and script-integration examples with zero failures, errors, or warnings under crystal-alpha. Compile/spec status: GREEN for that focused run. Native platform support has its own device and publication gates.

The retained static, manifest, axe-core, IBM Equal Access, reduced-motion, and accessibility-tree reports pass. The current retained combined browser audit reports 100 findings, including theme-variable checks, and is not a clean browser acceptance result. These reports establish useful coverage; they do not establish complete WCAG conformance or current screen-reader behavior. Publish the report identities and reconcile those findings as part of the consumer trail.

[Released component guide](https://github.com/amberframework/asset_pipeline/blob/v0.37.0/docs/web-design-system/README.md) · [Component API](https://github.com/amberframework/asset_pipeline/blob/v0.37.0/docs/web-design-system/component-api.md) · [Asset Pipeline release](https://github.com/amberframework/asset_pipeline/releases/tag/v0.37.0).

## Core optimization with a controlled workload

The round-19 program tested 500, 1,000, and 1,500 mixed routes, route semantics, consumed parameters, allocations, parsed requests, and real localhost sockets. The safe matcher improved 3.33–4.05 times across the recorded compiler/route matrix. At 1,000 routes with parameter consumption, stock-compiler results changed from about 1.63 million to 5.75 million matches per second, with allocation falling from 871 to 130 bytes per match.

That isolated improvement translated into smaller complete-request gains, as expected. At 50 localhost connections, recorded direct JSON throughput increased 6.5%; `respond_with` throughput increased 12.2%, with p99 latency falling 16.8%. Parsed-HTTP CPU results exclude sockets and kernel scheduling and retain their separate scope.

The released beta.5 route-set source is byte-identical to the measured round-19 matcher, and its default router calls the span path. This verification uses source identity because the experiment checkpoint is not an ancestor of the release history. It establishes implementation inclusion; the historical performance numbers remain tied to their original workload, compilers, and hardware.

[Round-19 report](https://github.com/crimson-knight/amber/blob/81516a59852e55a9284395e19ee832dd2c9ca132/benchmarks/ROUTER_PERFORMANCE_ROUND19.md) · [Released matcher](https://github.com/amberframework/amber/blob/v2.0.0-beta.5/src/amber/router/engine/route_set.cr).

## Hosted complete request research

Rounds 22 and 25 used a separate load generator and a one-shared-vCPU DigitalOcean target. A deterministic 1,000-route mixed API consumed payload fields and serialized real responses. Seven rotating repetitions per candidate retained source/compiler/binary identities, request-table hashes, latency, CPU, memory, and response errors.

| Round 25 body path | Median requests per second | Median paired change vs JSON | Paired wins |
| --- | ---: | ---: | ---: |
| Generic JSON params | 24,505 | Baseline | — |
| Buffered typed JSON | 25,621 | +7.3% | 5/7 |
| MessagePack map | 30,020 | +22.8% | 7/7 |
| MessagePack array | 30,453 | +25.2% | 6/7 |
| CBOR map | 26,288 | +12.4% | 6/7 |
| CBOR positional array | 31,594 | +28.7% | 7/7 |

Round 25 retained 42 trials and 17,252,140 successful responses with zero socket errors or non-2xx responses. The paired estimate differs from dividing aggregate medians because it compares variants within each rotating repetition. CBOR map had worse aggregate p99 than JSON: 4.10 ms versus 3.55 ms. Throughput and latency belong together.

Round 22 separately retained 49 trials and 18,728,053 successful responses. It measured 21,795 median RPS for its JSON baseline, 25,072 for typed JSON, and 29,297 for MessagePack array. These are distinct runs; compare candidates against their own control. The earlier blog and white-paper drafts already provide a substantial publication starting point.

These codec candidates are research prototypes. Their measured container/field validation is separate from the production request-schema API. The round-25 report describes an earlier placeholder-schema state; beta.5 subsequently ships executable schemas, so the earlier blocker is historical context. This pass verifies the retained experiments and current release identity; it does not attribute the prototype gains to today's released schema/CBOR path.

The host runs are compact synthetic API workloads, distinct from the marketing homepage, database-backed workloads, native UI, and cross-framework leaderboards. Round-25 materials remain local. `build_evidence.py` reconciles all 91 trials, recomputes medians and paired ratios, checks response errors, verifies released router identity, and deliberately alters measurements to prove that mismatched aggregates fail. It does not rerun the cloud benchmarks.

[Public round-22 technical report](https://github.com/crimson-knight/amber/blob/81516a59852e55a9284395e19ee832dd2c9ca132/benchmarks/DIGITALOCEAN_FRAMEWORK_ROUND22.md) · [Existing reader-facing article draft](https://github.com/crimson-knight/amber/blob/81516a59852e55a9284395e19ee832dd2c9ca132/docs/publications/amber-request-path-performance-blog.md) · [Reconciled local evidence](evidence.json).

## Application work, component caching, and useful rejected experiments

The September Pet Tracker lab found that a 50-record page still copied all 10,000 model records. Bounded page snapshots reduced p95 model CPU from 52.162 to 0.349 microseconds and median allocation from approximately 320,050 to 2,080 bytes. Each result uses 21 recorded batches. Full rendering and the measured HTTP path did not improve from this model change; that is part of the finding.

Profiling then found repeated regular-expression compilation in Asset Pipeline's touch-target renderer. Caching two immutable patterns preserved byte-identical HTML at 50, 1,000, and 10,000 records. Twenty-one alternating pairs at each size reduced median paired full-render CPU by 31.7%, 23.7%, and 31.6%, respectively. A separate 600-render trace recorded 26.4% fewer whole-process cycles, including setup and GC. One trace per variant supports that workload observation, rather than a cross-device guarantee. The retained report describes a saved framework patch with an open dependency-pin gate; current release inclusion has not been verified.

The September 28 CLI findings also record component cache warming: a 50-row, 10,507-byte table changed from cold p50/p95 19.834/42.834 microseconds to prewarmed 0.875/1.083 microseconds across 500 release-build iterations. Those figures are retained report values; this pass has not located their raw timing samples. They measure a component, separate from complete Amber requests. Four alternating PGO comparisons found no stable p95 gain, so the compiler experiment remains inconclusive.

The local evidence auditor recomputes the model p95, all 63 renderer pairs, identical-output hashes, and cycle-counter change from retained artifacts. It copies those artifacts alongside the cloud matrices. These application and component findings extend the research story while preserving their scope and availability.

[Model baseline](model-cpu-before.jsonl) · [Model candidate](model-cpu-after.jsonl) · [Paired renderer trials](renderer-ab.jsonl) · [Cycle counters](renderer-cpu-counters.json).

## Make the research a contribution standard

Each performance proposal should name a real workload, its current cost, and a testable hypothesis. Its PR should link a short research record containing the baseline, exact change, paired result, behavioral checks, and keep/reject decision. A release gets one user-facing sentence and a link to the full record.

Publish useful rejected ideas too: unsafe shared mutable matcher results, noisy validation micro-optimizations, and streaming typed JSON that lost to one bounded buffer all explain why the accepted design is the way it is. The record makes future contributors faster and helps reviewers challenge the evidence.

Use [the research standard](RESEARCH_STANDARD.md) for new proposals and PRs. Keep component, core framework, application, native runtime, and compiler measurements explicitly scoped. The website should expose a research library linked to roadmap cards and the exact releases that contain accepted changes.
