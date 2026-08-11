---
title: "Adapters"
section: "guides"
order: 25
is_section: true
description: "Pluggable session storage and pub/sub messaging in Amber 2.0"
---

# Adapter System

Amber 2.0 routes session storage and pub/sub messaging through adapter
interfaces. In-memory adapters are built in; an application can register a
separate implementation when it needs an external store or message broker.

## Why Adapters?

In Amber 1.x, Redis was required for sessions and WebSocket messaging. This created issues:

- Required Redis installation for development
- External dependency even for simple apps
- No flexibility for other backends

Amber 2.0 solves this with:

- Memory-based adapters work immediately
- No external dependencies required
- Implement custom adapters for any backend
- Tests can use the in-memory implementations without an external service

## Built-in Adapters

### Memory Adapters (Default)

**File: `config/environments/development.yml` — edit the existing `session:`
and `pubsub:` keys. Apply the same shape deliberately to `test.yml` or
`production.yml`; environment files do not inherit from one another.**

```yaml
session:
  key: "amber.session"
  store: "signed_cookie"
  adapter: "memory"
  expires: 3600

pubsub:
  adapter: "memory"
```

Memory adapters are perfect for:

- Development environments
- Testing
- Single-server deployments
- Simple applications

### Cookie Sessions

For stateless session storage:

**File: one file under `config/environments/`, such as
`config/environments/production.yml` — replace that environment's existing
`session:` section.**

```yaml
session:
  key: "amber.session"
  store: "signed_cookie"
  expires: 3600
```

## Configuration

### Session Configuration

**File: `config/environments/production.yml` — replace the existing `session:`
section after registering the custom `database` adapter.**

```yaml
session:
  key: "myapp.session"
  adapter: "database"  # Your custom adapter
  expires: 86400       # 24 hours
```

### PubSub Configuration

**File: the applicable file under `config/environments/` — edit the existing
`pubsub:` section.**

```yaml
pubsub:
  adapter: "memory"  # Or custom adapter name
```

## Custom Adapters

Implement custom adapters for your specific needs:

- Database sessions (PostgreSQL, MySQL)
- Redis (via community shard)
- Cloud storage (AWS DynamoDB)
- Message queues (RabbitMQ, Kafka)

See [Session Adapters](sessions/) and [PubSub Adapters](pubsub/) for implementation guides.

## Migration from Redis

If you used Redis in Amber 1.x, see the [Migration Guide](../../migration-guide/redis-to-adapters/) for step-by-step migration instructions.
