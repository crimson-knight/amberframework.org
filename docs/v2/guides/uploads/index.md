---
title: "File Uploads (Gemma)"
section: "guides"
order: 50
is_section: true
description: "File attachment toolkit for Crystal applications"
---

# File Uploads with Gemma

> **Preview ecosystem guide:** Gemma is not part of the Amber 2.0.0-beta.3
> core web-app release gate. Its package version, API, and platform support may
> change independently. Confirm a compatible official release before adding it
> to an application.

Gemma is a file attachment toolkit for Crystal applications, inspired by [Shrine for Ruby](https://shrinerb.com). It connects model attachments to validation, temporary uploads, permanent storage, and delivery across configurable backends.

## Where the examples go

- Add dependencies in `shard.yml` and run commands from the application root.
- Configure Gemma in `config/application.cr`, which the released V2 template
  loads directly.
- Attachment declarations belong in Grant models under `src/models/`.
- Upload handling belongs in the receiving controller under `src/controllers/`;
  form and display markup belongs in the matching ECR file under `src/views/`.

Blocks on this page use those destinations unless a closer label says
otherwise.

## Why Gemma?

- **Storage Agnostic** - Switch between filesystem and S3 without changing application code
- **Grant Integration** - First-class support for Grant ORM with `has_one_attached` and `has_many_attached`
- **Validation Support** - Built-in validators for file size, content type, and dimensions
- **Plugin System** - Add MIME type detection and metadata extraction
- **Two-Stage Uploads** - Cache files temporarily, then promote to permanent storage

## Installation

**File: `shard.yml` — add Gemma under the existing `dependencies:` key.**

```yaml
dependencies:
  gemma:
    github: amberframework/gemma
    version: ~> 0.6.5
```

Run `shards install` from the application root.

## Quick Start

### 1. Configure Storage

**File: `config/application.cr` — append this setup after `require "amber"`.
Do not put it in the generated empty `config/initializers/` directory unless
you also add and verify an explicit require.**

```crystal
require "gemma"

Gemma.configure do |config|
  # Temporary storage for uploads in progress
  config.storages["cache"] = Gemma::Storage::FileSystem.new(
    "uploads",
    prefix: "cache"
  )

  # Permanent storage for completed uploads
  config.storages["store"] = Gemma::Storage::FileSystem.new("uploads")
end
```

### 2. Add Attachment to Model

**File: `src/models/user.cr` — keep the attachment declaration inside `User`.**

```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable

  column id : Int64, primary: true
  column name : String
  column avatar_data : JSON::Any?

  has_one_attached :avatar
end
```

### 3. Use in Controller

**File: `src/controllers/users_controller.cr` — add this behavior inside the
action that receives the upload.**

```crystal
class UsersController < ApplicationController
  def create
    user = User.new(user_params)

    # Assign uploaded file
    if file = params.files["avatar"]?
      user.avatar = file.file
    end

    if user.save
      redirect_to "/users/#{user.id}"
    else
      render "users/new.ecr"
    end
  end
end
```

### 4. Display in View

**File: `src/views/users/show.ecr` — render the attachment inside the user page.**

```ecr
<% if user.avatar %>
  <img src="<%= user.avatar_url %>" alt="Avatar">
<% end %>
```

## How It Works

Gemma uses a two-stage upload process:

1. **Cache Stage** - Files are first uploaded to temporary "cache" storage
2. **Store Stage** - On model save, cached files are promoted to permanent "store" storage

This approach provides several benefits:

- Failed validations don't leave orphaned files
- Users can preview uploads before final submission
- Background processing can happen between stages

```crystal
# Behind the scenes
user.avatar = uploaded_file  # Uploaded to cache
user.save                     # Promoted to store
```

## Core Concepts

### UploadedFile

Represents an uploaded file with metadata:

```crystal
uploaded_file = user.avatar

uploaded_file.id              # => "abc123.jpg"
uploaded_file.url             # => "/uploads/abc123.jpg"
uploaded_file.size            # => 12345
uploaded_file.mime_type       # => "image/jpeg"
uploaded_file.original_filename # => "photo.jpg"
uploaded_file.extension       # => "jpg"
uploaded_file.exists?         # => true

# Access raw IO
uploaded_file.open do |io|
  # Process file content
end

# Download to tempfile
uploaded_file.download do |tempfile|
  # Work with local file
end
```

### Storages

Gemma supports multiple storage backends:

| Storage | Use Case |
|---------|----------|
| `FileSystem` | Local development, simple deployments |
| `S3` | Production, cloud deployments |
| `Memory` | Testing |

### Attacher

The internal mechanism that manages file attachment lifecycle:

```crystal
attacher = user._avatar_attacher

attacher.file       # Current file
attacher.cached?    # File in temporary storage?
attacher.stored?    # File in permanent storage?
attacher.changed?   # File was modified?
attacher.url        # File URL
```

## Features

### Single File Attachments

```crystal
class User < Grant::Base
  include Gemma::Grant::Attachable

  column avatar_data : JSON::Any?
  has_one_attached :avatar
end

user.avatar = File.open("photo.jpg")
user.save

user.avatar_url  # => "/uploads/abc123.jpg"
```

### Multiple File Attachments

```crystal
class Post < Grant::Base
  include Gemma::Grant::Attachable

  column images_data : JSON::Any?
  has_many_attached :images
end

post.images = [File.open("img1.jpg"), File.open("img2.jpg")]
post.save

post.images.each do |image|
  puts image.url
end

# Add single file
post.add_image(File.open("img3.jpg"))

# Remove file
post.remove_image(post.images.first)

# Clear all
post.clear_images
```

### Custom Uploaders

Create custom uploaders for specialized handling:

```crystal
class ImageUploader < Gemma
  def generate_location(io, metadata, context, **options)
    name = super(io, metadata, **options)

    # Organize by model and ID
    File.join(
      context[:model].class.name.underscore,
      context[:model].id.to_s,
      name
    )
  end
end

# Use custom uploader
has_one_attached :avatar, uploader: ImageUploader
```

## Next Steps

- [Attachments](attachments/) - Single and multiple file attachments
- [Storage Backends](storage/) - Configure FileSystem and S3
- [Validation](validation/) - Validate file uploads
