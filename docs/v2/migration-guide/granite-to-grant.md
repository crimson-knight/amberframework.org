---
title: "Granite to Grant Migration"
section: "migration-guide"
order: 20
description: "Migrate from Granite ORM to Grant ORM"
---

# Migrating from Granite to Grant

> **Preview migration path:** Grant is not included in the Amber
> `2.0.0-beta.2` core web template. Confirm a compatible official Grant release
> and its current API before beginning this migration; do not substitute a
> personal fork as an application default.

This guide is retained as evaluation material for teams considering a future
Granite-to-Grant migration.

## Why Grant?

| Feature | Granite | Grant |
|---------|---------|-------|
| Associations | Limited (has_many only) | Full (belongs_to, has_many, has_one, polymorphic) |
| Validations | Granite validation API | Built-in and custom Grant validators |
| Callbacks | Before/after save | Full lifecycle (create, update, destroy) |
| Query Interface | Basic where/find | Chainable scopes, joins, includes |
| Transactions | Manual | Built-in with savepoints |
| Encryption | None | Attribute encryption |
| Secure Tokens | None | has_secure_token, signed_id |

## Coexistence Strategy

Grant and Granite can coexist during migration:

```yaml
# shard.yml
dependencies:
  granite:
    github: amberframework/granite
    version: ~> 0.6.0
  grant:
    github: amberframework/grant
    version: ~> 0.3.0
```

Migrate models incrementally, starting with new features.

## Basic Model Migration

### Column Definitions

**Granite:**
```crystal
class User < Granite::Base
  connection pg
  table users

  column id : Int64, primary: true
  column email : String
  column name : String?
  column admin : Bool = false
  column created_at : Time?
  column updated_at : Time?
end
```

**Grant:**
```crystal
class User < Grant::Base
  column id : Int64, primary: true
  column email : String
  column name : String?
  column admin : Bool = false

  timestamps  # Automatically handles created_at and updated_at
end
```

### Key Differences

1. **No `connection` declaration** - Grant uses a global connection pool
2. **No `table` declaration** - Inferred from class name (configurable)
3. **`timestamps` macro** - Replaces manual timestamp columns
4. **Nullable by default** - Use `Type?` for nullable columns

## Connection Configuration

**Granite:**
```crystal
Granite::Connections << Granite::Adapter::Pg.new(
  name: "pg",
  url: ENV["DATABASE_URL"]
)
```

**Grant:**
```crystal
Grant::Connections.add(
  "primary",
  ENV["DATABASE_URL"]
)

# Or configure via environment
# Grant auto-detects DATABASE_URL
```

## Associations Migration

### has_many

**Granite:**
```crystal
class User < Granite::Base
  has_many :posts

  # Manual setup often required
  def posts
    Post.all("WHERE user_id = ?", id)
  end
end
```

**Grant:**
```crystal
class User < Grant::Base
  has_many :posts  # Just works!

  # Additional options available
  has_many :published_posts, Post, -> { where(published: true) }
  has_many :comments, through: :posts
end
```

### belongs_to

**Granite:** (manual)
```crystal
class Post < Granite::Base
  column user_id : Int64?

  def user
    User.find(user_id) if user_id
  end
end
```

**Grant:**
```crystal
class Post < Grant::Base
  column user_id : Int64

  belongs_to :user
end

post = Post.find!(1)
post.user  # => User instance, lazy loaded
```

### has_one

**Granite:** (manual)
```crystal
class User < Granite::Base
  def profile
    Profile.first("WHERE user_id = ?", id)
  end
end
```

**Grant:**
```crystal
class User < Grant::Base
  has_one :profile
end

user.profile  # => Profile or nil
```

### Polymorphic Associations

**Granite:** Not supported

**Grant:**
```crystal
class Comment < Grant::Base
  column commentable_id : Int64
  column commentable_type : String

  belongs_to :commentable, polymorphic: true
end

class Post < Grant::Base
  has_many :comments, as: :commentable
end

class Photo < Grant::Base
  has_many :comments, as: :commentable
end
```

## Validations Migration

### Basic Validations

**Granite:**
```crystal
class User < Granite::Base
  validate :email, "can't be blank" do |user|
    !user.email.nil? && !user.email.not_nil!.empty?
  end
end
```

**Grant:**
```crystal
class User < Grant::Base
  validates :email, presence: true
  validates :email, format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, uniqueness: true
end
```

### Available Validators

| Granite | Grant |
|---------|-------|
| Manual blocks | `presence`, `absence`, `format`, `length`, `inclusion`, `exclusion`, `uniqueness`, `numericality`, `confirmation` |

### Custom Validations

**Granite:**
```crystal
class User < Granite::Base
  validate :custom_email_check do |user|
    # validation logic
  end
end
```

**Grant:**
```crystal
class User < Grant::Base
  validate :custom_email_check

  private def custom_email_check
    if email && !email.ends_with?("@company.com")
      errors.add(:email, "must be a company email")
    end
  end
end
```

## Callbacks Migration

**Granite:**
```crystal
class Post < Granite::Base
  before_save :set_slug

  def set_slug
    self.slug ||= title.downcase.gsub(" ", "-")
  end
end
```

**Grant:**
```crystal
class Post < Grant::Base
  before_save :set_slug
  before_create :set_published_at
  after_create :notify_subscribers
  after_destroy :cleanup_assets

  private def set_slug
    self.slug ||= title.downcase.gsub(" ", "-")
  end
end
```

### Available Callbacks

| Lifecycle | Granite | Grant |
|-----------|---------|-------|
| Create | before_save, after_save | before_create, after_create, around_create |
| Update | before_save, after_save | before_update, after_update, around_update |
| Save | before_save, after_save | before_save, after_save, around_save |
| Destroy | before_destroy, after_destroy | before_destroy, after_destroy, around_destroy |
| Validation | - | before_validation, after_validation |

## Query Interface Migration

### Finding Records

**Granite:**
```crystal
User.find(1)           # May return nil
User.find!(1)          # Raises on not found
User.first             # First record
User.all               # All records
```

**Grant:**
```crystal
User.find(1)           # Returns User?
User.find!(1)          # Raises RecordNotFound
User.first             # First record
User.last              # Last record
User.all               # ActiveRecord::Relation
```

### Where Clauses

**Granite:**
```crystal
User.all("WHERE email = ? AND active = ?", ["user@example.com", true])
```

**Grant:**
```crystal
User.where(email: "user@example.com", active: true)
User.where("email = ? AND active = ?", "user@example.com", true)
User.where(email: "user@example.com").where(active: true)  # Chainable
```

### Ordering and Limiting

**Granite:**
```crystal
User.all("ORDER BY created_at DESC LIMIT 10")
```

**Grant:**
```crystal
User.order(created_at: :desc).limit(10)
User.order(:name).first(5)
User.recent.limit(10)  # Using scope
```

### Scopes

**Granite:** Not supported natively

**Grant:**
```crystal
class Post < Grant::Base
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_author, ->(user : User) { where(user_id: user.id) }
end

Post.published.recent.limit(10)
Post.by_author(current_user).published
```

## CRUD Operations

### Create

**Granite:**
```crystal
user = User.new
user.email = "user@example.com"
user.save

# Or
User.create!(email: "user@example.com")
```

**Grant:**
```crystal
user = User.new(email: "user@example.com")
user.save

# Or
User.create!(email: "user@example.com")

# Build without save
user = User.build(email: "user@example.com")
```

### Update

**Granite:**
```crystal
user.email = "new@example.com"
user.save
```

**Grant:**
```crystal
user.email = "new@example.com"
user.save

# Or
user.update!(email: "new@example.com")

# Update multiple
User.where(role: "guest").update_all(role: "member")
```

### Destroy

**Granite:**
```crystal
user.destroy
```

**Grant:**
```crystal
user.destroy
user.destroy!  # Raises on failure

# Destroy multiple
User.where(inactive: true).destroy_all
```

## Transactions

**Granite:** (manual)
```crystal
Granite::Connections["pg"].transaction do |tx|
  user.save
  profile.save
end
```

**Grant:**
```crystal
Grant::Base.transaction do
  user.save!
  profile.save!
  # Automatically rolls back on exception
end

# Nested transactions with savepoints
Grant::Base.transaction do
  user.save!

  Grant::Base.transaction(requires_new: true) do
    # Savepoint - can fail without rolling back outer transaction
    risky_operation.save!
  rescue
    # Inner transaction rolled back, outer continues
  end
end
```

## Error Handling

**Granite:**
```crystal
unless user.save
  user.errors.each do |error|
    puts error
  end
end
```

**Grant:**
```crystal
unless user.save
  user.errors.full_messages.each do |message|
    puts message
  end

  # Access specific field errors
  user.errors[:email].each do |error|
    puts "Email #{error}"
  end
end

# Or use bang methods
begin
  user.save!
rescue Grant::RecordInvalid => e
  puts e.record.errors.full_messages
end
```

## Migration Checklist

### Per Model

- [ ] Update class inheritance (`Granite::Base` → `Grant::Base`)
- [ ] Remove `connection` and `table` declarations
- [ ] Replace manual timestamp columns with `timestamps`
- [ ] Convert associations to Grant syntax
- [ ] Migrate validations to declarative style
- [ ] Update callbacks to new lifecycle hooks
- [ ] Convert raw SQL queries to chainable interface
- [ ] Add scopes for common queries
- [ ] Update error handling code
- [ ] Run tests

### Application-Wide

- [ ] Update connection configuration
- [ ] Review transaction usage
- [ ] Update specs to use Grant factories/fixtures
- [ ] Run full test suite
- [ ] Performance test critical queries

## Running Both ORMs

During migration, you may need models to interact:

```crystal
# Grant model referencing Granite model
class Comment < Grant::Base
  column post_id : Int64

  def post
    # Manually fetch Granite model
    Post.find(post_id)
  end
end

# Or create a thin Grant wrapper
class PostGrant < Grant::Base
  self.table_name = "posts"

  column id : Int64, primary: true
  column title : String
  # ... mirror Granite columns
end
```

## Troubleshooting

### "undefined method" errors

Grant uses different method names. Common changes:
- `all("WHERE ...")` → `where(...)`
- `first("WHERE ...")` → `find_by(...)`
- Manual association methods → `has_many`/`belongs_to`

### Validation errors

Grant validations are more strict:
```crystal
# May need to handle nil differently
validates :email, presence: true  # Fails on nil
validates :name, presence: true, allow_nil: true  # Passes on nil
```

### Association loading

Grant associations are lazy-loaded by default:
```crystal
# N+1 query issue
users.each { |u| puts u.posts.size }

# Use eager loading
users = User.includes(:posts)
users.each { |u| puts u.posts.size }  # No N+1
```
