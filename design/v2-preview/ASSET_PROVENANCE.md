# Preview asset provenance

Status: **PREVIEW — NOT APPROVED FOR RELEASE**

## Character references

The owner-provided visual references live outside the repository in:

`/Users/crimsonknight/Documents/remote_sync_vault/amber_framework_brand_ideas`

The owner references establish the canonical studio: playful, low-key character
acting with compact rounded faces, visible cheek blush, open smiles, simplified
linework, warm cel shading, and energetic poses. Generated files remain
preview-only until the owner reviews and approves them.

## Inviting hero refinement (active homepage hero)

The active homepage hero is `amber-hero-inviting-studio.webp`. It was created
with Codex built-in image **edit** mode from
`amber-hero-original-studio.webp`; the source PNG is
`exec-d23f9739-f173-4133-8725-e5b1473c19c6.png` in the generation directory
below.

The edit prompt asked to change only Amber's foreground hand and lower arm to
an anatomically clear, palm-up beckoning gesture with softly curled fingers,
while preserving her open smile, blush, face, hair, outfit, laptop, warm cel
shading, wide composition, and left-side negative space. It explicitly
excluded grabbing, pointing, reaching at the viewer, extra fingers, and a
serious or glossy studio shift. The 1536-by-1024 result was encoded as a
quality-84 WebP without overwriting the prior source.

## Original-studio correction

The active preview set was generated with Codex built-in image generation after
the owner identified the first set as too serious and stylistically distant from
the references. Existing files were retained for side-by-side comparison; the
correction uses versioned filenames rather than overwriting them.

| Corrected local asset | Built-in generation source |
|---|---|
| `amber-hero-original-studio.webp` | `exec-b2cd0447-7726-4ba1-aa77-48b2501354db.png` |
| `amber-id-original-studio.webp` | `exec-905db6da-3b42-4a36-9f20-edcb52d608ef.png` |
| `grant-id-original-studio.webp` | `exec-e192560b-8ebb-4898-a711-b50986cb1d72.png` |
| `gemma-id-original-studio.webp` | `exec-aeff5a84-d2db-47ae-8639-45c27868f558.png` |
| `amber-chibi-original-studio.webp` | `exec-b9e4843e-6d5c-4388-90a0-4a9d543348d4.png` |

The generation source directory, including the inviting hero edit, is:

`/Users/crimsonknight/.codex/generated_images/019fb8fe-b340-7f60-8fe6-b412352a3660/`

The original five prompts shared the canonical-studio constraints above and explicitly
excluded glossy, sultry, stern, executive, tactical, and fashion-editorial
rendering. Character-specific direction preserved Amber's cream technical
jacket and amber crystal motif, Grant's teal data and warehouse motifs, and
Gemma's violet hair and file or fulfillment motifs. Portrait and chibi sources
were resized to 800 by 800 pixels; the wide hero remains 1536 by 1024. All were
encoded as quality-84 WebP assets. The portrait and chibi files remain active;
the original wide hero is retained as the reproducible source for the active
beckoning version.

## First generated set (comparison only)

The earlier character assets were created through the locally authenticated
Higgsfield CLI using GPT Image 2 with the same owner references. They are no
longer wired into the active preview because their longer facial proportions,
more composed acting, and glossy rendering shifted the cast toward a different
studio style.

| Final local asset | Higgsfield job |
|---|---|
| `amber-laptop-hero.webp` | `6c2d8745-9032-4982-82ba-cff1a2e46632` |
| `amber-id.webp` | `6d3a699d-45cb-4bcb-a3e9-b150f74a1a25` |
| `grant-id.webp` | `050ad165-831e-49a1-9f72-a35b7ab450b4` |
| `gemma-id.webp` | `42a4c5bf-e49a-4cc1-b13b-99ecdf9c2ac3` |
| `amber-chibi.webp` | `0c8a5114-522a-4436-8f1e-b28aa87814b9` |

The Higgsfield source PNG exports were converted to the checked-in WebP files
and removed after visual and natural-dimension checks. The WebP comparison files
remain locally available and retain their reproducible Higgsfield job references.

## Fonts

Fraunces and Manrope are copied from the official `google/fonts` repository and
served from `public/assets/fonts/`. Their SIL Open Font License files are stored
beside the fonts. The official TTF sources were converted to the checked-in
WOFF2 files and then removed as redundant runtime copies. The production
website must not call Google Fonts.

## Code-native assets

The Amber crystal mark, crystal-field particles, icons, terminal window,
browser preview, and motion are authored as local SVG, HTML, CSS, and vanilla
JavaScript. No third-party front-end runtime is required.
