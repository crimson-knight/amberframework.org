---
title: "Grant ORM"
section: "guides/models"
order: 10
is_section: true
description: "Preview ActiveRecord-style ORM material for Amber V2 evaluators"
---

# Grant ORM

> **Preview ecosystem guide:** Grant is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

Grant is an ActiveRecord-style ORM for Crystal that provides a familiar
interface for database operations. It is being evaluated as part of the wider
V2 ecosystem, but the core beta web template does not install it or select a
default ORM.

## Why Grant?

Grant aims for feature parity with Rails 8+ ActiveRecord while leveraging Crystal's compile-time type safety:

- **Familiar API**: If you know ActiveRecord, you know Grant
- **Type Safety**: Compile-time checking eliminates many runtime errors
- **Zero-cost Abstractions**: Performance comparable to hand-written SQL
- **Fiber-based Concurrency**: Native async support without callback complexity
- **Horizontal Sharding**: Built-in support for distributed databases

## Feature Overview

| Category | Features |
|----------|----------|
| **Core** | Models, columns, timestamps, CRUD operations |
| **Associations** | belongs_to, has_one, has_many, has_many :through, polymorphic |
| **Validations** | All standard validators, custom validations, conditional validation |
| **Callbacks** | Full lifecycle hooks including transaction callbacks |
| **Queries** | Fluent interface, scopes, complex conditions, eager loading |
| **Security** | Encrypted attributes, secure tokens, signed IDs |
| **Advanced** | Enums, serialization, dirty tracking, optimistic/pessimistic locking |

## Quick Start

### Define a Model

```crystal
class User < Grant::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column name : String
  column role : String = "user"
  column active : Bool = true

  has_many :posts
  has_one :profile

  validates_presence_of :email, :name
  validates_email :email
  validate_uniqueness :email

  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: "admin") }

  timestamps
end
```

### Basic Operations

```crystal
# Create
user = User.create!(email: "alice@example.com", name: "Alice")

# Read
user = User.find(1)
users = User.where(active: true).order(:name).limit(10)

# Update
user.update!(name: "Alice Smith")

# Delete
user.destroy!
```

### Associations

```crystal
# Define relationships
class Post < Grant::Base
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :taggings, as: :taggable
  has_many :tags, through: :taggings
end

# Use associations
user = User.find(1)
user.posts.each do |post|
  puts post.title
  puts post.comments.count
end

# Eager loading (N+1 prevention)
posts = Post.includes(:user, :comments).where(published: true)
```

### Validations

```crystal
class Product < Grant::Base
  column price : Float64
  column stock : Int32
  column sku : String

  validates_presence_of :sku, :price
  validates_numericality_of :price, greater_than: 0
  validates_format_of :sku, with: /\A[A-Z]{2}-\d{4}\z/
  validate_uniqueness :sku

  validate "price must be reasonable" do |product|
    product.price < 1_000_000
  end
end
```

### Callbacks

```crystal
class Order < Grant::Base
  before_create :generate_order_number
  before_save :calculate_total
  after_create :send_confirmation
  after_commit :update_inventory, on: :create

  private def generate_order_number
    self.order_number = "ORD-#{Time.utc.to_unix}-#{SecureRandom.hex(4)}"
  end

  private def calculate_total
    self.total = line_items.sum(&.price)
  end
end
```

## Database Support

Grant supports multiple databases:

- **PostgreSQL** (recommended): Full feature support including arrays, JSONB, UUID
- **MySQL**: JSON columns, full-text search
- **SQLite**: Great for development and testing

```crystal
# config/database.cr
Grant::Connections << Grant::Adapter::Pg.new(
  name: "primary",
  url: ENV["DATABASE_URL"]
)
```

## Getting Started

1. [Models and Columns](basics/) - Define your data structure
2. [Associations](associations/) - Connect related models
3. [Validations](validations/) - Ensure data integrity
4. [Callbacks](callbacks/) - Hook into the lifecycle
5. [Querying](queries/) - Find and filter data
6. [Transactions](transactions/) - Maintain data consistency
7. [Security](security/) - Encryption, tokens, and secure IDs

## Migration from Granite

If you're migrating from Granite (Amber 1.x's default ORM), Grant provides a similar API with enhanced features. See the [Migration Guide](../../../migration-guide/granite-to-grant/) for details.
