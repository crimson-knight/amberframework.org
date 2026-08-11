---
title: "WebSockets and live pages"
section: "guides"
order: 82
description: "Build a server-rendered Amber page that receives channel events through a local ES module"
---

# WebSockets and live pages

Amber's default remains server-rendered HTML. Add a WebSocket when the document
is already useful and one part of it needs to change as work happens. Amber V2
provides client sockets, topic-based channels, broadcasts from controllers or
jobs, presence events, three decoders, and short-window connection recovery.

This guide builds one complete path. Every block names its destination.

## 1. Generate the channel

**Run from: the application root.**

```bash
amber generate channel Status --topics=status
```

**File: `src/channels/status_channel.cr` — replace the generated
handler with this small rebroadcasting channel.**

```crystal
class StatusChannel < Amber::WebSockets::Channel
  def handle_message(client_socket, message)
    rebroadcast!(message)
  end
end
```

`status:*` is a topic family. A page can join `status:reports`, while another
joins `status:deploys`, without creating another channel class.

## 2. Define the socket boundary

**File: `src/sockets/user_socket.cr` — create this file.**

```crystal
struct UserSocket < Amber::WebSockets::ClientSocket
  channel "status:*", StatusChannel

  def on_connect : Bool
    true
  end
end
```

Authentication belongs in `on_connect`. The socket exposes the request
`session`, `cookies`, `params`, and `context`; return `false` to reject the
connection.

**File: `src/my_app.cr` — require sockets and channels before the routes.**

```crystal
require "./channels/**"
require "./sockets/**"
require "../config/routes"
```

Replace `my_app` with the generated application filename.

## 3. Register the handshake

**File: `config/routes.cr` — add this line inside `routes :web`.**

```crystal
websocket "/ws", UserSocket
```

## 4. Join from a local ES module

**File: `public/js/live-status.js` — create this browser module.**

```javascript
const protocol = location.protocol === "https:" ? "wss" : "ws";
const socket = new WebSocket(`${protocol}://${location.host}/ws`);

socket.addEventListener("open", () => {
  socket.send(JSON.stringify({
    event: "join",
    topic: "status:reports",
    payload: {}
  }));
});

socket.addEventListener("message", ({data}) => {
  const message = JSON.parse(data);
  if (message.event !== "report:ready") return;

  document
    .querySelector(`[data-report="${message.payload.id}"]`)
    ?.setAttribute("data-state", "ready");
});
```

**File: `src/views/layouts/application.ecr` — add the module to the existing
import map and import it after the map.**

```ecr
<script type="importmap">
  {"imports":{"app":"/js/app.js","live-status":"/js/live-status.js"}}
</script>
<script type="module">
  import "app";
  import "live-status";
</script>
```

No npm package, bundler, client framework, or CDN is required.

## 5. Publish after work succeeds

**File: the controller, service, or job that owns the successful operation.**

```crystal
StatusChannel.broadcast_to(
  "status:reports",
  "report:ready",
  {"id" => report.id.to_s}
)
```

Broadcast after the state change succeeds. A background job can call the same
class method when slow work finishes.

## Protocol and lifecycle

The default JSON envelope contains `event`, `topic`, and `payload`. Clients send
`join`, `message`, and `leave`; applications define their own event names for
server broadcasts. Amber also includes text and binary decoders, channel error
isolation, presence join/leave diffs, a 30-second heartbeat, a 100-second idle
timeout, and a 60-second reconnection window with a bounded 100-message buffer.

Those defaults are process-local. The built-in pub/sub adapter does not fan an
event across multiple Amber processes. Register a shared adapter before relying
on cross-instance broadcasts, and measure the proxy and operating-system limits
for the connection count your application expects.

## Measured on the Amber website

The August 11, 2026 release candidate for this website uses the same channel
path described above. On a DigitalOcean one-shared-vCPU, 512 MB-class target it
held 1,000 joined clients for 85 seconds with zero connection errors. While
those sockets remained open, a separate host drove the rendered `/index.json`
path at a median 8,058 requests/second across three trials; the median trial's
p99 latency was 26.77 ms.

That is a dated boundary, not a universal connection limit. The clients were
idle after joining, the test did not exercise fan-out, TLS, proxies, or multiple
processes, and the sequential shared-vCPU stages were noisy. Read the
[complete machine-readable evidence](/benchmarks/amber-v2-site-websocket-2026-08-11.json)
before using the number for planning.

Continue with [Sockets](sockets.md) for authentication and lifecycle hooks, or
[Background jobs](../background-jobs/) to publish an event after queued work.
