# Amber research contribution standard draft

Every change starts with an issue proposal. Research turns that proposal into a reproducible explanation of the problem, the change, and the decision. This draft extends the contribution contract for performance and component work.

## The smallest useful record

1. **Problem and workload:** Who is affected; request/route/data/component/device shape; observable correctness and usability requirements.
2. **Discovery:** Profile or audit artifact identifying the cost or behavior; link its raw data and hash.
3. **Hypothesis:** One change and the predicted measurable effect.
4. **Identity:** Baseline/candidate full source commits plus dirty patch hash when applicable; exact toolchain/dependency/OS/device identities and hashes; build flags and fixture hash.
5. **Method:** Reproduction commands, warmup, repetition count, rotated baseline/candidate order, environment limits, and complete response/input checks.
6. **Results:** Raw trials, within-pair comparisons, p50/p95/p99 where relevant, allocation/memory, sample variability, and neighboring-workload regressions. Ratios state their baseline and aggregation method.
7. **Behavior:** Correctness, concurrent ownership, malformed-input/limit behavior, or component keyboard/focus/theme/reflow checks appropriate to the change.
8. **Decision and availability:** Keep, revise, reject, or inconclusive; known limits; linked proposal and PR; eventual release/tag/artifact evidence.

A component usability claim includes a runnable consumer and its interaction states. An accessibility claim names exactly what automated checks, assistive-technology checks, and human checks ran. A native result names simulator/emulator/device and includes fresh launch, input, lifecycle, and applicable presentation/energy evidence.

## Store and publish it once

Keep the detailed report and reproduction harness with the owning repository. Use a stable research ID such as `amber-router-mixed-routes`; give each run an immutable evidence bundle with hashes. A publication registry associates the research ID with its report, code/proposal/PR links, implementation status, and released version. Feature labels associate the record with relevant roadmap cards.

The public note answers three questions in a few paragraphs: what cost did we discover, what did we change, and what happened on the same workload? It links to the full methods and raw evidence. The release note uses one bounded user-facing sentence and that same research link.

Suggested PR fields:

```text
Proposal: <fully qualified issue URL>
Research: <stable report URL or repository path>
Evidence: <bundle URL and SHA-256>
Result scope: <component | application | framework | native runtime | compiler>
Decision: <keep | revise | reject | inconclusive>
Release sentence: <one user-facing sentence>
```

## Review and automation

The reviewer confirms that the method exercises the claimed behavior, the raw data reproduces the summary, and the candidate improves the intended scenario without unacceptable regressions. Include a deliberate corrupt/missing-sample or exceeded-budget probe so a healthy-looking summary cannot conceal a failed run.

The proposed collector imports reviewed metadata from trusted source records. A changed report/source identity invalidates its previous verification until reconciliation succeeds. Preserve negative and inconclusive results as research; only kept, merged, and actually released changes become shipped accomplishments. Site and GitHub views share the same record.

Current automation in this packet reconciles retained cloud samples and source identities locally. Required PR checks, publication registry ingestion, public research hosting, and automatic synchronization remain installation work.

## Research behind recommended business patterns

A recommendation carries a working reference app and a tested operating range under the [business-template contract](/docs/v2/project/business-templates). Describe the reader's problem, selected pattern, assumptions, measured alternative and decision. Run complete application/database requests and jobs against representative data, with correctness, cold/steady/burst/soak scenarios, repeated samples, declared deployment and operational headroom. Publish raw results and the applicable exact template/release identity beside the tutorial.

Core routing, codecs, model-only work, and application capacity keep separate claim scopes. Every numeric template capacity needs its own app/database evidence. The current three app invitations have zero measured profiles. [The tenancy article](TENANCY_STORY_DRAFT.md) and [editorial backlog](PATTERN_EDITORIAL_BACKLOG.md) start the publication trail and name remaining tutorial, migration, candidate and measurement gates.

A relevant source/schema/index/configuration/workload/environment change invalidates the affected profile until rerun and review. Keep the reusable reference harness with the template, so builders and agents can choose a published profile and check their app's assumptions without designing the methodology from scratch.

[The public-state accuracy process](../contribution-system/ACCURACY_PROCESS.md) defines owners, state transitions, source-change review, separate measurement and verification dates, and event/daily reconciliation. The local comparison validator reproduces values from the retained sources and exact released package manifests before accepting the display payload.
