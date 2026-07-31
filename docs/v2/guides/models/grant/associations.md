---
title: "Associations"
section: "guides/models/grant"
order: 20
description: "Defining relationships between models in Grant ORM"
---

# Associations

> **Preview ecosystem guide:** Grant is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Grant provides powerful association methods to define relationships between models.

## belongs_to

Creates a one-to-one connection where the declaring model holds the foreign key.

```crystal
class Post < Grant::Base
  belongs_to :user

  column id : Int64, primary: true
  column title : String
  column user_id : Int64  # Foreign key
end

# Usage
post = Post.find(1)
author = post.user  # Fetches associated user
```

### belongs_to Options

```crystal
class Post < Grant::Base
  # Custom foreign key
  belongs_to user : User, foreign_key: author_id : Int64

  # Optional association (allows NULL)
  belongs_to :category, optional: true

  # With counter cache
  belongs_to :blog, counter_cache: true

  # Touch parent on save
  belongs_to :article, touch: true

  # Custom class name
  belongs_to :author, class_name: User
end
```

## has_one

Creates a one-to-one connection where the other model holds the foreign key.

```crystal
class User < Grant::Base
  has_one :profile

  column id : Int64, primary: true
  column email : String
end

class Profile < Grant::Base
  belongs_to :user

  column id : Int64, primary: true
  column bio : String
  column user_id : Int64
end

# Usage
user = User.find(1)
profile = user.profile
user.profile = Profile.new(bio: "My bio")
```

## has_many

Creates a one-to-many connection.

```crystal
class User < Grant::Base
  has_many :posts
  has_many :comments

  # With custom foreign key
  has_many :articles, class_name: Post, foreign_key: :author_id

  column id : Int64, primary: true
end

# Usage
user = User.find(1)
user.posts.each do |post|
  puts post.title
end

# Add new post
user.posts << Post.new(title: "New Post")
```

## has_many :through

Creates a many-to-many connection through a join model.

```crystal
class User < Grant::Base
  has_many :participations
  has_many :rooms, through: :participations

  column id : Int64, primary: true
  column name : String
end

class Participation < Grant::Base
  belongs_to :user
  belongs_to :room

  column id : Int64, primary: true
  column joined_at : Time
  column role : String  # Additional attributes
end

class Room < Grant::Base
  has_many :participations
  has_many :users, through: :participations

  column id : Int64, primary: true
  column name : String
end

# Usage
user = User.find(1)
user.rooms.each { |room| puts room.name }

# Create association
Participation.create!(user: user, room: room, role: "member")
```

## Polymorphic Associations

Allow a model to belong to multiple other models through a single association.

```crystal
class Comment < Grant::Base
  belongs_to :commentable, polymorphic: true

  column id : Int64, primary: true
  column content : String
  column commentable_id : Int64?
  column commentable_type : String?
end

class Post < Grant::Base
  has_many :comments, as: :commentable
end

class Photo < Grant::Base
  has_many :comments, as: :commentable
end

# Usage
post = Post.create!(title: "My Post")
photo = Photo.create!(url: "image.jpg")

comment1 = Comment.create!(content: "Great post!", commentable: post)
comment2 = Comment.create!(content: "Nice photo!", commentable: photo)

# Retrieve polymorphic association
comment = Comment.find(1)
if comment.commentable.is_a?(Post)
  puts "Comment on post: #{comment.commentable.title}"
end
```

## Self-Referential Associations

Models that have associations to themselves.

```crystal
class Employee < Grant::Base
  belongs_to :manager, class_name: Employee, optional: true
  has_many :subordinates, class_name: Employee, foreign_key: :manager_id

  column id : Int64, primary: true
  column name : String
  column manager_id : Int64?
end

# Usage
ceo = Employee.create!(name: "CEO")
manager = Employee.create!(name: "Manager", manager: ceo)
employee = Employee.create!(name: "Employee", manager: manager)

ceo.subordinates      # => [manager]
manager.subordinates  # => [employee]
employee.manager      # => manager
```

## Association Options

### dependent

Controls what happens to associated records when parent is destroyed.

```crystal
class Author < Grant::Base
  # Destroys all posts when author is destroyed
  has_many :posts, dependent: :destroy

  # Sets category_id to NULL on products
  has_many :products, dependent: :nullify

  # Prevents deletion if players exist
  has_many :players, dependent: :restrict
end
```

### counter_cache

Maintains count of associated records on parent model.

```crystal
class Blog < Grant::Base
  column posts_count : Int32 = 0
  has_many :posts
end

class Post < Grant::Base
  belongs_to :blog, counter_cache: true
end

# Usage
blog = Blog.create!(title: "My Blog")
Post.create!(title: "First Post", blog: blog)
blog.reload.posts_count  # => 1
```

### touch

Updates parent's `updated_at` when child is saved.

```crystal
class Comment < Grant::Base
  belongs_to :post, touch: true

  # Touch specific column
  belongs_to :article, touch: :last_activity_at
end

# Updates post.updated_at whenever comment changes
comment.update!(content: "Updated")
```

### autosave

Automatically saves associated records with parent.

```crystal
class Order < Grant::Base
  has_many :line_items, autosave: true
  has_one :invoice, autosave: true
end

order = Order.new
order.line_items << LineItem.new(product: "Widget", qty: 2)
order.invoice = Invoice.new(total: 100)
order.save!  # Saves everything in transaction
```

## Nested Attributes

Accept nested attributes for associated records.

```crystal
class Order < Grant::Base
  has_many :line_items

  accepts_nested_attributes_for line_items : LineItem,
    allow_destroy: true,
    reject_if: ->(attrs : Hash) { attrs["quantity"]?.try(&.to_i) == 0 },
    limit: 50
end

# Create order with line items
order = Order.create!(
  customer_id: 1,
  line_items_attributes: [
    {product_id: 1, quantity: 2},
    {product_id: 3, quantity: 1}
  ]
)
```

## Eager Loading (N+1 Prevention)

```crystal
# Bad: N+1 queries
posts = Post.all
posts.each do |post|
  puts post.author.name  # Query for each post
end

# Good: Eager loading
posts = Post.includes(:author)
posts.each do |post|
  puts post.author.name  # No additional queries
end

# Multiple associations
posts = Post.includes(:author, :comments)

# Nested associations
users = User.includes(posts: [:comments, :tags])
```

## Validating Associations

```crystal
class Order < Grant::Base
  has_many :line_items
  belongs_to :customer

  validates_associated :line_items

  validate :must_have_items

  private def must_have_items
    if line_items.empty?
      errors.add(:line_items, "must have at least one item")
    end
  end
end
```

## Best Practices

### 1. Index Foreign Keys

```sql
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_blog_id ON posts(blog_id);
```

### 2. Use dependent Wisely

- `:destroy` - When child records should be deleted
- `:nullify` - When child records can exist independently
- `:restrict` - When deletion should be prevented

### 3. Document Complex Associations

```crystal
# Represents many-to-many between users and projects
# through team memberships with role attribute
class TeamMembership < Grant::Base
  belongs_to :user
  belongs_to :project

  column role : String  # "owner", "member", "viewer"
end
```
