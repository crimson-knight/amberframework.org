---
title: "Migration Guide"
section: "migration-guide"
order: 100
is_section: true
description: "Upgrading from Amber 1.x to Amber 2.0"
---

# Migration Guide: Amber 1.x to 2.0

> Amber `2.0.0-beta.2` release-gates the framework core and ECR web template.
> Grant, Gemma, Asset Pipeline, persistence/auth generators, and native output
> are preview surfaces. Treat their migration sections as evaluation material,
> not prerequisites for adopting the framework beta.

This guide covers the major changes in Amber 2.0 and how to migrate your existing applications.

## Overview

Amber 2.0 is a significant release that modernizes the framework while maintaining the simplicity and productivity that Crystal developers love. The major changes are:

| Component | Amber 1.x | Amber 2.0 |
|-----------|-----------|-----------|
| JavaScript | Webpack bundling | No bundled asset pipeline; preview ESM tooling is separate |
| ORM | Granite | No bundled ORM; Grant migration material is preview |
| Sessions | Hard-coded Redis | Pluggable Adapters |
| WebSockets | Hard-coded Redis | Pluggable PubSub Adapters |
| Request Validation | Manual | Schema API |
| File Uploads | Manual | No bundled attachment shard; Gemma material is preview |

## Migration Path

We recommend migrating incrementally:

1. **Update Dependencies** - Update `shard.yml` for Amber 2.0
2. **Migrate Sessions** - Switch from Redis to adapter system
3. **Keep persistence explicit** - Continue a compatible ORM or evaluate a new one separately
4. **Migrate templates** - Convert Slang/Kilt views to ECR
5. **Adopt core features** - Add Schema API, jobs, mailers, and adapters incrementally

## Breaking Changes Summary

### Configuration

**1.x:**
```crystal
Amber::Server.configure do |app|
  app.session = {
    :redis => Redis.new(url: ENV["REDIS_URL"]),
    :key => "session_id",
    :secret => ENV["SECRET_KEY_BASE"]
  }
end
```

**2.0:**
```crystal
Amber::Server.configure do |app|
  app.session = Amber::SessionAdapters::CookieStore.new(
    secret_key: ENV["SECRET_KEY_BASE"]
  )
end
```

### WebSocket PubSub

**1.x:**
```crystal
# Hard-coded Redis
channel.subscribe("chat_room_1")
channel.broadcast("message", "chat_room_1", data)
```

**2.0:**
```crystal
# Via adapter
pubsub = Amber::PubSubAdapters::MemoryAdapter.new
channel.subscribe("chat_room_1")
pubsub.publish("chat_room_1", data)
```

### Model Layer

**1.x (Granite):**
```crystal
class User < Granite::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
end
```

**2.0 (Grant):**
```crystal
class User < Grant::Base
  column id : Int64, primary: true
  column email : String

  has_many :posts
  validates :email, presence: true, format: EMAIL_REGEX
end
```

### JavaScript Assets

**1.x (Webpack):**
```javascript
// webpack.config.js required
// npm install required
// node_modules/ required
import $ from "jquery"
```

**2.0 (ESM + Import Maps):**
```crystal
# Crystal configuration
import_map.add_import("jquery", "https://cdn.jsdelivr.net/npm/jquery@3.7.1/+esm")
```

```javascript
// Native ESM, no build step
import $ from "jquery"
```

## Compatibility Notes

### Granite Support

Granite remains compatible with Amber 2.0. You can:
- Continue using Granite alongside Grant
- Migrate models incrementally
- Use Grant for new models while keeping Granite for existing ones

### Redis Support

While Redis is no longer required, it's still fully supported:
- Redis session adapter available
- Redis pub/sub adapter available
- Upgrade path for existing Redis infrastructure

## Quick Start

### Update shard.yml

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.2
```

Add an ORM, database driver, assets, or attachments only from that component's
own compatible release instructions. They are no longer implicit framework
dependencies.

### Run Migration

```bash
shards update

# Remove webpack if no longer needed
rm -rf node_modules package.json webpack.config.js

# Test your application
crystal spec
```

## Detailed Migration Guides

Each major component has its own detailed migration guide:

- [Webpack to ESM](webpack-to-esm/) - Migrate from Webpack bundling to native ESM modules
- [Granite to Grant](granite-to-grant/) - Migrate from Granite ORM to Grant ORM
- [Redis to Adapters](redis-to-adapters/) - Migrate from hard-coded Redis to pluggable adapters

## Getting Help

If you encounter issues during migration:

1. Check the specific migration guides above
2. Review the [Amber 2.0 Release Notes](https://github.com/amberframework/amber/releases)
3. Ask in the [Amber Discord](https://discord.gg/amber)
4. Open an issue on [GitHub](https://github.com/amberframework/amber/issues)

## Timeline Recommendations

### Small Applications (< 10 models)
Migrate all at once. Set aside a day for the migration.

### Medium Applications (10-50 models)
- Week 1: Update dependencies, migrate sessions/adapters
- Week 2: Migrate models incrementally
- Week 3: Migrate assets, test thoroughly

### Large Applications (50+ models)
- Phase 1: Update to Amber 2.0, keep Granite
- Phase 2: Migrate sessions to adapter system
- Phase 3: Incrementally migrate models to Grant
- Phase 4: Replace Webpack with Asset Pipeline
- Phase 5: Adopt new features (Schema API, Gemma)
