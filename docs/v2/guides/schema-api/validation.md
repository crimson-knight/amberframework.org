---
title: "Validation"
section: "guides/schema-api"
order: 20
description: "Built-in validators and custom validation in Amber 2.0"
---

# Validation

Schema fields can enforce presence, length, format, numeric bounds, and custom
rules before application code receives a typed value.

## Built-in Validators

### Required

```crystal
field :email, String, required: true
field :age, Int32, required: true
field :bio, String?  # Optional by default
```

### String Validators

#### Length

```crystal
field :username, String, min_length: 3, max_length: 20
field :password, String, min_length: 8
field :bio, String, max_length: 500
field :zip_code, String, length: 5  # Exact length
```

#### Format

```crystal
field :email, String, format: :email
field :url, String, format: :url
field :phone, String, format: :phone_number
field :ssn, String, format: /^\d{3}-\d{2}-\d{4}$/  # Custom regex
```

#### Predefined Formats

```crystal
:email          # Valid email address
:url            # Valid URL (http/https)
:uri            # Valid URI
:uuid           # Valid UUID v4
:phone_number   # International phone format
:ip_address     # IPv4 or IPv6
:ipv4           # IPv4 only
:ipv6           # IPv6 only
:credit_card    # Credit card number (Luhn check)
:slug           # URL-safe slug
:alpha          # Letters only
:numeric        # Numbers only
:alphanumeric   # Letters and numbers
```

### Numeric Validators

```crystal
field :age, Int32, min: 18, max: 120
field :price, Float64, min: 0.01, max: 999999.99
field :quantity, Int32, min: 1
field :percentage, Float64, min: 0.0, max: 100.0
```

### Enum Validators

```crystal
field :status, String, enum: ["active", "inactive", "pending"]
field :role, String, enum: UserRoles::ALL
field :priority, Int32, enum: [1, 2, 3, 4, 5]
```

### Array Validators

```crystal
field :tags, Array(String), min_items: 1, max_items: 10
field :categories, Array(Int32), unique: true
field :emails, Array(String), each: {format: :email}
```

## Conditional Validations

### When Field Has Value

```crystal
class OrderSchema < Amber::Schema::Definition
  field :payment_method, String, enum: ["card", "paypal", "bitcoin"]

  # Only validate card fields when payment is "card"
  when_field :payment_method, "card" do
    field :card_number, String, required: true, format: :credit_card
    field :cvv, String, required: true, length: 3..4
    field :expiry, String, required: true, format: /^\d{2}\/\d{2}$/
  end

  when_field :payment_method, "paypal" do
    field :paypal_email, String, required: true, format: :email
  end
end
```

### When Field Present

```crystal
when_present :coupon_code do
  validate :valid_coupon
  validate :not_expired
end
```

### Field Dependencies

```crystal
# All must be present together
requires_together :address, :city, :state, :zip

# Exactly one must be present
requires_one_of :email, :phone, :username

# At least one must be present
requires_any_of :home_phone, :work_phone, :mobile_phone
```

## Custom Validators

### Instance Method Validators

```crystal
class RegistrationSchema < Amber::Schema::Definition
  field :password, String, required: true, min_length: 8
  field :password_confirmation, String, required: true
  field :age, Int32, required: true

  validate :password_matches
  validate :age_appropriate

  private def password_matches
    if password != password_confirmation
      errors.add(:password_confirmation, "doesn't match password")
    end
  end

  private def age_appropriate
    if age < 13
      errors.add(:age, "must be 13 or older")
    elsif age < 18
      warnings.add(:age, "parental consent required")
    end
  end
end
```

### Validator Classes

Create reusable validators:

```crystal
class EmailUniquenessValidator < Amber::Schema::Validator
  def validate(value : String, field : Field, schema : Schema)
    if User.exists?(email: value)
      schema.errors.add(field.name, "is already taken")
    end
  end
end

class SignupSchema < Amber::Schema::Definition
  field :email, String, required: true, format: :email,
        validator: EmailUniquenessValidator.new
end
```

## Validation Contexts

Run different validations based on context:

```crystal
class UserSchema < Amber::Schema::Definition
  field :email, String, required: true, format: :email
  field :password, String, required: true, min_length: 8, on: :create
  field :current_password, String, required: true, on: :update

  validate :password_complexity, on: :create
  validate :current_password_correct, on: :update
  validate :email_domain_allowed  # Runs in all contexts
end

# Usage
schema = UserSchema.new(data, context: :create)
schema = UserSchema.new(data, context: :update)
```

## Custom Error Messages

```crystal
field :age, Int32,
      required: {message: "is required for registration"},
      min: {value: 18, message: "must be 18 or older to register"}

field :email, String,
      format: {value: :email, message: "doesn't look like a valid email"}
```

## Error Handling

### Error Response Formatting

```crystal
class ValidationErrorResponse < Amber::Schema::Response
  def initialize(error : Amber::Schema::ValidationError)
    @errors = error.errors
    @message = "Validation failed"
  end

  def to_json
    {
      message: @message,
      errors: @errors,
      error_code: "VALIDATION_ERROR"
    }.to_json
  end
end
```

### In Controller

```crystal
def create
  case result = CreateUserSchema.validate(request)
  when Amber::Schema::Success
    user = User.create!(result.data)
    respond_with 201, user.to_json
  when Amber::Schema::Failure
    respond_with 400, {
      message: "Validation failed",
      errors: result.error.errors
    }.to_json
  end
end
```

## Validation Flow

The validation process follows this order:

1. **Parse** - Extract data from request based on content type
2. **Coerce** - Convert string values to proper types
3. **Validate** - Run all validators in order
4. **Transform** - Apply any transformations
5. **Return** - Success with typed data or Failure with errors
