---
title: "Images, brand, and color"
section: "guides/pet-tracker-everywhere"
order: 70
description: "Use the portraits, iOS and Android image catalogs, and complete responsive CSS generated with Pet Tracker"
---

# Images, brand, and color

> **Preview — planned work, not a released workflow.** Amber `2.0.0-beta.5` and `amber_cli` `2.0.6` support the web path in [Build a Pet Tracker](../pet-tracker/), but not the commands described here. This preview template pins pre-release Amber `2.0.0-beta.2+ab90eae910a4` at commit `ab90eae910a4bd3a74f3f52ba8dfe238817994c3` and `asset_pipeline` at commit `2aa345bb8f6254554775634d07053cbed09ffe91`; it is outside the [supported beta path](../../beta-support.md). Nothing on this page is a runnable public workflow.

The beta.3 preview template brought the pets with it. Mochi, Rocky, and Pip
appeared in the web source tree, the public web tree, and the iOS and Android
image catalogs. The evaluation changed their artwork without rewriting the
shared screen.

**Asset URL note:** The Markdown renderer cannot call ECR's `asset_path`
helper. The image links below use the generated fingerprinted URLs from the
static asset manifest. Rebuild assets and update these URLs when a source
image changes; an unhashed source path is not served by this asset pipeline.

## Where the examples go

The preview template `0.1.0-beta.3` generated these paths:

```text
app/assets/images/pets/                 editable portrait sources
app/assets/stylesheets/pet-tracker.css  editable responsive web style
public/assets/pets/                     web-ready portrait copies
public/assets/pet-tracker.css           web-ready stylesheet copy
config/android_assets.yml               native logical-name mapping
mobile/ios/Assets.xcassets/             generated iOS image sets
src/views/pet/pet_tracker_screen.cr     shared image choice and semantics
```

The `app/assets` files are your authored sources. This beta bundle also ships
matching `public/assets` copies so the first generated web app runs immediately.
When you add a fingerprinting build to your application, keep the authored
sources and let that build produce the public files.

## Keep Amber’s identity intact

Amber’s checked-in primary character mark remains the Amber identity above the
sample. The orange paw belongs to Pet Tracker inside its own screen. Treat it as
sample-app artwork, not as a replacement Amber logo.

## Meet the generated pets

<div class="pet-artwork-grid">
  <figure>
    <a href="/assets/images/guides/pet-tracker/animals/mochi-cat-8cad23e7372629336ebdae208ff4574f.webp" download="mochi-cat.webp"><img src="/assets/images/guides/pet-tracker/animals/mochi-cat-8cad23e7372629336ebdae208ff4574f.webp" alt="Mochi, a smiling orange-and-white cat with a teal collar" loading="lazy"></a>
    <figcaption><strong>Mochi</strong><span>Cat · transparent WebP</span></figcaption>
  </figure>
  <figure>
    <a href="/assets/images/guides/pet-tracker/animals/rocky-dog-5ad177f936dfdb4434f816b22a55d192.webp" download="rocky-dog.webp"><img src="/assets/images/guides/pet-tracker/animals/rocky-dog-5ad177f936dfdb4434f816b22a55d192.webp" alt="Rocky, a happy golden dog with a teal collar" loading="lazy"></a>
    <figcaption><strong>Rocky</strong><span>Dog · transparent WebP</span></figcaption>
  </figure>
  <figure>
    <a href="/assets/images/guides/pet-tracker/animals/pip-rabbit-b785d65a90c0319564b59956f51cac9e.webp" download="pip-rabbit.webp"><img src="/assets/images/guides/pet-tracker/animals/pip-rabbit-b785d65a90c0319564b59956f51cac9e.webp" alt="Pip, a gentle brown-and-white rabbit" loading="lazy"></a>
    <figcaption><strong>Pip</strong><span>Rabbit · transparent WebP</span></figcaption>
  </figure>
</div>

Generation installs those same portraits here:

```text
app/assets/images/pets/mochi-cat.webp
app/assets/images/pets/rocky-dog.webp
app/assets/images/pets/pip-rabbit.webp
app/assets/images/pets/paw-mark.webp

public/assets/pets/mochi-cat.webp
public/assets/pets/rocky-dog.webp
public/assets/pets/pip-rabbit.webp
public/assets/pets/paw-mark.webp
```

The download links are handy when you adapt an existing app. You do not need to
download the portraits again after generating Pet Tracker.

## Choose one image identity in the shared screen

The preview `PetTrackerScreen` chooses a web URL or native logical name at
the last responsible moment. `PetSummary` remains ordinary product data; it
does not know about browsers, Android resources, or asset catalogs.

**File: `src/views/pet/pet_tracker_screen.cr`.**

```crystal
private def image_source(context : UI::ScreenContext, species : String) : String
  slug = case species.downcase
         when "cat"    then "mochi-cat"
         when "dog"    then "rocky-dog"
         when "rabbit" then "pip-rabbit"
         else               return ""
         end
  return "/assets/pets/#{slug}.webp" if web?(context)
  context.platform == :android ? "pet-tracker/#{slug}" : "pet-tracker-#{slug}"
end
```

The card uses that result and keeps its accessibility meaning beside it:

```crystal
image = UI::Image.new(image_source(context, pet.species))
image.content_mode = UI::ContentMode::Fit
image.minimum_width = image.maximum_width = 72.0
image.minimum_height = image.maximum_height = 72.0
image.accessibility_label = "Portrait of #{pet.name}, #{pet.species}"
image.test_id = "pet-avatar-#{pet.id}"
```

On web, the URL points at `public/assets/pets`. Android resolves the
`pet-tracker/...` identity through its generated catalog. iOS resolves the
hyphenated identity through `Assets.xcassets`.

## Package the portraits for Android

**File: `config/android_assets.yml`.**

```yaml
schema_version: 1
images:
  pet-tracker/paw-mark:
    source: app/assets/images/pets/paw-mark.webp
    density: nodpi
  pet-tracker/mochi-cat:
    source: app/assets/images/pets/mochi-cat.webp
    density: nodpi
  pet-tracker/rocky-dog:
    source: app/assets/images/pets/rocky-dog.webp
    density: nodpi
  pet-tracker/pip-rabbit:
    source: app/assets/images/pets/pip-rabbit.webp
    density: nodpi
```

`mobile/android/android.sh build` compiles this catalog into the Android host
and checks that all four image identities are present in the APK and AAB. The
current compiler accepts bounded PNG, JPEG, WebP, and Android VectorDrawable
XML input. The portraits are 1024×1024 WebP files and the paw is 512×512; all
four pass its current size limit.

## Use one color schema

Here is the whole palette once, named for what each color does:

| Role | Value | Use |
|---|---|---|
| cream | `#FFF9EF` | page canvas |
| paper | `#FFFDF9` | cards and form panel |
| orange | `#F47A16` | primary action and product accent |
| orange dark | `#D95B0A` | action contrast and text accent |
| ink | `#211914` | primary text |
| muted | `#76675D` | supporting text |
| line | `#E9D3B9` | borders |
| teal | `#147F80` | adopted status |
| teal soft | `#E2F1EF` | adopted status background |
| waiting | `#A94B0B` | waiting status text |
| waiting soft | `#FFF0D7` | waiting status background |

The web renderer gives the root element the `pet-tracker` class. Component
selectors stay inside that root. The global `html` and `body` rules below are
the deliberate exception: they set the document canvas and remove browser
default margins.

## Copy the complete web stylesheet

If you generated Pet Tracker, this exact file is already at
`app/assets/stylesheets/pet-tracker.css`. If you are adapting an existing app,
copy the whole block and serve its built copy at `/assets/pet-tracker.css`.

```css
html,
body {
  min-height: 100%;
  margin: 0;
}

body {
  background: #fff9ef;
}

.pet-tracker {
  --pet-cream: #fff9ef;
  --pet-paper: #fffdf9;
  --pet-orange: #f47a16;
  --pet-orange-dark: #d95b0a;
  --pet-ink: #211914;
  --pet-muted: #76675d;
  --pet-line: #e9d3b9;
  --pet-teal: #147f80;
  --pet-teal-soft: #e2f1ef;
  --pet-waiting: #a94b0b;
  --pet-waiting-soft: #fff0d7;
  min-height: 100vh;
  box-sizing: border-box;
  padding: 0 clamp(24px, 5vw, 76px);
  overflow-x: hidden;
  background:
    radial-gradient(circle at 7% 4%, rgb(244 122 22 / 9%) 0, transparent 24rem),
    radial-gradient(circle at 94% 12%, rgb(20 127 128 / 6%) 0, transparent 22rem),
    var(--pet-cream);
  color: var(--pet-ink);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.pet-tracker,
.pet-tracker * {
  box-sizing: border-box;
}

.pet-tracker [data-testid="pet-tracker-screen"] {
  display: grid !important;
  width: min(1280px, 100%);
  min-height: 100vh;
  margin-inline: auto;
  padding: 28px 0 0 !important;
  grid-template-columns: minmax(290px, 360px) minmax(0, 1fr);
  grid-template-areas:
    "header header"
    "notice notice"
    "form heading"
    "form pets"
    "kindness pets"
    "footer footer";
  gap: 22px 38px !important;
  align-items: start !important;
  align-content: start;
}

.pet-tracker [data-testid="pet-tracker-screen"] > *,
.pet-tracker [data-testid="pet-tracker-header"] > *,
.pet-tracker [data-testid="new-pet-form"] > *,
.pet-tracker [data-testid="pet-list"] > *,
.pet-tracker [data-testid^="pet-card-content-"] > *,
.pet-tracker [data-testid^="pet-summary-"] > *,
.pet-tracker [data-testid^="pet-copy-"] > * {
  min-width: 0;
  max-width: 100%;
}

.pet-tracker [data-testid="pet-tracker-header"] {
  display: flex !important;
  grid-area: header;
  width: 100%;
  align-items: center !important;
  padding: 0 8px 24px;
  border-bottom: 1px solid var(--pet-line);
}

.pet-tracker [data-testid="pet-brand"] {
  display: flex !important;
  min-width: 0;
  align-items: center !important;
}

.pet-tracker [data-testid="pet-brand-mark"] {
  width: 58px !important;
  min-width: 58px !important;
  max-width: 58px !important;
  height: 58px !important;
  min-height: 58px !important;
  max-height: 58px !important;
  object-fit: contain !important;
}

.pet-tracker [data-testid="pet-title"],
.pet-tracker [data-testid="pets-heading"] {
  font-family: Georgia, "Times New Roman", serif;
  color: var(--pet-ink) !important;
}

.pet-tracker [data-testid="pet-title"] {
  font-size: clamp(2rem, 3vw, 2.65rem) !important;
  line-height: 1 !important;
}

.pet-tracker [data-testid="pet-subtitle"] {
  margin-top: 3px;
  color: var(--pet-muted) !important;
}

.pet-tracker [data-testid="pet-desktop-nav"] {
  display: flex !important;
  align-items: center !important;
  gap: 30px !important;
}

.pet-tracker [data-testid="pet-desktop-nav"] a {
  position: relative;
  padding: 12px 2px;
  color: var(--pet-ink) !important;
  font-weight: 750;
  text-decoration: none;
}

.pet-tracker [data-testid="pet-nav-pets"]::after {
  position: absolute;
  right: 0;
  bottom: 3px;
  left: 0;
  height: 3px;
  border-radius: 999px;
  background: var(--pet-orange);
  content: "";
}

.pet-tracker [data-testid="pet-mobile-menu"] {
  display: none !important;
  width: 46px;
  min-width: 46px;
  padding: 5px !important;
  border: 0 !important;
  background: transparent !important;
  color: var(--pet-ink) !important;
  font-size: 1.55rem;
}

.pet-tracker [data-testid="pet-notice"] {
  grid-area: notice;
  width: 100%;
  padding: 11px 14px;
  border: 1px solid var(--pet-line);
  border-radius: 12px;
  background: rgb(255 253 249 / 90%);
  color: var(--pet-muted) !important;
}

.pet-tracker [data-testid="new-pet-form"] {
  grid-area: form;
  width: 100%;
  padding: 26px;
  border: 1px solid var(--pet-line);
  border-radius: 18px;
  background: rgb(255 253 249 / 94%);
  box-shadow: 0 18px 50px rgb(93 50 20 / 8%);
}

.pet-tracker [data-testid="new-pet-form"] > div > span:first-child {
  display: block;
  margin-bottom: 14px;
  padding: 0 !important;
  color: var(--pet-ink) !important;
  font-family: Georgia, "Times New Roman", serif;
  font-size: 1.85rem !important;
  font-weight: 800 !important;
  line-height: 1.15;
  text-transform: none !important;
}

.pet-tracker .am-form-field {
  display: grid !important;
  width: 100%;
  gap: 8px !important;
  padding: 8px 0 !important;
  border: 0 !important;
  background: transparent !important;
}

.pet-tracker .am-form-field > span {
  min-width: 0 !important;
  color: var(--pet-ink) !important;
  font-weight: 750;
}

.pet-tracker input {
  width: 100%;
  min-width: 0 !important;
  min-height: 54px !important;
  padding: 12px 15px;
  border: 1px solid var(--pet-line);
  border-radius: 10px;
  background: #fff;
  color: var(--pet-ink);
  font: inherit;
}

.pet-tracker [data-testid="pet-species"] {
  padding-right: 42px;
  background-image:
    linear-gradient(45deg, transparent 50%, var(--pet-muted) 50%),
    linear-gradient(135deg, var(--pet-muted) 50%, transparent 50%);
  background-position:
    calc(100% - 19px) 24px,
    calc(100% - 13px) 24px;
  background-repeat: no-repeat;
  background-size: 6px 6px, 6px 6px;
}

.pet-tracker input:focus {
  border-color: var(--pet-orange);
  outline: 0;
  box-shadow: 0 0 0 4px rgb(244 122 22 / 14%);
}

.pet-tracker .am-button {
  min-height: 48px !important;
  padding: 10px 16px;
  border: 1px solid var(--pet-orange);
  border-radius: 10px;
  background: var(--pet-paper);
  color: var(--pet-orange-dark);
  font: inherit;
  font-weight: 800;
  cursor: pointer;
}

.pet-tracker [data-testid="save-pet"] {
  width: 100%;
  min-height: 56px !important;
  background: linear-gradient(135deg, var(--pet-orange), var(--pet-orange-dark));
  color: #fff;
  font-size: 1.04rem;
}

.pet-tracker [data-testid="pets-heading"] {
  grid-area: heading;
  align-self: end;
  padding-top: 7px;
  font-size: clamp(1.9rem, 3vw, 2.35rem) !important;
  line-height: 1.1;
}

.pet-tracker [data-testid="pet-list"] {
  display: grid !important;
  grid-area: pets;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 20px;
  width: 100%;
}

.pet-tracker [data-testid="pet-list"] > [role="listitem"] {
  min-width: 0;
  padding: 0 !important;
}

.pet-tracker [role="group"][data-testid^="pet-card-"] {
  width: 100%;
  min-width: 0;
  max-width: 100%;
  height: 100%;
  overflow: hidden;
  border: 1px solid var(--pet-line);
  border-radius: 16px;
  background: rgb(255 253 249 / 96%);
  box-shadow: 0 14px 36px rgb(93 50 20 / 8%);
}

.pet-tracker [data-testid^="pet-card-content-"] {
  display: flex !important;
  width: 100%;
  min-width: 0;
  max-width: 100%;
  height: 100%;
  padding: 18px !important;
  align-items: stretch !important;
}

.pet-tracker [data-testid^="pet-summary-"] {
  display: flex !important;
  width: 100%;
  flex-direction: column !important;
  align-items: stretch !important;
  gap: 14px !important;
}

.pet-tracker [data-testid^="pet-avatar-"] {
  width: 100% !important;
  min-width: 100% !important;
  max-width: 100% !important;
  height: 190px !important;
  min-height: 190px !important;
  max-height: 190px !important;
  padding: 8px;
  border-radius: 13px;
  background: linear-gradient(145deg, #fff0d7, #fff9ef);
  object-fit: contain !important;
}

.pet-tracker [data-testid^="pet-copy-"] {
  display: flex !important;
  width: 100%;
  align-items: flex-start !important;
}

.pet-tracker [data-testid^="pet-name-"] {
  font-family: Georgia, "Times New Roman", serif;
  font-size: 1.55rem !important;
  line-height: 1.05;
}

.pet-tracker [data-testid^="pet-species-label-"] {
  color: var(--pet-muted) !important;
}

.pet-tracker [data-testid^="pet-status-"] {
  align-self: flex-start;
  margin-top: 7px;
  padding: 7px 11px;
  border-radius: 999px;
  font-weight: 750;
  line-height: 1.15;
}

.pet-tracker [data-testid^="pet-status-adopted-"] {
  background: var(--pet-teal-soft);
  color: var(--pet-teal) !important;
}

.pet-tracker [data-testid^="pet-status-waiting-"] {
  background: var(--pet-waiting-soft);
  color: var(--pet-waiting) !important;
}

.pet-tracker [data-testid^="pet-actions-"] {
  display: grid !important;
  width: 100%;
  margin-top: auto;
  grid-template-columns: minmax(0, 1fr) 54px;
  gap: 10px !important;
}

.pet-tracker [data-testid^="pet-actions-"] .am-form,
.pet-tracker [data-testid^="pet-actions-"] .am-form > div,
.pet-tracker [data-testid^="pet-actions-"] .am-form-field {
  min-width: 0;
  max-width: 100%;
}

.pet-tracker [data-testid^="pet-actions-"] .am-form:first-child > div,
.pet-tracker [data-testid^="pet-actions-"] .am-form:first-child .am-form-field {
  width: 100%;
}

.pet-tracker [data-testid^="pet-actions-"] .am-form:first-child {
  width: auto;
}

.pet-tracker [data-testid^="pet-actions-"] .am-form:last-child,
.pet-tracker [data-testid^="pet-actions-"] .am-form:last-child > div,
.pet-tracker [data-testid^="pet-actions-"] .am-form:last-child .am-form-field,
.pet-tracker [data-testid^="toggle-pet-"] {
  width: 54px;
}

.pet-tracker [data-testid^="pet-actions-"] .am-form-field {
  padding: 0 !important;
}

.pet-tracker [data-testid^="details-pet-"] {
  width: 100%;
  border-color: var(--pet-line);
  color: var(--pet-ink);
}

.pet-tracker [data-testid^="details-pet-"]::after {
  margin-left: 8px;
  content: "›";
  font-size: 1.25rem;
  line-height: 0;
}

.pet-tracker [data-testid^="toggle-pet-"] {
  border-color: var(--pet-orange);
  color: var(--pet-orange-dark);
}

.pet-tracker [data-testid="pet-kindness-card"] {
  grid-area: kindness;
  align-self: start;
  border: 0;
  background: linear-gradient(135deg, #fff0d7, #fff9ef);
  box-shadow: none;
}

.pet-tracker [data-testid="pet-kindness-note"] {
  display: flex !important;
  padding: 4px !important;
}

.pet-tracker [data-testid="pet-kindness-heart"] {
  color: var(--pet-orange) !important;
}

.pet-tracker [data-testid="pet-footer"] {
  display: flex !important;
  grid-area: footer;
  width: calc(100% + 2 * clamp(24px, 5vw, 76px));
  margin-top: 28px;
  margin-left: calc(-1 * clamp(24px, 5vw, 76px));
  padding: 26px clamp(24px, 5vw, 76px) 30px;
  border-top: 1px solid var(--pet-line);
  background: rgb(255 253 249 / 72%);
}

.pet-tracker [data-testid="pet-footer-promise"] {
  color: var(--pet-muted);
}

.pet-tracker [data-testid="pet-footer-promise"] img {
  width: 28px !important;
  height: 28px !important;
}

@media (max-width: 980px) {
  .pet-tracker [data-testid="pet-list"] {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 840px) {
  .pet-tracker {
    padding: 0 16px;
  }

  .pet-tracker [data-testid="pet-tracker-screen"] {
    width: 100%;
    padding: 22px 0 0 !important;
    grid-template-columns: minmax(0, 1fr);
    grid-template-areas:
      "header"
      "notice"
      "form"
      "heading"
      "pets"
      "footer";
    gap: 20px !important;
  }

  .pet-tracker [data-testid="pet-tracker-header"] {
    gap: 10px !important;
    padding: 0 0 20px;
  }

  .pet-tracker [data-testid="pet-brand"] {
    flex: 1 1 auto;
  }

  .pet-tracker [data-testid="pet-brand-copy"] {
    min-width: 0;
  }

  .pet-tracker [data-testid="pet-tracker-header"] > [style*="flex: 1 1 0%"] {
    display: none !important;
  }

  .pet-tracker [data-testid="pet-brand-mark"] {
    width: 48px !important;
    min-width: 48px !important;
    max-width: 48px !important;
    height: 48px !important;
    min-height: 48px !important;
    max-height: 48px !important;
  }

  .pet-tracker [data-testid="pet-title"] {
    font-size: clamp(1.7rem, 8vw, 2.1rem) !important;
  }

  .pet-tracker [data-testid="pet-subtitle"] {
    font-size: 0.9rem !important;
  }

  .pet-tracker [data-testid="pet-desktop-nav"] {
    display: none !important;
  }

  .pet-tracker [data-testid="pet-mobile-menu"] {
    display: inline-flex !important;
    margin-left: auto;
    flex: 0 0 auto;
    align-items: center;
    justify-content: center;
  }

  .pet-tracker [data-testid="new-pet-form"] {
    width: 100%;
    min-width: 0;
    max-width: 100%;
    padding: 18px;
  }

  .pet-tracker [data-testid="new-pet-form"] > div,
  .pet-tracker [data-testid="new-pet-form"] .am-form-field,
  .pet-tracker [data-testid="pet-list"] > [role="listitem"] {
    width: 100%;
    min-width: 0;
    max-width: 100%;
  }

  .pet-tracker [data-testid="new-pet-form"] > div > span:first-child {
    margin-bottom: 8px;
    font-size: 1.32rem !important;
  }

  .pet-tracker input {
    min-height: 48px !important;
  }

  .pet-tracker [data-testid="save-pet"] {
    min-height: 50px !important;
  }

  .pet-tracker [data-testid="pets-heading"] {
    padding-top: 1px;
    font-size: 1.75rem !important;
  }

  .pet-tracker [data-testid="pet-list"] {
    grid-template-columns: minmax(0, 1fr);
    gap: 10px;
  }

  .pet-tracker [data-testid^="pet-card-content-"] {
    padding: 10px 12px !important;
  }

  .pet-tracker [data-testid^="pet-summary-"] {
    display: grid !important;
    grid-template-columns: 76px minmax(0, 1fr);
    align-items: center !important;
    gap: 12px !important;
  }

  .pet-tracker [data-testid^="pet-avatar-"] {
    width: 76px !important;
    min-width: 76px !important;
    max-width: 76px !important;
    height: 76px !important;
    min-height: 76px !important;
    max-height: 76px !important;
    padding: 4px;
    border-radius: 12px;
  }

  .pet-tracker [data-testid^="pet-copy-"] {
    display: grid !important;
    min-width: 0;
    max-width: 100%;
    grid-template-columns: minmax(0, 1fr) auto;
    grid-template-areas:
      "name status"
      "species status";
    column-gap: 10px !important;
    row-gap: 1px !important;
    align-items: center !important;
  }

  .pet-tracker [data-testid^="pet-copy-"] > :nth-child(1) {
    grid-area: name;
  }

  .pet-tracker [data-testid^="pet-copy-"] > :nth-child(2) {
    grid-area: species;
  }

  .pet-tracker [data-testid^="pet-copy-"] > :nth-child(3) {
    grid-area: status;
  }

  .pet-tracker [data-testid^="pet-name-"] {
    font-size: 1.08rem !important;
  }

  .pet-tracker [data-testid^="pet-status-"] {
    max-width: 132px;
    margin-top: 0;
    padding: 6px 9px;
    font-size: 0.78rem !important;
    text-align: center;
    white-space: nowrap;
  }

  .pet-tracker [data-testid^="pet-actions-"] {
    display: none !important;
  }

  .pet-tracker [data-testid="pet-kindness-card"] {
    display: none;
  }

  .pet-tracker [data-testid="pet-footer"] {
    width: calc(100% + 32px);
    margin-top: 10px;
    margin-left: -16px;
    padding: 22px 16px 28px;
  }

  .pet-tracker [data-testid="pet-footer-promise"] {
    display: none !important;
  }
}

@media (max-width: 420px) {
  .pet-tracker [data-testid="pet-brand"] {
    gap: 10px !important;
  }

  .pet-tracker [data-testid="pet-mobile-menu"] {
    width: 40px;
    min-width: 40px;
  }

  .pet-tracker [data-testid^="pet-summary-"] {
    grid-template-columns: 68px minmax(0, 1fr);
  }

  .pet-tracker [data-testid^="pet-avatar-"] {
    width: 68px !important;
    min-width: 68px !important;
    max-width: 68px !important;
    height: 68px !important;
    min-height: 68px !important;
    max-height: 68px !important;
  }
}
```

The media query rearranges the same browser view below 840 pixels. It does not
create a second mobile-web screen. iOS and Android ignore this CSS and render
the same Crystal view tree with native controls.

## Carry the same identities to iOS

Template `0.1.0-beta.3` generates `Assets.xcassets` with the paw and all three
portraits. Xcode compiles that catalog into the iOS application. The UI test
asserts the paw identity, and its retained simulator screenshot shows all three
starter portraits in the rendered screen.

The iOS names are:

```text
pet-tracker-paw-mark
pet-tracker-mochi-cat
pet-tracker-rocky-dog
pet-tracker-pip-rabbit
```

Apple-ready source files are available as [Mochi PNG](/assets/images/guides/pet-tracker/animals/mochi-cat-2c5cae0f1fef5540e6db6912c367a82f.png),
[Rocky PNG](/assets/images/guides/pet-tracker/animals/rocky-dog-8fb27775399300e3aeaca84cb59f9806.png),
and [Pip PNG](/assets/images/guides/pet-tracker/animals/pip-rabbit-360b5c62f169a1e803566aaac9e08d0a.png).
The future macOS host should reuse these authored PNGs and equivalent logical
identities. That macOS catalog remains proposed.

## Preview asset checks

These checks were used against the evaluated preview consumer. They are
historical examples, not instructions for the released toolchain.

**Historical preview commands — illustrative only:**

```text
test -f public/assets/pet-tracker.css
test -f public/assets/pets/mochi-cat.webp
test -f public/assets/pets/rocky-dog.webp
test -f public/assets/pets/pip-rabbit.webp
test -f public/assets/pets/paw-mark.webp
bash mobile/android/android.sh build
bash mobile/ios/ios.sh build
```

Then load the stylesheet and each portrait from a clean browser process, and
inspect the Android output and iOS asset catalog for the four logical image
names. A release proof also checks TalkBack or VoiceOver, large text, dark
surfaces, and real hardware.
