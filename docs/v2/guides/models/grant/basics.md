---
title: "Models and Columns"
section: "guides/models/grant"
order: 10
description: "Defining models, columns, and data types in Grant ORM"
---

# Models and Columns

> **Preview ecosystem guide:** Grant is not part of the Amber 2.0.0-beta.1
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Models in Grant represent database tables and provide an object-oriented interface for data interaction.

## Basic Model Definition

```crystal
class User < Grant::Base
  connection pg        # Database connection
  table users         # Table name (optional, defaults to pluralized class name)

  column id : Int64, primary: true
  column email : String
  column name : String
  column active : Bool = true

  timestamps          # Adds created_at and updated_at
end
```

## Column Types

### Primitive Types

```crystal
class Product < Grant::Base
  connection pg

  # Integer types
  column id : Int64, primary: true      # BIGINT
  column quantity : Int32               # INTEGER
  column position : Int16               # SMALLINT

  # Floating point
  column price : Float64                # DOUBLE PRECISION
  column rating : Float32               # FLOAT

  # String types
  column name : String                  # VARCHAR/TEXT
  column description : String?          # Nullable string

  # Boolean
  column active : Bool = true           # BOOLEAN

  # Time/Date
  column published_at : Time?           # TIMESTAMP

  timestamps
end
```

### Special Types

```crystal
class AdvancedModel < Grant::Base
  connection pg

  # UUID (PostgreSQL, MySQL 8+)
  column id : UUID, primary: true

  # JSON (PostgreSQL JSONB, MySQL JSON)
  column metadata : JSON::Any?
  column settings : JSON::Any = JSON.parse("{}")

  # Arrays (PostgreSQL only)
  column tags : Array(String)?
  column scores : Array(Int32)?

  # Binary data
  column file_data : Bytes?
end
```

## Column Options

| Option | Description | Example |
|--------|-------------|---------|
| `primary: true` | Marks as primary key | `column id : Int64, primary: true` |
| `auto: false` | Disables auto-increment | `column uuid : String, primary: true, auto: false` |
| `converter:` | Custom type converter | `column data : JSON::Any, converter: Grant::Converters::Json` |
| Default value | Sets default | `column active : Bool = true` |

## Primary Keys

### Standard Auto-increment

```crystal
class User < Grant::Base
  column id : Int64, primary: true
end
```

### UUID Primary Key

```crystal
class Document < Grant::Base
  connection pg
  column id : UUID, primary: true
  column title : String
end

doc = Document.new(title: "Report")
doc.save
doc.id # => "550e8400-e29b-41d4-a716-446655440000"
```

### Natural Key

```crystal
class Country < Grant::Base
  connection pg
  column iso_code : String, primary: true, auto: false
  column name : String
end

Country.create!(iso_code: "US", name: "United States")
```

## Timestamps

```crystal
class Post < Grant::Base
  column id : Int64, primary: true
  column title : String

  timestamps  # Adds created_at and updated_at
end

post = Post.create!(title: "Hello")
post.created_at  # => 2025-01-15 12:00:00 UTC
post.updated_at  # => 2025-01-15 12:00:00 UTC

post.update!(title: "Hello World")
post.updated_at  # => 2025-01-15 12:05:00 UTC (updated)
```

## Default Values

### Static Defaults

```crystal
class Article < Grant::Base
  column status : String = "draft"
  column views : Int32 = 0
  column featured : Bool = false
  column tags : Array(String) = [] of String
end
```

### Dynamic Defaults via Callbacks

```crystal
class Token < Grant::Base
  column value : String?
  column expires_at : Time?

  before_create :set_defaults

  private def set_defaults
    self.value ||= Random::Secure.hex(32)
    self.expires_at ||= 24.hours.from_now
  end
end
```

## Multiple Database Connections

### Registering Connections

```crystal
# config/database.cr
Grant::Connections << Grant::Adapter::Pg.new(
  name: "primary",
  url: ENV["PRIMARY_DATABASE_URL"]
)

Grant::Connections << Grant::Adapter::Mysql.new(
  name: "legacy",
  url: ENV["LEGACY_DATABASE_URL"]
)

Grant::Connections << Grant::Adapter::Sqlite.new(
  name: "cache",
  url: "sqlite3://./cache.db"
)
```

### Using Different Connections

```crystal
class User < Grant::Base
  connection primary
  table users
end

class LegacyCustomer < Grant::Base
  connection legacy
  table customers
end

class CacheEntry < Grant::Base
  connection cache
  table cache_entries
end
```

## Type Converters

### Built-in Converters

```crystal
# Enum converter
enum Status
  Active
  Inactive
  Pending
end

class Account < Grant::Base
  column status : Status, converter: Grant::Converters::Enum(Status, String)
end

# JSON converter for custom types
class Settings
  include JSON::Serializable
  property theme : String = "light"
  property notifications : Bool = true
end

class User < Grant::Base
  column preferences : Settings, converter: Grant::Converters::Json(Settings, String)
end
```

### Custom Converters

```crystal
module Grant::Converters
  class EncryptedString < Grant::Converters::Base(String, String)
    def self.from_db(value : String) : String
      decrypt(value)
    end

    def self.to_db(value : String) : String
      encrypt(value)
    end
  end
end

class SecureModel < Grant::Base
  column secret : String, converter: Grant::Converters::EncryptedString
end
```

## JSON Serialization

Grant models include JSON::Serializable by default:

```crystal
user = User.find(1)
json = user.to_json
# => {"id":1,"name":"John","email":"john@example.com"}

# Custom serialization
class User < Grant::Base
  @[JSON::Field(key: "user_name")]
  column name : String

  @[JSON::Field(ignore: true)]
  column password_hash : String?
end
```

## Database-Specific Features

### PostgreSQL

```crystal
class PgModel < Grant::Base
  connection pg

  # Arrays
  column tags : Array(String)

  # JSONB
  column metadata : JSON::Any

  # Full-text search scope
  scope :search, ->(query : String) {
    where("to_tsvector('english', content) @@ plainto_tsquery('english', ?)", [query])
  }
end
```

### MySQL

```crystal
class MysqlModel < Grant::Base
  connection mysql

  # JSON column (MySQL 5.7+)
  column settings : JSON::Any

  # Full-text search
  scope :search, ->(query : String) {
    where("MATCH(title, content) AGAINST(? IN NATURAL LANGUAGE MODE)", [query])
  }
end
```

## Best Practices

### 1. Choose Appropriate Types

```crystal
# Good: Use specific types
column price_cents : Int32      # Store money as integers
column email : String           # Validated elsewhere
column published : Bool         # Clear boolean

# Avoid: Ambiguous types
column price : Float64          # Floating point money issues
column data : String            # Consider JSON::Any
```

### 2. Use Nullability Appropriately

```crystal
# Required fields (not nilable)
column email : String
column name : String

# Optional fields (nilable)
column bio : String?
column deleted_at : Time?
```

### 3. Set Sensible Defaults

```crystal
column status : String = "pending"
column retry_count : Int32 = 0
column active : Bool = true
```
