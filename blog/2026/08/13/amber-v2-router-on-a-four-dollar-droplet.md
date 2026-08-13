# We Reran Amber V2's Router on a $4 DigitalOcean Droplet

Here is the correction first: Amber's old `55.7x` router headline did not come
from a cloud run, and it should not be repeated as a general Amber V2
performance claim.

The underlying router work is real. The old evidence was not strong enough for
the way we described it. We have now rerun the released Amber V2 beta.4 router
against `amber_router` 0.4.4 on DigitalOcean's smallest $4 Basic Droplet, with
a corrected workload and every trial preserved.

## What had actually run in the cloud

Amber already had credible hosted performance evidence, but three different
benchmarks had been getting blended into one story:

- The original router table was an in-process microbenchmark on an unspecified
  local machine. Its notes recorded Crystal 1.18.2, but not the CPU, memory,
  provider, or raw paired trials.
- An April 21 Amber 1.4-versus-V2 HTTP comparison ran on DigitalOcean, but the
  application server was an eight-vCPU CPU-optimized Droplet—not the smallest
  target.
- The July 17 mixed-application result and August 11 website result did use the
  exact `s-1vcpu-512mb-10gb` size. Those are whole-HTTP capacity tests, not a
  before-and-after test of the two router engines.

So the narrow question—how the released V2 router compares with Amber 1.x's
router on that same tiny server—was still unanswered.

## The replacement test

The measured target was DigitalOcean Basic `s-1vcpu-512mb-10gb` in NYC3: one
shared `DO-Regular` vCPU, 512 MiB advertised memory, 469,236 KiB visible to
Linux, no swap, and a 10 GiB disk. DigitalOcean's API listed it at $4 per month
when the test ran on August 13, 2026.

We compiled two separate static x86-64 binaries with Crystal 1.21.0 using
`--release --no-debug --static`:

- before: `amber_router` 0.4.4, commit
  `8f05718a4d49411e664f57a7f162565ce25fab75`;
- after: Amber `2.0.0-beta.4`, commit
  `a2128cdb4fef07025e0cc1c1578d4c807ae6c274`.

Both binaries received the same 100-, 1,000-, and 10,000-route tables. The mix
was 60% fixed, 25% variable, 10% variable with a fixed suffix, and 5% glob.
Each glob route had a distinct match shape. We tested fixed, variable, glob,
and not-found lookups with two seconds of warmup and five seconds of
measurement per process.

Every scenario ran as seven before-and-after pairs. Odd repetitions ran the
old router first; even repetitions ran V2 first. The result for each scenario
is the median of its seven same-repetition V2/old ratios. That pairing matters
on shared cloud CPUs because both absolute rates can move when neighboring
workloads change.

## Results

Amber V2 was faster in all 84 individual pairs. Every scenario's median
bootstrap interval stayed above `1.0x`, and alternating order did not change
the story: the geometric mean was `1.90x` when the old router ran first and
`1.87x` when V2 ran first.

Across the 12 scenario medians, the geometric-mean speedup was **1.89x**.

> **Unit:** every rate in this table is an in-process router lookup per second,
> not a completed HTTP request per second.

| Routes | Lookup | Amber 1.x router lookups/s | Amber V2 beta.4 router lookups/s | Median paired speedup | 95% bootstrap interval |
| ---: | --- | ---: | ---: | ---: | ---: |
| 100 | Fixed | 599,440/s | 885,523/s | **1.44x** | 1.35x–1.59x |
| 100 | Variable | 796,564/s | 1,205,931/s | **1.55x** | 1.50x–1.60x |
| 100 | Glob | 384,426/s | 608,145/s | **1.58x** | 1.56x–1.60x |
| 100 | Not found | 669,406/s | 1,628,256/s | **2.31x** | 2.23x–2.55x |
| 1,000 | Fixed | 481,508/s | 706,379/s | **1.43x** | 1.39x–1.55x |
| 1,000 | Variable | 572,084/s | 999,892/s | **1.70x** | 1.66x–1.87x |
| 1,000 | Glob | 252,411/s | 526,378/s | **2.03x** | 1.91x–2.08x |
| 1,000 | Not found | 619,668/s | 1,280,214/s | **1.96x** | 1.92x–2.00x |
| 10,000 | Fixed | 256,122/s | 417,707/s | **1.58x** | 1.45x–1.69x |
| 10,000 | Variable | 306,469/s | 592,417/s | **1.95x** | 1.74x–2.02x |
| 10,000 | Glob | 69,704/s | 310,112/s | **4.54x** | 4.33x–4.69x |
| 10,000 | Not found | 441,333/s | 828,546/s | **1.82x** | 1.72x–1.97x |

The 100-route rows are the best shorthand for an ordinary application: fixed,
variable, and glob lookup medians improved by 44% to 58%, while the tested
not-found path improved by 131%. At the intentionally extreme 10,000-route
tier, the corrected unique-glob lookup improved by 354%.

The intervals are deterministic percentile-bootstrap intervals over seven
paired ratios. They describe the repeatability of this bounded run; they are
not a promise about every cloud host or application.

## Why `55.7x` changed

The old glob generator varied the glob parameter name but reused only five
effective URL shapes. At the 10,000-route tier, its 500 declared glob routes
became 100 terminal entries behind each of those five shapes. The old test
really did measure that duplicate-route edge case, but the result was described
as though it represented 10,000 unique routes.

The replacement generator gives every glob route a unique prefix and looks up
the last one. That is a cleaner test of a large route table and a harder test
of the old router's linear child scan. It also produces a much smaller, much
more defensible number than `55.7x`.

The audit found two other historical-label problems. The old generator called
10% of its routes "constrained" without ever passing a regular-expression
constraint, and the cross-framework script loaded stored Amber results while
running only the third router fresh with a different route generator. We have
corrected those descriptions and marked that cross-framework output as
historical mixed-provenance material, not a ranking.

## What changed in V2

The Amber 1.x router kept fixed, variable, glob, and terminal children together
in one array. Matching scanned that mixed array and performed runtime type
checks along the way. Beta.4 separates those structures: fixed segments use a
hash, variable segments stay in a small array, a glob gets its own slot, and
terminal leaves live separately as value types.

V2 also registers route segments by index instead of repeatedly shifting an
array and splits paths into a pre-sized array in one pass. Registration is
recorded by this benchmark but excluded from timed lookup throughput.

One earlier explanation said `RoutedResult` became a struct. It did not;
`RoutedResult` remains a class in beta.4. The performance gain does not require
us to overstate the implementation.

## Router lookups are not HTTP requests

These rates measure only `RouteSet#find`. They exclude sockets, HTTP parsing,
middleware, controller dispatch, ECR rendering, JSON serialization, databases,
TLS, reverse proxies, and the public network. Millions of router lookups per
second must never be presented as millions of HTTP requests per second.

For complete application behavior, use the separately documented hosted
results: the 26,271-byte Amber website homepage sustained a 5,907 requests per
second median on this size, while a deterministic mixed 1,000-route JSON
workload sustained 21,795 requests per second. Those workloads answer a
different question and keep their own limitations.

## Inspect and reproduce it

The [machine-readable summary](/benchmarks/amber-v2-router-digitalocean-2026-08-13-summary.json)
contains the target, source revisions, compiler, binary checksums, workload,
paired ratios, intervals, and limitations. The [raw 168 trials](/benchmarks/amber-v2-router-digitalocean-2026-08-13-raw.jsonl)
and [machine snapshot](/benchmarks/amber-v2-router-digitalocean-2026-08-13-machine.txt)
are published beside it. The harness lives in Amber's
`benchmarks/router_cloud/` directory.

The honest conclusion is better than the old headline: Amber V2's released
router is measurably faster on the smallest server used for these published
experiments, the result survives paired cloud trials, and you can inspect every
number we used to say so.
