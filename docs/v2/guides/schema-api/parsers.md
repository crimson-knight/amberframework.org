---
title: "Parsers"
section: "guides/schema-api"
order: 30
description: "Content type handling for JSON, XML, forms, CSV, Protocol Buffers, and MessagePack"
---

# Parsers

## Where the examples go

Parser and field declarations belong inside schema classes under
`src/schemas/`. Blocks labeled as example requests are HTTP request bodies, not
source files. Content negotiation belongs in the receiving controller under
`src/controllers/`, and the endpoint belongs in `config/routes.cr`. Multipart
file handling must also follow the application's upload-validation boundary.

Select a parser through the schema's content type. Amber provides explicit
parsers for the formats listed below.

## Supported Content Types

- `application/json` - JSON data
- `application/xml` - XML documents
- `application/x-www-form-urlencoded` - Form data
- `multipart/form-data` - File uploads and forms
- `text/csv` - CSV bulk operations
- `application/x-protobuf` - Protocol Buffers
- `application/msgpack` - MessagePack

## JSON Parser

The most common format for APIs:

```crystal
class CreateOrderSchema < Amber::Schema::Definition
  content_type "application/json"

  field :items, Array(OrderItemSchema), required: true
  field :shipping_address, AddressSchema
  field :billing_address, AddressSchema
  field :same_as_shipping, Bool, default: false

  validates_to OrderRequest, OrderValidationError
end
```

Example request:

```json
{
  "items": [
    {"product_id": 1, "quantity": 2},
    {"product_id": 3, "quantity": 1}
  ],
  "shipping_address": {
    "street": "123 Main St",
    "city": "Springfield",
    "zip": "12345"
  },
  "same_as_shipping": true
}
```

## XML Parser

For SOAP APIs or XML-based integrations:

```crystal
class CreateOrderXMLSchema < Amber::Schema::Definition
  content_type "application/xml"

  field :items, Array(OrderItemSchema), xpath: "//order/items/item"
  field :shipping_address, AddressSchema, xpath: "//order/shipping"
  field :billing_address, AddressSchema, xpath: "//order/billing"
  field :same_as_shipping, Bool, xpath: "//order/@sameAsShipping"

  validates_to OrderRequest, OrderValidationError
end
```

Example request:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<order sameAsShipping="true">
  <items>
    <item>
      <product_id>1</product_id>
      <quantity>2</quantity>
    </item>
  </items>
  <shipping>
    <street>123 Main St</street>
    <city>Springfield</city>
  </shipping>
</order>
```

## Form Parser

For traditional HTML forms:

```crystal
class CreateOrderFormSchema < Amber::Schema::Definition
  content_type "application/x-www-form-urlencoded"

  # Arrays use bracket notation: item_ids[]=1&item_ids[]=2
  field :item_ids, Array(Int32), repeated: true
  field :item_quantities, Array(Int32), repeated: true

  # Nested objects use bracket notation
  field :shipping_street, String, as: "shipping[street]"
  field :shipping_city, String, as: "shipping[city]"
  field :shipping_zip, String, as: "shipping[zip]"

  validates_to OrderRequest, OrderValidationError

  # Transform flat form data to nested structure
  def transform
    items = item_ids.zip(item_quantities).map do |id, qty|
      OrderItem.new(product_id: id, quantity: qty)
    end

    self.items = items
    self.shipping_address = Address.new(
      street: shipping_street,
      city: shipping_city,
      zip: shipping_zip
    )
  end
end
```

## Multipart Parser

For file uploads:

```crystal
class UploadSchema < Amber::Schema::Definition
  content_type "multipart/form-data"

  field :title, String, required: true
  field :description, String
  field :file, Amber::Schema::UploadedFile, required: true

  # File validation
  validates :file do
    max_size 10.megabytes
    allowed_types ["image/jpeg", "image/png", "application/pdf"]
  end

  validates_to UploadRequest, UploadValidationError
end
```

### Multiple Files

```crystal
class GalleryUploadSchema < Amber::Schema::Definition
  content_type "multipart/form-data"

  field :album_name, String, required: true
  field :images, Array(Amber::Schema::UploadedFile), max_items: 20

  validates :images do
    each do
      max_size 5.megabytes
      allowed_types ["image/jpeg", "image/png", "image/webp"]
    end
  end
end
```

## CSV Parser

For bulk operations:

```crystal
class BulkImportSchema < Amber::Schema::Definition
  content_type "text/csv"

  # Define expected columns
  csv_columns do
    column :email, String, required: true, format: :email
    column :name, String, required: true
    column :role, String, enum: ["admin", "user"]
  end

  # Row validation
  max_rows 1000
  skip_invalid_rows false

  validates_to BulkImportRequest, BulkImportError
end
```

## Multiple Content Types

Support multiple formats for the same endpoint:

```crystal
class CreateUserController < ApplicationController
  # Select schema based on content type
  SCHEMAS = {
    "application/json" => CreateUserJSONSchema,
    "application/xml" => CreateUserXMLSchema,
    "application/x-www-form-urlencoded" => CreateUserFormSchema
  }

  def create
    content_type = request.headers["Content-Type"]
    schema_class = SCHEMAS[content_type]?

    unless schema_class
      return respond_with 415, {error: "Unsupported content type"}.to_json
    end

    case result = schema_class.validate(request)
    when Amber::Schema::Success
      user = User.create!(result.data)
      respond_with 201, user.to_json
    when Amber::Schema::Failure
      respond_with 400, result.error.to_response.to_json
    end
  end
end
```

## Content Negotiation

Automatic schema selection:

```crystal
class UserSchema < Amber::Schema::Definition
  # Define multiple content types
  accepts "application/json", "application/xml", "application/x-www-form-urlencoded"

  field :email, String, required: true
  field :name, String, required: true

  validates_to UserRequest, UserValidationError
end
```

The parser will automatically handle the request based on the `Content-Type` header.
