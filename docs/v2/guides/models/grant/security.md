---
title: "Security Features"
section: "guides/models/grant"
order: 70
description: "Encrypted attributes, secure tokens, and signed IDs in Grant ORM"
---

# Security Features

Grant provides built-in security features for protecting sensitive data, generating secure tokens, and creating tamper-proof URLs.

## Encrypted Attributes

Store sensitive data encrypted at rest.

### Basic Encryption

```crystal
class User < Grant::Base
  column id : Int64, primary: true
  column email : String
  column ssn : String?
  column credit_card_number : String?

  # Encrypt these fields
  encrypts :ssn, :credit_card_number
end

# Usage is transparent
user = User.create!(
  email: "alice@example.com",
  ssn: "123-45-6789"
)

user.ssn  # => "123-45-6789" (decrypted)
# In database: encrypted blob
```

### Deterministic Encryption

Use deterministic encryption when you need to search encrypted fields.

```crystal
class User < Grant::Base
  # Non-deterministic (more secure, cannot search)
  encrypts :ssn

  # Deterministic (searchable)
  encrypts :phone_number, deterministic: true
end

# Can search deterministic fields
User.where(phone_number: "+1-555-1234")  # Works

# Cannot search non-deterministic fields
User.where(ssn: "123-45-6789")  # Won't work
```

### Configuration

```crystal
# config/initializers/encryption.cr
Grant::Encryption.configure do |config|
  config.primary_key = ENV["ENCRYPTION_PRIMARY_KEY"]
  config.key_derivation_salt = ENV["ENCRYPTION_KEY_DERIVATION_SALT"]
  config.deterministic_key = ENV["ENCRYPTION_DETERMINISTIC_KEY"]
end

# Generate keys
# crystal eval 'require "random"; puts Random::Secure.hex(32)'
```

## Secure Tokens

Generate cryptographically secure tokens for authentication.

### Basic Token Generation

```crystal
class User < Grant::Base
  column id : Int64, primary: true
  column email : String
  column auth_token : String?

  has_secure_token :auth_token
end

user = User.create!(email: "alice@example.com")
user.auth_token  # => "pX27zsMN2ViQKta1bGfLmVJE"

# Regenerate token
user.regenerate_auth_token
```

### Token Options

```crystal
class ApiKey < Grant::Base
  column id : Int64, primary: true
  column user_id : Int64
  column key : String?
  column secret : String?

  # Default: 24 characters, URL-safe base64
  has_secure_token :key

  # Custom length
  has_secure_token :secret, length: 32

  # Hex format
  has_secure_token :hex_key, length: 16, alphabet: :hex
end
```

### Token Authentication

```crystal
class ApplicationController < Amber::Controller::Base
  def authenticate_api_key
    token = request.headers["Authorization"]?
      .try(&.gsub("Bearer ", ""))

    unless token && ApiKey.find_by(key: token)
      halt!(401, "Invalid API key")
    end
  end
end
```

## Signed IDs

Create tamper-proof, expiring identifiers for URLs.

### Basic Signed IDs

```crystal
class User < Grant::Base
  include Grant::SignedId

  column id : Int64, primary: true
  column email : String
end

user = User.find!(1)

# Generate signed ID
signed_id = user.signed_id
# => "eyJfcmFpbHMiOnsibWVzc2FnZSI6Ik1RPT0iL..."

# Find by signed ID
found = User.find_signed(signed_id)
# => User(id: 1, email: "alice@example.com")

# Invalid/tampered ID returns nil
User.find_signed("tampered_id")  # => nil
```

### Expiring Signed IDs

```crystal
# Expires in 15 minutes
signed_id = user.signed_id(expires_in: 15.minutes)

# Expires at specific time
signed_id = user.signed_id(expires_at: 1.hour.from_now)

# Expired ID returns nil
User.find_signed(expired_signed_id)  # => nil
```

### Scoped Signed IDs

```crystal
# Scope to specific purpose
signed_id = user.signed_id(purpose: :password_reset)

# Must use same purpose to verify
User.find_signed(signed_id, purpose: :password_reset)  # Works
User.find_signed(signed_id, purpose: :email_confirm)   # => nil
```

### Use Cases

```crystal
class PasswordResetController < ApplicationController
  def create
    user = User.find_by!(email: params["email"])
    token = user.signed_id(
      expires_in: 15.minutes,
      purpose: :password_reset
    )

    PasswordResetMailer.send(user.email, token)
    redirect_to "/login", notice: "Check your email"
  end

  def update
    user = User.find_signed!(
      params["token"],
      purpose: :password_reset
    )

    user.update!(password: params["password"])
    redirect_to "/login", notice: "Password updated"
  rescue Grant::InvalidSignedId
    redirect_to "/forgot-password", alert: "Invalid or expired link"
  end
end
```

## Token Generation (token_for)

Generate purpose-specific tokens that can include record state.

```crystal
class User < Grant::Base
  include Grant::TokenFor

  column id : Int64, primary: true
  column email : String
  column password_salt : String

  # Token invalidates when password_salt changes
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end
end

# Generate token
user = User.find!(1)
token = user.generate_token_for(:password_reset)

# Find by token
found = User.find_by_token_for(:password_reset, token)

# Token invalidates if password changes
user.update!(password_salt: SecureRandom.hex)
User.find_by_token_for(:password_reset, token)  # => nil
```

## Data Normalization

Automatically normalize data before saving.

```crystal
class User < Grant::Base
  column email : String
  column phone : String?
  column name : String

  # Normalize email
  normalizes :email, &.downcase.strip

  # Normalize name
  normalizes :name, &.strip.titleize

  # Normalize phone (remove non-digits)
  normalizes :phone do |phone|
    phone.gsub(/\D/, "")
  end
end

user = User.new(
  email: "  ALICE@Example.COM  ",
  name: "alice smith",
  phone: "(555) 123-4567"
)

user.email  # => "alice@example.com"
user.name   # => "Alice Smith"
user.phone  # => "5551234567"
```

## Enum Attributes

Type-safe enumerated values.

```crystal
class User < Grant::Base
  column id : Int64, primary: true
  column role : String

  enum Role
    Guest
    Member
    Admin
    SuperAdmin
  end

  enum_attribute role : Role = :member
end

user = User.new
user.role        # => Role::Member
user.member?     # => true
user.admin?      # => false

user.admin!      # Sets role to Admin
user.role        # => Role::Admin

# Scopes generated automatically
User.admin       # Users with admin role
User.member      # Users with member role
```

## Best Practices

### 1. Protect Sensitive Data

```crystal
class User < Grant::Base
  # Always encrypt PII
  encrypts :ssn, :tax_id, :bank_account

  # Deterministic only when searchable needed
  encrypts :phone_number, deterministic: true

  # Never log sensitive data
  @[JSON::Field(ignore: true)]
  column ssn : String?
end
```

### 2. Use Scoped Tokens

```crystal
# Always scope tokens to purpose
signed_id = user.signed_id(purpose: :password_reset)

# Never use generic signed IDs for sensitive operations
```

### 3. Set Appropriate Expiration

```crystal
# Short expiration for sensitive operations
password_reset_token = user.signed_id(
  expires_in: 15.minutes,
  purpose: :password_reset
)

# Longer for less sensitive
email_unsubscribe = user.signed_id(
  expires_in: 30.days,
  purpose: :unsubscribe
)
```

### 4. Rotate Encryption Keys

```crystal
# Support key rotation
Grant::Encryption.configure do |config|
  config.primary_key = ENV["NEW_ENCRYPTION_KEY"]
  config.previous_keys = [ENV["OLD_ENCRYPTION_KEY"]]
end
```
