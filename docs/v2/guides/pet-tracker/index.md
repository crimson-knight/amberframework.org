---
title: "Build a Pet Tracker"
section: "guides"
order: 5
is_section: true
description: "Build and test a complete Amber V2 app with HTML, JSON, ECR, local CSS, and browser-native JavaScript"
---

# Build a Pet Tracker

This is the first complete Amber V2 application guide. It starts from the clean
web template and builds one small feature all the way through:

- typed Crystal records and an in-memory catalog;
- routes and one controller with HTML and JSON representations;
- ECR list and detail views;
- local CSS that carries Amber's warm, faceted visual language;
- local JavaScript loaded through the generated import map;
- request specs and a native application build.

The catalog is intentionally in memory. That keeps the tutorial inside the
release-gated web core while persistence integrations remain preview surfaces.

## 1. Generate the application

**Run from: the parent directory where `pet_tracker/` should be created.**

```bash
amber new pet_tracker
cd pet_tracker
```

Keep the generated layout and import map. The steps below replace the `/` route
and add application-owned files around that working baseline.

## 2. Define the record

**File: `src/models/pet.cr` — create this complete file.**

```crystal
struct Pet
  include JSON::Serializable

  getter slug : String
  getter name : String
  getter kind : String
  getter status : String
  getter note : String

  def initialize(@slug, @name, @kind, @status, @note)
  end
end
```

`JSON::Serializable` gives the same typed record an explicit JSON
representation. The ECR views will read the getters directly.

## 3. Add a small catalog

**File: `src/models/pet_catalog.cr` — create this complete file.**

```crystal
module PetCatalog
  PETS = [
    Pet.new("miso", "Miso", "Cat", "Available", "Window-seat specialist"),
    Pet.new("juniper", "Juniper", "Dog", "Fostered", "Trail-tested optimist"),
    Pet.new("pixel", "Pixel", "Rabbit", "Available", "Quiet keyboard companion"),
  ]

  def self.all : Array(Pet)
    PETS
  end

  def self.find(slug : String) : Pet?
    PETS.find { |pet| pet.slug == slug }
  end
end
```

This is the tutorial's temporary data boundary. A future database-backed app
can replace `PetCatalog` without moving rendering or route decisions into the
model.

## 4. Negotiate HTML and JSON

**File: `src/controllers/pets_controller.cr` — create this complete file.**

```crystal
class PetsController < ApplicationController
  def index
    pets = PetCatalog.all

    respond_with do
      html { render("index.ecr") }
      json { pets.to_json }
    end
  end

  def show
    pet = PetCatalog.find(params["slug"])
    unless pet
      return set_response(
        body: "Pet not found",
        status_code: 404,
        content_type: "text/plain"
      )
    end

    respond_with do
      html { render("show.ecr") }
      json { pet.to_json }
    end
  end
end
```

Each action loads its resource once. `respond_with` then states which public
representations exist. Read [Respond With](../controllers/respond-with/) for
content negotiation details.

## 5. Register the routes

**File: `config/routes.cr` — replace the generated `routes :web` block. Leave
the generated pipelines and `routes :static` block in place.**

```crystal
routes :web do
  get "/", PetsController, :index
  get "/pets", PetsController, :index
  get "/pets/:slug", PetsController, :show
end
```

The dynamic `:slug` segment is available as `params["slug"]` inside `show`.

## 6. Create the ECR views

**File: `src/views/pets/index.ecr` — create this complete list view.**

```ecr
<main class="pet-shell">
  <header class="pet-hero">
    <p class="pet-eyebrow">Pet Tracker · Amber V2</p>
    <h1>Small records.<br><em>Good homes.</em></h1>
    <p>Meet the animals currently moving through our foster network.</p>
  </header>

  <nav class="pet-filters" aria-label="Filter pets">
    <button type="button" data-pet-filter="all" aria-pressed="true">All pets</button>
    <button type="button" data-pet-filter="available" aria-pressed="false">Available</button>
    <button type="button" data-pet-filter="fostered" aria-pressed="false">Fostered</button>
  </nav>

  <section class="pet-grid" aria-label="Pets">
    <% pets.each do |pet| %>
      <article class="pet-card" data-pet-status="<%= escape_html(pet.status.downcase) %>">
        <span class="pet-kind"><%= escape_html(pet.kind) %></span>
        <h2><a href="/pets/<%= escape_html(pet.slug) %>"><%= escape_html(pet.name) %></a></h2>
        <p><%= escape_html(pet.note) %></p>
        <span class="pet-status"><%= escape_html(pet.status) %></span>
      </article>
    <% end %>
  </section>
</main>
```

The template owns HTML and escapes every value at the output boundary. The
controller only coordinates data and representations.

**File: `src/views/pets/show.ecr` — create this complete detail view.**

```ecr
<main class="pet-shell pet-detail">
  <a class="pet-back" href="/pets">← All pets</a>
  <p class="pet-eyebrow"><%= escape_html(pet.kind) %> · <%= escape_html(pet.status) %></p>
  <h1><%= escape_html(pet.name) %></h1>
  <p><%= escape_html(pet.note) %></p>
</main>
```

No layout change is required. The generated
`src/views/layouts/application.ecr` already loads `/css/app.css`, maps the
stable module name `app` to `/js/app.js`, and inserts the action template as
`content`.

## 7. Carry the visual language into the app

The website's visual language is a starting vocabulary, not a requirement to
copy its identity. This layer reuses warm paper, amber accents, compact status
labels, editorial type scale, and soft card geometry from the generated
starter.

**File: `public/css/app.css` — append this component layer after the generated
starter styles.**

```css
.pet-shell {
  width: min(1120px, calc(100% - 40px));
  margin-inline: auto;
  padding-block: clamp(72px, 10vw, 132px);
}

.pet-hero { max-width: 760px; }
.pet-eyebrow {
  color: var(--amber-accent-deep);
  font-size: .72rem;
  font-weight: 850;
  letter-spacing: .15em;
  text-transform: uppercase;
}

.pet-hero h1,
.pet-detail h1 {
  margin: 0;
  font-family: ui-serif, Georgia, serif;
  font-size: clamp(4rem, 9vw, 7.5rem);
  letter-spacing: -.055em;
  line-height: .88;
}

.pet-hero h1 em { color: var(--amber-accent); }
.pet-hero > p:last-child { max-width: 42rem; color: var(--amber-muted); font-size: 1.08rem; }
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
  min-height: 270px;
  padding: 28px;
  border: 1px solid var(--amber-line);
  border-radius: 20px;
  background: rgba(255, 253, 249, .82);
  box-shadow: var(--amber-shadow);
}

.pet-card[hidden] { display: none; }
.pet-kind, .pet-status { color: var(--amber-accent-deep); font-size: .68rem; font-weight: 850; letter-spacing: .1em; text-transform: uppercase; }
.pet-card h2 { margin: 54px 0 8px; font-family: ui-serif, Georgia, serif; font-size: 2.4rem; }
.pet-card h2 a { text-decoration: none; }
.pet-card p { min-height: 3rem; color: var(--amber-muted); }
.pet-status { display: inline-flex; margin-top: 18px; padding: 6px 9px; border: 1px solid var(--amber-line); border-radius: 999px; }
.pet-back { color: var(--amber-accent-deep); font-weight: 800; text-decoration: none; }
.pet-detail .pet-eyebrow { margin-top: 80px; }

@media (max-width: 780px) {
  .pet-grid { grid-template-columns: 1fr; }
  .pet-card { min-height: 0; }
}
```

Everything is local. There is no hosted font, CSS framework, JavaScript
package, Node.js process, or build step.

## 8. Add browser behavior

**File: `public/js/app.js` — replace the generated starter module with this
complete filter behavior.**

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

The generated import map already loads this file as the `app` module. The
filter is progressive enhancement: all pet links and content remain available
when JavaScript is disabled.

## 9. Test the public contract

**File: `spec/controllers/pets_controller_spec.cr` — create this complete
request spec.**

```crystal
require "../spec_helper"

describe PetsController do
  it "renders the pet list as HTML" do
    response = get("/pets")
    assert_response_success(response)
    response.body.should contain("Small records")
    response.body.should contain("Miso")
  end

  it "returns the same pets as JSON" do
    headers = HTTP::Headers{"Accept" => "application/json"}
    response = get("/pets", headers: headers)
    assert_response_success(response)
    response.headers["Content-Type"].should contain("application/json")
    response.body.should contain(%("slug":"miso"))
  end

  it "returns 404 for an unknown pet" do
    get("/pets/not-here").status_code.should eq(404)
  end
end
```

Keep the generated `spec/controllers/home_controller_spec.cr`. Its `/` request
now verifies the second route into `PetsController#index`.

**Run from: the `pet_tracker/` application root.**

```bash
shards install
crystal spec
crystal build src/pet_tracker.cr -o bin/pet_tracker
amber watch
```

Open `http://127.0.0.1:3000/`, filter the cards, follow a pet link, then request
the negotiated JSON representation:

**Run from: any terminal while `amber watch` is running.**

```bash
curl -H 'Accept: application/json' http://127.0.0.1:3000/pets
curl -H 'Accept: application/json' http://127.0.0.1:3000/pets/miso
```

The published guide was checked against a clean Amber CLI 2.0.3 web scaffold:
all four request examples passed and the application compiled successfully.

## Where to go next

- [Web Template](../web-template/) explains every generated baseline file.
- [Views](../views/) expands the controller, ECR, partial, and layout boundary.
- [Import Maps](../assets/import-maps/) shows how to split browser behavior into
  more local modules.
- [Beta Support](../../beta-support/) separates release-gated web core from
  preview persistence and native surfaces.
