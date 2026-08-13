---
title: "Build a Pet Tracker"
section: "guides"
order: 5
is_section: true
description: "Build and test a complete Amber V2 app with Grant, Micrate, SQLite, HTML, JSON, ECR, local CSS, and import maps"
---

# Build a Pet Tracker

This is the canonical first Amber V2 application. It uses the same supported
path as the release test:

- SQLite and Grant for real persisted records;
- a reversible Micrate migration;
- typed request validation;
- generated create, read, update, and delete routes;
- ECR pages and a shared form partial;
- one `respond_with` action that serves HTML or JSON;
- local CSS and browser-native JavaScript;
- request specs and a compiled application binary.

## 1. Generate the application

**Run from: the parent directory where `pet_tracker/` should be created.**

```bash
amber new pet_tracker --type web
cd pet_tracker
```

The default is SQLite. `shard.yml` contains Amber, Grant, and
`crystal-sqlite3`; `config/database.cr` registers Grant's `primary` connection;
and the environment YAML files point development and test at separate database
files under `db/`.

## 2. Generate the complete Pet resource

**Run from: the `pet_tracker/` application root beside `shard.yml`.**

```bash
amber generate scaffold Pet name:string:required species:string:required adopted:bool
```

**Generated output: files created by the scaffold plus the updated route file.**

```text
src/models/pet.cr
src/schemas/pet_schema.cr
src/controllers/pet_controller.cr
src/views/pet/index.ecr
src/views/pet/show.ecr
src/views/pet/new.ecr
src/views/pet/edit.ecr
src/views/pet/_form.ecr
spec/models/pet_spec.cr
spec/controllers/pet_controller_spec.cr
db/migrations/<timestamp>_create_pets.sql
config/routes.cr
```

The generator adds `resources "/pets", PetController` inside the existing
`routes :web` block. That one declaration owns the index, show, new, create,
edit, update, and destroy routes.

## 3. Inspect the model and request boundary

**File: `src/models/pet.cr` — generated Grant model.**

```crystal
class Pet < Grant::Base
  connection primary
  table pets

  column id : Int64, primary: true
  column name : String
  column species : String
  column adopted : Bool?

  timestamps
end
```

`name` and `species` are required because their generator arguments ended in
`:required`. `adopted` is nullable while a new form is being built and receives
a database default when omitted.

**File: `src/schemas/pet_schema.cr` — generated request validation.**

```crystal
class PetSchema < Amber::Schema::Definition
  content_type "application/x-www-form-urlencoded"

  field :name, String, required: true
  field :species, String, required: true
  field :adopted, Bool
end
```

Amber CLI `2.0.6` binds that schema automatically above
the generated `create` and `update` actions:

**File: `src/controllers/pet_controller.cr` — generated controller excerpt.**

```crystal
class PetController < ApplicationController
  schema :create, PetSchema
  schema :update, PetSchema

  def create
    schema = validated_as(PetSchema)
    pet = Pet.new
    pet.name = schema.name.not_nil!
    pet.species = schema.species.not_nil!
    pet.adopted = schema.adopted
    # Save and redirect, or render the model failure.
  end
end
```

Amber validates browser input before the action assigns values to the Grant
model. The generated HTML failure hook returns status 422 and re-renders
`src/views/pet/new.ecr` or `src/views/pet/edit.ecr` with `@errors`; it does not
turn the form into a JSON error. This is the released CLI `2.0.6` and framework
`2.0.0-beta.5` path.

Database constraints remain in the migration; request validation does not
replace them.

## 4. Inspect and apply the migration

**File: `db/migrations/<timestamp>_create_pets.sql` — generated reversible SQL.**

```sql
-- +micrate Up
CREATE TABLE IF NOT EXISTS pets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(255) NOT NULL,
  adopted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- +micrate Down
DROP TABLE IF EXISTS pets;
```

**Run from: the application root.**

```bash
amber database migrate
AMBER_ENV=test amber database migrate
amber database status
```

The first command writes `db/pet_tracker_development.db`; the second writes the
isolated test database. Micrate records applied versions in each database, so
running `migrate` again is safe.

## 5. Understand the generated form

**File: `src/views/pet/_form.ecr` — shared by new and edit pages.**

The generated partial chooses the correct action, includes the CSRF token, and
uses method override for an edit:

**File: `src/views/pet/_form.ecr` — generated shared form excerpt.**

```ecr
<form action="<%= @pet.persisted? ? "/pets/#{@pet.id}" : "/pets" %>" method="POST">
  <%= csrf_tag %>
  <% if @pet.persisted? %>
    <%= hidden_field("_method", "PATCH") %>
  <% end %>

  <%= label("name") %>
  <%= text_field("name", value: @pet.name?) %>

  <%= label("species") %>
  <%= text_field("species", value: @pet.species?) %>

  <%= checkbox("adopted", checked: @pet.adopted? || false, value: "true") %>
  <%= label("adopted") %>

  <%= submit_button("Save") %>
</form>
```

The question-mark readers are deliberate: a new model has not received its
required values yet, so the form must be able to read `nil` without raising.
The controller uses the non-null schema result before saving.

## 6. Serve HTML and JSON from one action

The generated controller renders HTML. Add a JSON representation to the index
without moving rendering logic into the model.

**File: `src/controllers/pet_controller.cr` — replace only the generated
`index` method. Leave `show`, `new`, `create`, `edit`, `update`, and `destroy`
as generated.**

```crystal
def index
  @pets = Pet.all.to_a

  respond_with do
    html { render("index.ecr") }
    json { @pets.to_json }
  end
end
```

The action loads records once. The `html` branch renders
`src/views/pet/index.ecr`; the `json` branch serializes the same Grant records.
The request `Accept` header chooses the representation. Read
[Respond With](../controllers/respond-with/) for negotiation and error cases.

## 7. Give the index the Amber visual language

**File: `src/views/pet/index.ecr` — replace the generated table with this
complete view.**

```ecr
<main class="pet-shell">
  <header class="pet-hero">
    <p class="pet-eyebrow">Pet Tracker · Amber V2</p>
    <h1>Small records.<br><em>Good homes.</em></h1>
    <p>Track the animals moving through the foster network.</p>
    <a class="pet-action" href="/pets/new">Add a pet</a>
  </header>

  <nav class="pet-filters" aria-label="Filter pets">
    <button type="button" data-pet-filter="all" aria-pressed="true">All pets</button>
    <button type="button" data-pet-filter="waiting" aria-pressed="false">Looking for a home</button>
    <button type="button" data-pet-filter="adopted" aria-pressed="false">Adopted</button>
  </nav>

  <section class="pet-grid" aria-label="Pets">
    <% @pets.each do |pet| %>
      <% status = (pet.adopted? || false) ? "adopted" : "waiting" %>
      <article class="pet-card" data-pet-status="<%= status %>">
        <span class="pet-kind"><%= HTML.escape(pet.species) %></span>
        <h2><a href="/pets/<%= pet.id %>"><%= HTML.escape(pet.name) %></a></h2>
        <span class="pet-status"><%= status == "adopted" ? "Adopted" : "Looking for a home" %></span>
        <a href="/pets/<%= pet.id %>/edit">Edit record</a>
      </article>
    <% end %>
  </section>
</main>
```

**File: `app/assets/stylesheets/app.css` — append this component layer after the generated
starter styles.**

```css
.pet-shell {
  width: min(1120px, calc(100% - 40px));
  margin-inline: auto;
  padding-block: clamp(72px, 10vw, 132px);
}

.pet-hero { max-width: 780px; }
.pet-eyebrow,
.pet-kind,
.pet-status {
  color: var(--amber-accent-deep);
  font-size: .72rem;
  font-weight: 850;
  letter-spacing: .12em;
  text-transform: uppercase;
}

.pet-hero h1 {
  margin: 0;
  font-family: ui-serif, Georgia, serif;
  font-size: clamp(4rem, 9vw, 7.5rem);
  letter-spacing: -.055em;
  line-height: .88;
}

.pet-hero h1 em { color: var(--amber-accent); }
.pet-action { display: inline-flex; margin-top: 20px; font-weight: 850; }
.pet-filters { display: flex; flex-wrap: wrap; gap: 8px; margin-block: 40px 22px; }
.pet-filters button {
  padding: 9px 13px;
  border: 1px solid var(--amber-line);
  border-radius: 999px;
  background: #fffdf9;
  color: var(--amber-muted);
  font: inherit;
  font-size: .76rem;
  font-weight: 800;
  cursor: pointer;
}

.pet-filters button[aria-pressed="true"] { border-color: var(--amber-accent); background: var(--amber-accent); color: white; }
.pet-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; }
.pet-card {
  min-height: 250px;
  padding: 28px;
  border: 1px solid var(--amber-line);
  border-radius: 20px;
  background: rgba(255, 253, 249, .82);
  box-shadow: var(--amber-shadow);
}

.pet-card[hidden] { display: none; }
.pet-card h2 { margin: 54px 0 18px; font-family: ui-serif, Georgia, serif; font-size: 2.4rem; }
.pet-card h2 a { text-decoration: none; }
.pet-status { display: flex; margin-bottom: 24px; }

@media (max-width: 780px) {
  .pet-grid { grid-template-columns: 1fr; }
  .pet-card { min-height: 0; }
}
```

This reuses the generated application's warm paper, amber accents, compact
labels, editorial scale, and card geometry. It does not copy the framework
website's character art or require an external design library.

## 8. Add browser-native filtering

**File: `app/assets/javascript/app.js` — replace the starter module with this behavior.**

```javascript
document.querySelectorAll("[data-pet-filter]").forEach((button) => {
  button.addEventListener("click", () => {
    const filter = button.dataset.petFilter;

    document.querySelectorAll("[data-pet-filter]").forEach((candidate) => {
      candidate.setAttribute("aria-pressed", String(candidate === button));
    });

    document.querySelectorAll("[data-pet-status]").forEach((card) => {
      card.hidden = filter !== "all" && card.dataset.petStatus !== filter;
    });
  });
});
```

The generated import map already loads this file as the `app` module. Filtering
is progressive enhancement: the records and links remain usable without
JavaScript.

## 9. Test HTML, JSON, and persistence

**File: `spec/controllers/pet_controller_spec.cr` — add this example inside
the generated `describe PetController` block.**

```crystal
describe "GET /pets as JSON" do
  it "returns the persisted collection" do
    headers = HTTP::Headers{"Accept" => "application/json"}
    response = get("/pets", headers: headers)

    assert_response_success(response)
    response.headers["Content-Type"].should contain("application/json")
    response.body.should eq("[]")
  end
end
```

**Run from: the application root.**

```bash
AMBER_ENV=test amber database migrate
amber assets build
amber assets check
crystal spec
crystal build src/pet_tracker.cr -o bin/pet_tracker
amber watch
```

Open <http://127.0.0.1:3000/pets/new>, create a Pet, open its detail page, edit
it, and return to the filtered index. Then request the second representation:

**Run from: another terminal while `amber watch` is running.**

```bash
curl -H 'Accept: application/json' http://127.0.0.1:3000/pets
```

Amber CLI's candidate release test automates this same database path: generate the Pet
scaffold, migrate development and test, run the generated specs, build and boot
the application, prove invalid input returns an HTML 422 with field errors,
create a valid Pet through the ECR form, edit it through `_method=PATCH`, and
read the updated record back.

## Where to go next

- [Web Template](../web-template/) explains every generated baseline file.
- [Grant models](../models/grant/) covers queries, validations, associations,
  callbacks, transactions, and security.
- [Migrations](../models/grant/migrations/) covers authored Micrate changes and
  release-safe database workflows.
- [Views](../views/) expands the controller, ECR, partial, and layout boundary.
- [Import Maps](../assets/import-maps/) shows how to split local browser code.
- [Beta Support](../../beta-support/) separates the supported web path from
  authentication, API-resource, Gemma, and native previews.
