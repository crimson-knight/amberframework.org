---
title: "File Validation"
section: "guides/uploads"
order: 30
description: "Validating file uploads for size, type, and dimensions"
---

# File Validation

> **Preview ecosystem guide:** Gemma is not part of the Amber 2.0.0-beta.1
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Gemma provides validation helpers for Grant models to ensure uploaded files meet your requirements.

## Setup

Include the `AttachmentValidators` module alongside `Attachable`:

```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column id : Int64, primary: true
  column avatar_data : JSON::Any?

  has_one_attached :avatar

  # Add validations
  validate_file_size_of :avatar, maximum: 5.megabytes
  validate_content_type_of :avatar, accept: ["image/jpeg", "image/png", "image/gif"]
end
```

## File Size Validation

Limit the size of uploaded files:

```crystal
# Maximum size only
validate_file_size_of :avatar, maximum: 5.megabytes

# Minimum size only
validate_file_size_of :document, minimum: 1.kilobyte

# Both minimum and maximum
validate_file_size_of :video, minimum: 100.kilobytes, maximum: 100.megabytes

# Custom error message
validate_file_size_of :avatar,
  maximum: 2.megabytes,
  message: "must be smaller than 2MB"
```

### Size Helpers

Crystal provides convenient size methods:

```crystal
1.kilobyte   # 1024 bytes
1.megabyte   # 1024 * 1024 bytes
1.gigabyte   # 1024 * 1024 * 1024 bytes

# Or use raw bytes
validate_file_size_of :avatar, maximum: 5_242_880  # 5MB in bytes
```

## Content Type Validation

Restrict allowed file types:

### Accept List

```crystal
# Single type
validate_content_type_of :avatar, accept: "image/jpeg"

# Multiple types
validate_content_type_of :avatar, accept: ["image/jpeg", "image/png", "image/gif"]

# Wildcard matching
validate_content_type_of :document, accept: ["application/pdf", "image/*"]
```

### Reject List

```crystal
# Block specific types
validate_content_type_of :upload, reject: ["application/x-executable", "application/x-msdownload"]

# Block category with wildcard
validate_content_type_of :document, reject: "video/*"
```

### Custom Message

```crystal
validate_content_type_of :avatar,
  accept: ["image/jpeg", "image/png"],
  message: "must be a JPEG or PNG image"
```

### Common Content Types

| Category | Types |
|----------|-------|
| Images | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/svg+xml` |
| Documents | `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.*` |
| Video | `video/mp4`, `video/webm`, `video/quicktime` |
| Audio | `audio/mpeg`, `audio/wav`, `audio/ogg` |
| Archives | `application/zip`, `application/x-tar`, `application/gzip` |

## Presence Validation

Require an attachment to be present:

```crystal
class Profile < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column photo_data : JSON::Any?
  has_one_attached :photo

  # Photo is required
  validate_presence_of :photo

  # Custom message
  validate_presence_of :photo, message: "Please upload a profile photo"
end
```

## Dimension Validation

Validate image dimensions (requires StoreDimensions plugin):

```crystal
require "fastimage"
require "gemma/plugins/store_dimensions"

class ImageUploader < Gemma
  load_plugin(
    Gemma::Plugins::StoreDimensions,
    analyzer: Gemma::Plugins::StoreDimensions::Tools::FastImage
  )
  finalize_plugins!
end

class Photo < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column image_data : JSON::Any?
  has_one_attached :image, uploader: ImageUploader

  # Exact dimensions
  validate_dimensions_of :image, width: 800, height: 600

  # Range of dimensions
  validate_dimensions_of :image,
    width: 100..2000,
    height: 100..2000

  # Only width constraint
  validate_dimensions_of :image, width: 800..1920

  # Only height constraint
  validate_dimensions_of :image, height: 600..1080
end
```

## Collection Size Validation

For `has_many_attached`, validate the number of files:

```crystal
class Post < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column images_data : JSON::Any?
  has_many_attached :images

  # Require at least one image
  validate_collection_size_of :images, minimum: 1

  # Maximum 10 images
  validate_collection_size_of :images, maximum: 10

  # Between 1 and 5 images
  validate_collection_size_of :images, minimum: 1, maximum: 5

  # Custom message
  validate_collection_size_of :images,
    maximum: 5,
    message: "You can upload at most 5 images"
end
```

## Combining Validations

Apply multiple validations to the same attachment:

```crystal
class Document < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column file_data : JSON::Any?
  has_one_attached :file

  # Must be present
  validate_presence_of :file

  # Size between 1KB and 10MB
  validate_file_size_of :file,
    minimum: 1.kilobyte,
    maximum: 10.megabytes

  # Must be PDF or Word document
  validate_content_type_of :file,
    accept: [
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ]
end
```

## Conditional Validation

Use standard Grant validation conditions:

```crystal
class User < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column avatar_data : JSON::Any?
  column is_premium : Bool = false

  has_one_attached :avatar

  # Premium users can upload larger avatars
  validate :avatar_size_for_user_type

  private def avatar_size_for_user_type
    return unless avatar

    max_size = is_premium ? 10.megabytes : 2.megabytes

    if (size = avatar.size) && size > max_size
      errors.add(:avatar, "is too large for your account type")
    end
  end
end
```

## Custom Validators

Create custom validation logic:

```crystal
class Photo < Grant::Base
  include Gemma::Grant::Attachable

  column image_data : JSON::Any?
  has_one_attached :image

  validate :image_aspect_ratio

  private def image_aspect_ratio
    return unless image

    width = image.metadata["width"]?.try(&.to_i)
    height = image.metadata["height"]?.try(&.to_i)

    return unless width && height

    ratio = width.to_f / height.to_f

    # Require 16:9 aspect ratio (with tolerance)
    unless (1.7..1.8).includes?(ratio)
      errors.add(:image, "must have a 16:9 aspect ratio")
    end
  end
end
```

### Virus Scanning

```crystal
class Upload < Grant::Base
  include Gemma::Grant::Attachable

  column file_data : JSON::Any?
  has_one_attached :file

  validate :scan_for_viruses

  private def scan_for_viruses
    return unless file && file_changed?

    file.download do |tempfile|
      result = `clamscan --no-summary #{tempfile.path}`
      status = $?.exit_code

      if status != 0
        errors.add(:file, "failed virus scan")
      end
    end
  end
end
```

## Error Messages

Access validation errors:

```crystal
user = User.new(name: "Alice")
user.avatar = large_file

unless user.valid?
  user.errors[:avatar].each do |error|
    puts error  # => "is too large (maximum is 5242880 bytes)"
  end
end
```

### Display in Views

```ecr
<% if @user.errors[:avatar].any? %>
  <div class="alert alert-danger">
    <% @user.errors[:avatar].each do |error| %>
      <p>Avatar <%= error %></p>
    <% end %>
  </div>
<% end %>
```

## MIME Type Detection

For accurate content type validation, use the DetermineMimeType plugin:

```crystal
require "gemma/plugins/determine_mime_type"

class SecureUploader < Gemma
  load_plugin(
    Gemma::Plugins::DetermineMimeType,
    analyzer: Gemma::Plugins::DetermineMimeType::Tools::File
  )
  finalize_plugins!
end

class Document < Grant::Base
  include Gemma::Grant::Attachable
  include Gemma::Grant::AttachmentValidators

  column file_data : JSON::Any?
  has_one_attached :file, uploader: SecureUploader

  # Now validates against actual file content, not just extension
  validate_content_type_of :file, accept: "application/pdf"
end
```

### Analyzer Options

| Analyzer | Description |
|----------|-------------|
| `File` | Uses system `file` command (most accurate) |
| `Mime` | Uses Crystal's `MIME.from_filename` |
| `ContentType` | Uses HTTP Content-Type header (least secure) |

## Best Practices

### 1. Always Validate Content Type

Don't trust file extensions alone:

```crystal
# Use File analyzer for security
load_plugin(
  Gemma::Plugins::DetermineMimeType,
  analyzer: Gemma::Plugins::DetermineMimeType::Tools::File
)

validate_content_type_of :upload, accept: [...]
```

### 2. Set Reasonable Size Limits

Prevent resource exhaustion:

```crystal
# Avatars: 2-5 MB
validate_file_size_of :avatar, maximum: 5.megabytes

# Documents: 10-50 MB
validate_file_size_of :document, maximum: 50.megabytes

# Videos: Set based on your infrastructure
validate_file_size_of :video, maximum: 500.megabytes
```

### 3. Validate Before Processing

Check files before expensive operations:

```crystal
class Video < Grant::Base
  validate_content_type_of :file, accept: "video/*"
  validate_file_size_of :file, maximum: 500.megabytes

  after_save :transcode_video

  private def transcode_video
    # Only runs if validations pass
    # Safe to process the file
  end
end
```

### 4. Provide Helpful Error Messages

Guide users to fix issues:

```crystal
validate_file_size_of :avatar,
  maximum: 5.megabytes,
  message: "must be smaller than 5MB. Try compressing your image."

validate_content_type_of :avatar,
  accept: ["image/jpeg", "image/png"],
  message: "must be a JPEG or PNG file. Other formats are not supported."
```
