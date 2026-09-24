---
title: "Multi-tenancy"
section: "guides/models/grant"
order: 65
description: "Row-level and PostgreSQL schema-per-tenant multi-tenancy in Grant, including a migration path from Rails' apartment gem"
---

# Multi-tenancy

> **Grant version:** The APIs on this page need Grant at commit
> `c6b5e72c1e2663fe6b5cb6794a5beddd0c34f7a3` or later. Amber CLI `2.0.6` pins
> an earlier commit, so update the `grant` entry in `shard.yml` and run
> `shards update grant`:
>
> ```yaml
> grant:
>   github: crimson-knight/grant
>   commit: c6b5e72c1e2663fe6b5cb6794a5beddd0c34f7a3
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
Grant::Tenant.with(current_account.id) do
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

Tenant-owned models need no extra declaration. Models whose tables live in
`public` for every tenant, such as users or plans, are marked excluded:

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
  Invoice.create!(number: "INV-100") # acme.invoices
  Plan.where(code: "pro").first      # public.plans
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
Grant::SchemaTenant.create_schema("acme")
Grant::SchemaTenant.create_tables("acme", Invoice, Payment)
Grant::SchemaTenant.list_schemas             # => ["acme", ...]
Grant::SchemaTenant.drop_schema("acme", cascade: true)
```

Create the tables for excluded models once, in `public`, with their migrator.

## Selecting the tenant per request

Both modes use the same shape of Amber pipe: work out the tenant, then wrap the
rest of the request in a tenant block. This example resolves the tenant from
the subdomain, like Apartment's `Subdomain` elevator.

**File: `src/pipes/tenant_pipe.cr` — create this pipe.**

```crystal
class TenantPipe
  include HTTP::Handler

  def call(context : HTTP::Server::Context)
    host = context.request.headers["Host"]?.try(&.split(':', 2).first)
    subdomain = host.try { |value| value.split('.').first if value.count('.') >= 2 }

    unless subdomain && (account = Account.find_by(subdomain: subdomain))
      context.response.respond_with_status(:not_found)
      return
    end

    # Row tenancy:
    Grant::Tenant.with(account.id) { call_next(context) }

    # Schema tenancy instead:
    # Grant::SchemaTenant.with(account.schema_name) { call_next(context) }
  end
end
```

`Account` here is a global model: in schema tenancy it is marked
`schema_tenant_excluded`, and in row tenancy it has no `multitenant`
declaration. Always look the subdomain up in your own table before entering a
tenant, rather than trusting the hostname.

**File: `config/routes.cr` — add the pipe to the pipelines that serve tenant
routes.**

```crystal
pipeline :web do
  plug Amber::Pipe::Error.new
  plug Amber::Pipe::Logger.new
  plug Amber::Pipe::Session.new
  plug Amber::Pipe::Flash.new
  plug TenantPipe.new
  plug Amber::Pipe::CSRF.new
end
```

Background jobs run outside the request, so wrap each job's work in the same
block with the tenant it was enqueued for. A fiber you `spawn` inside a tenant
block does **not** inherit the tenant; open a new block inside it.

## Coming from the apartment gem

| Apartment (Rails) | Grant |
|---|---|
| `Apartment::Tenant.switch("acme") { ... }` | `Grant::SchemaTenant.with("acme") { ... }` |
| `Apartment::Tenant.switch!("acme")` | Use a block. Grant always scopes a tenant to a bounded unit of work. |
| `Apartment::Tenant.current` | `Grant::SchemaTenant.current_schema` |
| `Apartment::Elevators::Subdomain` | The `TenantPipe` above |
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
  `select_value`, and so on) are always raw and never scoped.
- In schema tenancy, raw SQL runs on the pinned connection, so unqualified
  tables resolve to the tenant's schema. Qualify global tables with `public.`.
