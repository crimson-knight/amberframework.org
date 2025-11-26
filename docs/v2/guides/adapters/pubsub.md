---
title: "PubSub Adapters"
section: "guides/adapters"
order: 20
description: "Implementing custom pub/sub messaging adapters for WebSockets"
---

# PubSub Adapters

PubSub adapters provide the messaging backend for WebSocket broadcasting and real-time communication. They enable features like chat rooms, live updates, and presence tracking.

## PubSub Adapter Interface

All pub/sub adapters must implement the abstract `PubSubAdapter` class:

```crystal
abstract class Amber::Adapters::PubSubAdapter
  abstract def publish(topic : String, sender_id : String, message : JSON::Any) : Nil
  abstract def subscribe(topic : String, &block : (String, JSON::Any) -> Nil) : Nil
  abstract def unsubscribe(topic : String) : Nil
end
```

## Built-in Memory Adapter

The `MemoryPubSubAdapter` is the default:

```crystal
# Automatically used when adapter: "memory"
class Amber::Adapters::MemoryPubSubAdapter < PubSubAdapter
  # Fiber-based async message delivery
  # Perfect for single-server deployments
end
```

## When to Use Custom Adapters

Memory adapter works great for:

- Development environments
- Single-server deployments
- Testing

Use custom adapters when:

- Running multiple application servers
- Need message persistence
- Requiring exactly-once delivery
- Scaling horizontally

## Creating a Custom Adapter

### Redis PubSub Adapter Example

```crystal
# src/adapters/redis_pubsub_adapter.cr
require "redis"

class RedisPubSubAdapter < Amber::Adapters::PubSubAdapter
  @subscriptions = {} of String => Redis::Subscription

  def initialize(@redis : Redis::PooledClient)
    @pubsub_redis = Redis.new(url: ENV["REDIS_URL"])
  end

  def publish(topic : String, sender_id : String, message : JSON::Any) : Nil
    payload = {
      sender_id: sender_id,
      message: message,
      timestamp: Time.utc.to_unix
    }.to_json

    @redis.publish(channel(topic), payload)
  end

  def subscribe(topic : String, &block : (String, JSON::Any) -> Nil) : Nil
    spawn do
      @pubsub_redis.subscribe(channel(topic)) do |on|
        on.message do |channel, payload|
          data = JSON.parse(payload)
          sender_id = data["sender_id"].as_s
          message = data["message"]
          block.call(sender_id, message)
        end
      end
    end
  end

  def unsubscribe(topic : String) : Nil
    @pubsub_redis.unsubscribe(channel(topic))
  end

  private def channel(topic : String)
    "pubsub:#{topic}"
  end
end
```

### PostgreSQL LISTEN/NOTIFY Adapter

```crystal
# src/adapters/postgres_pubsub_adapter.cr

class PostgresPubSubAdapter < Amber::Adapters::PubSubAdapter
  @listeners = {} of String => Fiber

  def initialize(@connection : DB::Database)
    @notify_conn = DB.open(ENV["DATABASE_URL"])
  end

  def publish(topic : String, sender_id : String, message : JSON::Any) : Nil
    payload = {sender_id: sender_id, message: message}.to_json
    @connection.exec("SELECT pg_notify($1, $2)", topic, payload)
  end

  def subscribe(topic : String, &block : (String, JSON::Any) -> Nil) : Nil
    @listeners[topic] = spawn do
      @notify_conn.using_connection do |conn|
        conn.exec("LISTEN #{topic}")
        conn.on_notification do |notification|
          if notification.channel == topic
            data = JSON.parse(notification.payload)
            block.call(data["sender_id"].as_s, data["message"])
          end
        end
      end
    end
  end

  def unsubscribe(topic : String) : Nil
    @notify_conn.exec("UNLISTEN #{topic}")
    @listeners.delete(topic)
  end
end
```

## Registering Custom Adapters

```crystal
# config/initializers/adapters.cr
require "../src/adapters/redis_pubsub_adapter"

Amber::Adapters::AdapterFactory.register_pubsub_adapter("redis") do
  redis = Redis::PooledClient.new(url: ENV["REDIS_URL"])
  RedisPubSubAdapter.new(redis)
end
```

## Configuration

```yaml
# config/environments/production.yml
pubsub:
  adapter: "redis"
```

## Using PubSub in WebSocket Channels

```crystal
# src/channels/chat_channel.cr
class ChatChannel < Amber::WebSockets::Channel
  def subscribed
    stream_from "chat_room_#{params["room_id"]}"
  end

  def receive(message)
    # Broadcast to all subscribers via adapter
    broadcast("chat_room_#{params["room_id"]}", message)
  end

  def unsubscribed
    stop_streaming_from "chat_room_#{params["room_id"]}"
  end
end
```

## Multi-Server Broadcasting

With a Redis or database adapter, broadcasts work across servers:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Server 1  │     │    Redis    │     │   Server 2  │
│  (Users A)  │────▶│   PubSub    │◀────│  (Users B)  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
   User A1             Broadcast           User B1
   User A2                                 User B2
```

When User A1 sends a message:

1. Server 1 publishes to Redis
2. Redis broadcasts to all subscribers
3. Server 2 receives and delivers to Users B

## Presence Tracking

Implement presence with your adapter:

```crystal
class PresenceChannel < Amber::WebSockets::Channel
  def subscribed
    track_presence("room_#{params["room_id"]}", current_user.id)
    broadcast_presence
  end

  def unsubscribed
    untrack_presence("room_#{params["room_id"]}", current_user.id)
    broadcast_presence
  end

  private def broadcast_presence
    presence = get_presence("room_#{params["room_id"]}")
    broadcast("presence_#{params["room_id"]}", {users: presence})
  end
end
```

## Testing

Use mock adapter for tests:

```crystal
class MockPubSubAdapter < Amber::Adapters::PubSubAdapter
  property published = [] of {String, String, JSON::Any}

  def publish(topic : String, sender_id : String, message : JSON::Any) : Nil
    published << {topic, sender_id, message}
  end

  def subscribe(topic : String, &block : (String, JSON::Any) -> Nil) : Nil
    # No-op for tests
  end

  def unsubscribe(topic : String) : Nil
    # No-op for tests
  end
end

# In tests
it "broadcasts message" do
  adapter = MockPubSubAdapter.new
  channel = ChatChannel.new(adapter)

  channel.receive({"text" => "Hello"})

  adapter.published.size.should eq(1)
  adapter.published.first[2]["text"].should eq("Hello")
end
```
