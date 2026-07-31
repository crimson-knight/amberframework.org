---
title: "Transactions"
section: "guides/models/grant"
order: 60
description: "Database transactions and locking strategies in Grant ORM"
---

# Transactions

> **Preview ecosystem guide:** Grant is not part of the Amber 2.0.0-beta.1
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Proper transaction management is essential for data integrity. Grant provides comprehensive support for transactions, isolation levels, and locking strategies.

## Basic Transactions

```crystal
Grant::Base.transaction do
  user = User.find!(1)
  user.balance -= 100
  user.save!

  transfer = Transfer.create!(
    user_id: user.id,
    amount: -100
  )

  # Automatic rollback on exception
  raise "Insufficient funds" if user.balance < 0
end
```

### Transaction Methods

```crystal
# Block syntax
Grant::Base.transaction do
  # All operations in one transaction
  User.create!(name: "Alice")
  User.create!(name: "Bob")
end

# With explicit rollback
Grant::Base.transaction do |tx|
  user = User.create!(name: "Alice")

  if some_condition_fails
    raise DB::Rollback.new("Condition failed")
  end
end
```

## Nested Transactions with Savepoints

```crystal
Grant::Base.transaction do
  order = Order.create!(customer_id: 1, total: 0)

  items.each do |item_data|
    Grant::Base.transaction do  # Savepoint
      item = OrderItem.create!(
        order_id: order.id,
        product_id: item_data[:product_id],
        quantity: item_data[:quantity]
      )

      product = Product.find!(item_data[:product_id])
      product.stock -= item_data[:quantity]

      # Rollback just this item if out of stock
      raise "Out of stock" if product.stock < 0

      product.save!
      order.total += item.subtotal
    end
  rescue
    # Skip item but continue with order
    Log.warn { "Skipping item #{item_data[:id]}" }
  end

  order.save!
end
```

## Isolation Levels

```crystal
# Available levels
IsolationLevel::ReadUncommitted
IsolationLevel::ReadCommitted
IsolationLevel::RepeatableRead
IsolationLevel::Serializable

# Serializable for financial operations
Grant::Base.transaction(isolation: :serializable) do
  account1 = Account.find!(1)
  account2 = Account.find!(2)

  account1.balance -= 100
  account2.balance += 100

  account1.save!
  account2.save!
end

# Read committed for reports
Grant::Base.transaction(isolation: :read_committed) do
  generate_report
end
```

## Pessimistic Locking

Lock rows to prevent concurrent modifications.

### Row-Level Locking

```crystal
Grant::Base.transaction do
  # Lock account for update
  account = Account.find!(1)
  account.lock!  # FOR UPDATE

  # No other transaction can modify this account
  account.balance -= 100
  account.save!
end

# Lock with custom mode
Grant::Base.transaction do
  account = Account.lock!(:share)  # FOR SHARE
  # Read but prevent updates
end
```

### with_lock Helper

```crystal
account = Account.find!(1)

account.with_lock do |locked_account|
  locked_account.balance -= 100
  locked_account.save!
end
```

### Lock Multiple Rows

```crystal
Grant::Base.transaction do
  accounts = Account.where(user_id: 1).lock
  accounts.each do |account|
    account.process_fees
  end
end
```

## Optimistic Locking

Use a version column to detect concurrent modifications.

```crystal
class Product < Grant::Base
  include Grant::Locking::Optimistic

  column id : Int64, primary: true
  column name : String
  column price : Float64
  column lock_version : Int32 = 0
end

# Automatic version checking
product = Product.find!(1)
product.price = 29.99
product.save!  # Increments lock_version

# Concurrent update detection
product1 = Product.find!(1)
product2 = Product.find!(1)

product1.price = 19.99
product1.save!  # Works

product2.price = 24.99
product2.save!  # Raises Grant::StaleRecordError
```

### Handling Conflicts

```crystal
def update_with_retry(product, max_retries = 3)
  retry_count = 0

  loop do
    begin
      yield product
      product.save!
      break
    rescue Grant::StaleRecordError
      retry_count += 1
      raise if retry_count >= max_retries

      product.reload
      Log.info { "Retrying update (attempt #{retry_count})" }
    end
  end
end

update_with_retry(product) do |p|
  p.stock -= 1
end
```

## Deadlock Prevention

### Ordered Locking

Always acquire locks in the same order to prevent deadlocks.

```crystal
def transfer_funds(from_id, to_id, amount)
  # Sort IDs to ensure consistent lock order
  ids = [from_id, to_id].sort

  Grant::Base.transaction do
    accounts = ids.map { |id| Account.find_and_lock!(id) }
    from = accounts.find { |a| a.id == from_id }.not_nil!
    to = accounts.find { |a| a.id == to_id }.not_nil!

    from.balance -= amount
    to.balance += amount

    from.save!
    to.save!
  end
end
```

### Lock Timeouts

```crystal
Grant::Base.transaction do
  Grant.connection.exec("SET LOCAL lock_timeout = '5s'")

  begin
    account = Account.find_and_lock!(1)
    account.process!
  rescue ex : DB::Error
    if ex.message.includes?("lock timeout")
      Log.warn { "Lock timeout, retrying..." }
    end
    raise ex
  end
end
```

## Transaction Callbacks

```crystal
class Order < Grant::Base
  after_commit :send_confirmation, on: :create
  after_commit :update_inventory, on: :update
  after_rollback :log_failure

  private def send_confirmation
    # Safe - transaction committed
    OrderMailer.confirmation(self).deliver_later
  end

  private def update_inventory
    InventoryService.sync(self)
  end

  private def log_failure
    Log.error { "Order #{id} failed to save" }
  end
end
```

## Best Practices

### 1. Keep Transactions Short

```crystal
# Good: Short transaction
Grant::Base.transaction do
  user.update!(status: "active")
end

# Bad: Long transaction
Grant::Base.transaction do
  users = User.all.to_a
  users.each do |user|
    user.process_complex_logic  # Time-consuming
    user.save!
  end
end
```

### 2. Use Appropriate Isolation

```crystal
# Serializable for critical financial operations
Grant::Base.transaction(isolation: :serializable) do
  transfer_funds(from, to, amount)
end

# Read committed for reports (better performance)
Grant::Base.transaction(isolation: :read_committed) do
  generate_report
end
```

### 3. Handle Failures Gracefully

```crystal
def process_order(order)
  Grant::Base.transaction do
    order.process!
    Payment.charge!(order)
    Inventory.decrement!(order)
  end
rescue Grant::RecordInvalid => e
  Log.error { "Validation failed: #{e.message}" }
  order.update!(status: "failed")
rescue => e
  Log.error { "Order processing failed: #{e.message}" }
  raise
end
```

### 4. Test Transaction Behavior

```crystal
describe "Transfer funds" do
  it "rolls back on failure" do
    account1 = Account.create!(balance: 100)
    account2 = Account.create!(balance: 50)

    expect_raises(Exception) do
      Grant::Base.transaction do
        account1.balance -= 200  # More than available
        account2.balance += 200
        account1.save!
        account2.save!
        raise "Insufficient funds"
      end
    end

    # Both accounts unchanged
    account1.reload.balance.should eq(100)
    account2.reload.balance.should eq(50)
  end
end
```
