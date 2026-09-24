---
title: "Multi-tenancy"
section: "guides/models/grant"
order: 65
description: "Row-level and PostgreSQL schema-per-tenant multi-tenancy in Grant, including a migration path from Rails' apartment gem"
---

# Multi-tenancy

> **Grant version:** The APIs on this page need Grant at commit
> `039b29468e3a1b853d9e16ba9d0738c12ea1ee23` or later. Amber CLI `2.0.6` pins
> an earlier commit, so update the `grant` entry in `shard.yml` and run
> `shards update grant`:
>
> ```yaml
> grant:
>   github: crimson-knight/grant
>   commit: 039b29468e3a1b853d9e16ba9d0738c12ea1ee23
> ```

Grant supports two kinds of multi-tenancy. Pick the one that matches how your
data is laid out today.

| Your data today | Use | Rails equivalent |
|---|---|---|
| One set of tables with a `tenant_id` (or `account_id`) column | **Row tenancy**: `multitenant :tenant_id` | `acts_as_tenant` |
| One PostgreSQL schema per tenant, identical tables in each | **Schema tenancy**: `Grant::SchemaTenant` | `apartment` (ros-apartment) |

Both modes set the tenant once per request and keep it **fiber-local**, so two
requests served at the same time never see each other's tenant. Both fail
loudly when a query runs without a tenant, rather than silently reading every
tenant's rows.

## Where the examples go

- Model declarations belong in one class file under `src/models/`.
- The tenant pipe belongs in its own file, such as `src/pipes/tenant_pipe.cr`,
  and is plugged into a pipeline in `config/routes.cr`.
- Queries run from the controller, job, or spec that owns the operation.

## Row tenancy

Add a tenant column to each tenant-owned table and declare it on the model:

**File: `src/models/invoice.cr` — create this model class.**

```crystal
class Invoice < Grant::Base
  connection primary
  table invoices

  column id : Int64, primary: true
  column tenant_id : Int64?
  column number : String

  multitenant :tenant_id
end
```

Wrap each unit of work in the current tenant:

```crystal
tenant_id = 42_i64 # Use the non-nil ID from the trusted account lookup.

Grant::Tenant.with(tenant_id) do
  Invoice.where(number: "INV-100").first # WHERE tenant_id = ? AND number = ?
  Invoice.count                          # counts this tenant's rows only
  Invoice.create!(number: "INV-101")     # tenant_id is filled in for you
end
```

What `multitenant` guarantees:

- **Every query is scoped.** `where`, `order`, `find`, `find_by`, `first`,
  `last`, `count`, `exists?`, calculations, joins, eager loads, batches, and
  bulk writes (`update_all`, `delete_all`, `destroy_all`) all add the tenant
  filter.
- **No tenant, no query.** Any of those calls outside `Grant::Tenant.with`
  raises `Grant::NoTenantError`.
- **New records inherit the tenant.** A `nil` tenant column is filled from the
  current tenant on create.
- **Cross-tenant writes are rejected.** Saving, updating, or destroying a record
  that belongs to another tenant raises `Grant::TenantMismatchError`.
- **Associations stay inside the tenant.** Association lookups, nested
  attributes, and eager loading resolve through the owner and the scope.

For deliberate cross-tenant work, such as an admin report or a data migration,
use `unscoped`:

```crystal
Invoice.unscoped.where(number: "INV-100").count

Invoice.unscoped do
  Invoice.where(tenant_id: nil).update_all(tenant_id: 1_i64)
end
```

Index the tenant column first in a composite index that also covers your common
filters, such as `CREATE INDEX ON invoices (tenant_id, created_at)`.

## Schema tenancy (PostgreSQL)

Schema tenancy keeps each tenant in its own PostgreSQL schema, exactly like the
`apartment` gem. Use it when you are migrating an Apartment app and do not want
to restructure its data first.

Tenant-owned models need no extra declaration. Use separate model classes for
row tenancy and schema tenancy: the row-scoped `Invoice` model above still
requires a row tenant, while `TenantInvoice` belongs to the schema. Models
whose tables live in `public` for every tenant, such as users or plans, are
marked excluded:

**File: `src/models/tenant_invoice.cr` and `src/models/payment.cr` — create
these tenant-owned model classes.**

```crystal
class TenantInvoice < Grant::Base
  connection primary
  table tenant_invoices

  column id : Int64, primary: true
  column number : String
end

class Payment < Grant::Base
  connection primary
  table payments

  column id : Int64, primary: true
  column amount_cents : Int64
end
```

**File: `src/models/plan.cr` — create this model class.**

```crystal
class Plan < Grant::Base
  connection primary
  table plans

  column id : Int64, primary: true
  column code : String

  schema_tenant_excluded
end
```

Inside a block, every statement on that fiber runs against the tenant's schema,
with `public` second in the search path:

```crystal
Grant::SchemaTenant.with("acme") do
  TenantInvoice.create!(number: "INV-100") # acme.tenant_invoices
  Plan.where(code: "pro").first             # public.plans
end
```

How it stays safe under concurrency:

- The block checks out **one** pooled connection and pins it to the fiber, so
  reads, writes, transactions, and eager loads all use the same session.
- Grant runs `SET search_path TO "acme", public` on that connection, and
  `RESET search_path` before the connection returns to the pool, including when
  the block raises. If the reset fails, Grant closes the connection instead of
  returning it.
- Schema names are validated and quoted, so a hostile subdomain cannot inject
  SQL.

Size your connection pool for the number of requests and jobs that run tenant
blocks at the same time: each active block holds one connection.

### Tenant lifecycle

```crystal
tenant_schema = "acme_demo"
Grant::SchemaTenant.create_schema(tenant_schema)
Grant::SchemaTenant.create_tables(tenant_schema, TenantInvoice, Payment)
puts Grant::SchemaTenant.list_schemas.inspect
Grant::SchemaTenant.drop_schema(tenant_schema, cascade: true)
```

Create the tables for excluded models once, in `public`, with their migrator.
The final call permanently deletes the named schema and its objects, so use a
disposable schema when exercising it.

## Selecting the tenant per request

Both modes use the same shape of Amber request pipe: look up the tenant from a
trusted account record, then wrap `call_next(context)` in the corresponding
tenant block. This matches Apartment's `Subdomain` elevator. Always look the
subdomain up in your own table before entering a tenant, rather than trusting
the hostname. Add the pipe to the pipeline that serves tenant routes.

`Account` is a global model: in schema tenancy it is marked
`schema_tenant_excluded`, and in row tenancy it has no `multitenant`
declaration.

Background jobs run outside the request, so wrap each job's work in the same
block with the tenant it was enqueued for. A fiber you `spawn` inside a tenant
block does **not** inherit the tenant; open a new block inside it.

## Coming from the apartment gem

| Apartment (Rails) | Grant |
|---|---|
| `Apartment::Tenant.switch("acme") { ... }` | `Grant::SchemaTenant.with("acme") { ... }` |
| `Apartment::Tenant.switch!("acme")` | Use a block. Grant always scopes a tenant to a bounded unit of work. |
| `Apartment::Tenant.current` | `Grant::SchemaTenant.current_schema` |
| `Apartment::Elevators::Subdomain` | An Amber request pipe that resolves the account, then wraps `call_next(context)` in `SchemaTenant.with` |
| `config.excluded_models = ["User"]` | `schema_tenant_excluded` on each global model |
| `Apartment::Tenant.create("acme")` | `create_schema("acme")`, then `create_tables("acme", ...)` |
| `Apartment::Tenant.drop("acme")` | `drop_schema("acme", cascade: true)` |
| `Apartment.tenant_names` | `Grant::SchemaTenant.list_schemas` |

Your existing PostgreSQL schemas work as they are: point Grant at the same
database and each `SchemaTenant.with` call reads the schema Apartment wrote.

If you later want to consolidate into row tenancy, copy each schema's rows into
shared tables with a `tenant_id` column. Primary keys collide across schemas
(every tenant has an `id = 1`), so build an old-to-new ID map per tenant, or
move to UUID keys, and remap foreign keys with it. The Grant repository's
`docs/schema_tenancy.md` has the full SQL pattern.

## Limits

- Schema tenancy is PostgreSQL only. Other adapters raise
  `Grant::UnsupportedSchemaTenantAdapterError`.
- Grant's migrator creates model tables; it is not a versioned migration runner
  like Rails. Run your DDL across tenant schemas from your own migration task.
- Raw SQL cannot carry a model's tenant scope. On a scoped model, the model-level
  raw methods (`find_by_sql`, `count_by_sql`, `exec`, `query`, `scalar`) raise
  `Grant::Querying::ScopedRawSqlError` unless you call them inside
  `Model.unscoped { ... }`; filter by tenant yourself with a bound parameter.
  `Model.connection` and `Grant.connection` (`exec_query`, `select_all`,
  `select_value`, and so on) are always raw and never scoped. See the
  [Raw SQL guide](raw-sql/) for binding, results, and routing details.
- In schema tenancy, raw SQL runs on the pinned connection, so unqualified
  tables resolve to the tenant's schema. Qualify global tables with `public.`.
