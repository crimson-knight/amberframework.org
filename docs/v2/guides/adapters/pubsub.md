---
title: "PubSub Adapters"
section: "guides/adapters"
order: 20
description: "Implement and register Amber V2 pub/sub adapters for WebSocket broadcasts"
---

# PubSub Adapters

Pub/sub adapters carry WebSocket messages between publishers and subscribers.
Amber V2 includes `MemoryPubSubAdapter`; applications can register a shared
broker when broadcasts must cross process or host boundaries.

## Complete adapter contract

A custom adapter inherits `Amber::Adapters::PubSubAdapter`.

**Reference API: implemented by a class under `src/adapters/`, for example
`src/adapters/redis_pubsub_adapter.cr`. Do not copy the abstract class into the
application.**

```crystal
abstract class Amber::Adapters::PubSubAdapter
  abstract def publish(topic : String, sender_id : String, message : JSON::Any) : Nil
  abstract def subscribe(topic : String, &block : (String, JSON::Any) -> Nil) : Nil
  abstract def unsubscribe(topic : String) : Nil
  abstract def unsubscribe_all : Nil
  abstract def close : Nil
end
```

Adapters may also override `healthy?`, `subscriber_count`, and `active_topics`
when the backend can report those values accurately.

The adapter owns broker subscriptions and resource cleanup. Calling
`unsubscribe(topic)` must stop delivery for that topic; `unsubscribe_all` and
`close` must release all remaining subscriptions and connections.

## Built-in memory adapter

**File: the applicable file under `config/environments/`, such as
`config/environments/development.yml` — edit its existing `pubsub:` section.**

```yaml
pubsub:
  adapter: "memory"
```

Use it for development, tests, and intentional single-process deployments. A
browser connected to one process cannot receive a message published only inside
another process through the memory adapter.

## Register a shared adapter

**File: `config/application.cr` — keep `require "amber"`, require the adapter
class, then register it before routes are loaded.**

```crystal
# config/application.cr
require "amber"
require "../src/adapters/redis_pubsub_adapter"

Amber::Adapters::AdapterFactory.register_pubsub_adapter("redis") do
  RedisPubSubAdapter.new(redis_client)
end
```

**File: `config/environments/production.yml` — edit the existing `pubsub:`
section after the adapter is registered.**

```yaml
# config/environments/production.yml
pubsub:
  adapter: "redis"
```

Redis is an example of an application-supplied broker, not a built-in Amber V2
adapter. The adapter must match the chosen Redis shard API, connection model,
authentication, TLS, and reconnect behavior.

## Message contract

`publish` receives a topic, sender ID, and `JSON::Any` message. A shared adapter
must preserve those three values across serialization so each subscriber callback
receives the original sender ID and message.

Define a collision-safe broker namespace for the application and environment.
Do not subscribe directly to an untrusted topic name without validating or
encoding it for the broker.

## Adapter verification

- publish and receive representative JSON values without losing types;
- preserve the sender ID used to identify or filter an originating socket;
- deliver to multiple subscribers on the same topic;
- stop delivery after `unsubscribe` and `unsubscribe_all`;
- close broker connections and listener fibers cleanly;
- recover or fail visibly after a broker disconnect;
- use two application processes to prove cross-process delivery;
- verify topic isolation between environments and applications;
- load-test the subscription count and message sizes expected in production.

Presence, replay, persistence, ordering, and exactly-once delivery are not
provided merely by implementing the Amber pub/sub interface. If the application
requires one of those guarantees, specify and test it as part of the adapter.

See [Redis to Adapters](../../migration-guide/redis-to-adapters/) for a staged
cutover and rollback checklist.
