---
title: "Sockets"
section: "guides/websockets"
order: 20
description: "Connect Amber V2 client sockets to generated WebSocket channels"
---

# Sockets

A client socket represents one WebSocket connection and maps topic patterns to
channel classes. Amber CLI V2 generates channels, while the socket boundary is
currently hand-authored:

```bash
amber generate channel ChatRoom --topics=chat_room
```

```crystal
struct ChatSocket < Amber::WebSockets::ClientSocket
  channel "chat_room:*", ChatRoomChannel

  def on_connect : Bool
    # `session`, `cookies`, and validated `params` are available here.
    !!session[:current_user_id]?
  end
end
```

Register the handshake route in `config/routes.cr`:

```crystal
Amber::Server.configure do
  routes :web do
    websocket "/chat", ChatSocket
  end
end
```

Return `false` from `on_connect` to reject the connection. Override
`on_disconnect`, `on_reconnect`, or `on_error` when the application needs
connection lifecycle behavior.

Broadcast to every subscriber of a topic from a controller or service:

```crystal
ChatSocket.broadcast(
  "message",
  "chat_room:123",
  "message_new",
  {"message" => "A new visitor!"}
)
```

The V1 `amber g socket` shortcut is not a command in the standalone V2 CLI.
Create the socket struct explicitly, generate channels with `amber generate
channel`, and cover the handshake and authorization behavior with specs.
