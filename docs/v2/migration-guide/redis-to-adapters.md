---
title: "Redis to Adapters Migration"
section: "migration-guide"
order: 30
description: "Move Amber 1.x session and pub/sub behavior behind Amber V2 adapter interfaces"
---

# Migrating from Redis to Adapters

Amber V2 removes Redis as a mandatory framework dependency. The framework ships
in-memory session and pub/sub adapters; it does **not** ship a first-party Redis
implementation. Applications that still need Redis must implement and register
adapters against the Amber interfaces.

This migration changes how Amber reaches the storage or message broker. It does
not require you to stop using Redis.

## Choose the target behavior

| Requirement | Suitable direction |
|---|---|
| Local development and tests | Built-in memory adapters |
| One application process where losing process-local state is acceptable | Built-in memory adapters after explicit verification |
| Sessions shared across processes or hosts | Registered external session adapter |
| WebSocket broadcasts shared across processes or hosts | Registered external pub/sub adapter |
| Existing Redis-backed production behavior | Custom Redis adapters or another verified shared backend |

The memory adapters are process-local. Do not use them as a silent replacement
for shared Redis state in a horizontally scaled deployment.

## Inventory the Amber 1.x contract

Before changing configuration, record:

- the session cookie name, signing or encryption behavior, expiration, and
  rotation rules;
- the Redis key and channel namespaces;
- the serialized session and pub/sub payload formats;
- whether users or broadcasts must survive a process restart;
- every application process that reads sessions or subscribes to broadcasts;
- cleanup jobs, Redis ACLs, TLS settings, and monitoring tied to the old keys.

Keep a deployable copy of the current configuration while the replacement is
tested.

## Built-in memory configuration

The clean V2 application selects the built-in adapters by name:

```yaml
# config/environments/development.yml
session:
  key: "my_app.session"
  store: "signed_cookie"
  adapter: "memory"
  expires: 3600

pubsub:
  adapter: "memory"
```

Use this path for development, tests, or a deployment whose process-local state
is an intentional constraint. Restart the application during testing to prove
that the resulting state loss is acceptable.

## Keep Redis through a custom session adapter

A shared session backend implements `Amber::Adapters::SessionAdapter`:

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

Register the application implementation before Amber builds the session store:

```crystal
# config/application.cr
require "amber"
require "../src/adapters/redis_session_adapter"

Amber::Adapters::AdapterFactory.register_session_adapter("redis") do
  RedisSessionAdapter.new(redis_client)
end
```

Then select the registered name in the environment configuration:

```yaml
session:
  key: "my_app.session"
  store: "signed_cookie"
  adapter: "redis"
  expires: 86400
```

The [Session Adapters guide](../../guides/adapters/sessions/) documents the complete
interface and registration contract. Compile and contract-test the application
adapter against the exact Redis shard version it uses.

## Keep cross-process broadcasts through a custom pub/sub adapter

A shared message backend implements `Amber::Adapters::PubSubAdapter`:

```crystal
abstract class Amber::Adapters::PubSubAdapter
  abstract def publish(topic : String, sender_id : String, message : JSON::Any) : Nil
  abstract def subscribe(topic : String, &block : (String, JSON::Any) -> Nil) : Nil
  abstract def unsubscribe(topic : String) : Nil
  abstract def unsubscribe_all : Nil
  abstract def close : Nil
end
```

Register and select the application implementation:

```crystal
# config/application.cr
require "amber"
require "../src/adapters/redis_pubsub_adapter"

Amber::Adapters::AdapterFactory.register_pubsub_adapter("redis") do
  RedisPubSubAdapter.new(redis_client)
end
```

```yaml
pubsub:
  adapter: "redis"
```

The [PubSub Adapters guide](../../guides/adapters/pubsub/) covers registration and
multi-process behavior. Test with at least two application processes; a
single-process browser test cannot prove cross-process delivery.

## Preserve or retire existing sessions deliberately

Changing a session backend can invalidate every active session. Choose one of
these policies before deployment:

- preserve the existing Redis key namespace and serialization in the new
  adapter;
- deploy a temporary dual-read migration that moves a session after a
  successful old-format read;
- schedule a coordinated logout and communicate it as an intentional product
  change.

Do not assume that forcing every user to sign in again is harmless. Account
recovery, long-running work, carts, CSRF state, and administrative sessions may
make session loss operationally significant.

## Cutover sequence

1. Add the adapter implementation and its dependency without removing the old
   Redis configuration.
2. Contract-test every adapter method, expiration behavior, malformed payload,
   connection failure, and reconnect path.
3. Exercise login, logout, session rotation, and WebSocket broadcasts in a
   staging deployment that matches the production process count.
4. Apply the chosen active-session migration policy.
5. Switch the Amber configuration to the registered adapter name.
6. Monitor adapter errors, Redis connections, session failures, and broadcast
   delivery through the rollback window.

## Removing Redis after the cutover

Remove Redis only after confirming that no application process, job worker,
cache, rate limiter, session store, or pub/sub subscriber still uses it. Inspect
the shard dependencies, environment variables, deployment manifests, secrets,
monitoring, and infrastructure configuration before retiring the service.

Keep the previous configuration and deployment artifact available until the
replacement has passed its production verification window.

## Verification checklist

- [ ] Session create, read, update, delete, destroy, and expiration behavior pass.
- [ ] Login, logout, rotation, and invalid-cookie behavior pass.
- [ ] Restart behavior matches the chosen state policy.
- [ ] Broadcasts reach subscribers in a second application process.
- [ ] Redis authentication, TLS, ACLs, timeouts, and reconnect behavior are tested when Redis remains.
- [ ] The active-session migration or coordinated logout is documented.
- [ ] The previous configuration can be restored without a code rewrite.
