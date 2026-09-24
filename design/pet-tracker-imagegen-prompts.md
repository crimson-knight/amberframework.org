# Pet Tracker ImageGen prompts

These six documentation assets were generated with the built-in ImageGen
workflow on September 20, 2026. The saved WebP files are under
`app/assets/images/guides/pet-tracker/`.

The comparison board was corrected after generation by compositing the exact
checked-in primary character mark,
`app/assets/characters/amber-chibi-hero-mark-v2.webp`, over the model-generated
leaf mark. ImageGen was not asked to redraw Amber’s identity.

## `target-comparison.webp`

```text
Use case: ui-mockup
Asset type: documentation guide comparison image for the Amber Framework Pet Tracker monolith
Primary request: Create a polished high-fidelity product UI comparison board showing the same Pet Tracker application across four compile targets: a large desktop web browser on the left, then three phones on the right labeled Mobile Web, iOS, and Android. The actual app content and styling inside all four screens must be nearly identical; only subtle browser or native system chrome may differ.
Scene/backdrop: clean warm editorial design-board backdrop in soft cream with a restrained technical presentation suitable for developer documentation.
Interface content: header title “Pet Tracker” with small friendly paw mark; welcoming subtitle “Everyone deserves a good home.”; compact “Add a pet” form with fields “Name” and “Species” and orange “Save pet” button; a responsive grid/list of pet cards for “Mochi” (Cat, Adopted), “Rocky” (Dog, Looking for a home), and “Pip” (Rabbit, Looking for a home); simple tasteful pet avatar illustrations; status pills; secondary action buttons. Desktop shows two-column composition with form sidebar and pet card grid. All three phone views show the same single-column composition and controls.
Style/medium: realistic high-fidelity interface mockup, crisp modern SaaS product design with friendly storybook warmth, production-ready spacing and typography, no photographic people.
Composition/framing: wide landscape presentation board, desktop browser approximately half the width, three phones evenly arranged to the right or foreground, every screen fully visible, straight-on view, no extreme perspective.
Color palette: Amber Framework palette: cream #FFF9EF, paper #FFFDF9, orange #F47A16 and #D95B0A, dark brown #211914, muted brown #76675D, teal #147F80, pale teal #E2F1EF, soft orange borders #E9D3B9.
Materials/textures: subtle paper grain only in the outer backdrop, clean flat UI surfaces, soft shadows, rounded 16px cards.
Text (verbatim): “Pet Tracker”, “Everyone deserves a good home.”, “Add a pet”, “Name”, “Species”, “Save pet”, “Mochi”, “Cat”, “Adopted”, “Rocky”, “Dog”, “Looking for a home”, “Pip”, “Rabbit”, “Mobile Web”, “iOS”, “Android”.
Constraints: preserve strong visual parity between mobile web, iOS, and Android; accessible contrast; large touch targets; professional developer-documentation quality; all devices should look like the same app built from one shared view system.
Avoid: Amber character illustration, robots, source code, dark mode, neon colors, glossy 3D UI, illegible tiny filler text, random charts, different visual design per platform, watermarks.
```

## `desktop-web.webp`

```text
Use case: ui-mockup
Asset type: desktop web view mock for the Amber Framework Pet Tracker documentation
Primary request: Create a single polished, high-fidelity desktop browser mockup of the Pet Tracker application. This is the wide-layout reference that the guide's copyable CSS will reproduce.
Scene/backdrop: straight-on browser window on a quiet warm cream documentation canvas; the browser and complete app viewport dominate the image.
Interface content: compact app header with orange paw mark, “Pet Tracker”, subtitle “Everyone deserves a good home.” and simple Pets navigation; a two-column content area with a narrow left “Add a pet” panel containing “Name”, “Species”, and an orange “Save pet” button; the right side titled “Our pets” with three responsive cards: Mochi / Cat / Adopted, Rocky / Dog / Looking for a home, Pip / Rabbit / Looking for a home. Each card has a small warm illustrated pet avatar, status pill, and modest secondary action.
Style/medium: production-quality web UI mockup, crisp accessible typography, friendly editorial warmth, realistic but clean browser chrome, flat UI surfaces.
Composition/framing: wide landscape, straight on, full application visible with generous whitespace; no phone devices in this image.
Color palette: cream #FFF9EF, paper #FFFDF9, orange #F47A16 and #D95B0A, dark brown #211914, muted brown #76675D, teal #147F80, pale teal #E2F1EF, border #E9D3B9.
Materials/textures: faint paper grain in the outer canvas only, rounded 16px cards, soft restrained shadows.
Text (verbatim): “Pet Tracker”, “Everyone deserves a good home.”, “Add a pet”, “Name”, “Species”, “Save pet”, “Our pets”, “Mochi”, “Cat”, “Adopted”, “Rocky”, “Dog”, “Looking for a home”, “Pip”, “Rabbit”.
Constraints: practical layout that can be implemented with ordinary CSS Grid and Flexbox; accessible contrast; clear 44px controls; developer-guide quality; show the whole screen.
Avoid: people, Amber character illustration, robots, source code, dark mode, neon colors, glassmorphism, glossy 3D controls, charts, watermarks, tiny illegible filler text.
```

## `mobile-parity.webp`

```text
Use case: ui-mockup
Asset type: mobile parity view mock for the Amber Framework Pet Tracker documentation
Primary request: Create a polished high-fidelity comparison of the same Pet Tracker mobile interface on three phones placed side by side: Mobile Web, iOS, and Android. The content, colors, typography, spacing, controls, and responsive layout inside the three screens must be visibly identical. Show only slight differences in outer system/browser chrome to communicate separate compile targets.
Scene/backdrop: warm cream developer-documentation board with the three devices centered and fully visible.
Interface content on every phone: compact header with orange paw and “Pet Tracker”; subtitle “Everyone deserves a good home.”; a rounded “Add a pet” card with “Name” and “Species” fields and full-width orange “Save pet” button; heading “Our pets”; compact stacked pet rows for Mochi / Cat / Adopted, Rocky / Dog / Looking for a home, Pip / Rabbit / Looking for a home, each with a small friendly illustrated pet avatar and status pill.
Style/medium: realistic high-fidelity mobile UI mockup, clean accessible product design with friendly editorial warmth, production-ready spacing.
Composition/framing: wide landscape triptych, straight-on devices, equal scale, labels beneath each phone reading exactly “Mobile Web”, “iOS”, and “Android”.
Color palette: cream #FFF9EF, paper #FFFDF9, orange #F47A16 and #D95B0A, dark brown #211914, muted brown #76675D, teal #147F80, pale teal #E2F1EF, border #E9D3B9.
Materials/textures: subtle paper grain in backdrop, clean flat UI, rounded 16px cards, restrained shadows.
Text (verbatim): “Pet Tracker”, “Everyone deserves a good home.”, “Add a pet”, “Name”, “Species”, “Save pet”, “Our pets”, “Mochi”, “Cat”, “Adopted”, “Rocky”, “Dog”, “Looking for a home”, “Pip”, “Rabbit”, “Mobile Web”, “iOS”, “Android”.
Constraints: all three app viewports must look like one shared UI system; clear 44px touch targets; accessible contrast; full screens visible; professional documentation asset.
Avoid: people, Amber character illustration, robots, source code, major UI variations between platforms, dark mode, neon colors, glassmorphism, glossy 3D controls, charts, watermarks, random filler text.
```

## Transparent pet portraits

Each portrait used `desktop-web.webp` as its only reference image and was saved
under `app/assets/images/guides/pet-tracker/animals/`.

### `mochi-cat.webp`

```text
Use case: background-extraction
Asset type: reusable transparent Pet Tracker avatar
Primary request: Extract and recreate only Mochi, the cheerful orange-and-white cat portrait shown in the first pet card of the reference image. Preserve the same warm hand-painted storybook illustration style, facial expression, orange markings, teal collar, and front-facing bust composition.
Input images: Image 1 is the approved Pet Tracker desktop mockup and exact style/subject reference.
Composition/framing: one centered cat head-and-shoulders portrait, square canvas, generous transparent padding, readable at 64px.
Lighting/mood: warm, friendly, soft, optimistic.
Constraints: genuinely transparent background with clean antialiased edges; one cat only; no card, border, badge, text, logo, accessories beyond the teal collar; preserve the reference likeness and palette.
Avoid: opaque cream rectangle, drop shadow, photorealism, 3D render, extra animals, text, watermark.
```

### `rocky-dog.webp`

```text
Use case: background-extraction
Asset type: reusable transparent Pet Tracker avatar
Primary request: Extract and recreate only Rocky, the cheerful golden dog portrait shown in the middle pet card of the reference image. Preserve the same warm hand-painted storybook illustration style, happy open-mouth expression, golden fur, teal collar with round gold tag, and front-facing bust composition.
Input images: Image 1 is the approved Pet Tracker desktop mockup and exact style/subject reference.
Composition/framing: one centered dog head-and-shoulders portrait, square canvas, generous transparent padding, readable at 64px.
Lighting/mood: warm, friendly, soft, optimistic.
Constraints: genuinely transparent background with clean antialiased edges; one dog only; no card, border, badge, text, logo, leaves, decorative rays, or accessories beyond the teal collar and gold tag; preserve the reference likeness and palette.
Avoid: opaque cream rectangle, drop shadow, photorealism, 3D render, extra animals, text, watermark.
```

### `pip-rabbit.webp`

```text
Use case: background-extraction
Asset type: reusable transparent Pet Tracker avatar
Primary request: Extract and recreate only Pip, the gentle brown-and-white rabbit portrait shown in the third pet card of the reference image. Preserve the same warm hand-painted storybook illustration style, upright ears, friendly front-facing expression, brown-and-white markings, and head-and-shoulders composition.
Input images: Image 1 is the approved Pet Tracker desktop mockup and exact style/subject reference.
Composition/framing: one centered rabbit head-and-shoulders portrait, square canvas, generous transparent padding, readable at 64px.
Lighting/mood: warm, friendly, soft, optimistic.
Constraints: genuinely transparent background with clean antialiased edges; one rabbit only; no card, border, badge, text, logo, leaves, collar, decorative plants, or extra objects; preserve the reference likeness and palette.
Avoid: opaque cream rectangle, drop shadow, photorealism, 3D render, extra animals, text, watermark.
```
