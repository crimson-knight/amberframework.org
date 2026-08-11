---
title: "Models"
section: "guides"
order: 50
is_section: true
description: "Model-layer choices and release boundaries for Amber V2 applications"
---

# Models in Amber V2

Amber `2.0.0-beta.2` does not install an ORM or database driver in the supported
web template. This keeps the first project build independent of a database and
lets an application choose its persistence layer explicitly.

[Grant](grant/) is documented as an ecosystem preview. Its release lifecycle
is separate from the Amber framework beta, so confirm a compatible official
Grant release before adding it to an application.

If you are migrating an Amber 1 application, keep the 1.4.1 documentation open
for the existing Granite or Jennifer code and use the
[Granite-to-Grant preview guide](../../migration-guide/granite-to-grant/) only
after reviewing its compatibility notice.
