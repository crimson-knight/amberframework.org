---
title: "Background jobs"
section: "guides"
order: 83
description: "Define, prioritize, retry, schedule, and safely capacity-plan Amber V2 background jobs"
---

# Background jobs

Amber V2 can move slow work out of an HTTP request without adding a job library.
Jobs serialize their arguments, enter a named queue, and run in worker fibers.
The built-in adapter is intentionally small; understand its durability and
memory boundary before using it in production.

## 1. Define and register a job

**File: `src/jobs/build_report_job.cr` — create this file.**

```crystal
class BuildReportJob < Amber::Jobs::Job
  include JSON::Serializable

  property report_id : Int64

  def initialize(@report_id : Int64)
  end

  def perform
    ReportBuilder.build(report_id)
  end

  def self.queue : String
    "reports"
  end

  def self.max_retries : Int32
    5
  end
end

Amber::Jobs.register(BuildReportJob)
```

**File: `src/my_app.cr` — require jobs before the server starts.**

```crystal
require "./jobs/**"
require "../config/routes"
```

Replace `my_app` with the generated application filename. Registration is
required because a worker must reconstruct the typed job from its JSON payload.

## 2. Enqueue from the request boundary

**File: `src/controllers/reports_controller.cr` — enqueue only after request
validation and persistence succeed.**

```crystal
class ReportsController < ApplicationController
  def create
    report = ReportCatalog.create(params)
    BuildReportJob.new(report.id).enqueue

    redirect_to "/reports/#{report.id}"
  end
end
```

Use `enqueue(delay: 5.minutes)` for delayed work or
`enqueue(queue: "critical")` for a one-off queue override.

## 3. Configure workers and queue priority

**File: `config/environments/development.yml` — add this top-level block for a
local, single-process application.**

```yaml
jobs:
  adapter: "memory"
  workers: 2
  auto_start: true
  polling_interval_seconds: 1.0
  scheduler_interval_seconds: 5.0
  work_stealing: false
```

**File: `config/application.cr` — set ordered queues when the application needs
more than `default`.**

```crystal
Amber::Jobs.configure do |config|
  config.queues = ["critical", "default", "reports", "low"]
end
```

Workers check this list from left to right and take the first available job.
This is strict queue ordering, not weighted fairness: a continuously full
`critical` queue can starve the queues after it.

## Retries and dead jobs

Each execution increments the envelope's attempt count. A failure is scheduled
again with exponential backoff; after `max_retries`, the adapter marks the job
dead. The in-memory adapter exposes completed, failed, scheduled, and dead job
collections for inspection, but Amber V2 does not yet ship a dashboard or a
durable replay policy.

Keep job bodies idempotent. A worker can fail after an external side effect but
before completion is recorded, so an adapter that promises delivery may run the
same logical job again.

## What request-aware work stealing means

**Beta.2 release boundary:** keep `work_stealing: false` in applications pinned
to Amber `2.0.0-beta.2`. That tag exposes the setting and starts an idle-only
worker, but its request pipeline does not update the activity counter. As a
result, the worker can treat a busy server as idle. The correction is validated
on the V2 development branch but is not a beta.2 capability until it appears in
a later framework tag.

The corrected design starts one additional idle-only worker. Amber's outer
request pipeline increments a live counter for each ordinary HTTP request and
decrements it in an `ensure` block. The idle-only worker dequeues a job only
when that counter is zero. Upgraded WebSocket connections are excluded so one
persistent connection does not disable idle work forever.

This is a conservative scheduling signal, not CPU or memory telemetry. A job
already running is allowed to finish, and Amber does not preempt it when a new
request arrives. Keep latency-sensitive production workers separate until the
application has measured its own job duration and request tail latency.

## Memory, durability, and multiple instances

The default `memory` adapter is:

- process-local and lost on restart;
- unbounded by the framework, so queued payloads consume application memory;
- unavailable to workers in another process;
- appropriate for development, tests, and deliberately small single-process
  deployments where those limits are acceptable.

For durable or multi-instance work, implement and register a `QueueAdapter`
backed by a service with explicit queue-size, payload-size, retention, timeout,
and retry policies. Do not increase worker count as a substitute for measuring
job memory. Start with one worker, record peak resident memory and p95 job time,
then raise concurrency within the smallest deployment target's headroom.

## Broadcast completion to the page

**File: `src/jobs/build_report_job.cr` — add the broadcast after the report is
successfully written.**

```crystal
def perform
  ReportBuilder.build(report_id)
  StatusChannel.broadcast_to(
    "status:reports",
    "report:ready",
    {"id" => report_id.to_s}
  )
end
```

The [WebSockets and live pages](../websockets/) guide shows the channel, socket,
route, and exact browser module that receives this event.
