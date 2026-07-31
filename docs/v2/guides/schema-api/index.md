---
title: "Schema API"
section: "guides"
order: 20
is_section: true
description: "Type-safe request handling with compile-time validation in Amber 2.0"
---

# Schema API

The Schema API is the headline feature of Amber 2.0. It provides compile-time validated request parameters with automatic type coercion, replacing the traditional params hash with a type-safe, validated approach.

## Why Schema API?

Traditional web frameworks handle request parameters as loosely-typed hashes:

```crystal
# Old way - runtime errors, no type safety
def create
  email = params[:email].as(String)  # Could fail at runtime
  age = params[:age].to_i            # No validation
end
```

With Schema API, you define your expectations upfront:

```crystal
# New way - compile-time safety, automatic validation
class CreateUserSchema < Amber::Schema::Definition
  field :email, String, required: true, format: :email
  field :age, Int32, min: 18

  validates_to UserRequest, UserValidationError
end
```

## Key Benefits

- **Type Safety**: Crystal's type system catches errors at compile time
- **Automatic Validation**: Built-in validators for common patterns
- **Content Type Aware**: Different schemas for JSON, XML, form data
- **Self-Documenting**: Schema definitions document your API
- **OpenAPI Generation**: Automatic API spec generation

## Quick Start

### 1. Define a Schema

```crystal
class CreatePostSchema < Amber::Schema::Definition
  content_type "application/json"

  field :title, String, required: true, max_length: 200
  field :body, String, required: true
  field :published, Bool, default: false
  field :tags, Array(String), max_items: 10

  validates_to PostRequest, PostValidationError
end
```

### 2. Define Success/Error Types

```crystal
class PostRequest < Amber::Schema::ValidatedRequest
  getter title : String
  getter body : String
  getter published : Bool
  getter tags : Array(String)
end

class PostValidationError < Amber::Schema::ValidationError
  def to_response
    {message: "Validation failed", errors: errors}
  end
end
```

### 3. Use in Controller

```crystal
class PostsController < ApplicationController
  def create
    case result = CreatePostSchema.validate(request)
    when Amber::Schema::Success
      post = Post.create!(result.data)
      respond_with 201, post.to_json
    when Amber::Schema::Failure
      respond_with 400, result.error.to_response.to_json
    end
  end
end
```

## Documentation Sections

- [Basics](basics/) - Schema definition, field types, and options
- [Validation](validation/) - Built-in validators and custom validation
- [Parsers](parsers/) - Content type handling (JSON, XML, Forms, etc.)
- [OpenAPI](openapi/) - Automatic API documentation generation
