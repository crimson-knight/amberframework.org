---
title: "Callbacks"
section: "guides/models/grant"
order: 40
description: "Lifecycle hooks and callback methods in Grant ORM"
---

# Callbacks

Callbacks are methods that get called at certain moments of an object's lifecycle. They allow you to trigger logic before or after alterations to your model's state.

## Available Callbacks

### Create Callbacks

```crystal
class User < Grant::Base
  before_validation :set_defaults           # 1. First callback
  # validations run here                    # 2. Validations
  after_validation :process_validated_data  # 3. After validation
  before_save :before_save_tasks           # 4. Before save (create or update)
  before_create :before_create_tasks       # 5. Before create specifically
  # INSERT happens here                     # 6. Database insert
  after_create :after_create_tasks         # 7. After create
  after_save :after_save_tasks            # 8. After save (create or update)
  after_commit :after_commit_tasks        # 9. After transaction commits
end
```

### Update Callbacks

```crystal
class Product < Grant::Base
  before_validation :normalize_data         # 1. First callback
  # validations run here                    # 2. Validations
  after_validation :process_changes        # 3. After validation
  before_save :before_save_tasks          # 4. Before save
  before_update :before_update_tasks      # 5. Before update specifically
  # UPDATE happens here                    # 6. Database update
  after_update :after_update_tasks        # 7. After update
  after_save :after_save_tasks           # 8. After save
  after_commit :after_commit_tasks       # 9. After transaction commits
end
```

### Destroy Callbacks

```crystal
class Comment < Grant::Base
  before_destroy :cleanup_associations     # 1. Before destroy
  # DELETE happens here                    # 2. Database delete
  after_destroy :log_deletion             # 3. After destroy
  after_commit :notify_deletion          # 4. After transaction commits
end
```

## Callback Registration

### Method Symbols

```crystal
class Article < Grant::Base
  before_save :sanitize_content
  after_create :publish_to_feed

  private def sanitize_content
    self.content = Sanitizer.clean(content)
  end

  private def publish_to_feed
    FeedService.publish(self) if published?
  end
end
```

### Blocks

```crystal
class Order < Grant::Base
  before_save do
    self.total = calculate_total
  end

  after_create do
    OrderMailer.confirmation(self).deliver_later
  end
end
```

### Conditional Callbacks

```crystal
class Post < Grant::Base
  # With symbol conditions
  before_save :update_slug, if: :title_changed?
  after_create :notify_subscribers, if: :published?

  # With proc conditions
  before_destroy :archive_content,
    if: ->(post : Post) { post.views > 1000 }

  # Multiple conditions
  after_save :clear_cache,
    if: :published?,
    unless: :draft?
end
```

## Common Callback Patterns

### Data Normalization

```crystal
class User < Grant::Base
  before_validation :normalize_fields

  column email : String
  column phone : String?
  column name : String

  private def normalize_fields
    self.email = email.downcase.strip
    self.phone = phone.try(&.gsub(/\D/, ""))
    self.name = name.split.map(&.capitalize).join(" ")
  end
end
```

### Setting Defaults

```crystal
class Document < Grant::Base
  before_create :set_defaults

  column uuid : String
  column version : Int32
  column status : String

  private def set_defaults
    self.uuid ||= UUID.random.to_s
    self.version ||= 1
    self.status ||= "draft"
  end
end
```

### Generating Tokens

```crystal
class Session < Grant::Base
  before_create :generate_token

  column token : String
  column expires_at : Time

  private def generate_token
    loop do
      self.token = Random::Secure.hex(32)
      break unless Session.exists?(token: token)
    end
    self.expires_at = 24.hours.from_now
  end
end
```

### Slug Generation

```crystal
class Article < Grant::Base
  before_save :generate_slug

  column title : String
  column slug : String

  private def generate_slug
    return unless title_changed?

    base_slug = title.downcase.gsub(/[^a-z0-9]+/, "-")
    self.slug = base_slug

    counter = 1
    while Article.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
```

### Audit Trails

```crystal
class AuditableModel < Grant::Base
  after_create :log_create
  after_update :log_update
  after_destroy :log_destroy

  private def log_create
    AuditLog.create!(
      model: self.class.name,
      record_id: id,
      action: "create",
      user_id: Current.user_id,
      changes: attributes.to_json
    )
  end

  private def log_update
    return unless changes.any?
    AuditLog.create!(
      model: self.class.name,
      record_id: id,
      action: "update",
      user_id: Current.user_id,
      changes: changes.to_json
    )
  end
end
```

### Cache Management

```crystal
class Product < Grant::Base
  after_save :clear_cache
  after_destroy :clear_cache

  private def clear_cache
    Cache.delete("product:#{id}")
    Cache.delete("category:#{category_id}:products")
  end
end
```

## Halting Execution

### Throwing :abort

```crystal
class Order < Grant::Base
  before_save :check_inventory

  private def check_inventory
    if total_items > available_stock
      errors.add(:items, "Insufficient inventory")
      throw :abort  # Halts execution
    end
  end
end
```

### Preventing Destruction

```crystal
class User < Grant::Base
  before_destroy :prevent_admin_deletion

  private def prevent_admin_deletion
    if admin? && User.where(admin: true).count == 1
      errors.add(:base, "Cannot delete the last admin")
      throw :abort
    end
  end
end
```

## Transaction Callbacks

### after_commit

Runs after the database transaction successfully commits:

```crystal
class Order < Grant::Base
  after_commit :send_confirmation, on: :create
  after_commit :update_inventory, on: :update

  private def send_confirmation
    # Safe to send email - transaction committed
    OrderMailer.confirmation(self).deliver_later
  end

  private def update_inventory
    # Safe to call external services
    InventoryService.sync(self)
  end
end
```

### after_rollback

Runs if the database transaction is rolled back:

```crystal
class Payment < Grant::Base
  after_rollback :log_failure

  private def log_failure
    Log.error { "Payment #{id} failed: #{errors.full_messages}" }
  end
end
```

## Performance Considerations

### Keep Callbacks Fast

```crystal
class Post < Grant::Base
  # Bad: Synchronous external call
  after_create :notify_external_service

  private def notify_external_service
    HTTPClient.post("https://api.example.com/webhook", body: to_json)
  end

  # Good: Queue for background processing
  after_create :queue_notification

  private def queue_notification
    NotificationJob.perform_later(self.id)
  end
end
```

### Use Conditional Callbacks

```crystal
class User < Grant::Base
  # Only run expensive callbacks when necessary
  after_save :sync_to_crm, if: :crm_fields_changed?

  private def crm_fields_changed?
    (changes.keys & ["email", "name", "company"]).any?
  end
end
```

## Skipping Callbacks

```crystal
# Skip callbacks when needed
user.save(skip_callbacks: true)

# Bulk operations skip callbacks
User.update_all(active: false)
user.update_columns(name: "New")  # Direct SQL, no callbacks
```

## Best Practices

### 1. Keep Callbacks Simple

```crystal
# Good: Single responsibility
before_save :normalize_email
before_save :hash_password
before_save :set_defaults

# Bad: Doing too much
before_save :do_everything
```

### 2. Use Appropriate Callback

```crystal
# Good: after_commit for external services
after_commit :send_email

# Bad: after_save might run even if rolled back
after_save :send_email
```

### 3. Consider Service Objects

```crystal
# Instead of complex callbacks
class User < Grant::Base
  after_create :setup_user_account

  private def setup_user_account
    UserAccountSetupService.new(self).perform
  end
end

class UserAccountSetupService
  def initialize(@user : User)
  end

  def perform
    create_profile
    send_welcome_email
    assign_default_role
  end
end
```
