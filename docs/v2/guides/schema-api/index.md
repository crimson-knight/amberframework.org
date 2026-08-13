---
title: "Request and Response Schemas"
section: "guides"
order: 20
is_section: true
description: "Executable request, response, and OpenAPI contracts in Amber V2"
---

# Request and response schemas

> **Released in `2.0.0-beta.5`:** the framework now enforces these request and
> response contracts automatically. Amber CLI `2.0.6` generates controllers
> that use this path by default.

Amber V2 schemas are executable controller contracts. One declaration controls
request parsing, validation, typed values, response validation, content
negotiation, and OpenAPI output. A declared controller schema runs automatically
before the action; it cannot become documentation that the application forgets
to enforce.

The V1 `params.validation` API remains functional in `2.0.0-beta.5`, but
it is deprecated. Amber plans to keep it throughout the initial V2 compatibility
window and remove it
no earlier than a later minor release such as 2.5. The exact removal release
will be announced separately. Upgrade the framework first, then migrate one
action at a time.

## Build a complete JSON endpoint

This example creates a pet through `POST /pets`. Every block names the file
where it belongs.

### 1. Define the request and response contracts

**File: `src/schemas/pet_schemas.cr` — create this file.**

```crystal
class CreatePetSchema < Amber::Schema::Definition
  content_type "application/json"
  additional_properties false

  field :name, String, required: true, min_length: 1, max_length: 80
  field :species, String, required: true, enum: ["cat", "dog", "other"]
  field :age, Int32, min: 0, max: 50
  field :request_id, String,
    required: true,
    source: Amber::Schema::ParamSource::Header,
    source_name: "X-Request-ID"
end

class PetResponseSchema < Amber::Schema::Definition
  content_type "application/json"
  additional_properties false

  field :id, Int64, required: true
  field :name, String, required: true
  field :species, String, required: true
  field :age, Int32
end
```

`additional_properties false` closes the contract. An undeclared request-body
or response field then fails validation. Omit that line while an existing API
must continue accepting and carrying fields that are not yet declared.

### 2. Bind both contracts to the controller action

**File: `src/controllers/pets_controller.cr` — add the declarations above the
action and the action inside `PetsController`.**

```crystal
require "../schemas/pet_schemas"

class PetsController < ApplicationController
  schema :create, CreatePetSchema
  response_schema :create,
    PetResponseSchema,
    status: 201,
    description: "Pet created"

  def create
    input = validated_as(CreatePetSchema)
    pet = Pet.create!(
      name: input.name.not_nil!,
      species: input.species.not_nil!,
      age: input.age
    )

    payload = {
      "id"      => JSON::Any.new(pet.id),
      "name"    => JSON::Any.new(pet.name),
      "species" => JSON::Any.new(pet.species),
    }
    payload["age"] = JSON::Any.new(pet.age.not_nil!) if pet.age

    respond_with(payload, status: 201)
  end
end
```

Amber parses and validates the request before `create` runs. `validated_as`
returns the request-local schema instance and its generated typed getters.
Use `validated_params` when a `Hash(String, JSON::Any)` is more convenient.

`respond_with` validates the response object and status before writing bytes.
If application code produces a shape or status outside `PetResponseSchema`,
Amber returns a 500 contract error instead of silently serving an undocumented
response.

### 3. Add the route

**File: `config/routes.cr` — add this inside the existing router block.**

```crystal
post "/pets", PetsController, :create
```

Schemas bind to controller actions, not to extra route keywords. The ordinary
route also supplies the metadata used by OpenAPI generation.

### 4. Exercise the contract

**Run from: the application root while `amber watch` is running.**

```bash
curl --fail-with-body \
  --request POST \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header 'X-Request-ID: guide-1' \
  --data '{"name":"Mochi","species":"cat","age":3}' \
  http://127.0.0.1:3000/pets
```

## Automatic contract responses

| Status | Meaning |
|---|---|
| `400` | The JSON, CBOR, or COSE body is malformed. |
| `406` | The requested response media type is not declared by the response schema. |
| `415` | The request `Content-Type` is not declared by the request schema. |
| `422` | The document parsed, but its values do not satisfy the schema. |
| `500` | Application code produced a response shape or status outside its declared contract. |
| `503` | A COSE request arrived before a key provider was configured. |

Actions without a declared schema retain their existing params behavior.

## Continue from here

- [Schema basics](basics/) covers field types, constraints, parameter sources,
  nested objects, and conditional relationships.
- [Validation and migration](validation/) explains enforcement, response
  contracts, and the deprecated-validator compatibility bridge.
- [Request formats](parsers/) covers JSON, forms, XML, CBOR, and encrypted COSE.
- [OpenAPI](openapi/) serves an OpenAPI 3.1 document from the same registered
  controller contracts.
