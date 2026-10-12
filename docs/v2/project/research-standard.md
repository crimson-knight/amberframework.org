---
title: "Measure, explain, and publish the decision"
section: "project"
order: 70
description: "Reproducible research records for performance and component changes"
---

# Measure, explain, and publish the decision

Every research change starts with an issue proposal. Name the real app problem, workload and observable correctness. Profile its cost, state one hypothesis, make the focused change and compare it on the same workload.

Record baseline/candidate full commits and any dirty patch hash; exact toolchain/dependency/OS/worker identities and hashes; build flags and fixture identity. Publish commands, warmup, repeated trials with rotated order, response/input checks, raw results, variability and neighboring-workload effects. Ratios name their baseline and aggregation method.

Keep the decision with the evidence: keep, revise, reject or inconclusive. Link the proposal, PR and eventual released implementation. Useful rejected experiments help the next contributor understand the choice.

Scope each result precisely: component, framework, complete application, native runtime or compiler. A component claim needs a runnable consumer and interaction states. Native claims name emulator/simulator/device, fresh launch, input and lifecycle. Accessibility claims name exactly which automated and human checks ran.

Business-pattern recommendations require the complete application/database workload under the [template contract](/docs/v2/project/business-templates). Publish data shape, deployment, cold/steady/burst/soak scenarios, correctness, repeated measurements, headroom and limits. Current app invitations have no measured capacity profiles.

Store the report and harness with the owning repository. Share a short public explanation of the cost, change and outcome, then link the full methods and raw evidence. A release note needs one user-facing sentence and those links. Source or environment changes invalidate affected results until rerun and review.

[Explore the retained component and performance research](https://amberframework.org/research/) · [Follow releases](https://amberframework.org/release-tracker/) · [Bring a proposal](https://github.com/amberframework/amber/issues).
