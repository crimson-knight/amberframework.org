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

## Published evidence

The [round 22 summary data](/benchmarks/amber-v2-round22-summary.json) records
the result, workload, source commit, request-table hash, and hardware boundary
in a machine-readable form. The source experiment used commit
`deccb9358fd378a8d4e060cd13a19a35c609197e`; the runner used commit
`744269f4fa83ea5a5cbbbeef58d541d0981171d1`.

The result should be rerun for the GA release. If the workload, hardware, or
harness changes, publish it as a new benchmark rather than silently replacing
the historical context.
