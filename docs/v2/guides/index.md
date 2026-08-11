---
title: "Guides"
section: ""
order: 40
is_section: true
description: "Amber V2 guides, reviewed replacements, and clearly marked carried-forward references"
---

# Guides

V2 carries forward framework concepts that still apply—controllers, requests,
responses, sessions, routing, cookies, testing, and other stable APIs. A
carried-forward page is labeled in the interface so you can distinguish it from
a guide reviewed or replaced specifically for V2.

Pages built around removed components are excluded rather than inherited.
Granite and Jennifer point to Grant replacements; legacy bundled-CLI commands
remain retired; assets and the standalone Amber CLI use their V2 guides.

## How to apply an example

Every code-bearing V2 guide now provides one of two placement contracts:

- a walkthrough labels each block with the exact **File**, **Files**, or
  **Run from** location and says whether to create, edit, replace, or inspect it;
- an API reference begins with **Where the examples go**, mapping declarations,
  usage fragments, configuration, views, and generated output to their normal
  application directories.

Paths are relative to the application root—the directory containing
`shard.yml`—unless a guide says otherwise. Treat `public/` as browser-served
application files only when the guide labels them as source; never hand-edit a
directory labeled as generated output.

## Supported beta core

- [Web template](web-template/) — exact output of Amber CLI 2.0.3
- [Schema API](schema-api/) — typed request parsing and validation
- [Adapters](adapters/) — framework adapter concepts and extension points

## Preview ecosystem material

- [Asset Pipeline](assets/) — separate native-ESM project
- [Native application template](native-preview/) — macOS, iOS, and Android preview
- [Grant](models/grant/) — separate ORM project
- [Gemma](uploads/) — separate attachment project

Preview pages describe work that can be evaluated, but they are not part of the
clean web-template compile guarantee. Start with the supported web template and
add preview projects deliberately.

## Maintaining a V1 application

Amber 1.4.1 documentation remains available from the version selector. Choose
that version when maintaining an existing V1 application. The V2 navigation
uses explicit badges and replacement links where the path changed.
