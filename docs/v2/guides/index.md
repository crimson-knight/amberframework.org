---
title: "V2 Guides"
section: ""
order: 40
is_section: true
description: "Verified Amber V2 core guides and clearly separated ecosystem previews"
---

# Amber V2 Guides

These guides do not inherit Amber 1.4.1 pages. Every page shown in the V2
navigation is authored for the V2 release so older Slang, Kilt, bundled CLI,
Webpack, Granite, or Redis assumptions cannot silently appear as current
instructions.

## Supported beta core

- [Web template](web-template/) — exact output of Amber CLI 2.0.2
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

## Stable V1 reference

Amber 1.4.1 documentation remains available from the version selector. Choose
that version when maintaining an existing V1 application; do not combine its
commands with a new V2 project.
