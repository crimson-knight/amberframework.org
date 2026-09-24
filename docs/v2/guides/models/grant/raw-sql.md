---
title: "Raw SQL"
section: "guides/models/grant"
order: 55
description: "Bound raw SQL, Grant result rows, and database connection routing"
---

# Raw SQL

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

Use Grant's query builder when it can express the operation. Use raw SQL for a
database-specific statement or a query that needs a result shape beyond model
attributes. Bind every value; do not build SQL by interpolating input.

## Where the examples go

- Keep each model declaration in its own file under `src/models/`.
- Run model and connection calls from the controller, job, service, or spec
  that owns the database operation.
- Register the model's primary database and any named database in a direct
  application config file such as `config/database.cr`.

## Model-level raw SQL

These model declarations are a compact example for the snippets below. In an
application, keep each model in its own file under `src/models/`.

```crystal
class Post < Grant::Base
  connection primary
  table posts

  column id : Int64, primary: true
  column author_id : Int64
  column title : String
end

class TenantPost < Grant::Base
  connection primary
  table tenant_posts

  column id : Int64, primary: true
  column tenant_id : Int64?
  column title : String

  multitenant :tenant_id
end
```

Use `find_by_sql` when you want hydrated, persisted model instances. Use
`count_by_sql` for a bound count. `exec` runs a bound write and returns
`DB::ExecResult`; `scalar` returns the first cell from raw SQL.

```crystal
posts = Post.find_by_sql(
  "SELECT * FROM posts WHERE author_id = ? ORDER BY id",
  [10_i64]
)

post_count = Post.count_by_sql(
  "SELECT COUNT(*) FROM posts WHERE author_id = ?",
  [10_i64]
)

Post.exec("UPDATE posts SET title = ? WHERE id = ?", ["Reviewed", 1_i64])
title = Post.scalar("SELECT title FROM posts WHERE id = ?", [1_i64])

puts "hydrated=#{posts.size}, count=#{post_count}, title=#{title.inspect}"
```

`Model.query(sql, binds) { |result_set| ... }` is also available when code
needs the adapter's live `DB::ResultSet`. These model-level raw methods cannot
apply a model's default scope; see [Scopes and tenancy](#scopes-and-tenancy)
before using them on scoped models.

## Connection results

`Model.connection` returns a raw facade for that model's configured database
and active read/write context. `Grant.connection(name)` returns a facade for a
registered connection by name; omitting the name selects Grant's default
database. Both facades bypass model scopes. Register a name such as `analytics`
before requesting it.

`exec_query` and its alias `select_all` return a buffered `Grant::Result`.
`columns` preserves database column order, `rows` contains positional arrays,
and `to_a` and `each` expose string-keyed row hashes. `select_one` returns the
first row or `nil`; `select_value` returns the first cell or `nil`;
`select_values` returns the first column from every row; and `select_rows`
returns every row positionally. `execute` is the write operation and returns
`DB::ExecResult`.

```crystal
connection = Post.connection
result = connection.exec_query(
  "SELECT id, title FROM posts WHERE author_id = ? ORDER BY id",
  [10_i64]
)

puts result.columns.inspect
puts result.rows.inspect
puts result.to_a.inspect
result.each { |row| puts row["title"] }

puts connection.select_all("SELECT id, title FROM posts WHERE author_id = ?", [10_i64]).size
puts connection.select_one("SELECT id, title FROM posts WHERE id = ?", [1_i64]).inspect
puts connection.select_value("SELECT title FROM posts WHERE id = ?", [1_i64]).inspect
puts connection.select_values("SELECT title FROM posts WHERE author_id = ?", [10_i64]).inspect
puts connection.select_rows("SELECT id, title FROM posts WHERE author_id = ?", [10_i64]).inspect

connection.execute("UPDATE posts SET title = ? WHERE id = ?", ["Updated", 1_i64])
analytics_count = Grant.connection("analytics").select_value("SELECT COUNT(*) FROM posts")
puts analytics_count.inspect
```

`Grant::Result::Value` is a stable union of database values supported by the
buffered result API. `Grant::Result.from` normalizes each driver value through
its adapter. With PostgreSQL, `numeric` values are strings so their exact text
is preserved, `uuid` values are `UUID`, and `smallint` values are `Int16`.
PostgreSQL intervals, geometric values, and arrays are returned as strings;
JSON parser values become `JSON::Any`. A value outside the result union raises
`Grant::Result::UnsupportedValueError`. `Model.scalar` returns the driver's
native scalar value instead of passing through this buffered normalization.

```crystal
result = Grant.connection.exec_query(<<-SQL)
  SELECT 12.340::numeric AS amount,
         'd9428888-122b-11e1-b85c-61cd3cbb3210'::uuid AS external_id,
         7::smallint AS rank
  SQL
row = result.to_a.first

puts row["amount"].is_a?(String)
puts row["external_id"].is_a?(UUID)
puts row["rank"].is_a?(Int16)
```

## Bind values and SQL fragments

Placeholders bind values as data. For example, this input cannot turn the
predicate into `OR TRUE`:

```crystal
untrusted_title = "' OR TRUE --"
matching_ids = Post.connection.select_values(
  "SELECT id FROM posts WHERE title = ?",
  [untrusted_title]
)
puts matching_ids.inspect # => [] when no row has that exact title
```

Do not interpolate `untrusted_title` into the SQL string. Bind parameters are
for values, not table or column names; choose dynamic identifiers from a
fixed allowlist.

`sanitize_sql_array` quotes values into a SQL fragment for compatibility with
ActiveRecord-style conditions. It is an escape hatch for constructing SQL text,
not the normal way to execute a query. Prefer a bound execution method whenever
the statement goes to the database.

```crystal
condition = Post.sanitize_sql_array(["title = ?", "A title"])
puts condition
```

## Reads, writes, and transactions

Connection read helpers (`exec_query`, `select_all`, `select_one`,
`select_value`, `select_values`, and `select_rows`) use the selected reading
route. `execute` uses the writing route and respects the active
`while_preventing_writes` context. `Model.exec` is also a write operation.

`Model.scalar` uses the model adapter path and marks a write for replica
stickiness before opening it. This keeps a `scalar` call on the primary and
keeps following reads on the primary during the configured lag window. It can
run a statement such as `INSERT ... RETURNING`, so it is not a read-only
replacement for `select_value`. The current `Model.scalar` implementation does
not call the write-prevention guard; keep it outside a write-preventing block.

The block below allows a read and catches the error from a write attempt:

```crystal
write_was_blocked = false

Post.while_preventing_writes do
  Post.connection.select_value("SELECT COUNT(*) FROM posts")

  begin
    Post.connection.execute("DELETE FROM posts WHERE id = ?", [1_i64])
  rescue ex : Grant::Transaction::ReadOnlyError
    write_was_blocked = true
  end
end

puts write_was_blocked # => true
```

Raw calls on the same adapter participate in its active transaction. Within a
`Grant::SchemaTenant.with` block, that adapter also uses the tenant's pinned
connection, so unqualified tables resolve through that schema's search path.
A facade for a different named database is a different connection and does not
join the transaction or schema-tenant context.

```crystal
Grant::SchemaTenant.with("acme") do
  Grant::Base.transaction do
    Post.connection.execute(
      "UPDATE posts SET title = ? WHERE id = ?",
      ["Tenant copy", 1_i64]
    )
    title = Post.connection.select_value("SELECT title FROM posts WHERE id = ?", [1_i64])
    puts title.inspect
  end
end
```

<a id="scopes-and-tenancy"></a>

## Scopes and tenancy

Raw SQL cannot infer a model's default scope or add a row-tenant predicate.
Model-level calls to `find_by_sql`, `count_by_sql`, `exec`, `query`, or `scalar`
on a model with a default scope raise
`Grant::Querying::ScopedRawSqlError` unless deliberately wrapped in
`Model.unscoped { ... }`. Add any tenant condition yourself and bind it:

```crystal
TenantPost.unscoped do
  posts = TenantPost.find_by_sql(
    "SELECT * FROM tenant_posts WHERE tenant_id = ? ORDER BY id",
    [7_i64]
  )
  puts posts.map(&.title).inspect
end
```

`Model.connection` and `Grant.connection(name)` always remain raw, even for a
scoped model. Include the required scope in their SQL explicitly. See the
[multi-tenancy guide](multi-tenancy/) for row and schema tenant setup.
