---
title: "Introduction to Amber 2.0"
section: ""
order: 10
is_section: true
description: "Amber Framework 2.0 - A major release with Schema API, Grant ORM, Asset Pipeline, and Gemma file attachments"
---

# Welcome to Amber 2.0

Amber 2.0 is a major release that brings significant improvements to the framework, including a completely redesigned request handling system, a new default ORM, modern asset management, and integrated file upload handling.

![Amber Framework](https://raw.githubusercontent.com/amberframework/site-assets/master/videos/amber-animated-logo.gif)

## What's New in Amber 2.0

### Schema API - Type-Safe Request Handling

The **Schema API** is the headline feature of Amber 2.0. It provides compile-time validated request parameters with automatic type coercion, replacing the traditional params hash with a type-safe, validated approach.

```crystal
class CreateUserSchema < Amber::Schema
  field email : String, validators: [Amber::Validators::Email]
  field name : String, validators: [Amber::Validators::Presence]
  field age : Int32?, validators: [Amber::Validators::Range.new(min: 18)]
end
```

[Learn more about Schema API](guides/schema-api/)

### Grant ORM - The Default Data Layer

**Grant** is now the default ORM for Amber 2.0. Inspired by Rails' ActiveRecord, Grant brings a familiar, productive API with Crystal's type safety:

- Associations: `belongs_to`, `has_many`, `has_many :through`
- Validations: Built-in validators with custom validation support
- Callbacks: Full lifecycle callbacks including transaction callbacks
- Security: Encrypted attributes, secure tokens, signed IDs
- Advanced: Scopes, eager loading, transactions, optimistic/pessimistic locking

```crystal
class User < Grant::Base
  table users
  column id : Int64, primary: true
  column email : String
  column name : String
  timestamps

  has_many :posts
  validates_presence_of :email
  encrypts :ssn
end
```

[Learn more about Grant ORM](guides/models/grant/)

### Asset Pipeline - Modern Frontend Assets

The new **Asset Pipeline** handles JavaScript, CSS, and images using modern ESM modules and import maps. No webpack required:

- ESM modules and import maps
- Stimulus framework integration
- Pure Crystal component system
- Automatic cache management

```crystal
front_loader = AssetPipeline::FrontLoader.new(
  js_source_path: Path["src/javascript"],
  js_output_path: Path["public/javascript"]
)
```

[Learn more about Asset Pipeline](guides/assets/)

### Gemma - File Attachments

**Gemma** provides seamless file upload handling with multiple storage backends:

- FileSystem, S3, and Memory storage
- Grant ORM integration with `has_one_attached` and `has_many_attached`
- File validation (size, content type)
- Metadata extraction plugins

```crystal
class User < Grant::Base
  include Gemma::Grant::Attachable

  has_one_attached :avatar
  has_many_attached :documents

  validate_file_size_of :avatar, maximum: 5.megabytes
end
```

[Learn more about Gemma](guides/file-uploads/)

### Adapter System - Pluggable Infrastructure

Amber 2.0 removes the hard Redis dependency in favor of a pluggable adapter system:

- Session adapters (Memory, Cookie, or custom)
- PubSub adapters for WebSocket broadcasting
- Easy to implement custom adapters

[Learn more about Adapters](guides/adapters/)

## Breaking Changes

Amber 2.0 includes several breaking changes from 1.x:

- **Redis removed**: Use the new adapter system or implement a Redis adapter
- **Webpack removed**: Use the new Asset Pipeline with import maps
- **Default ORM**: Grant replaces Granite as the default (Granite still supported)
- **Schema API**: New request handling replaces traditional params

[View the full Migration Guide](migration-guide/)

## Getting Started

If you're new to Amber 2.0:

1. [Quick Start Guide](getting-started/) - Get up and running in minutes
2. [Schema API Basics](guides/schema-api/basics/) - Learn type-safe request handling
3. [Grant ORM Guide](guides/models/grant/) - Master the new default ORM

## Getting Help

* [**Discord**](https://discord.gg/vwvP5zakSn) for quick questions
* [**Stack Overflow**](https://stackoverflow.com/questions/tagged/amber-framework) for detailed questions
* [**GitHub**](https://github.com/amberframework/amber) for issues and source code
* [**Twitter**](https://twitter.com/amberframework) for news and announcements

## Contributing

Amber is a community effort. Join us!

[Contribute to Amber](https://github.com/amberframework/amber/blob/master/.github/CONTRIBUTING.md)
