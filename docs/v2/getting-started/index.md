---
title: "Getting Started"
section: ""
order: 20
is_section: true
description: "Build your first Amber V2 application from scratch"
---

# Getting Started

## Quick Start

This guide will help you build a full-stack web application from scratch using Amber V2's new features:

- **Grant ORM** - ActiveRecord-style database models
- **Schema API** - Type-safe request validation with OpenAPI generation
- **Asset Pipeline** - Native ESM modules without Webpack

We'll build the same Pet Tracker app from the V1 tutorial, but using V2's modern approach.

**What's different from V1?**

| Amber V1 | Amber V2 |
|----------|----------|
| `amber new pet-tracker` | Create project manually |
| `amber g scaffold Pet` | Create model/controller manually |
| Granite ORM | Grant ORM |
| Raw params hash | Schema API validation |
| Webpack + npm | Asset Pipeline (native ESM) |

Let's get started!

## Step 1: Create Project Structure

First, create a new directory for your application:

```bash
mkdir pet-tracker
cd pet-tracker
```

Create the `shard.yml` file with your dependencies:

```yaml
name: pet-tracker
version: 0.1.0
crystal: ">= 1.10.0"

dependencies:
  amber:
    github: crimson-knight/amber
    branch: master
  grant:
    github: crimson-knight/grant
    branch: main
  asset_pipeline:
    github: amberframework/asset_pipeline
  pg:
    github: will/crystal-pg
  mysql:
    github: crystal-lang/crystal-mysql
  sqlite3:
    github: crystal-lang/crystal-sqlite3

targets:
  pet-tracker:
    main: src/pet-tracker.cr
```

> **Note:** The mysql and sqlite3 dependencies are required because Grant supports multiple database adapters and references them at compile time.

Install the dependencies:

```bash
shards install
```

## Step 2: Create Directory Structure

Create the V2 application structure:

```bash
mkdir -p config
mkdir -p src/controllers
mkdir -p src/models
mkdir -p src/schemas
mkdir -p src/views/layouts
mkdir -p src/views/pets
mkdir -p src/views/home
mkdir -p src/javascript/controllers
mkdir -p public/javascript
mkdir -p public/css
mkdir -p db/migrations
```

Your project should now look like this:

```
pet-tracker/
├── config/
├── db/
│   └── migrations/
├── public/
│   ├── css/
│   └── javascript/
├── src/
│   ├── controllers/
│   ├── javascript/
│   │   └── controllers/
│   ├── models/
│   ├── schemas/
│   └── views/
│       ├── home/
│       ├── layouts/
│       └── pets/
├── lib/
└── shard.yml
```

## Step 3: Create the Application Entry Point

Create `src/pet-tracker.cr`:

```crystal
# src/pet-tracker.cr
require "amber"
require "grant"
require "grant/adapter/pg"
require "grant/adapter/mysql"
require "grant/adapter/sqlite"
require "asset_pipeline"
require "pg"

# Load configuration
require "../config/database"
require "../config/routes"

# Load application code
require "./models/*"
require "./schemas/*"
require "./controllers/*"

# Configure and start the server
Amber::Server.configure do
  name = "Pet Tracker"
  host = "0.0.0.0"
  port = 3000
end

Amber::Server.start
```

> **Note:** All three Grant adapters (pg, mysql, sqlite) must be required because Grant's internal code references them at compile time, even if you only use PostgreSQL.

## Step 4: Configure the Database

Create `config/database.cr`:

```crystal
# config/database.cr
Grant::ConnectionRegistry.establish_connection(
  database: "primary",
  adapter: Grant::Adapter::Pg,
  url: ENV["DATABASE_URL"]? || "postgres://localhost/pet_tracker_development"
)
```

Create the database:

```bash
createdb pet_tracker_development
```

## Step 5: Create the Pet Model

Create `src/models/pet.cr` using Grant ORM:

```crystal
# src/models/pet.cr
class Pet < Grant::Base
  table "pets"

  column id : Int64, primary: true
  column name : String
  column breed : String
  column age : Int32
  column created_at : Time?
  column updated_at : Time?
end
```

> **Note:** Grant uses `table "name"` (not `self.table_name`), and `primary: true` for the primary key column. The `auto_increment` option is not needed - it's handled automatically by the database.

Create the database migration. Create `db/migrations/001_create_pets.sql`:

```sql
-- db/migrations/001_create_pets.sql
CREATE TABLE pets (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  breed VARCHAR(255) NOT NULL,
  age INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Run the migration:

```bash
psql pet_tracker_development < db/migrations/001_create_pets.sql
```

## Step 6: Create Schema Definitions

Create `src/schemas/pet_schemas.cr` for type-safe request validation:

```crystal
# src/schemas/pet_schemas.cr
require "amber/schema"

class CreatePetSchema < Amber::Schema::Definition
  field :name, String, required: true
  field :breed, String, required: true
  field :age, Int32, required: true
end

class UpdatePetSchema < Amber::Schema::Definition
  field :name, String
  field :breed, String
  field :age, Int32
end
```

## Step 7: Create the Application Controller

Create `src/controllers/application_controller.cr`:

```crystal
# src/controllers/application_controller.cr
class ApplicationController < Amber::Controller::Base
  LAYOUT = "application.slang"
end
```

## Step 8: Create the Pets Controller

Create `src/controllers/pets_controller.cr`:

```crystal
# src/controllers/pets_controller.cr
class PetsController < ApplicationController
  # Type annotations required for Crystal's type inference
  @pets : Array(Pet) | Grant::Collection(Pet) | Nil
  @pet : Pet?
  @errors : Array(String)?

  def index
    @pets = Pet.all
    render "pets/index.slang"
  end

  def show
    @pet = Pet.find!(params["id"].to_i64)
    render "pets/show.slang"
  end

  def new
    @pet = Pet.new
    @errors = [] of String
    render "pets/new.slang"
  end

  def create
    # Convert params to Hash(String, JSON::Any) for Schema API
    params_hash = {} of String => JSON::Any
    params.to_h.each do |k, v|
      params_hash[k] = JSON::Any.new(v.to_s)
    end

    schema = CreatePetSchema.new(params_hash)
    result = schema.validate

    if result.success?
      data = result.data.not_nil!
      @pet = Pet.new
      @pet.not_nil!.name = data["name"].as_s
      @pet.not_nil!.breed = data["breed"].as_s
      @pet.not_nil!.age = data["age"].as_s.to_i

      if @pet.not_nil!.save
        flash[:success] = "Pet created successfully!"
        redirect_to "/pets/#{@pet.not_nil!.id}"
      else
        @errors = ["Failed to save pet"]
        render "pets/new.slang"
      end
    else
      @pet = Pet.new
      @errors = result.errors.map { |e| e.message }.compact
      render "pets/new.slang"
    end
  end

  def edit
    @pet = Pet.find!(params["id"].to_i64)
    @errors = [] of String
    render "pets/edit.slang"
  end

  def update
    @pet = Pet.find!(params["id"].to_i64)
    pet = @pet.not_nil!

    # Convert params to Hash(String, JSON::Any) for Schema API
    params_hash = {} of String => JSON::Any
    params.to_h.each do |k, v|
      params_hash[k] = JSON::Any.new(v.to_s)
    end

    schema = UpdatePetSchema.new(params_hash)
    result = schema.validate

    if result.success?
      data = result.data.not_nil!
      pet.name = data["name"]?.try(&.as_s) || pet.name
      pet.breed = data["breed"]?.try(&.as_s) || pet.breed
      pet.age = data["age"]?.try(&.as_s.to_i) || pet.age

      if pet.save
        flash[:success] = "Pet updated successfully!"
        redirect_to "/pets/#{pet.id}"
      else
        @errors = ["Failed to update pet"]
        render "pets/edit.slang"
      end
    else
      @errors = result.errors.map { |e| e.message }.compact
      render "pets/edit.slang"
    end
  end

  def destroy
    @pet = Pet.find!(params["id"].to_i64)
    @pet.not_nil!.destroy
    flash[:success] = "Pet deleted successfully!"
    redirect_to "/pets"
  end
end
```

> **Important Notes:**
> - Type annotations (`@pets`, `@pet`, `@errors`) are required for Crystal's type inference
> - The Schema API expects `Hash(String, JSON::Any)` - you must convert params
> - Use `schema.validate` which returns a result object, then check `result.success?`
> - Access validated data with `result.data.not_nil!`
> - Use `.as_s` to convert `JSON::Any` to `String`, and `.as_s.to_i` for integers

## Step 9: Create the Home Controller

Create `src/controllers/home_controller.cr`:

```crystal
# src/controllers/home_controller.cr
class HomeController < ApplicationController
  def index
    render "home/index.slang"
  end
end
```

Create `src/views/home/index.slang`:

```slang
h1 Welcome to Pet Tracker
p Track your pets with Amber V2!

.actions
  a.btn.btn-primary href="/pets" View All Pets
  a.btn.btn-secondary href="/pets/new" Add New Pet
```

## Step 10: Configure Routes

Create `config/routes.cr`:

```crystal
# config/routes.cr
Amber::Server.configure do
  routes :web do
    # Home
    get "/", HomeController, :index

    # Pets resource
    get "/pets", PetsController, :index
    get "/pets/new", PetsController, :new
    post "/pets", PetsController, :create
    get "/pets/:id", PetsController, :show
    get "/pets/:id/edit", PetsController, :edit
    patch "/pets/:id", PetsController, :update
    put "/pets/:id", PetsController, :update
    delete "/pets/:id", PetsController, :destroy
  end
end
```

> **Note:** The `Amber::Server.configure` block does not take a block parameter - use `do` without `|app|`.

## Step 11: Create Views

### Layout Template

Create `src/views/layouts/application.slang`:

```slang
doctype html
html
  head
    meta charset="utf-8"
    meta name="viewport" content="width=device-width, initial-scale=1"
    title Pet Tracker - Amber V2
    link rel="stylesheet" href="/css/application.css"
  body
    nav.navbar
      .container
        a.navbar-brand href="/" Pet Tracker
        ul.nav
          li
            a href="/pets" Pets
          li
            a href="/pets/new" New Pet

    main.container
      - if flash[:success]?
        .alert.alert-success = flash[:success]
      - if flash[:error]?
        .alert.alert-danger = flash[:error]

      == content

    footer.footer
      .container
        p Built with Amber V2
```

### Pet Views

Create `src/views/pets/index.slang`:

```slang
h1 All Pets

a.btn.btn-primary href="/pets/new" Add New Pet

- if @pets.not_nil!.empty?
  p.empty-state No pets yet. Add your first pet!
- else
  table.table
    thead
      tr
        th Name
        th Breed
        th Age
        th Actions
    tbody
      - @pets.not_nil!.each do |pet|
        tr
          td = pet.name
          td = pet.breed
          td = "#{pet.age} years"
          td.actions
            a.btn.btn-sm href="/pets/#{pet.id}" View
            a.btn.btn-sm href="/pets/#{pet.id}/edit" Edit
            form method="post" action="/pets/#{pet.id}" style="display:inline"
              input type="hidden" name="_method" value="delete"
              button.btn.btn-sm.btn-danger type="submit" Delete
```

Create `src/views/pets/show.slang`:

```slang
- pet = @pet.not_nil!
h1 = pet.name

.pet-details
  dl
    dt Name
    dd = pet.name

    dt Breed
    dd = pet.breed

    dt Age
    dd = "#{pet.age} years old"

.actions
  a.btn href="/pets" Back to List
  a.btn.btn-primary href="/pets/#{pet.id}/edit" Edit
```

Create `src/views/pets/new.slang`:

```slang
h1 New Pet

- unless @errors.not_nil!.empty?
  .alert.alert-danger
    ul
      - @errors.not_nil!.each do |error|
        li = error

form method="post" action="/pets"
  .form-group
    label for="name" Name
    input.form-control type="text" name="name" id="name" required="required"

  .form-group
    label for="breed" Breed
    input.form-control type="text" name="breed" id="breed" required="required"

  .form-group
    label for="age" Age
    input.form-control type="number" name="age" id="age" min="1" max="50" required="required"

  .form-actions
    a.btn href="/pets" Cancel
    button.btn.btn-primary type="submit" Create Pet
```

Create `src/views/pets/edit.slang`:

```slang
- pet = @pet.not_nil!
h1 Edit #{pet.name}

- unless @errors.not_nil!.empty?
  .alert.alert-danger
    ul
      - @errors.not_nil!.each do |error|
        li = error

form method="post" action="/pets/#{pet.id}"
  input type="hidden" name="_method" value="patch"

  .form-group
    label for="name" Name
    input.form-control type="text" name="name" id="name" value="#{pet.name}" required="required"

  .form-group
    label for="breed" Breed
    input.form-control type="text" name="breed" id="breed" value="#{pet.breed}" required="required"

  .form-group
    label for="age" Age
    input.form-control type="number" name="age" id="age" value="#{pet.age}" min="1" max="50" required="required"

  .form-actions
    a.btn href="/pets/#{pet.id}" Cancel
    button.btn.btn-primary type="submit" Update Pet
```

> **Note:** Crystal requires nil-safety. Use `.not_nil!` when accessing instance variables that could be nil in views.

## Step 12: Add Basic Styles

Create `public/css/application.css`:

```css
/* public/css/application.css */
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.6;
  color: #333;
  background: #f5f5f5;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* Navigation */
.navbar {
  background: #2c3e50;
  padding: 1rem 0;
  margin-bottom: 2rem;
}

.navbar .container {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.navbar-brand {
  color: white;
  text-decoration: none;
  font-size: 1.5rem;
  font-weight: bold;
}

.nav {
  list-style: none;
  display: flex;
  gap: 1rem;
}

.nav a {
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
}

.nav a:hover {
  color: white;
}

/* Main Content */
main {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  margin-bottom: 2rem;
}

h1 {
  margin-bottom: 1.5rem;
  color: #2c3e50;
}

/* Buttons */
.btn {
  display: inline-block;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  text-decoration: none;
  cursor: pointer;
  font-size: 1rem;
  background: #ecf0f1;
  color: #333;
  margin-right: 0.5rem;
}

.btn:hover {
  background: #bdc3c7;
}

.btn-primary {
  background: #3498db;
  color: white;
}

.btn-primary:hover {
  background: #2980b9;
}

.btn-secondary {
  background: #95a5a6;
  color: white;
}

.btn-danger {
  background: #e74c3c;
  color: white;
}

.btn-danger:hover {
  background: #c0392b;
}

.btn-sm {
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
}

/* Tables */
.table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.5rem 0;
}

.table th,
.table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid #ecf0f1;
}

.table th {
  background: #f8f9fa;
  font-weight: 600;
}

.table tbody tr:hover {
  background: #f8f9fa;
}

/* Forms */
.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-control {
  width: 100%;
  padding: 0.5rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.form-control:focus {
  outline: none;
  border-color: #3498db;
  box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
}

.form-actions {
  margin-top: 1.5rem;
}

/* Alerts */
.alert {
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1rem;
}

.alert-success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.alert-danger {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.alert ul {
  margin-left: 1rem;
}

/* Pet Details */
.pet-details {
  margin: 1.5rem 0;
}

.pet-details dl {
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 0.5rem;
}

.pet-details dt {
  font-weight: 600;
  color: #666;
}

.pet-details dd {
  margin: 0;
}

/* Empty State */
.empty-state {
  text-align: center;
  color: #666;
  padding: 2rem;
}

/* Footer */
.footer {
  text-align: center;
  padding: 1rem 0;
  color: #666;
}

/* Actions */
.actions {
  margin-top: 1rem;
}

td.actions form {
  display: inline;
}
```

## Step 13: Build and Run

Compile the application:

```bash
crystal build src/pet-tracker.cr -o pet-tracker
```

Run the application:

```bash
./pet-tracker
```

Visit [http://localhost:3000](http://localhost:3000) to see your Pet Tracker!

## Summary

You've just built a complete Amber V2 application with:

1. **Manual project setup** - No CLI generators needed
2. **Grant ORM** - ActiveRecord-style models
3. **Schema API** - Type-safe request validation
4. **RESTful routes** - Full CRUD operations
5. **Slang templates** - Clean, concise views

## Key API Differences from V1

| Component | V1 API | V2 API |
|-----------|--------|--------|
| Server config | `Amber::Server.configure do \|app\|` | `Amber::Server.configure do` |
| Routes | `app.routes :web do` | `routes :web do` |
| ORM table | `self.table_name = "pets"` | `table "pets"` |
| Database | `Granite::Connections <<` | `Grant::ConnectionRegistry.establish_connection` |
| Schema validation | `schema.valid?` | `schema.validate.success?` |

## What We Built

| V1 Command | V2 Equivalent |
|------------|---------------|
| `amber new pet-tracker` | Manual `shard.yml` + directory structure |
| `amber g scaffold Pet` | Manual model, controller, views, schemas |
| `amber db create migrate` | `createdb` + SQL migrations |
| `amber watch` | `crystal build` + `./pet-tracker` |

## Next Steps

Now that you have a working application, explore these V2 features:

- **[Asset Pipeline](../guides/assets/)** - Add Stimulus.js for interactivity
- **[Grant ORM](../guides/models/grant/)** - Associations, scopes, callbacks
- **[Schema API](../guides/schema-api/)** - OpenAPI spec generation
- **[Gemma](../guides/uploads/)** - File attachments and uploads
- **[Adapters](../guides/adapters/)** - Configure sessions and WebSocket pub/sub

## Complete Commands Summary

Here's a summary of all commands used in this tutorial:

```bash
# Create project
mkdir pet-tracker && cd pet-tracker

# Create shard.yml (see Step 1)
# Then install dependencies
shards install

# Create directory structure
mkdir -p config
mkdir -p src/{controllers,models,schemas}
mkdir -p src/views/{layouts,pets,home}
mkdir -p src/javascript/controllers
mkdir -p public/{javascript,css}
mkdir -p db/migrations

# Create database
createdb pet_tracker_development

# Run migration
psql pet_tracker_development < db/migrations/001_create_pets.sql

# Build and run
crystal build src/pet-tracker.cr -o pet-tracker
./pet-tracker
```
