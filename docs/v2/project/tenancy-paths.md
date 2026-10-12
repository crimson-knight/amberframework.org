---
title: "One app, several organizations"
section: "project"
order: 60
description: "Choosing shared-table or PostgreSQL schema tenancy with Grant"
---

# One app, several organizations

An Amber user asked for multi-tenancy similar to Apartment in Rails. Their real need was a client portal where each organization owns its records. That led to Grant's row and PostgreSQL schema tenancy work, now merged into source. CLI 2.0.7 includes the updated Grant source pin. The complete runnable migration tutorial and measured portal profile are still being prepared.

For a new shared-table app, records carry a tenant column. Grant's model declaration is `multitenant :tenant_id`, with context established by `Grant::Tenant.with(id)`. The documented scope checks reject missing tenant context and mismatched writes. App authorization still determines which organization the person can access.

Apartment's documented layouts use PostgreSQL schemas or separate databases. For an existing schema-based app, first evaluate retaining schemas. Grant's PostgreSQL path uses `Grant::SchemaTenant.with("organization_schema")`; shared models can declare `schema_tenant_excluded`. A block pins a connection and restores context afterward. The app orchestrates DDL across existing tenant schemas and sizes the pool for concurrent requests and jobs.

Start with two organizations. Exercise normal and denied reads/writes, concurrent requests, failures/restoration and persisted records after restart. Carry the authorized tenant identity into background work and establish its context inside the job; fiber-local context needs explicit setup in a new worker.

Pin source Rails/Apartment and target Amber/Grant versions. If moving several schemas into shared tables, overlapping primary keys need an explicit new key mapping and foreign-key transformation. Preserve tenant ownership, constraints and relationships, compare counts, and rehearse cutover and recovery on representative data.

The pattern recommendation should come with a real database-backed operating range. Current core research does not establish this portal's capacity. We still need a runnable reference app, passing candidate/consumer and migration checks, repeated realistic workload measurements and reviewed budgets before publishing a scale promise.

[Grant tenancy source](https://github.com/crimson-knight/grant/pull/46) · [Versioned schema guide](https://github.com/crimson-knight/grant/blob/c89099a3470b08cc914ca0e72538d9d3b64cc525/docs/schema_tenancy.md) · [Apartment documentation](https://github.com/rails-on-services/apartment) · [Template promise](/docs/v2/project/business-templates).
