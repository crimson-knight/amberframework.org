# Amber V2 experience preview

Status: **PREVIEW — NOT APPROVED FOR RELEASE**

This branch is a proofing environment for the Amber V2 website, brand, and
documentation experience. It must not be merged into `master`, connected to a
production deployment, or described publicly as released until the owner has
reviewed the rendered proof and explicitly approved the release.

## Product story

Amber helps a solo developer move from idea to MVP to a maintainable business
application without losing clear conventions. Amber is the lead product and
the lead character. The ecosystem is introduced through responsibilities that
map to real software boundaries rather than decorative mascots.

- **Amber — framework and front office.** Routing, controllers, views,
  presentation, interaction, the asset pipeline, and the shape of the app.
- **Grant — records and warehouse.** Models, relations, migrations, queries,
  transactions, and dependable record keeping.
- **Gemma — files and fulfillment.** Attachments, storage, validation,
  streaming, and delivery.
- **Background jobs — open role.** The character and final name are not yet
  approved. The preview may explain the responsibility but must label any
  proposed identity as a concept.

The homepage gives Grant a dedicated persistence spotlight before the full
crew roster. That spotlight must say that Grant is an independently changing
ecosystem preview and that the core web template does not silently install or
select an ORM.

## Application types

The installed Amber CLI is the authority for template claims:

- `web` is the default and the V2 beta release-gated path.
- `native` is a preview for macOS, iOS, and Android. It must never be styled or
  described as equivalent to the supported web path.

## Visual direction

- Warm ivory canvas, precise amber line work, dark terminal surfaces.
- Amber leads the hero and appears throughout the docs, blog, and guide moments.
- Grant uses teal data and warehouse motifs.
- Gemma uses violet file, parcel, and delivery motifs.
- The character studio is playful and low-key: compact rounded faces, visible
  cheek blush, expressive brows, bright open smiles, simplified linework, warm
  cel shading, and energetic poses.
- Avoid glossy fashion-editorial rendering, long severe facial proportions,
  stern executive poses, tactical seriousness, and polished enterprise-anime
  styling. Those traits make the same cast feel as if it moved to another
  studio.
- Character cards read like personnel files or ID badges.
- Homepage character art has transparent edges and responsive crops; the desk
  sits against the lower-right viewport edge while the code-native crystal
  field remains visible behind it.
- Motion communicates state: terminal progress, a pointer click and ping,
  simultaneous terminal movement and browser growth, card focus, and a
  restrained crystal field. It never blocks reading or ignores reduced-motion
  preferences.
- The application-type background begins with the supported web path and
  changes to frontier art when native receives pointer, keyboard, or centered
  mobile focus. Card calls to action follow the same focus state.
- The crystal mark is tall, symmetrical, faceted, and legible at favicon size.

## Responsibility translation

Character pages may translate ownership into familiar Rails responsibilities,
but must not claim API compatibility. Grant maps to Active Record, Solid Cache,
and the durable record layer behind database-backed queues. Gemma maps to
Active Storage and S3-compatible upload, object-storage, and delivery policy.
Amber maps to routing, Action Pack, Action View, configuration, and application
structure.

## Template delivery boundary

Amber CLI `2.0.2` embeds the generated scaffold, so a template fix currently
requires a CLI patch release. The beta docs must say this plainly and must not
promise remote template freshness. The signed remote-channel design in
`TEMPLATE_DELIVERY_STRATEGY.md` remains proposed until its trust, caching,
compatibility, and offline behavior are implemented and release-tested.

## The Amber Way

The site should explain Amber's established six-part foundation:

1. **Productivity:** conventions and a coherent application structure remove
   routine decisions.
2. **Performance:** Crystal's type system and native compilation belong in the
   architecture from the beginning.
3. **Happiness:** clear errors, readable defaults, and fast feedback protect
   developer attention.
4. **Humility:** borrow tested ideas, acknowledge incomplete work, and invite
   correction.
5. **Respect:** treat user and contributor time as valuable through complete
   documentation and explicit changes.
6. **Trust:** keep code, responsibilities, and context understandable enough
   for another developer or coding agent to extend safely.
