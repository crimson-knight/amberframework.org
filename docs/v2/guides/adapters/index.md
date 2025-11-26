---
title: "Adapters"
section: "guides"
order: 25
is_section: true
description: "Pluggable session storage and pub/sub messaging in Amber 2.0"
---

# Adapter System

Amber 2.0 introduces a pluggable adapter system for session storage and pub/sub messaging. This replaces the hard Redis dependency from v1.x with a flexible architecture that works out-of-the-box and can be extended with custom backends.

## Why Adapters?

In Amber 1.x, Redis was required for sessions and WebSocket messaging. This created issues:

- Required Redis installation for development
- External dependency even for simple apps
- No flexibility for other backends

Amber 2.0 solves this with:

- Memory-based adapters work immediately
- No external dependencies required
- Implement custom adapters for any backend
- Easy testing without external services

## Built-in Adapters

### Memory Adapters (Default)

```yaml
# config/environments/development.yml
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

```yaml
session:
  key: "amber.session"
  store: "signed_cookie"
  expires: 3600
```

## Configuration

### Session Configuration

```yaml
# config/environments/production.yml
session:
  key: "myapp.session"
  adapter: "database"  # Your custom adapter
  expires: 86400       # 24 hours
```

### PubSub Configuration

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
