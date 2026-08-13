---
title: "Validation and Migration"
section: "guides/schema-api"
order: 20
description: "Automatic schema enforcement, response contracts, and gradual V1 migration"
---

# Validation and migration

> **Release candidate:** automatic action enforcement and the HTML failure hook
> are under review for the next V2 beta in
> [Amber PR #1408](https://github.com/amberframework/amber/pull/1408), not the
> already-tagged beta.4. The deprecated validator remains functional in both.

A schema bound with `schema :action, SchemaClass` runs before user callbacks and
before the controller action. Application code does not call a manual
`SchemaClass.validate(request)` method, and no extra route keyword is required.

This distinction matters: the same declarations that generate documentation
are the declarations Amber enforces at runtime.

## Where the examples go

- Put reusable contracts under `src/schemas/`.
- Put action bindings, `validated_as` or `validated_params` reads, response
  declarations, and the HTML failure hook inside the matching controller under
  `src/controllers/`.
- The short typed-value and closed-contract fragments on this page belong
  inside those schema or controller files; they are not terminal commands.
- Put request-level acceptance examples under `spec/controllers/` and isolated
  contract examples under `spec/schemas/`.

## Request enforcement

**File: `src/controllers/pets_controller.cr`.**

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

Amber performs this request-local sequence before `create` runs:

1. verify the request media type against the schema;
2. parse the body and collect declared path, query, header, and cookie values;
3. coerce each declared value once;
4. apply required, range, length, enum, format, pattern, nested, conditional,
   and cross-field rules;
5. expose the same normalized values to constraints, typed getters, and the
   controller action.

If validation fails, the action does not run. Amber writes the structured error
response and stops the controller callback path.

## Keep HTML form failures as HTML

The default failure body is JSON because controller schemas commonly protect
API boundaries. A server-rendered controller can override one hook without
giving up automatic enforcement.

**File: `src/controllers/pets_controller.cr` — add this inside
`PetsController`.**

```crystal
protected def handle_schema_validation_failure(
  action : Symbol,
  result : Amber::Schema::LegacyResult,
) : Nil
  @errors = result.errors
  error = result.errors.first?
  response.status_code = error.is_a?(Amber::Schema::RequestParseError) ? error.http_status : 422
  response.content_type = "text/html"

  case action
  when :create
    @pet = Pet.new
    context.content = render("new.ecr")
  when :update
    if pet = Pet.find(params[:id])
      @pet = pet
      context.content = render("edit.ecr")
    else
      redirect_to "/pets"
    end
  else
    super
  end
end
```

Setting `context.content` gives Amber the complete rendered response and keeps
the action from running. New CLI HTML scaffolds use this pattern so an invalid
form returns an ECR page with its field errors; API controllers keep the JSON
default.

## Typed values and the normalized hash

```crystal
input = validated_as(CreatePetSchema)
name = input.name.not_nil! # String
age = input.age            # Int32?

values = validated_params.not_nil!
raw_name = values["name"] # JSON::Any
```

`validated_as` verifies that the request-local schema has the expected class.
It never returns a schema object shared by another request. The field metadata
is shared, while data, errors, and typed values remain request-local.

After a schema succeeds, the controller's existing `params` helper prioritizes
the normalized schema values and falls back to raw params for undeclared keys.
That bridge supports action-by-action migration without changing unrelated
controller code.

## Response enforcement

**File: `src/controllers/pets_controller.cr` — declare the response above the
action and use the schema-aware `respond_with` inside it.**

```crystal
response_schema :create,
  PetResponseSchema,
  status: 201,
  description: "Pet created"

def create
  input = validated_as(CreatePetSchema)
  pet = Pet.create!(name: input.name.not_nil!)

  respond_with({
    "id"   => JSON::Any.new(pet.id),
    "name" => JSON::Any.new(pet.name),
  }, status: 201)
end
```

Before serialization, Amber validates the response shape and exact declared
status. A mismatch becomes a 500 contract error. If the client asks for a
format the response schema does not declare, Amber returns 406.

Use the regular controller `respond_with` blocks for HTML, JSON, XML, text,
JavaScript, or Markdown pages that do not use a response schema. The schema
version accepts `Hash(String, JSON::Any)`, a named tuple, or `nil` so it can
validate and encode the response contract.

## Open and closed contracts

Schemas accept undeclared fields by default for backwards compatibility.
Choose a closed contract deliberately:

```crystal
class CreatePetSchema < Amber::Schema::Definition
  additional_properties false

  field :name, String, required: true
end
```

With that line, an undeclared request-body field produces 422 and an
undeclared response field produces the response-contract 500. Without it,
undeclared fields remain available in the normalized data.

## Failure statuses

| Status | Contract boundary |
|---|---|
| `400` | Malformed JSON, CBOR, or COSE document |
| `406` | Undeclared response representation |
| `415` | Undeclared request representation |
| `422` | Parsed values fail the request schema |
| `500` | Response shape or status fails its schema |
| `503` | COSE input is valid in principle, but no key provider is configured |

The error response includes a stable code, the affected field when applicable,
and validation details. Do not turn a malformed document into a 422 or a
well-formed invalid document into a 400; the distinction helps clients correct
the right layer.

## Migrate the deprecated validator gradually

Existing V1-style code continues to compile and run in Amber V2:

**File: the existing action under `src/controllers/` — unchanged legacy code.**

```crystal
validation = params.validation do
  required(:email) { |value| value.email? }
end
```

The compiler emits a deprecation warning because new code should use an
executable controller schema. The warning does not mean the API was removed in
V2.0. Amber plans no removal before a later V2 minor such as 2.5, and the exact
release will be announced separately.

Use this order:

1. change the Amber version and verify the existing application first;
2. define one action's request schema under `src/schemas/`;
3. bind it with `schema :action, SchemaClass`;
4. replace reads with `validated_as(SchemaClass)` or `validated_params`;
5. add `response_schema` to API actions whose output should be enforced;
6. run the action's request specs and the complete application suite;
7. repeat for the next action.

The source-compatible `validate_schema` and `auto_validate` declarations may
remain during the migration, but they no longer control enforcement: a bound
schema always runs automatically.

## Test both sides of the contract

For every bound action, keep request specs that prove at least:

- one valid request reaches the action;
- malformed input returns 400;
- an unsupported request content type returns 415;
- valid syntax with invalid values returns 422;
- each supported response media type is negotiated correctly;
- an unsupported `Accept` value returns 406; and
- a deliberately invalid response fails closed with 500.

For COSE endpoints, also test a valid inbound envelope, authentication failure,
an unknown key ID, key rotation, and behavior when configuration is absent.
