---
title: "Schema Basics"
section: "guides/schema-api"
order: 10
description: "Schema definition, field types, and options in Amber 2.0"
---

# Schema Basics

A schema declares an input contract: accepted content type, typed fields,
defaults, validation rules, and the value or error type produced after parsing.

## Schema Definition

A schema is a class that inherits from `Amber::Schema::Definition`:

```crystal
class CreateUserSchema < Amber::Schema::Definition
  content_type "application/json"

  field :email, String, required: true, format: :email
  field :name, String, required: true
  field :age, Int32, min: 18

  validates_to UserRequest, UserValidationError
end
```

## Field Types

### Basic Types

```crystal
field :name, String              # String field
field :age, Int32                # Integer field
field :price, Float64            # Float field
field :active, Bool              # Boolean field
field :id, UUID                  # UUID field
field :created_at, Time          # Time field
```

### Collections

```crystal
field :tags, Array(String)                # Array of strings
field :scores, Array(Int32)               # Array of integers
field :metadata, Hash(String, String)     # Hash/dictionary
```

### Nested Objects

```crystal
field :address, AddressSchema             # Single nested object
field :addresses, Array(AddressSchema)    # Array of nested objects
```

## Field Options

### Required Fields

```crystal
field :email, String, required: true    # Must be present
field :nickname, String?                # Optional (can be nil)
field :bio, String                      # Optional by default
```

### Default Values

```crystal
field :role, String, default: "user"
field :active, Bool, default: true
field :page, Int32, default: 1
```

### Field Aliases

Map different input names to your field:

```crystal
field :email, String, as: "user_email"       # JSON: {"user_email": "..."}
field :full_name, String, as: "fullName"     # CamelCase input
```

### Normalization

Transform values before validation:

```crystal
field :email, String,
  normalize: ->(s : String) { s.downcase.strip }

field :phone, String,
  normalize: ->(s : String) { s.gsub(/\D/, "") }

field :tags, Array(String),
  normalize: ->(tags : Array(String)) { tags.map(&.downcase).uniq }
```

## Parameter Sources

Specify where parameters come from:

```crystal
class SearchSchema < Amber::Schema::Definition
  # From URL query string: ?q=search&page=1
  from_query do
    field :q, String, as: :query
    field :page, Int32, default: 1
    field :per_page, Int32, default: 20
  end

  # From URL path: /categories/:category_id/products
  from_path do
    field :category_id, Int32
  end

  # From HTTP headers
  from_header do
    field :api_key, String, key: "X-API-Key"
    field :version, String, key: "X-API-Version", default: "v1"
  end

  # From request body
  from_body do
    field :filters, SearchFilters
  end

  validates_to SearchRequest, SearchValidationError
end
```

## Nested Schemas

Create reusable schemas for nested objects:

```crystal
class AddressSchema < Amber::Schema::Definition
  field :street, String, required: true
  field :city, String, required: true
  field :state, String, required: true, length: 2
  field :zip, String, required: true, format: /^\d{5}(-\d{4})?$/

  validates_to Address, AddressValidationError
end

class UserSchema < Amber::Schema::Definition
  field :name, String, required: true
  field :email, String, required: true, format: :email

  # Single nested object
  field :primary_address, AddressSchema

  # Array of nested objects
  field :addresses, Array(AddressSchema), max_items: 5

  validates_to User, UserValidationError
end
```

## Schema Inheritance

Share common fields across schemas:

```crystal
# Base schema with common fields
abstract class BaseUserSchema < Amber::Schema::Definition
  field :email, String, required: true, format: :email
  field :name, String, required: true
end

# Registration adds password
class RegistrationSchema < BaseUserSchema
  field :password, String, required: true, min_length: 8
  field :password_confirmation, String, required: true
  field :terms_accepted, Bool, required: true

  validate :password_matches
  validates_to NewUser, RegistrationError
end

# Update doesn't require password
class UpdateUserSchema < BaseUserSchema
  field :bio, String, max_length: 500
  field :avatar_url, String, format: :url

  validates_to UserUpdate, UpdateError
end
```

## Type Coercion

The schema system automatically converts string inputs:

```crystal
# Input: {"age": "25", "active": "true", "price": "19.99"}
class ProductSchema < Amber::Schema::Definition
  field :age, Int32        # "25" -> 25
  field :active, Bool      # "true" -> true
  field :price, Float64    # "19.99" -> 19.99
end
```

### Custom Coercion

```crystal
class DateRangeSchema < Amber::Schema::Definition
  field :start_date, Time,
    coerce: ->(s : String) { Time.parse(s, "%Y-%m-%d", Time::Location::UTC) }

  field :status, Status,
    coerce: ->(s : String) { Status.parse(s) }
end
```

## State-Based Types

Schemas validate to specific success and failure types:

```crystal
# Success type - immutable, validated data
class UserRequest < Amber::Schema::ValidatedRequest
  getter email : String
  getter name : String
  getter age : Int32

  # Computed properties
  def adult? : Bool
    age >= 18
  end
end

# Failure type - contains validation errors
class UserValidationError < Amber::Schema::ValidationError
  def to_response
    {
      message: "User validation failed",
      errors: errors,
      fields: errors.keys
    }
  end
end
```

## Transformations

Apply transformations after validation:

```crystal
class RegistrationSchema < Amber::Schema::Definition
  field :first_name, String, required: true
  field :last_name, String, required: true
  field :email, String, required: true

  # Add computed fields after validation
  transform do |data|
    data.full_name = "#{data.first_name} #{data.last_name}"
    data.username = data.email.split("@").first
  end

  validates_to Registration, RegistrationError
end
```

## Documentation Metadata

Add documentation for API generation:

```crystal
class APISchema < Amber::Schema::Definition
  description "Creates a new user account"

  field :email, String,
    required: true,
    format: :email,
    description: "User's email address",
    example: "user@example.com"

  field :role, String,
    enum: ["admin", "user", "guest"],
    default: "user",
    description: "User's role in the system"
end
```
