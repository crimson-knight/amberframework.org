---
title: "Session Adapters"
section: "guides/adapters"
order: 10
description: "Implementing custom session storage adapters"
---

# Session Adapters

Session adapters provide the storage backend for user sessions. Amber 2.0 includes a memory adapter by default, and you can implement custom adapters for any storage backend.

## Session Adapter Interface

All session adapters must implement the abstract `SessionAdapter` class:

```crystal
abstract class Amber::Adapters::SessionAdapter
  abstract def get(session_id : String) : String?
  abstract def set(session_id : String, value : String) : Nil
  abstract def delete(session_id : String) : Nil
  abstract def destroy(session_id : String) : Nil
  abstract def exists?(session_id : String) : Bool
end
```

## Built-in Memory Adapter

The `MemorySessionAdapter` is the default:

```crystal
# Automatically used when adapter: "memory"
class Amber::Adapters::MemorySessionAdapter < SessionAdapter
  # Thread-safe in-memory storage
  # Automatic expiration cleanup
end
```

## Creating a Custom Adapter

### Database Session Adapter Example

```crystal
# src/adapters/database_session_adapter.cr
require "amber"

class DatabaseSessionAdapter < Amber::Adapters::SessionAdapter
  def initialize(@connection : DB::Database)
  end

  def get(session_id : String) : String?
    result = @connection.query_one?(
      "SELECT data FROM sessions WHERE id = $1 AND expires_at > NOW()",
      session_id,
      as: String
    )
    result
  end

  def set(session_id : String, value : String) : Nil
    expires_at = Time.utc + session_ttl
    @connection.exec(
      "INSERT INTO sessions (id, data, expires_at) VALUES ($1, $2, $3)
       ON CONFLICT (id) DO UPDATE SET data = $2, expires_at = $3",
      session_id, value, expires_at
    )
  end

  def delete(session_id : String) : Nil
    @connection.exec("DELETE FROM sessions WHERE id = $1", session_id)
  end

  def destroy(session_id : String) : Nil
    delete(session_id)
  end

  def exists?(session_id : String) : Bool
    @connection.query_one?(
      "SELECT 1 FROM sessions WHERE id = $1 AND expires_at > NOW()",
      session_id,
      as: Int32
    ).present?
  end

  private def session_ttl
    Amber.settings.session["expires"].as_i.seconds
  end
end
```

### Redis Session Adapter Example

```crystal
# src/adapters/redis_session_adapter.cr
require "redis"

class RedisSessionAdapter < Amber::Adapters::SessionAdapter
  def initialize(@redis : Redis::PooledClient)
  end

  def get(session_id : String) : String?
    @redis.get(key(session_id))
  end

  def set(session_id : String, value : String) : Nil
    @redis.setex(key(session_id), session_ttl, value)
  end

  def delete(session_id : String) : Nil
    @redis.del(key(session_id))
  end

  def destroy(session_id : String) : Nil
    delete(session_id)
  end

  def exists?(session_id : String) : Bool
    @redis.exists(key(session_id)) > 0
  end

  private def key(session_id : String)
    "session:#{session_id}"
  end

  private def session_ttl
    Amber.settings.session["expires"].as_i
  end
end
```

## Registering Custom Adapters

Register your adapter with the `AdapterFactory`:

```crystal
# config/initializers/adapters.cr
require "../src/adapters/database_session_adapter"
require "../src/adapters/redis_session_adapter"

# Register database adapter
Amber::Adapters::AdapterFactory.register_session_adapter("database") do
  DatabaseSessionAdapter.new(AppDatabase.connection)
end

# Register Redis adapter
Amber::Adapters::AdapterFactory.register_session_adapter("redis") do
  redis = Redis::PooledClient.new(url: ENV["REDIS_URL"])
  RedisSessionAdapter.new(redis)
end
```

## Configuration

Update your environment configuration:

```yaml
# config/environments/production.yml
session:
  key: "myapp.session"
  adapter: "database"  # Use your registered adapter
  expires: 86400
```

## Database Schema

For database-backed sessions, create a migrations:

```sql
-- db/migrations/create_sessions.sql
CREATE TABLE sessions (
  id VARCHAR(64) PRIMARY KEY,
  data TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_expires ON sessions(expires_at);
```

## Session Cleanup

For database adapters, implement periodic cleanup:

```crystal
# lib/tasks/cleanup_sessions.cr
desc "Clean expired sessions"
task :cleanup_sessions do
  AppDatabase.connection.exec(
    "DELETE FROM sessions WHERE expires_at < NOW()"
  )
  puts "Expired sessions cleaned up"
end
```

Schedule this with cron:

```bash
# Clean sessions every hour
0 * * * * cd /app && crystal lib/tasks/cleanup_sessions.cr
```

## Testing with Adapters

Use memory adapter for fast tests:

```crystal
# spec/spec_helper.cr
Amber.settings.session["adapter"] = "memory"
```

Or mock the adapter:

```crystal
# spec/support/mock_session_adapter.cr
class MockSessionAdapter < Amber::Adapters::SessionAdapter
  property sessions = {} of String => String

  def get(session_id : String) : String?
    sessions[session_id]?
  end

  def set(session_id : String, value : String) : Nil
    sessions[session_id] = value
  end

  def delete(session_id : String) : Nil
    sessions.delete(session_id)
  end

  def destroy(session_id : String) : Nil
    delete(session_id)
  end

  def exists?(session_id : String) : Bool
    sessions.has_key?(session_id)
  end
end
```
