---
title: "Guides"
section: ""
order: 40
is_section: true
description: "Amber V2 guides, reviewed replacements, and stable framework references"
---

# Guides

V2 keeps framework concepts that still apply—controllers, requests, responses,
sessions, routing, cookies, testing, and other stable APIs. An unchanged page
has no badge. **New** and **Updated** badges identify material written or
revised for V2.

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

- [Build a Pet Tracker](pet-tracker/) — the canonical first app, from routes to HTML, JSON, CSS, and browser-native JavaScript
- [Web template](web-template/) — exact output of Amber CLI 2.0.5
- [Asset Pipeline](assets/) — CSS, JavaScript, images, fonts, SRI, and immutable caching
- [Grant](models/grant/) — the default relational model layer
- [Migrations](models/grant/migrations/) — authored Micrate SQL and safe release workflow
- [Schema API](schema-api/) — typed request parsing and validation
- [WebSockets and live pages](websockets/) — server-rendered documents with channel-driven ES module updates
- [Background jobs](background-jobs/) — queues, retries, delayed work, work stealing, and capacity boundaries
- [Adapters](adapters/) — framework adapter concepts and extension points

## Preview ecosystem material

- [Native application template](native-preview/) — macOS, iOS, and Android preview
- [Gemma](uploads/) — separate attachment project

Preview pages describe work that can be evaluated, but they are not part of the
clean web-template compile guarantee. The Asset Pipeline is part of that
guarantee; add native and attachment projects deliberately.

## Use the docs with an assistant

[AI assistants](ai-assistants/) explains how to give ChatGPT, Claude, or Gemini
the current V2 source set. It also provides a single Markdown knowledge bundle
and a tested Custom GPT instruction contract. The assistant should cite these
pages, preserve exact file locations, and name beta boundaries rather than
silently filling gaps from older Amber versions.

## Maintaining a V1 application

Amber 1.4.1 documentation remains available from the version selector. Choose
that version when maintaining an existing V1 application. V2 uses badges only
where a page is new or materially updated and uses replacement links where the
path changed.
