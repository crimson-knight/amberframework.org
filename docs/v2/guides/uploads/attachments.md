---
title: "File Attachments"
section: "guides/uploads"
order: 10
description: "Attaching single and multiple files to Grant models"
---

# File Attachments

> **Preview ecosystem guide:** Gemma is not part of the Amber 2.0.0-beta.2
> core web-app release gate. Its package version, API, and platform support may
> change independently. Do not add a personal fork as a default dependency.

Gemma provides seamless integration with Grant ORM through the `Attachable` module. This guide covers single and multiple file attachments.

## Setup

Include the `Attachable` module in your Grant model:

```crystal
require "gemma/grant"

class User < Grant::Base
  include Gemma::Grant::Attachable

  column id : Int64, primary: true
  column name : String

  # Column to store attachment metadata (JSON)
  column avatar_data : JSON::Any?

  # Declare the attachment
  has_one_attached :avatar
end
```

## Single File Attachments

### Declaration

Use `has_one_attached` to attach a single file:

```crystal
class User < Grant::Base
  include Gemma::Grant::Attachable

  column id : Int64, primary: true
  column profile_picture_data : JSON::Any?
  column resume_data : JSON::Any?

  has_one_attached :profile_picture
  has_one_attached :resume
end
```

The column name must be `{attachment_name}_data` with type `JSON::Any?`.

### Attaching Files

```crystal
# From IO object
user.avatar = File.open("avatar.jpg")

# From uploaded file in controller
user.avatar = params.files["avatar"].file

# Clear attachment
user.avatar = nil
```

### Accessing Attachments

```crystal
# Get the UploadedFile object
file = user.avatar

# Check if attached
if user.avatar
  puts "Avatar attached!"
end

# Get URL
url = user.avatar_url

# With URL options
url = user.avatar_url(host: "https://cdn.example.com")

# Check if changed (before save)
user.avatar_changed?  # => true/false
```

### File Metadata

```crystal
file = user.avatar

file.id                # Unique identifier
file.original_filename # Original upload name
file.extension         # File extension
file.size              # Size in bytes
file.mime_type         # MIME type
file.metadata          # All metadata hash
```

### Working with File Content

```crystal
# Open for reading
user.avatar.open do |io|
  content = io.gets_to_end
end

# Download to tempfile
user.avatar.download do |tempfile|
  # tempfile is a File object
  system("convert", tempfile.path, "thumbnail.jpg")
end

# Stream to destination
io = IO::Memory.new
user.avatar.stream(io)
```

## Multiple File Attachments

### Declaration

Use `has_many_attached` for multiple files:

```crystal
class Post < Grant::Base
  include Gemma::Grant::Attachable

  column id : Int64, primary: true
  column title : String
  column images_data : JSON::Any?
  column attachments_data : JSON::Any?

  has_many_attached :images
  has_many_attached :attachments
end
```

### Attaching Multiple Files

```crystal
# Replace all files
post.images = [
  File.open("photo1.jpg"),
  File.open("photo2.jpg"),
  File.open("photo3.jpg")
]

# From controller with multiple file upload
post.images = params.files.select { |f| f.field == "images" }.map(&.file)
```

### Managing Collections

```crystal
# Get all files (Array of UploadedFile)
files = post.images

# Iterate
post.images.each do |image|
  puts image.url
end

# Count
post.images.size

# Add single file (singular form of attachment name)
post.add_image(File.open("new_photo.jpg"))

# Remove specific file
post.remove_image(post.images.first)

# Clear all files
post.clear_images

# Check if changed
post.images_changed?
```

## Lifecycle Callbacks

Gemma automatically hooks into Grant's lifecycle:

```crystal
class Document < Grant::Base
  include Gemma::Grant::Attachable

  column file_data : JSON::Any?
  has_one_attached :file

  # Gemma registers these automatically:
  # before_save  - promotes cached files to store
  # after_save   - persists attachment data
  # after_destroy - cleans up attached files
end
```

### Custom Processing

Add your own callbacks for additional processing:

```crystal
class Photo < Grant::Base
  include Gemma::Grant::Attachable

  column image_data : JSON::Any?
  column thumbnail_data : JSON::Any?

  has_one_attached :image
  has_one_attached :thumbnail

  after_save :generate_thumbnail

  private def generate_thumbnail
    return unless image && image_changed?

    image.download do |tempfile|
      # Generate thumbnail using ImageMagick
      thumb_path = "/tmp/thumb_#{id}.jpg"
      system("convert", tempfile.path, "-thumbnail", "100x100^", thumb_path)

      self.thumbnail = File.open(thumb_path)
      save! if thumbnail_changed?

      File.delete(thumb_path)
    end
  end
end
```

## Custom Uploaders

Create custom uploaders for specialized behavior:

```crystal
class AvatarUploader < Gemma
  # Custom file location
  def generate_location(io, metadata, context, **options)
    user = context[:model]
    filename = metadata["filename"]? || "avatar"
    extension = File.extname(filename)

    "users/#{user.id}/avatar#{extension}"
  end
end

class User < Grant::Base
  include Gemma::Grant::Attachable

  column avatar_data : JSON::Any?

  # Use custom uploader
  has_one_attached :avatar, uploader: AvatarUploader
end
```

### Uploader with Plugins

```crystal
require "gemma/plugins/determine_mime_type"
require "gemma/plugins/store_dimensions"

class ImageUploader < Gemma
  load_plugin(
    Gemma::Plugins::DetermineMimeType,
    analyzer: Gemma::Plugins::DetermineMimeType::Tools::File
  )

  load_plugin(
    Gemma::Plugins::StoreDimensions,
    analyzer: Gemma::Plugins::StoreDimensions::Tools::FastImage
  )

  finalize_plugins!
end

# Now metadata includes width/height
image.metadata["width"]   # => 1920
image.metadata["height"]  # => 1080
image.metadata["mime_type"]  # => "image/jpeg"
```

## Form Integration

### ECR Template

```erb
<form action="/users" method="post" enctype="multipart/form-data">
  <div class="form-group">
    <label for="avatar">Avatar</label>
    <input type="file" name="avatar" id="avatar" accept="image/*">
  </div>

  <% if @user.avatar %>
    <div class="current-avatar">
      <img src="<%= @user.avatar_url %>" alt="Current avatar">
      <label>
        <input type="checkbox" name="remove_avatar" value="1">
        Remove avatar
      </label>
    </div>
  <% end %>

  <button type="submit">Save</button>
</form>
```

### Controller Handling

```crystal
class UsersController < ApplicationController
  def update
    user = User.find!(params["id"])

    # Handle file upload
    if file = params.files["avatar"]?
      user.avatar = file.file
    end

    # Handle removal
    if params["remove_avatar"]? == "1"
      user.avatar = nil
    end

    if user.save
      redirect_to "/users/#{user.id}"
    else
      render "users/edit.ecr"
    end
  end
end
```

## Direct Uploads

For large files, upload directly to storage:

```crystal
# Controller
def presign
  # Generate presigned URL for direct S3 upload
  storage = Gemma.find_storage("cache").as(Gemma::Storage::S3)

  # Return presigned URL to client
  json({
    url:    storage.presigned_url(key),
    fields: storage.presigned_fields(key)
  })
end

def create
  user = User.new(user_params)

  # Accept cached file data from client
  if cached_data = params["avatar_data"]?
    user.avatar = JSON.parse(cached_data).as_h
  end

  user.save
end
```

## Best Practices

### 1. Always Use `JSON::Any?` Column Type

```crystal
# Correct
column avatar_data : JSON::Any?

# Wrong - will fail
column avatar_data : String?
```

### 2. Check for Attachment Before Accessing URL

```crystal
# Safe
url = user.avatar_url if user.avatar

# Or use the helper that returns nil
url = user.avatar_url  # => nil if no attachment
```

### 3. Clean Up Orphaned Files

```crystal
# Files are automatically deleted on destroy
user.destroy  # Avatar file is deleted

# For manual cleanup
user.avatar.try(&.delete)
user.update!(avatar_data: nil)
```

### 4. Use Appropriate Storage per Environment

```crystal
Gemma.configure do |config|
  if ENV["AMBER_ENV"] == "production"
    config.storages["store"] = Gemma::Storage::S3.new(...)
  else
    config.storages["store"] = Gemma::Storage::FileSystem.new("uploads")
  end
end
```
