---
title: "Validations"
section: "guides/models/grant"
order: 30
description: "Data validation and error handling in Grant ORM"
---

# Validations

Grant provides a robust validation system that ensures data integrity before persisting to the database.

## Basic Validation

```crystal
class User < Grant::Base
  column email : String
  column age : Int32

  validates_email :email
  validates_numericality_of :age, greater_than: 0
end

user = User.new(email: "invalid", age: -5)
user.valid?  # => false
user.errors  # => Array of validation errors
user.save    # => false (won't save invalid records)
user.save!   # => raises Grant::RecordInvalid
```

## Built-in Validators

### Presence and Absence

```crystal
class Product < Grant::Base
  column name : String
  column internal_notes : String?

  validates_presence_of :name
  validate_not_blank :name

  validates_absence_of :internal_notes  # Must be nil/blank
end
```

### Numericality

```crystal
class Order < Grant::Base
  column total : Float64
  column quantity : Int32
  column discount : Float64

  validates_numericality_of :total, greater_than: 0
  validates_numericality_of :quantity,
    only_integer: true,
    greater_than: 0
  validates_numericality_of :discount,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
end
```

**Options:**
- `greater_than`, `greater_than_or_equal_to`
- `less_than`, `less_than_or_equal_to`
- `equal_to`, `other_than`
- `odd: true`, `even: true`
- `only_integer: true`
- `in: range`
- `allow_nil: true`, `allow_blank: true`

### Format

```crystal
class User < Grant::Base
  column username : String
  column phone : String

  validates_format_of :username, with: /\A[a-zA-Z0-9_]+\z/
  validates_format_of :phone, with: /\A\d{3}-\d{3}-\d{4}\z/
  validates_format_of :username, without: /\A(admin|root)\z/,
    message: "is reserved"
end
```

### Length/Size

```crystal
class Article < Grant::Base
  column title : String
  column body : String
  column tags : Array(String)

  validates_length_of :title, minimum: 5, maximum: 100
  validates_length_of :body, minimum: 100
  validates_size_of :tags, maximum: 10
  validates_length_of :slug, is: 8  # Exactly 8
end
```

### Email and URL

```crystal
class Contact < Grant::Base
  column email : String
  column website : String?

  validates_email :email
  validates_url :website, allow_blank: true
end
```

### Confirmation

```crystal
class Account < Grant::Base
  column email : String
  column password : String

  validates_confirmation_of :email
  validates_confirmation_of :password
end

# Usage requires confirmation fields
account = Account.new(
  email: "user@example.com",
  password: "secret123"
)
account.email_confirmation = "user@example.com"
account.password_confirmation = "secret123"
account.valid?  # => true
```

### Inclusion and Exclusion

```crystal
class Subscription < Grant::Base
  column plan : String
  column username : String

  validates_inclusion_of :plan,
    in: ["free", "basic", "premium", "enterprise"]

  validates_exclusion_of :username,
    in: ["admin", "root", "system"],
    message: "is reserved"
end
```

### Uniqueness

```crystal
class User < Grant::Base
  column email : String
  column employee_id : String
  column company_id : Int64

  validate_uniqueness :email

  # Scoped uniqueness (unique within scope)
  validate_uniqueness :employee_id, scope: :company_id
end
```

## Custom Validations

### Block Syntax

```crystal
class Post < Grant::Base
  column title : String
  column content : String

  validate :title, "can't be blank" do |post|
    !post.title.to_s.blank?
  end

  validate :content, "must be at least 10 characters" do |post|
    post.content.size >= 10
  end
end
```

### Method Reference

```crystal
class Product < Grant::Base
  column price : Float64
  column sale_price : Float64?
  column on_sale : Bool

  validate :valid_sale_price

  private def valid_sale_price
    return true unless on_sale && sale_price

    if sale_price.not_nil! >= price
      errors.add(:sale_price, "must be less than regular price")
    end
  end
end
```

### Model-level Validation

```crystal
class Order < Grant::Base
  validate "total must equal sum of line items" do |order|
    calculated_total = order.line_items.sum(&.total_price)
    (order.total_amount - calculated_total).abs < 0.01
  end
end
```

## Conditional Validations

### Using Symbols

```crystal
class Post < Grant::Base
  column title : String
  column content : String
  column published : Bool

  validates_length_of :title, minimum: 10, if: :published?
  validates_presence_of :content, unless: :draft?

  def published?
    published == true
  end

  def draft?
    !published
  end
end
```

### Using Procs

```crystal
class Order < Grant::Base
  column payment_method : String
  column credit_card : String?

  validates_presence_of :credit_card,
    if: ->(order : Order) { order.payment_method == "credit" }
end
```

## Validation Contexts

```crystal
class User < Grant::Base
  column email : String
  column password : String

  # Only on create
  validates_presence_of :password, on: :create

  # Only on update
  validates_confirmation_of :password, on: :update

  # Custom context
  validate :email, "must be corporate email", on: :corporate do |user|
    user.email.ends_with?("@company.com")
  end
end

# Usage with context
user.valid?(:corporate)
user.save(context: :corporate)
```

## Working with Errors

```crystal
user = User.new(email: "invalid", age: 10)
user.valid?  # => false

# Get all errors
user.errors  # => Array(Grant::Error)

# Get errors for specific field
email_errors = user.errors.select { |e| e.field == :email }

# Get error messages
user.errors.map(&.message)
# => ["is not a valid email", "must be at least 18"]

# Full error messages
user.errors.map { |e| "#{e.field} #{e.message}" }
# => ["email is not a valid email", "age must be at least 18"]

# Add custom errors
user.errors.add(:base, "Something went wrong")
```

## Custom Error Messages

```crystal
class User < Grant::Base
  validates_numericality_of :age,
    greater_than_or_equal_to: 18,
    message: "You must be at least 18 years old"

  validates_format_of :email,
    with: /@company\.com\z/,
    message: "must be a company email address"
end
```

## Validation Callbacks

```crystal
class User < Grant::Base
  before_validation :normalize_email
  after_validation :set_defaults

  private def normalize_email
    self.email = email.downcase.strip if email
  end

  private def set_defaults
    self.role ||= "user" if errors.empty?
  end
end
```

## Skipping Validations

```crystal
# Skip validations (use carefully!)
user.save(validate: false)

# Bulk operations skip validations
User.update_all(active: false)
```

## Best Practices

### 1. Layer Validations

```crystal
class CreditCard < Grant::Base
  # Format validation
  validates_format_of :number, with: /\A\d{16}\z/

  # Business logic validation
  validate :number, "must pass Luhn check" do |card|
    LuhnValidator.valid?(card.number)
  end

  # Database constraint (in migration)
  # ADD CONSTRAINT valid_card_number CHECK (char_length(number) = 16)
end
```

### 2. Add Database Constraints

```crystal
# Model validation
validate_uniqueness :email

# Also add database constraint
# CREATE UNIQUE INDEX users_email_unique ON users(email);
```

### 3. Order Validations by Cost

```crystal
class Product < Grant::Base
  # Fast validations first
  validates_presence_of :name
  validates_length_of :name, in: 1..100

  # Database queries later
  validate_uniqueness :sku

  # Expensive operations last
  validate :image, "must be valid" do |product|
    ImageValidator.valid?(product.image_data) if product.image_data
  end
end
```
