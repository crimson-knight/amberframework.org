---
title: "OpenAPI 3.1"
section: "guides/schema-api"
order: 40
description: "Generate OpenAPI 3.1 from Amber's enforced controller contracts"
---

# OpenAPI 3.1

> **Released in `2.0.0-beta.5`:** OpenAPI generation reads the same controller
> contracts that Amber enforces at runtime.

`Amber::Schema::OpenAPI.generate` builds an OpenAPI 3.1 document from the
ordinary Amber router and the request and response schemas registered by
controllers. The generated document describes the same contracts Amber
enforces at runtime.

There is no separate OpenAPI registry, route-level request or response contract
keyword, or manually maintained schema list. Controller declarations are the
Amber V2 source of truth.

## Where the examples go

- Put request and response contracts under `src/schemas/`.
- Put their action bindings in the matching controller under `src/controllers/`.
- Put the document-serving action in `src/controllers/open_api_controller.cr`.
- Put every ordinary application route, including `/openapi.json`, inside the
  existing router block in `config/routes.cr`.
- The relationship fragment on this page belongs inside a schema class; it is
  not a standalone Crystal file.

## What Amber records

For each routed controller action, generation can include:

- the HTTP verb and path, with `:id` converted to `{id}`;
- a deterministic operation ID from the controller and action;
- path, query, header, and cookie parameters;
- the body-only request component;
- every declared JSON, CBOR, or COSE media type;
- the declared success status and description;
- field types, required fields, defaults, ranges, lengths, formats, patterns,
  and enums;
- nested object and array references;
- `dependentRequired` for `requires_together`;
- `oneOf` for `requires_one_of`;
- conditional `if`/`then` relationships; and
- the automatic 400, 415, 422, and 500 contract responses.

`application/cose` is described as a binary COSE Encrypt0 body containing the
declared CBOR schema. It is not mislabeled as a plain JSON object.

## 1. Bind schemas to controller actions

**File: `src/controllers/pets_controller.cr`.**

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
    # Create and return the pet with schema-aware respond_with.
  end
end
```

## 2. Register the ordinary route

**File: `config/routes.cr` — add this inside the router block.**

```crystal
post "/pets", PetsController, :create
```

Route registration supplies the endpoint metadata. Keep request and response
contract declarations on the controller; the ordinary route needs no extra
contract options.

## 3. Serve the document

**File: `src/controllers/open_api_controller.cr` — create this controller.**

```crystal
class OpenAPIController < ApplicationController
  def show
    response.content_type = "application/json"

    Amber::Schema::OpenAPI.generate(
      title: "Pet Tracker API",
      version: "2.0.0",
      description: "The executable contract for the Pet Tracker API",
      server_url: ENV["PUBLIC_URL"]? || "http://127.0.0.1:3000"
    )
  end
end
```

**File: `config/routes.cr` — add the document endpoint.**

```crystal
get "/openapi.json", OpenAPIController, :show
```

**Run from: the application root while the server is running.**

```bash
curl --fail-with-body \
  --header 'Accept: application/json' \
  http://127.0.0.1:3000/openapi.json
```

The method returns formatted JSON. Store a generated copy under `public/` only
when the application intentionally publishes a build artifact; generation can
also happen per request as shown above.

## Parameters stay out of the body

**File: `src/schemas/update_pet_schema.cr`.**

```crystal
class UpdatePetSchema < Amber::Schema::Definition
  field :id, Int64,
    required: true,
    source: Amber::Schema::ParamSource::Path

  field :preview, Bool,
    default: false,
    source: Amber::Schema::ParamSource::Query

  field :request_id, String,
    required: true,
    source: Amber::Schema::ParamSource::Header,
    source_name: "X-Request-ID"

  field :name, String, required: true
end
```

The generated request-body component contains `name`, but not `id`, `preview`,
or `request_id`. Those values become OpenAPI parameters at their real request
locations. This keeps generated clients from sending a required header inside
the JSON document.

## Relationships remain machine-readable

```crystal
class ContactSchema < Amber::Schema::Definition
  field :latitude, Float64
  field :longitude, Float64
  requires_together :latitude, :longitude

  field :email, String
  field :phone, String
  requires_one_of :email, :phone

  field :kind, String, enum: ["person", "business"]
  when_field :kind, "business" do
    field :company_name, String, required: true
  end
end
```

Amber emits the paired-coordinate dependency, exact contact alternative, and
business-only requirement. OpenAPI is therefore more than a field-name dump;
it preserves the relationships needed by validation-aware clients and tools.

## Current boundary

OpenAPI generation currently derives operation IDs, request and response
components, parameters, media types, statuses, descriptions, constraints, and
relationships. Application-wide tags, authentication schemes, contact
metadata, and a bundled Swagger UI are not configured through the Schema API
today. Add those in a separately owned document transformation or UI layer
instead of copying unsupported configuration examples into the application.
