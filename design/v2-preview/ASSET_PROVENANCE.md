# Asset provenance

Status: **APPROVED FOR PUBLIC BETA**

## Character references

The owner-provided visual references live outside the repository in:

`/Users/crimsonknight/Documents/remote_sync_vault/amber_framework_brand_ideas`

The owner references establish the canonical studio: playful, low-key character
acting with compact rounded faces, visible cheek blush, open smiles, simplified
linework, warm cel shading, and energetic poses. The owner reviewed and
approved the active public-beta set after several art-direction rounds.

## Responsive desk hero (active homepage hero)

The active homepage hero is a responsive transparent asset set created through
the locally authenticated Higgsfield CLI. It preserves the approved playful
Amber pose, her desk, laptop, mug, notebook, papers, open smile, and blush while
removing the painted room and loose floating crystal decorations. The live CSS
places the desk on the lower-right edge so the code-native crystal field remains
visible behind it without a rectangular image boundary.

| Active local asset | Purpose |
|---|---|
| `amber-hero-desk-transparent-higgsfield.webp` | 1800 by 1208 wide-screen source with alpha |
| `amber-hero-desk-desktop-higgsfield.webp` | 1500 by 1208 desktop crop with alpha |
| `amber-hero-desk-mobile-higgsfield.webp` | 1250 by 1208 mobile crop with alpha |

The precision edit used Higgsfield Nano Banana Pro job
`4d8abedb-6926-423e-aa14-442b726dd877`. Its prompt instructed the model to
preserve Amber's exact face, smile, blush, hand, fingers, outfit, laptop, mug,
notebook, papers, and complete desk while removing only the room, orbit lines,
floating crystals, and loose desk crystals. Because that model rendered a
checker pattern rather than an alpha channel, a local saturation-and-luminance
key produced the final transparency before responsive crops were encoded with
`cwebp`. Automatic background-removal jobs
`37df4ada-0d15-4c2a-b946-6935d27a7583` and
`16e7828a-d15a-47a1-8bf3-4baa61393c0f` were reviewed but rejected because they
removed too much of the desk or left an inferior edge. Rejected outputs are not
wired into the site.

## Application and responsibility scenes

The retired native-application frontier image came from Higgsfield job
`7a9e57d6-ddfd-4cb3-9ce2-ff4335500c25`, encoded as
`amber-frontier-higgsfield.webp`. Its prompt placed Amber, Grant, and Gemma at
the edge of a warm, expansive, unexplored landscape. It is retained for
provenance but is not wired into the website: the scene did not fit the brand
closely enough, so the native hover and focus state uses a six-part code-native
platform map instead.

Grant's records warehouse is Higgsfield job
`25fe362e-93ae-4357-8301-4f0e1a0d5d63`, encoded as
`grant-records-warehouse-higgsfield.webp`. The prompt asked for the playful,
blushing Grant to work inside a huge archive of paper records and database-like
drawers—not a vinyl-record warehouse.

Gemma's file-logistics warehouse is Higgsfield job
`20a2cb94-d466-42a0-8923-2433cbe8eb7e`, encoded as
`gemma-file-logistics-higgsfield.webp`. The prompt asked for playful Gemma to
route a large glowing digital-file crate through a violet logistics warehouse,
expressing uploads, S3-compatible storage, and delivery.

All three scene sources were exported from Higgsfield, visually inspected, and
encoded as local quality WebP assets. Only the Grant and Gemma warehouse scenes
are active at runtime; the retired frontier image introduces no browser request.

## Prior inviting hero refinement (retained source)

The prior homepage hero, `amber-hero-inviting-studio.webp`, was created
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
quality-84 WebP without overwriting the prior source. It remains reproducible
source material but is no longer wired into the homepage.

## Original-studio correction

The active public-beta set was generated with Codex built-in image generation after
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

## Primary chibi character mark

`public/assets/characters/amber-chibi-hero-mark-v2.webp` is the active primary
character mark. Codex built-in image generation used
`amber-chibi-original-studio.webp` and `amber-id-original-studio.webp` as the
style and identity references. The generated source is:

`/Users/crimsonknight/.codex/generated_images/019fb8fe-b340-7f60-8fe6-b412352a3660/exec-dc9b6888-9017-4000-84fe-f18cee888396.png`

The prompt requested one full-body, playful original-studio Amber with large
amber eyes, visible blush, a warm smile, her cream technical jacket, feet at
shoulder width, one hand at her hip, and one clear peace sign. It prohibited a
serious or editorial studio shift, props, text, cropping, extra characters, and
green in the subject. Generation used a flat `#00ff00` background; the bundled
`remove_chroma_key.py` helper removed that background with a soft, contracted,
despilled matte before `cwebp` encoded the 1254-by-1254 transparent asset at
quality 92 and alpha quality 100. The original generated PNG remains in the
generation directory and was not overwritten.

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

## Third-party identity assets

These marks are stored locally and used only to identify the tools or services
named beside them. The site makes no runtime request to the source sites.

| Local asset | Source and handling |
|---|---|
| `crys-mascot.svg` | Exact Crys mascot SVG from the official Crystal media page, `https://crystal-lang.org/media/`; colors and proportions are unchanged. |
| `claude-icon-rounded.svg` | Exact rounded Claude icon extracted from the official Anthropic press kit linked by `https://www.anthropic.com/news`; the asset remains unchanged. |
| `openai-symbol-2025.svg` | Standalone OpenAI 2025 symbol from `https://commons.wikimedia.org/wiki/File:OpenAI_logo_2025_(symbol).svg`, which identifies it as derived from OpenAI's official mark. Usage follows `https://openai.com/brand/`; the path data is unchanged. |

## Code-native assets

The Amber crystal supporting motif, crystal-field particles, Markdown icons,
terminal window, browser preview, and motion are authored as local SVG, HTML,
CSS, and vanilla JavaScript. No third-party front-end runtime is required.
