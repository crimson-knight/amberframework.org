# Amber V2 schemas are contracts the framework actually enforces

There is an easy trap in API frameworks: you write a beautiful schema, use it
to generate documentation, and then discover that the real request path never
actually ran it.

We found that gap in Amber's V2 beta work. The Schema API had good ideas and a
lot of surface area, but declaring a schema did not yet guarantee that a
request would succeed or fail because of it. That is exactly the kind of thing
a beta is supposed to expose before people build production assumptions on
top of it.

Amber `2.0.0-beta.5` closes that gap. The reviewed work landed in
[Amber PR #1408](https://github.com/amberframework/amber/pull/1408), and the
published prerelease tag points to that canonical merge commit.

## The compatibility promise comes first

If an Amber 1.x application uses `params.validation`, upgrading the framework
should still feel like an upgrade. That API is deprecated, but it remains
functional in V2. We do not plan to remove it before a later V2 minor such as
2.5, and the exact removal release will be announced separately.

That means an application can change its Amber version, run its tests, build,
and ship the stability improvements before rewriting validation code. New
schemas can then be adopted one action at a time. A deprecation warning is a
migration prompt, not a demand to stop the upgrade and rebuild every
controller.

## One contract now owns the whole boundary

Put a reusable request contract under `src/schemas/`:

```crystal
class CreatePetSchema < Amber::Schema::Definition
  content_type "application/json"
  additional_properties false

  field :name, String, required: true, min_length: 1, max_length: 80
  field :species, String, required: true, enum: ["cat", "dog", "other"]
  field :age, Int32, min: 0, max: 50
end
```

Bind it to the action in `src/controllers/pets_controller.cr`:

```crystal
class PetsController < ApplicationController
  schema :create, CreatePetSchema

  def create
    input = validated_as(CreatePetSchema)
    Pet.create!(
      name: input.name.not_nil!,
      species: input.species.not_nil!,
      age: input.age
    )
  end
end
```

The ordinary route stays ordinary:

```crystal
# config/routes.cr
post "/pets", PetsController, :create
```

Before `create` runs, Amber checks the media type, parses the body, collects
declared path, query, header, and cookie values, coerces each value, and applies
the schema. Invalid input stops there. The action receives a request-local
typed object, not a mutable schema instance shared by concurrent requests.

A `response_schema` declaration applies the same discipline on the way out.
Application code that produces the wrong shape or status fails as a 500
contract error instead of silently serving a response that disagrees with its
documentation.

The same enforced declarations generate OpenAPI 3.1. They carry body fields,
real path/query/header/cookie parameters, nested schemas, paired fields,
alternatives, conditional requirements, content types, and response status.
There is no second registry for the documentation to drift away in.

## JSON, compact CBOR, or encrypted COSE

The contract can accept and return `application/json` or deterministic,
bounded `application/cbor`. An application that owns both ends of the wire can
also choose `application/cose`: a COSE Encrypt0 envelope containing that CBOR
object and authenticated with ChaCha20-Poly1305.

COSE works in both directions. Amber authenticates and decrypts the incoming
message before validation, then can validate, encode, authenticate, and encrypt
the response with a fresh nonce. There is intentionally no built-in
development key; an application must supply a 32-byte deployment secret and
key ID.

CSV, Protocol Buffers, and MessagePack are not built-in formats. We found old
draft documentation that said they were and removed it. Release documentation
should describe the framework people can actually run, not the framework a
draft once imagined.

## We measured what enforcement costs

The performance question is not whether an isolated route matcher can move
millions of strings. It is what happens to complete HTTP requests when Amber
parses, routes, validates, runs the action, validates the response, and writes
the result.

On August 13, 2026, the exact $4 DigitalOcean target—one shared vCPU and 512 MB
advertised memory—ran four versions of the same eight-field request and
five-field acknowledgement. A separate four-dedicated-vCPU machine generated
load over an isolated private VPC. Each scenario had a warmup and seven
rotating 15-second measurements with 16 persistent connections.

| Complete HTTP scenario | Median requests/s | Observed range | Median p50 | Median p99 |
| --- | ---: | ---: | ---: | ---: |
| Generic JSON without schemas | 20,728 | 19,019–22,618 | 0.688 ms | 2.813 ms |
| Validated JSON | **19,488** | 18,573–22,236 | 0.721 ms | 3.185 ms |
| Validated CBOR | **21,742** | 19,904–23,256 | 0.646 ms | 2.921 ms |
| Bidirectional authenticated COSE | **14,443** | 10,962–15,160 | 1.006 ms | 3.612 ms |

In this workload, request and response enforcement cost 6.0% compared with
generic JSON decoding. CBOR was 11.6% faster than validated JSON and reduced
the request body from 257 bytes to 223 bytes. Bidirectional COSE was 25.9%
slower than validated JSON because it did the cryptographic work on both the
request and response.

All **7,974,608** measured requests returned HTTP 200. No slower trial was
discarded as an outlier, and the Amber process peaked at 16.6 MiB on the 512 MB
target.

## The request path improved too

The previous round used the same cloud plans, region, reported processor
models, 1,002-route workload, payloads, load tool, connection count, rotation,
and measurement duration. After integrating the optimized span router and the
associated request, params, pipeline, and responder allocation work, the
medians improved by 49.2% for generic JSON, 50.1% for validated JSON, 46.1% for
validated CBOR, and 39.1% for bidirectional COSE.

That is the complete integrated patch set—not proof that the router alone
caused every percentage point. The rounds also ran on separate ephemeral
Droplets, so ordinary cloud-host variation remains a limitation.

## Keep the workload attached to the number

This was a synthetic in-memory acknowledgement endpoint. It did not include a
database, external service, TLS termination, HTML rendering, application
logging middleware, or public-internet latency. It establishes the measured
cost of codecs, validation, and the framework request path on constrained
hardware. It is not a production capacity promise.

The Amber website's roughly 5,900 complete homepage responses per second is a
different, application-shaped workload and remains the better headline for
what a real rendered site did. The 19,488 validated JSON result answers a more
specific question: can Amber make request and response contracts real without
giving up the performance people came to Crystal for? In this measured
workload, yes.

Start with the [request and response schema guide](/docs/v2/guides/schema-api/),
read the [full performance methodology](/docs/v2/guides/performance/), or
inspect the [machine-readable summary](/benchmarks/amber-v2-schema-contract-round27-summary.json)
when you need the exact retained values.
