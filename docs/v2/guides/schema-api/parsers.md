---
title: "Request Formats"
section: "guides/schema-api"
order: 30
description: "JSON, forms, XML, deterministic CBOR, and encrypted COSE requests"
---

# Request formats

> **Released in `2.0.0-beta.5`:** bounded CBOR and bidirectional authenticated
> COSE are available as opt-in request and response formats.

Declare every request representation an action actually accepts. Amber checks
the incoming `Content-Type` before parsing and returns 415 when the media type
is outside the contract.

## Where the examples go

- Put `content_type` and field declarations inside a contract under
  `src/schemas/`.
- Put the COSE provider in `config/wire_format.cr` and require it from
  `config/application.cr`.
- The JSON, form, and XML documents shown here are HTTP request bodies sent to
  the bound action; they are not files to add to the application.
- Run key-generation and request commands from the application root beside
  `shard.yml`.

## Supported request media types

| Media type | Parser |
|---|---|
| `application/json` or `text/json` | JSON object |
| `application/xml`, `text/xml`, or `application/xhtml+xml` | XML document |
| `application/x-www-form-urlencoded` | Form fields, including bracket notation |
| `multipart/form-data` | Form fields and uploaded-file metadata |
| `application/cbor` | Bounded deterministic CBOR object |
| `application/cose` | COSE Encrypt0 containing the CBOR object |

CSV, Protocol Buffers, and MessagePack are not built-in Amber V2 schema
formats. Applications may integrate them separately, but public contracts
should not claim framework support that is not present.

## Declare one or more formats

**File: `src/schemas/create_pet_schema.cr`.**

```crystal
class CreatePetSchema < Amber::Schema::Definition
  content_type "application/json"

  field :name, String, required: true
  field :species, String, required: true
end
```

To support the same JSON-compatible object through JSON, CBOR, and encrypted
COSE:

```crystal
content_type "application/json", "application/cbor", "application/cose"
```

The controller binding is unchanged. Amber chooses the request parser from
`Content-Type` and the schema-aware response format from `Accept`.

## JSON

**File: the request body sent to the bound action — not a Crystal source file.**

```json
{
  "name": "Mochi",
  "species": "cat",
  "age": 3,
  "tags": ["indoor", "friendly"]
}
```

The top-level document must be an object. Malformed JSON and non-finite numbers
fail before field validation.

## URL-encoded forms

**File: `src/schemas/registration_schema.cr`.**

```crystal
class RegistrationSchema < Amber::Schema::Definition
  content_type "application/x-www-form-urlencoded"

  field :name, String, required: true
  field :email, String, required: true, format: "email"
  field :age, Int32, min: 13
  field :tags, Array(String)
end
```

**Example HTTP body:**

```text
name=Alex&email=alex%40example.com&age=28&tags[]=crystal&tags[]=amber
```

Amber reuses the router's cached form parse when method override or another
request step has already inspected the body. It does not consume the form once
for routing and then hand an empty stream to the schema.

## Multipart forms and files

**File: `src/schemas/photo_upload_schema.cr`.**

```crystal
class PhotoUploadSchema < Amber::Schema::Definition
  content_type "multipart/form-data"

  field :title, String, required: true
  field :photo, Hash(String, JSON::Any),
    required: true,
    max_size: 5_000_000,
    allowed_types: ["image/jpeg", "image/png", "image/webp"],
    allowed_extensions: ["jpg", "jpeg", "png", "webp"]
end
```

The multipart parser exposes uploaded-file metadata to the schema and reuses
Amber's cached multipart fields and files. Validation at this layer is an
admission check; use the [uploads guide](../uploads/) for storage ownership,
image processing, and serving policy.

## XML

**File: `src/schemas/create_event_schema.cr`.**

```crystal
class CreateEventSchema < Amber::Schema::Definition
  content_type "application/xml"

  field :name, String, required: true
  field :starts_at, Time, required: true
end
```

**Example HTTP body:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<event>
  <name>Amber meetup</name>
  <starts_at>2026-09-01T18:00:00Z</starts_at>
</event>
```

XML is available for inbound schema parsing. The schema-aware `respond_with`
encoder currently emits JSON, CBOR, or COSE; do not declare automatic XML
response encoding unless the controller implements and tests that response
path explicitly.

## Deterministic CBOR

`application/cbor` carries the JSON-compatible contract in a compact binary
form. Amber's decoder is bounded to:

- 1 MiB per document;
- 32 levels of nesting; and
- 16,384 collection items.

It rejects indefinite lengths, duplicate map keys, invalid UTF-8, trailing
bytes, byte strings where a JSON-compatible value is required, and non-finite
numbers. Typed schema validation runs after decoding exactly as it does for
JSON.

## Authenticated COSE Encrypt0

`application/cose` carries that deterministic CBOR object in a tagged COSE
Encrypt0 envelope using ChaCha20-Poly1305. Amber authenticates and decrypts the
request, validates the object, then can encode, authenticate, and encrypt the
response with a fresh 96-bit nonce.

There is no built-in development key.

### 1. Generate a 32-byte deployment key

**Run from: the application root.**

```bash
openssl rand -base64 32
```

Store the result in the deployment secret manager as `AMBER_WIRE_KEY`. Store a
non-empty identifier such as `2026-08` as `AMBER_WIRE_KEY_ID`. Do not commit
either value.

### 2. Configure the provider

**File: `config/wire_format.cr` — create this file.**

```crystal
Amber::Schema::COSE.configure(
  Amber::Schema::COSE::KeyProvider.from_env!
)
```

**File: `config/application.cr` — require it after Amber and before controller
files.**

```crystal
require "amber"
require "./wire_format"
require "../src/controllers/application_controller"
require "../src/controllers/**"
require "./routes"
```

The key provider selects keys by COSE key ID and can retain a grace key during
rotation. A COSE request without configuration returns 503. Authentication,
unknown-key, malformed-envelope, and replay-policy behavior should be covered
by application tests before production use.

## Response negotiation

Declare formats on the response schema too:

```crystal
class PetResponseSchema < Amber::Schema::Definition
  content_type "application/json", "application/cbor", "application/cose"

  field :id, Int64, required: true
  field :name, String, required: true
end
```

- `Accept: application/json` returns JSON.
- `Accept: application/cbor` returns deterministic CBOR.
- `Accept: application/cose` returns authenticated COSE Encrypt0 containing
  deterministic CBOR.
- An undeclared representation returns 406.

The `X-Amber-Wire-Format` header describes Amber's selected COSE profile. It is
informational and never replaces client-side authentication of the message.
