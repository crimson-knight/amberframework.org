# Preview asset provenance

Status: **PREVIEW — NOT APPROVED FOR RELEASE**

## Character references

The owner-provided visual references live outside the repository in:

`/Users/crimsonknight/Documents/remote_sync_vault/amber_framework_brand_ideas`

Generated character assets in `public/assets/characters/` were created through
the locally authenticated Higgsfield CLI using GPT Image 2 with those images as
identity and style references. Generated files remain preview-only until the
owner reviews and approves them.

| Final local asset | Higgsfield job |
|---|---|
| `amber-laptop-hero.webp` | `6c2d8745-9032-4982-82ba-cff1a2e46632` |
| `amber-id.webp` | `6d3a699d-45cb-4bcb-a3e9-b150f74a1a25` |
| `grant-id.webp` | `050ad165-831e-49a1-9f72-a35b7ab450b4` |
| `gemma-id.webp` | `42a4c5bf-e49a-4cc1-b13b-99ecdf9c2ac3` |
| `amber-chibi.webp` | `0c8a5114-522a-4436-8f1e-b28aa87814b9` |

The source PNG exports were converted to the checked-in WebP files and removed
after visual and natural-dimension checks. This keeps the preview lightweight
without losing the reproducible Higgsfield job references.

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
