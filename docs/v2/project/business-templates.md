---
title: "Choose a pattern with a tested operating range"
section: "project"
order: 50
description: "The business-template promise and the evidence behind recommendations"
---

# Choose a pattern with a tested operating range

We want you to choose a familiar business pattern and deployment profile before building. Every recommendation should explain the problem it solves, why we chose it, how to migrate, and what we measured. Maintainers supply the working reference app and reusable checks; you and your assistant choose a profile and verify your app's assumptions.

The intended promise is specific: this version of this template meets these correctness and performance targets under this published workload and environment. A wider range requires another measurement and review.

| App idea | First pattern to evaluate | First useful proof |
| --- | --- | --- |
| Organization client portal | Shared tables with row-scoped tenancy; preserve PostgreSQL schemas when that fits an existing Apartment app | Two organizations create, list, edit and restart; authorization and jobs preserve ownership |
| Inventory tracker | Typed forms, durable records, indexed lookups and bounded lists | Correct stock movements, concurrent updates, search/edit and restart persistence |
| Service request desk | One typed workflow, registered jobs and a verified delivery adapter | State transitions, safe repeated work, reminder delivery and recovery |

These are app invitations. Packaged reference templates, executed migration tutorials and measured capacity profiles are in preparation. The default memory job adapter is process-local and lost on restart; reliable reminders need their own verified delivery/recovery path.

## What a recommendation carries

- A runnable example at an exact template/release revision and hash, with supported toolchain/dependencies, configuration, schema/indexes and fixtures.
- A short explanation of intended use, assumptions, measured rationale and meaningful alternatives.
- A version-pinned migration with ID/relationship/constraint checks, dry run, cutover and rehearsed recovery.
- A measured operating range: tenant/data distribution, request/job mix, offered rate and concurrency, hardware/resources, database/pool/network, cold/steady/burst/soak durations, correctness, latency, throughput, errors, CPU/memory and relevant database/queue results.
- Raw repeated trials, uncertainty, operational headroom, observed limits, accountable review and intended-use guidance for people and agents.

Core router or codec results supply evidence at their own scope. Numeric business-app capacity needs complete application/database measurements. You own suitability and acceptable latency, isolation, cost and growth needs; maintainers own the reference profile and harness.

A relevant source, schema/index, configuration, workload or environment change invalidates the affected profile until remeasurement and review. Keep earlier profiles tied to earlier releases. Publish the tutorial, profile, agent guidance and budgets together through the [release contract](/docs/v2/project/release-contract).
