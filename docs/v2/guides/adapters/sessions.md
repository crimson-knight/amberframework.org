---
title: "Session Adapters"
section: "guides/adapters"
order: 10
description: "Implement and register Amber V2 session storage adapters"
---

# Session Adapters

Session adapters store the key/value data associated with a session ID. Amber
V2 includes `MemorySessionAdapter`; applications can register another backend
through `AdapterFactory` when state must survive a restart or be shared across
processes.

## Complete adapter contract

A custom adapter inherits `Amber::Adapters::SessionAdapter` and implements every
abstract operation:

```crystal
abstract class Amber::Adapters::SessionAdapter
  abstract def get(session_id : String, key : String) : String?
  abstract def set(session_id : String, key : String, value : String) : Nil
  abstract def delete(session_id : String, key : String) : Nil
  abstract def destroy(session_id : String) : Nil
  abstract def exists?(session_id : String, key : String) : Bool
  abstract def keys(session_id : String) : Array(String)
  abstract def values(session_id : String) : Array(String)
  abstract def to_hash(session_id : String) : Hash(String, String)
  abstract def empty?(session_id : String) : Bool
  abstract def expire(session_id : String, seconds : Int32) : Nil
  abstract def batch_set(session_id : String, values : Hash(String, String)) : Nil
  abstract def batch(session_id : String, &block : Amber::Adapters::SessionBatchOperations ->) : Nil
end
```

Adapters may also override `close` to release connections and `healthy?` to
report backend availability.

`batch_set` and `batch` should be atomic when the backend supports transactions
or pipelining. The expiration operation applies to the complete session, not an
individual key.

## Built-in memory adapter

Select the built-in adapter by name:

```yaml
session:
  key: "my_app.session"
  store: "signed_cookie"
  adapter: "memory"
  expires: 3600
```

Memory state belongs to one application process and disappears when that process
stops. Use it for development, tests, or a deployment where that lifecycle is an
explicit product decision.

## Register an application adapter

Load and register the adapter before Amber builds the configured session store.
The generated application already requires `config/application.cr`, so it is a
reliable registration point:

```crystal
# config/application.cr
require "amber"
require "../src/adapters/redis_session_adapter"

Amber::Adapters::AdapterFactory.register_session_adapter("redis") do
  RedisSessionAdapter.new(redis_client)
end
```

Then select the registered name per environment:

```yaml
# config/environments/production.yml
session:
  key: "my_app.session"
  store: "signed_cookie"
  adapter: "redis"
  expires: 86400
```

The generated V2 application does not automatically require every file under
`config/initializers/`. If you choose that directory, add an explicit require
before `Amber::Server.start` and prove the load order in a clean build.

## Adapter verification

Test the implementation independently from controller behavior:

- create, read, update, and delete more than one key in a session;
- distinguish deleting one key from destroying the complete session;
- return consistent results from `keys`, `values`, `to_hash`, and `empty?`;
- expire a session and verify its keys disappear;
- prove `batch_set` and `batch` do not expose a partial update;
- exercise backend timeout, reconnect, and unavailable states;
- close connections cleanly during shutdown;
- run concurrent access tests that match the deployment process model.

For a Redis migration, also preserve or intentionally replace the previous key
namespace, serialization, expiration, and active-session policy. See
[Redis to Adapters](../../migration-guide/redis-to-adapters/).
