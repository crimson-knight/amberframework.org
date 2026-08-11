---
title: "Querying"
section: "guides/models/grant"
order: 50
description: "Finding and filtering data with Grant's fluent query interface"
---

# Querying

> **Preview ecosystem guide:** Grant is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

Grant provides a fluent, chainable query API that generates efficient SQL while maintaining type safety.

## Basic Querying

```crystal
# Find all active users
users = User.where(active: true)

# Chain multiple conditions (AND)
posts = Post.where(published: true, featured: true)
            .where(author_id: current_user.id)

# Find with multiple fields
post = Post.find_by(slug: "my-post", published: true)
```

### Query Execution

Queries are lazy - they don't execute until you call a terminal method:

```crystal
# Building query (not executed)
query = User.where(active: true).order(:name)

# Execution happens here
users = query.select     # Returns array of User
first = query.first      # Returns User?
count = query.count      # Returns Int32
exists = query.exists?   # Returns Bool
```

## Where Conditions

### Basic WHERE

```crystal
# Equality
User.where(status: "active")
User.where(age: 25)

# Multiple conditions (AND)
User.where(status: "active", verified: true)
```

### Comparison Operators

```crystal
Post.where(:views, :gt, 100)        # Greater than
Post.where(:price, :lteq, 50.0)     # Less than or equal
Post.where(:created_at, :gt, 7.days.ago)

# Available operators
Post.where(:field, :eq, value)      # =
Post.where(:field, :neq, value)     # !=
Post.where(:field, :gt, value)      # >
Post.where(:field, :lt, value)      # <
Post.where(:field, :gteq, value)    # >=
Post.where(:field, :lteq, value)    # <=
Post.where(:field, :in, array)      # IN
Post.where(:field, :nin, array)     # NOT IN
Post.where(:field, :like, pattern)  # LIKE
```

### WhereChain Methods

```crystal
# Pattern matching
User.where.like(:email, "%@gmail.com")
User.where.not_like(:name, "test%")

# Comparisons
User.where.gt(:age, 18)
User.where.lt(:age, 65)
User.where.gteq(:score, 80)
User.where.lteq(:price, 100)

# NULL checks
User.where.is_null(:deleted_at)
User.where.is_not_null(:verified_at)

# Ranges
User.where.between(:age, 25..35)
Product.where.between(:price, 10.0..50.0)

# NOT IN
User.where.not_in(:id, [1, 2, 3])
```

### Raw SQL Conditions

```crystal
# With placeholders
Post.where("LOWER(title) LIKE ?", ["%crystal%"])
User.where("age * 2 > ?", [50])

# PostgreSQL specific
Post.where("tags @> ARRAY[?]::varchar[]", ["ruby"])
Post.where("metadata->>'key' = $", ["value"])
```

## OR and NOT Conditions

### OR Groups

```crystal
# Simple OR
User.where(role: "admin").or { |q| q.where(role: "moderator") }
# SQL: WHERE role = 'admin' OR role = 'moderator'

# Complex OR
User.where(verified: true)
    .or do |q|
      q.where(role: "admin")
       .where.gt(:level, 10)
    end
# SQL: WHERE verified = true OR (role = 'admin' AND level > 10)
```

### NOT Groups

```crystal
# Simple NOT
User.not { |q| q.where(status: "banned") }

# Complex NOT
User.not do |q|
  q.where(active: false)
   .where.is_null(:email_verified_at)
end
# SQL: WHERE NOT (active = false AND email_verified_at IS NULL)
```

## Ordering and Limiting

```crystal
# Single field
User.order(:name)              # ASC by default
User.order(created_at: :desc)  # Explicit direction

# Multiple fields
Post.order(featured: :desc, created_at: :desc)

# Limit and offset
Post.limit(10)
Post.offset(20).limit(10)  # Pagination

# First/Last
User.first          # Single record
User.first(5)       # First 5 records
User.last(10)       # Last 10 records

# Distinct
User.distinct.select(:country)
```

## Scopes

### Defining Scopes

```crystal
class Post < Grant::Base
  # Simple scopes
  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Parameterized scopes
  scope :by_author, ->(author_id : Int32) { where(author_id: author_id) }
  scope :tagged_with, ->(tag : String) { where("tags @> ARRAY[?]", [tag]) }
  scope :older_than, ->(date : Time) { where.lt(:created_at, date) }

  # Complex scopes
  scope :popular, -> {
    where.gt(:views, 1000)
         .where.gt(:likes, 100)
         .order(views: :desc)
  }
end

# Using scopes
Post.published.recent.limit(10)
Post.by_author(current_user.id).featured
```

### Default Scopes

```crystal
class Product < Grant::Base
  # Applied to all queries automatically
  default_scope { where(active: true).where.is_null(:deleted_at) }

  # Bypass default scope
  scope :all_including_deleted, -> { unscoped }
end

Product.all              # Includes default scope
Product.unscoped.all     # Bypasses default scope
```

## Joins and Eager Loading

### Joins

```crystal
# Join with association
Post.joins(:author)
    .where("users.active = ?", [true])

# Left joins (include records without association)
User.left_joins(:posts)
    .where("posts.id IS NULL")  # Users without posts
```

### Eager Loading

```crystal
# Preload associations
posts = Post.includes(:author, :comments)
posts.each do |post|
  puts post.author.name        # No additional query
  puts post.comments.size      # No additional query
end

# Nested includes
User.includes(posts: [:comments, :tags])
```

## Aggregations

```crystal
# Count
User.count
User.where(active: true).count
User.distinct.count(:country)

# Sum, Average, Min, Max
Order.sum(:total)
Product.average(:price)
Product.minimum(:price)
Product.maximum(:stock)

# With grouping
Order.group_by(:customer_id).sum(:total)
Review.group_by(:product_id).average(:rating)
```

## Batch Processing

```crystal
# Bad: Loads everything at once
User.all.each { |user| user.process! }

# Good: Process in batches
User.find_in_batches(batch_size: 1000) do |users|
  users.each(&.process!)
end
```

## Pluck for Values

```crystal
# Bad: Instantiate models
emails = User.where(active: true).map(&.email)

# Good: Direct database values
emails = User.where(active: true).pluck(:email)
```

## Complex Query Example

```crystal
def search_products(params)
  query = Product.where(active: true)

  # Text search
  if term = params["q"]?
    query = query.where.like(:name, "%#{term}%")
                 .or { |q| q.where.like(:description, "%#{term}%") }
  end

  # Price range
  if min_price = params["min_price"]?
    query = query.where.gteq(:price, min_price.to_f)
  end
  if max_price = params["max_price"]?
    query = query.where.lteq(:price, max_price.to_f)
  end

  # Categories
  if categories = params["categories"]?
    query = query.where.in(:category_id, categories.split(","))
  end

  # In stock only
  if params["in_stock"]?
    query = query.where.gt(:stock, 0)
  end

  # Sorting
  case params["sort"]?
  when "price_asc"
    query = query.order(:price)
  when "price_desc"
    query = query.order(price: :desc)
  when "newest"
    query = query.order(created_at: :desc)
  else
    query = query.order(:name)
  end

  query.limit(params.fetch("limit", "20").to_i)
end
```

## Best Practices

### 1. Use Indexes

```crystal
# Ensure indexed columns in WHERE
User.where(email: "user@example.com")  # email should be indexed
```

### 2. Select Only Needed Columns

```crystal
# Bad: Loads all columns
users = User.where(active: true)

# Good: Load only required columns
users = User.where(active: true).select(:id, :name, :email)
```

### 3. Avoid N+1 Queries

```crystal
# Bad: N+1 queries
posts = Post.all
posts.each { |post| puts post.author.name }

# Good: Eager loading
posts = Post.includes(:author)
posts.each { |post| puts post.author.name }
```
