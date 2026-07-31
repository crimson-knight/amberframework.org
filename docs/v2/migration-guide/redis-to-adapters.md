---
title: "Redis to Adapters Migration"
section: "migration-guide"
order: 30
description: "Migrate from hard-coded Redis to pluggable session and pub/sub adapters"
---

# Migrating from Redis to Adapters

Amber 2.0 replaces hard-coded Redis dependencies with a pluggable adapter system. You can now choose the best storage backend for your deployment: cookies, Redis, memory, or custom implementations.

## Why the Change?

| Aspect | Amber 1.x | Amber 2.0 |
|--------|-----------|-----------|
| Session Storage | Redis required | Cookie, Redis, Memory, or custom |
| WebSocket PubSub | Redis required | Memory, Redis, or custom |
| Dependencies | Always need Redis | Use what fits your needs |
| Development | Redis must be running | Works out of the box |
| Deployment | More infrastructure | Deploy anywhere |

## Session Migration

### Before (Amber 1.x)

```crystal
# config/application.cr
Amber::Server.configure do |app|
  app.session = {
    :redis => Redis.new(url: ENV["REDIS_URL"]),
    :key => "session_id",
    :secret => ENV["SECRET_KEY_BASE"]
  }
end
```

### After (Amber 2.0)

#### Option 1: Cookie Store (Recommended for most apps)

```crystal
# config/application.cr
require "amber/session_adapters/cookie_store"

Amber::Server.configure do |app|
  app.session = Amber::SessionAdapters::CookieStore.new(
    secret_key: ENV["SECRET_KEY_BASE"],
    session_key: "_myapp_session",
    expire_after: 24.hours
  )
end
```

Benefits:
- No external dependencies
- Scales horizontally without shared state
- Session travels with the request

Limitations:
- 4KB size limit
- Data visible to client (encrypted, but visible)

#### Option 2: Redis Store (For existing Redis users)

```crystal
# config/application.cr
require "amber/session_adapters/redis_store"

Amber::Server.configure do |app|
  app.session = Amber::SessionAdapters::RedisStore.new(
    redis_url: ENV["REDIS_URL"],
    session_key: "_myapp_session",
    expire_after: 24.hours
  )
end
```

Use when:
- You already have Redis infrastructure
- Sessions need to exceed 4KB
- You need server-side session invalidation

#### Option 3: Memory Store (Development/Testing)

```crystal
# config/application.cr
require "amber/session_adapters/memory_store"

Amber::Server.configure do |app|
  app.session = Amber::SessionAdapters::MemoryStore.new(
    session_key: "_myapp_session"
  )
end
```

Note: Memory store doesn't persist across restarts and doesn't scale horizontally.

### Environment-Based Configuration

```crystal
# config/application.cr
Amber::Server.configure do |app|
  app.session = case ENV["AMBER_ENV"]?
  when "production"
    if ENV["REDIS_URL"]?
      Amber::SessionAdapters::RedisStore.new(
        redis_url: ENV["REDIS_URL"],
        session_key: "_myapp_session"
      )
    else
      Amber::SessionAdapters::CookieStore.new(
        secret_key: ENV["SECRET_KEY_BASE"],
        session_key: "_myapp_session"
      )
    end
  when "test"
    Amber::SessionAdapters::MemoryStore.new(
      session_key: "_myapp_session"
    )
  else # development
    Amber::SessionAdapters::CookieStore.new(
      secret_key: ENV["SECRET_KEY_BASE"]? || "dev_secret_key_at_least_32_chars",
      session_key: "_myapp_session"
    )
  end
end
```

## WebSocket PubSub Migration

### Before (Amber 1.x)

```crystal
# Hard-coded Redis pub/sub
class ChatSocket < Amber::WebSockets::Channel
  def on_connect
    subscribe("chat_room_#{@room_id}")
  end

  def on_message(action, message)
    # Uses Redis internally
    broadcast("chat_room_#{@room_id}", message)
  end
end
```

### After (Amber 2.0)

#### Option 1: Memory Adapter (Single Server)

```crystal
# config/initializers/pubsub.cr
require "amber/pubsub_adapters/memory_adapter"

PUBSUB = Amber::PubSubAdapters::MemoryAdapter.new
```

```crystal
class ChatSocket < Amber::WebSockets::Channel
  def on_connect
    PUBSUB.subscribe("chat_room_#{@room_id}") do |message|
      send_to_client(message)
    end
  end

  def on_message(action, message)
    PUBSUB.publish("chat_room_#{@room_id}", message)
  end

  def on_disconnect
    PUBSUB.unsubscribe("chat_room_#{@room_id}")
  end
end
```

Use when:
- Single server deployment
- Development/testing
- Low message volume

#### Option 2: Redis Adapter (Multi-Server)

```crystal
# config/initializers/pubsub.cr
require "amber/pubsub_adapters/redis_adapter"

PUBSUB = Amber::PubSubAdapters::RedisAdapter.new(
  url: ENV["REDIS_URL"]
)
```

```crystal
class ChatSocket < Amber::WebSockets::Channel
  def on_connect
    PUBSUB.subscribe("chat_room_#{@room_id}") do |message|
      send_to_client(message)
    end
  end

  def on_message(action, message)
    PUBSUB.publish("chat_room_#{@room_id}", message)
  end
end
```

Use when:
- Multiple app servers
- High message volume
- Need message persistence

### Environment-Based PubSub

```crystal
# config/initializers/pubsub.cr
PUBSUB = case ENV["AMBER_ENV"]?
when "production"
  Amber::PubSubAdapters::RedisAdapter.new(
    url: ENV["REDIS_URL"]
  )
else
  Amber::PubSubAdapters::MemoryAdapter.new
end
```

## Migration Steps

### Step 1: Update shard.yml

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.2

  # Redis now optional
  redis:
    github: stefanwille/crystal-redis
    version: ~> 2.8.0
```

### Step 2: Update Session Configuration

1. Remove old Redis session config
2. Choose and configure new adapter
3. Test session functionality

```crystal
# Remove this:
app.session = {
  :redis => Redis.new(...),
  ...
}

# Add this:
app.session = Amber::SessionAdapters::CookieStore.new(...)
```

### Step 3: Update WebSocket Code

1. Create PubSub adapter instance
2. Update channels to use adapter
3. Test real-time features

### Step 4: Remove Redis (if no longer needed)

```yaml
# shard.yml - remove if not using Redis adapter
# redis:
#   github: stefanwille/crystal-redis
```

```bash
shards update
```

## Custom Adapters

### Custom Session Adapter

```crystal
class MySessionAdapter < Amber::SessionAdapters::Base
  def initialize(@connection : MyDatabase)
  end

  def load(session_id : String) : Hash(String, String)
    @connection.get_session(session_id) || {} of String => String
  end

  def save(session_id : String, data : Hash(String, String)) : Nil
    @connection.set_session(session_id, data, ttl: 24.hours)
  end

  def destroy(session_id : String) : Nil
    @connection.delete_session(session_id)
  end

  def generate_id : String
    Random::Secure.hex(32)
  end
end

# Use it
Amber::Server.configure do |app|
  app.session = MySessionAdapter.new(DB_CONNECTION)
end
```

### Custom PubSub Adapter

```crystal
class MyPubSubAdapter < Amber::PubSubAdapters::Base
  def initialize(@broker : MessageBroker)
  end

  def subscribe(channel : String, &block : String -> Nil) : Nil
    @broker.subscribe(channel, &block)
  end

  def unsubscribe(channel : String) : Nil
    @broker.unsubscribe(channel)
  end

  def publish(channel : String, message : String) : Nil
    @broker.publish(channel, message)
  end
end
```

## Session Data Migration

If migrating from Redis sessions to cookies, existing sessions will be lost. Options:

### Option 1: Accept Session Loss

For most apps, users simply log in again. Plan migration during low-traffic period.

### Option 2: Gradual Migration

Support both adapters temporarily:

```crystal
class HybridSessionAdapter < Amber::SessionAdapters::Base
  def initialize(@redis : RedisStore, @cookie : CookieStore)
  end

  def load(session_id : String) : Hash(String, String)
    # Try cookie first, fall back to Redis
    data = @cookie.load(session_id)
    return data unless data.empty?

    # Migrate from Redis to cookie
    redis_data = @redis.load(session_id)
    unless redis_data.empty?
      @cookie.save(session_id, redis_data)
      @redis.destroy(session_id)  # Clean up Redis
    end
    redis_data
  end

  def save(session_id : String, data : Hash(String, String)) : Nil
    @cookie.save(session_id, data)
  end

  def destroy(session_id : String) : Nil
    @cookie.destroy(session_id)
    @redis.destroy(session_id)
  end
end
```

### Option 3: Coordinate Session Migration

For critical sessions (admin, long-running workflows):

1. Export important sessions from Redis
2. Notify affected users
3. Migrate, requiring re-authentication

## Removing Redis Dependency

Once migrated, you can remove Redis entirely:

### 1. Update shard.yml

```yaml
# Remove or comment out
# redis:
#   github: stefanwille/crystal-redis
```

### 2. Remove Redis Config

```bash
# Remove Redis-related environment variables
# REDIS_URL, REDIS_HOST, etc.
```

### 3. Update Docker/Infrastructure

```dockerfile
# Remove from docker-compose.yml
# redis:
#   image: redis:alpine
```

### 4. Run Tests

```bash
crystal spec

# Ensure no Redis references remain
grep -r "Redis" src/
grep -r "REDIS" src/
```

## Troubleshooting

### Sessions Not Persisting (Cookie Store)

Check cookie size - cookies have a 4KB limit:

```crystal
# Log session size
puts "Session size: #{session.to_json.bytesize} bytes"

# Consider storing only essential data
session["user_id"] = user.id.to_s  # Good
session["user"] = user.to_json     # Bad - too large
```

### WebSocket Messages Not Broadcasting (Multi-Server)

Ensure Redis adapter is used in production:

```crystal
if ENV["AMBER_ENV"] == "production" && !ENV["REDIS_URL"]?
  raise "REDIS_URL required for WebSocket pub/sub in production"
end
```

### Performance Issues

Compare adapter performance:

```crystal
# Benchmark session operations
require "benchmark"

Benchmark.ips do |x|
  x.report("cookie") { cookie_adapter.load("test") }
  x.report("redis") { redis_adapter.load("test") }
  x.report("memory") { memory_adapter.load("test") }
end
```

Cookie is typically fastest for small sessions; Redis for large sessions with many servers.

## Security Considerations

### Cookie Store Security

- Always use `SECRET_KEY_BASE` of at least 32 characters
- Session data is encrypted but may be visible to determined attackers
- Don't store sensitive data directly in sessions

```crystal
# Good
session["user_id"] = user.id.to_s

# Bad - sensitive data
session["credit_card"] = card_number
```

### Redis Store Security

- Use `REDIS_URL` with authentication
- Enable TLS in production: `rediss://...`
- Consider Redis ACLs for additional security
