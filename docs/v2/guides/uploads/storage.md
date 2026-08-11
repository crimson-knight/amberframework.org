---
title: "Storage Backends"
section: "guides/uploads"
order: 20
description: "Configure FileSystem, S3, and Memory storage for file uploads"
---

# Storage Backends

> **Preview ecosystem guide:** Gemma is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

Gemma supports multiple storage backends for flexibility across different environments. All storages implement the same interface, allowing you to switch backends without changing application code.

## Where the examples go

Storage construction and Gemma-wide configuration belong in
`config/application.cr`, which the released V2 template loads directly. Direct
upload, URL, and metadata operations belong in the controller, job, service, or
spec that owns the file operation. Test-only memory storage belongs in
`spec/spec_helper.cr`. Directory trees on this page describe runtime output,
not source files to create by hand.

## Configuration

**File: `config/application.cr` — append this setup after `require "amber"`.
Keep one `Gemma.configure` block and extend it as storage needs grow.**

```crystal
require "gemma"

Gemma.configure do |config|
  # Temporary storage (for uploads in progress)
  config.storages["cache"] = Gemma::Storage::FileSystem.new(
    "uploads",
    prefix: "cache"
  )

  # Permanent storage
  config.storages["store"] = Gemma::Storage::FileSystem.new("uploads")
end
```

## FileSystem Storage

Store files on the local filesystem. Best for development and simple deployments.

### Basic Configuration

```crystal
Gemma::Storage::FileSystem.new(
  "uploads"  # Base directory
)
```

### Full Configuration

```crystal
Gemma::Storage::FileSystem.new(
  "uploads",                    # Base directory
  prefix: "attachments",        # Subdirectory prefix
  permissions: 0o644,           # File permissions (default)
  directory_permissions: 0o755, # Directory permissions (default)
  clean: true                   # Auto-clean empty directories (default)
)
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `directory` | String | Required | Base directory for file storage |
| `prefix` | String? | `nil` | Subdirectory within base directory |
| `permissions` | Int | `0o644` | UNIX permissions for files |
| `directory_permissions` | Int | `0o755` | UNIX permissions for directories |
| `clean` | Bool | `true` | Remove empty parent directories on delete |

### URL Generation

```crystal
storage = Gemma::Storage::FileSystem.new("public/uploads", prefix: "files")

# URLs are relative paths
storage.url("abc123.jpg")
# => "/files/abc123.jpg"

# With host
storage.url("abc123.jpg", host: "https://cdn.example.com")
# => "https://cdn.example.com/files/abc123.jpg"
```

### Directory Structure

```
uploads/
├── cache/           # Temporary files (prefix: "cache")
│   └── abc123.jpg
└── files/           # Permanent files (prefix: "files")
    └── def456.pdf
```

## S3 Storage

Store files in Amazon S3 or S3-compatible services (DigitalOcean Spaces, MinIO, etc.).

### Basic Configuration

```crystal
require "gemma"

client = Awscr::S3::Client.new(
  region: "us-east-1",
  aws_access_key: ENV["AWS_ACCESS_KEY_ID"],
  aws_secret_key: ENV["AWS_SECRET_ACCESS_KEY"]
)

Gemma::Storage::S3.new(
  bucket: "my-app-uploads",
  client: client
)
```

### Full Configuration

```crystal
storage = Gemma::Storage::S3.new(
  bucket: "my-app-uploads",
  client: client,
  prefix: "attachments",        # Key prefix in bucket
  public: false,                # Set public ACL on upload
  upload_options: {             # Default upload options
    "x-amz-acl" => "private",
    "Cache-Control" => "max-age=31536000"
  }
)
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `bucket` | String | Required | S3 bucket name |
| `client` | Awscr::S3::Client | Required | S3 client instance |
| `prefix` | String? | `nil` | Key prefix for all objects |
| `public` | Bool | `false` | Make uploads publicly readable |
| `upload_options` | Hash | `{}` | Default headers for uploads |

### S3-Compatible Services

#### DigitalOcean Spaces

```crystal
client = Awscr::S3::Client.new(
  region: "nyc3",
  aws_access_key: ENV["SPACES_ACCESS_KEY"],
  aws_secret_key: ENV["SPACES_SECRET_KEY"],
  endpoint: "https://nyc3.digitaloceanspaces.com"
)

storage = Gemma::Storage::S3.new(
  bucket: "my-space",
  client: client,
  public: true  # Spaces URLs are typically public
)
```

#### MinIO

```crystal
client = Awscr::S3::Client.new(
  region: "us-east-1",
  aws_access_key: ENV["MINIO_ACCESS_KEY"],
  aws_secret_key: ENV["MINIO_SECRET_KEY"],
  endpoint: "http://localhost:9000"
)

storage = Gemma::Storage::S3.new(
  bucket: "uploads",
  client: client
)
```

### URL Generation

S3 storage generates presigned URLs:

```crystal
# Presigned URL (default, time-limited)
storage.url("abc123.jpg")
# => "https://bucket.s3.amazonaws.com/abc123.jpg?X-Amz-..."

# For public buckets, you may want direct URLs
# Configure your application to generate these
```

### Public Access

```crystal
# Make all uploads public
storage = Gemma::Storage::S3.new(
  bucket: "public-assets",
  client: client,
  public: true  # Sets x-amz-acl: public-read
)

# Or per-upload via upload_options
storage.upload(file, "key", upload_options: {"x-amz-acl" => "public-read"})
```

## Memory Storage

In-memory storage for testing. Files are not persisted.

```crystal
Gemma::Storage::Memory.new
```

### Testing Configuration

```crystal
# spec/spec_helper.cr
Gemma.configure do |config|
  config.storages["cache"] = Gemma::Storage::Memory.new
  config.storages["store"] = Gemma::Storage::Memory.new
end
```

## Environment-Based Configuration

Configure different storages per environment:

**File: `config/application.cr` — replace the earlier `Gemma.configure` block
with this environment-aware version; do not define both.**

```crystal
require "gemma"

Gemma.configure do |config|
  # Cache storage (same for all environments)
  config.storages["cache"] = Gemma::Storage::FileSystem.new(
    "uploads",
    prefix: "cache"
  )

  # Store storage (varies by environment)
  case ENV["AMBER_ENV"]?
  when "production"
    client = Awscr::S3::Client.new(
      region: ENV["AWS_REGION"],
      aws_access_key: ENV["AWS_ACCESS_KEY_ID"],
      aws_secret_key: ENV["AWS_SECRET_ACCESS_KEY"]
    )

    config.storages["store"] = Gemma::Storage::S3.new(
      bucket: ENV["S3_BUCKET"],
      client: client,
      prefix: "uploads"
    )

  when "test"
    config.storages["store"] = Gemma::Storage::Memory.new

  else # development
    config.storages["store"] = Gemma::Storage::FileSystem.new(
      "uploads",
      prefix: "store"
    )
  end
end
```

## Storage Interface

All storages implement these methods:

```crystal
# Upload a file
storage.upload(io, "path/to/file.jpg")

# Check if file exists
storage.exists?("path/to/file.jpg")  # => true/false

# Get file URL
storage.url("path/to/file.jpg")  # => "https://..."

# Open file for reading
storage.open("path/to/file.jpg")  # => IO

# Delete file
storage.delete("path/to/file.jpg")

# Get full path/key
storage.path("path/to/file.jpg")  # => "uploads/path/to/file.jpg"
```

## Direct Usage

You can use storages directly without models:

```crystal
# Upload file
storage = Gemma.find_storage("store")
storage.upload(File.open("document.pdf"), "documents/report.pdf")

# Or via Gemma class
uploaded_file = Gemma.upload(File.open("photo.jpg"), "store")

# Access the file
uploaded_file.url       # URL to file
uploaded_file.exists?   # Check existence
uploaded_file.delete    # Remove file
```

## Custom Metadata

Pass metadata during upload:

```crystal
Gemma.upload(
  file,
  "store",
  metadata: {
    "filename" => "report.pdf",
    "mime_type" => "application/pdf",
    "size" => file.size.to_s
  }
)
```

For S3, metadata is used for Content-Disposition:

```crystal
# Sets Content-Disposition: inline; filename="report.pdf"
storage.upload(
  file,
  "key",
  metadata: {"filename" => "report.pdf"}
)
```

## Best Practices

### 1. Separate Cache and Store

Always configure both storages:

```crystal
config.storages["cache"] = ...  # Temporary uploads
config.storages["store"] = ...  # Permanent storage
```

### 2. Use Environment Variables

Never hardcode credentials:

```crystal
client = Awscr::S3::Client.new(
  region: ENV["AWS_REGION"],
  aws_access_key: ENV["AWS_ACCESS_KEY_ID"],
  aws_secret_key: ENV["AWS_SECRET_ACCESS_KEY"]
)
```

### 3. Set Appropriate Permissions

For FileSystem, restrict access:

```crystal
Gemma::Storage::FileSystem.new(
  "uploads",
  permissions: 0o600,           # Owner read/write only
  directory_permissions: 0o700  # Owner full access only
)
```

### 4. Configure CDN for Production

Serve files through a CDN:

```crystal
# In production, prefix URLs with CDN
def avatar_cdn_url
  return nil unless avatar

  if ENV["AMBER_ENV"] == "production"
    "https://cdn.example.com#{avatar_url}"
  else
    avatar_url
  end
end
```

### 5. Clean Up Cache Periodically

Cached files should be temporary. Clean them periodically:

```crystal
# Cron job or scheduled task
Dir.glob("uploads/cache/**/*").each do |path|
  if File.file?(path) && File.info(path).modification_time < 1.day.ago
    File.delete(path)
  end
end
```
