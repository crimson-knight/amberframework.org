---
title: "Grant ORM"
section: "guides/models"
order: 10
is_section: true
description: "The ActiveRecord-style ORM included in Amber V2 web applications"
---

# Grant ORM

> **Supported web path:** Amber CLI `2.0.4` includes Grant in every generated
> web application and pins the reviewed V2 commit. The Grant project keeps its
> own release lifecycle, so preserve the generated pin when following this beta.

Grant is an ActiveRecord-style ORM for Crystal that provides a familiar
interface for database operations. It is the default model layer for the Amber
V2 web template, with SQLite as the zero-setup database.

## Where the examples go

- Model declarations, columns, associations, validations, and callbacks belong
  in one class file under `src/models/`, such as `src/models/user.cr`.
- CRUD and query snippets run from the controller, job, service, or spec that
  owns the operation; they are expressions, not complete source files.
- Register database connections in a direct file under `config/`, such as
  `config/database.cr`, because the V2 entry point requires `config/*`.
- Run every command from the application root, beside `shard.yml`.

Blocks on this page use those destinations unless a closer label says
otherwise.

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

**File: `src/models/user.cr` — create this model class.**

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

**File: the controller, job, service, or spec that owns the user operation.**

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

**Files: declare relationships in the matching files under `src/models/`;
execute the usage examples from an application operation or spec.**

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

**File: `src/models/product.cr` — keep these validations inside `Product`.**

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

**File: `src/models/order.cr` — keep these callbacks and private methods inside
`Order`.**

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

**File: `config/database.cr` — create this direct config file so the generated
V2 entry point loads it through `require "../config/*"`.**

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
