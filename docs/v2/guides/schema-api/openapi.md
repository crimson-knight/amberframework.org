---
title: "OpenAPI Generation"
section: "guides/schema-api"
order: 40
description: "Automatic OpenAPI specification generation from schemas"
---

# OpenAPI Generation

The Schema API can automatically generate OpenAPI (Swagger) specifications from your schema definitions.

## Basic OpenAPI Metadata

Add OpenAPI metadata to your schemas:

```crystal
class CreateUserSchema < Amber::Schema::Definition
  openapi do
    operation_id "createUser"
    tags ["Users", "Registration"]
    summary "Create a new user account"
    description "Creates a new user with the provided information"

    responses do
      success 201, "User created successfully"
      error 400, "Invalid request data"
      error 409, "Email already exists"
    end
  end

  field :email, String,
    required: true,
    format: :email,
    description: "User's email address",
    example: "user@example.com"

  field :name, String,
    required: true,
    description: "User's full name",
    example: "John Doe"

  field :role, String,
    enum: ["admin", "user", "guest"],
    default: "user",
    description: "User's role in the system"

  validates_to UserRequest, UserValidationError
end
```

## Field Documentation

Document each field for the API spec:

```crystal
field :email, String,
  required: true,
  format: :email,
  description: "User's email address",
  example: "user@example.com",
  deprecated: false

field :password, String,
  required: true,
  min_length: 8,
  description: "User's password (min 8 characters)",
  example: "securepassword123",
  write_only: true  # Won't appear in response schemas
```

## Generating the Spec

Generate the OpenAPI specification:

```crystal
# config/initializers/openapi.cr
OpenAPI.configure do |config|
  config.title = "My API"
  config.version = "2.0.0"
  config.description = "API documentation for My Application"

  config.servers = [
    {url: "https://api.example.com", description: "Production"},
    {url: "https://staging-api.example.com", description: "Staging"}
  ]

  config.contact = {
    name: "API Support",
    email: "support@example.com"
  }
end

# Generate spec
spec = OpenAPI.generate_from_schemas([
  CreateUserSchema,
  UpdateUserSchema,
  ListUsersSchema
])

File.write("public/openapi.json", spec.to_json)
```

## Route Integration

Connect schemas to routes:

```crystal
# config/routes.cr
routes :api do
  post "/users", UsersController, :create,
    schema: CreateUserSchema,
    response_schema: UserResponseSchema

  get "/users/:id", UsersController, :show,
    schema: GetUserSchema,
    response_schema: UserResponseSchema
end
```

## Response Schemas

Define response schemas:

```crystal
class UserResponseSchema < Amber::Schema::Response
  field :id, Int64
  field :email, String
  field :name, String
  field :role, String
  field :created_at, Time

  openapi do
    description "User object response"
  end
end

class ErrorResponseSchema < Amber::Schema::Response
  field :message, String
  field :errors, Hash(String, Array(String))
  field :error_code, String

  openapi do
    description "Error response with validation details"
  end
end
```

## Security Definitions

Define authentication schemes:

```crystal
OpenAPI.configure do |config|
  config.security_schemes = {
    "bearerAuth" => {
      type: "http",
      scheme: "bearer",
      bearer_format: "JWT"
    },
    "apiKey" => {
      type: "apiKey",
      in: "header",
      name: "X-API-Key"
    }
  }
end

# Apply to schema
class ProtectedSchema < Amber::Schema::Definition
  openapi do
    security ["bearerAuth"]
  end

  # ...fields
end
```

## Serving the Spec

Serve the OpenAPI spec and Swagger UI:

```crystal
# config/routes.cr
routes :api do
  # OpenAPI JSON spec
  get "/openapi.json", OpenAPIController, :spec

  # Swagger UI (if using swagger-ui assets)
  get "/docs", OpenAPIController, :swagger_ui
end
```

```crystal
# src/controllers/openapi_controller.cr
class OpenAPIController < ApplicationController
  def spec
    spec = OpenAPI.generate
    respond_with 200, spec.to_json, "application/json"
  end

  def swagger_ui
    render "openapi/swagger_ui.slang"
  end
end
```

## Example Generated Spec

The generated OpenAPI spec looks like:

```json
{
  "openapi": "3.0.3",
  "info": {
    "title": "My API",
    "version": "2.0.0"
  },
  "paths": {
    "/users": {
      "post": {
        "operationId": "createUser",
        "tags": ["Users", "Registration"],
        "summary": "Create a new user account",
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/CreateUser"
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "User created successfully"
          },
          "400": {
            "description": "Invalid request data"
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "CreateUser": {
        "type": "object",
        "required": ["email", "name"],
        "properties": {
          "email": {
            "type": "string",
            "format": "email",
            "description": "User's email address",
            "example": "user@example.com"
          },
          "name": {
            "type": "string",
            "description": "User's full name",
            "example": "John Doe"
          },
          "role": {
            "type": "string",
            "enum": ["admin", "user", "guest"],
            "default": "user"
          }
        }
      }
    }
  }
}
```
