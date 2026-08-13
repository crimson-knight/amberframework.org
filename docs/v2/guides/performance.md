---
title: "Performance"
section: "guides"
order: 90
description: "Amber V2 benchmark results, methodology, limits, and reproduction evidence"
---

# Performance

Amber treats performance as an architectural property and a documentation
obligation. Every published number should travel with its workload, hardware,
protocol, duration, errors, and limits.

## Hosted Amber V2 result

On July 17, 2026, the Amber V2 performance lab measured a mature mixed
application on a DigitalOcean Basic one-vCPU, 512 MB-class target. A separate
four-vCPU host generated load over a private VPC.

| Current Amber JSON path | Result |
|---|---:|
| Median throughput | **21,795 requests/second** |
| Median p50 latency | 655 microseconds |
| Median p99 latency | 4.20 milliseconds |
| Repetitions | 7 |
| Socket errors | 0 |
| Non-2xx responses | 0 |

This result is whole HTTP traffic over real sockets. It is not an in-process
router lookup rate.

## This website on the same smallest target

On August 11, 2026, we compiled the Amber Framework website release candidate
for Linux `x86_64-v2` and ran it on the current $4/month DigitalOcean size: one
shared vCPU with 512 MB advertised memory. A separate four-vCPU machine drove
traffic over the private VPC.

| Actual website path | Median throughput | Median-trial p50 | Median-trial p99 |
|---|---:|---:|---:|
| Complete 26,271-byte homepage | **5,907 req/s** | 2.67 ms | 7.07 ms |
| Rendered `/index.json` | **9,355 req/s** | 1.66 ms | 5.84 ms |
| Static `/llms.txt` | **14,085 req/s** | 1.08 ms | 3.90 ms |

Each row used four load-generator threads, 16 persistent connections, a
five-second warmup, and five 15-second trials. Together, these baseline and
WebSocket-concurrency stages delivered 2,944,287 successful HTTP responses
with zero reported socket errors and zero non-2xx responses.

The same release candidate then held 100, 500, and 1,000 joined WebSocket
clients. All 2,600 connection attempts across the stages and the second
1,000-client cycle succeeded. During the first 1,000-client hold, the rendered
JSON path sustained a median **8,058 requests/second**; the median trial's p99
was 26.77 ms.

This is useful capacity evidence, but not a scaling curve. The connection
stages ran sequentially on a shared-vCPU target and were visibly noisy: the
500-client stage was slower than the 1,000-client stage. Clients joined a topic
and then remained idle, so the result does not measure broadcast fan-out, slow
consumers, TLS, a reverse proxy, a public network, or multiple Amber processes.

The complete [website and WebSocket evidence](/benchmarks/amber-v2-site-websocket-2026-08-11.json)
includes every throughput trial, response size, resource snapshot, executable
fingerprint, method, and limitation.

## Workload

The release-mode `x86_64-v2` binary installed 1,000 routes and replayed the same
deterministic 4,096-request table in every trial:

| Dimension | Mix |
|---|---|
| Route shapes | 45% static, 25% REST ID, 15% ID plus action, 5% nested, 5% constrained, 5% glob |
| HTTP methods | 65% GET, 20% POST, 8% PUT, 5% PATCH, 2% DELETE |
| Locality | 70% selected the first 20% in each method-and-shape cell |
| Query strings | 20% of requests |
| Connections | 16 |
| Load-generator threads | 4 |
| Warmup | 5 seconds |
| Measurement | 15 seconds |
| Repetitions | 7, with rotating variant order |

Writes carried an eight-field JSON CRUD/mobile payload. Controllers consumed
every decoded field and serialized an acknowledgement. Reads consumed captured
route parameters and serialized a response. The measured path included the
Crystal HTTP parser and serializer, Amber routing and pipeline dispatch, body
decoding, controller work, and JSON serialization.

Across the complete seven-variant body-codec/compiler matrix, the load
generator received **18,728,053 successful responses** with zero socket errors
and zero non-2xx responses.

## What the number means

The 21,795 requests/second result is more demanding and more representative
than a static-response endpoint. It supports the narrower statement that Amber
V2 can exceed 10,000 requests/second in this documented one-vCPU hosted
workload.

It does not establish:

- a cross-framework ranking;
- a universal result for every Amber application;
- a production capacity plan or service-level agreement;
- database, cache, proxy, TLS, or public-internet performance;
- the throughput of the final beta tag on different hardware.

Application behavior, infrastructure, compiler version, connection strategy,
and request shape can move the result substantially. Benchmark your deployed
path before making capacity decisions.

## Router microbenchmarks are separate

Amber also measures route matching in isolation. Those results can reach
millions of lookups per second because they intentionally exclude sockets,
HTTP parsing, middleware, controller dispatch, template rendering, and response
serialization. They are useful for choosing router implementations, but they
must never be presented as HTTP requests per second.

## Released router before and after on the $4 target

On August 13, 2026, we ran a corrected router-only comparison on the exact
DigitalOcean `s-1vcpu-512mb-10gb` size: one shared vCPU, 512 MiB advertised
memory, 469,236 KiB visible memory, and no swap. Both static binaries used
Crystal 1.21.0 and the same workload. The comparison was `amber_router` 0.4.4
against Amber `2.0.0-beta.4`.

Each of 12 scenarios used seven paired trials with alternating order. Amber V2
was faster in all 84 individual pairs, and every scenario's median bootstrap
interval excluded `1.0x`. The geometric mean across the 12 scenario medians
was **1.89x**.

> **Unit:** every rate in this table is an in-process router lookup per second,
> not a completed HTTP request per second.

| Route table | Lookup | V1 router lookups/s | V2 beta.4 router lookups/s | Median paired speedup |
|---:|---|---:|---:|---:|
| 100 | Fixed | 599,440/s | 885,523/s | **1.44x** |
| 100 | Variable | 796,564/s | 1,205,931/s | **1.55x** |
| 100 | Glob | 384,426/s | 608,145/s | **1.58x** |
| 100 | Not found | 669,406/s | 1,628,256/s | **2.31x** |
| 10,000 | Unique glob | 69,704/s | 310,112/s | **4.54x** |

This rerun also corrected the old `55.7x` headline. The historical glob
generator reused only five effective URL shapes, so the 10,000-route tier put
100 terminal entries behind each shape. That result measured a real
duplicate-route edge case, but it was not a clean 10,000-unique-route
comparison and is no longer a general Amber V2 claim.

Read [the complete benchmark explanation](/blog/2026/08/13/amber-v2-router-on-a-four-dollar-droplet),
inspect the [machine-readable paired summary](/benchmarks/amber-v2-router-digitalocean-2026-08-13-summary.json),
or download the [168 raw trials](/benchmarks/amber-v2-router-digitalocean-2026-08-13-raw.jsonl).

## Published evidence

The [round 22 summary data](/benchmarks/amber-v2-round22-summary.json) records
the result, workload, source commit, request-table hash, and hardware boundary
in a machine-readable form. The source experiment used commit
`deccb9358fd378a8d4e060cd13a19a35c609197e`; the runner used commit
`744269f4fa83ea5a5cbbbeef58d541d0981171d1`.

The result should be rerun for the GA release. If the workload, hardware, or
harness changes, publish it as a new benchmark rather than silently replacing
the historical context.

The separate [August 11 website evidence](/benchmarks/amber-v2-site-websocket-2026-08-11.json)
records what the actual public-site release candidate did under both HTTP and
held-WebSocket load. Keep these two workloads separate when quoting them.
