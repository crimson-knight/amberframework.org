---
title: "Schema Basics"
section: "guides/schema-api"
order: 10
description: "Field types, constraints, sources, and relationships in Amber V2 schemas"
---

# Schema basics

> **Release candidate:** the automatically enforced controller contracts on
> this page are under review for the next V2 beta in
> [Amber PR #1408](https://github.com/amberframework/amber/pull/1408), not the
> already-tagged beta.4.

Schema classes live under `src/schemas/`. They declare the data an action
accepts or returns; the controller binds those classes to actions with `schema`
and `response_schema`.

## Where the examples go

- Put named and reusable contracts in `src/schemas/*.cr`.
- Put `schema` and `response_schema` bindings inside the matching class under
  `src/controllers/`.
- Put route declarations inside the existing router block in `config/routes.cr`.
- The short field and relationship fragments on this page belong inside an
  `Amber::Schema::Definition` subclass under `src/schemas/`; they are not
  terminal commands or standalone Crystal files.

## Built-in field types

**File: a schema under `src/schemas/` — these are field declarations inside an
`Amber::Schema::Definition` subclass.**

```crystal
field :name, String
field :quantity, Int32
field :account_id, Int64
field :ratio, Float32
field :price, Float64
field :active, Bool
field :published_at, Time
field :external_id, UUID
field :tags, Array(String)
field :scores, Hash(String, Int32)
```

Amber also supports typed arrays and `Hash(String, T)` for the built-in value
types. If any collection member cannot be coerced, the field fails validation;
Amber does not discard the invalid item and report the shortened collection as
valid.

An unknown custom type fails closed unless the application registers an
explicit coercion for it.

## Required, default, and closed fields

```crystal
class RegistrationSchema < Amber::Schema::Definition
  content_type "application/json"
  additional_properties false

  field :email, String, required: true, format: "email"
  field :role, String, default: "member", enum: ["member", "admin"]
  field :age, Int32, min: 13, max: 120
end
```

- `required: true` rejects a missing or null value.
- `default:` supplies and coerces a value when the field is absent.
- `additional_properties false` rejects undeclared input or response keys.
- The default is open for backwards compatibility, so existing APIs can adopt
  fields incrementally.

## Constraints

```crystal
field :email, String, required: true, format: "email"
field :role, String, enum: ["member", "admin"]
field :score, Float64, min: 0.0, max: 1.0
field :nickname, String, min_length: 2, max_length: 30
field :slug, String, pattern: "^[a-z0-9-]+$"
```

Supported formats include `email`, `url` or `uri`, `uuid`, `iso8601` or
`datetime`, `date`, `time`, `ipv4`, `ipv6`, and `hostname`. A different format
string is treated as a regular-expression pattern; an invalid pattern fails
validation instead of silently becoming a no-op.

## Body, path, query, header, and cookie values

The request body is the default source. Set `source` for every value that comes
from another part of the request. Use `source_name` when the wire name should
not become the Crystal getter name.

**File: `src/schemas/show_pet_schema.cr` — create this file.**

```crystal
class ShowPetSchema < Amber::Schema::Definition
  field :id, Int64,
    required: true,
    source: Amber::Schema::ParamSource::Path

  field :include_visits, Bool,
    default: false,
    source: Amber::Schema::ParamSource::Query,
    source_name: "include_visits"

  field :request_id, String,
    source: Amber::Schema::ParamSource::Header,
    source_name: "X-Request-ID"

  field :session_hint, String,
    source: Amber::Schema::ParamSource::Cookie,
    source_name: "pet_session"
end
```

**File: `src/controllers/pets_controller.cr` — bind and use the schema inside
`PetsController`.**

```crystal
schema :show, ShowPetSchema

def show
  input = validated_as(ShowPetSchema)
  pet = Pet.find!(input.id.not_nil!)
  # Render or return the pet.
end
```

**File: `config/routes.cr` — add the path that supplies `:id`.**

```crystal
get "/pets/:id", PetsController, :show
```

OpenAPI emits path, query, header, and cookie fields as parameters rather than
incorrectly placing them in the JSON request body.

## Conditional fields

**File: `src/schemas/account_schema.cr` — create this schema.**

```crystal
class AccountSchema < Amber::Schema::Definition
  field :kind, String, required: true, enum: ["person", "business"]

  when_field :kind, "person" do
    field :first_name, String, required: true
    field :last_name, String, required: true
  end

  when_field :kind, "business" do
    field :company_name, String, required: true
    field :tax_id, String, required: true
  end
end
```

`when_present :field` provides the same conditional-required behavior when the
trigger only needs to exist. Conditional fields are normalized and constrained
through the same request-local validation pass as ordinary fields.

## Cross-field and nested relationships

```crystal
class AddressSchema < Amber::Schema::Definition
  field :city, String, required: true
  field :postal_code, String, required: true
end

class DeliverySchema < Amber::Schema::Definition
  field :latitude, Float64
  field :longitude, Float64
  requires_together :latitude, :longitude

  field :email, String
  field :phone, String
  requires_one_of :email, :phone

  nested :address, AddressSchema, required: true
end
```

- `requires_together` requires all named fields when any one appears.
- `requires_one_of` requires exactly one named field.
- `nested` validates an object with another schema and prefixes nested error
  paths, such as `address.city`.
- `embedded_array :addresses, AddressSchema` applies the nested contract to
  each object in an array and reports indexed paths.

These relationships also become OpenAPI `dependentRequired`, `oneOf`, nested
`$ref`, and conditional `if`/`then` structures.

## Inline action schemas

Keep reusable contracts in `src/schemas/`. For a genuinely action-local input,
the controller can declare the fields inline:

**File: `src/controllers/health_controller.cr`.**

```crystal
class HealthController < ApplicationController
  schema :check do
    field :verbose, Bool,
      default: false,
      source: Amber::Schema::ParamSource::Query
  end

  def check
    values = validated_params.not_nil!
    # Build the health response.
  end
end
```

The inline declaration is enforced automatically just like a named schema.
