# Amber V2 public beta: the new first run is live

Amber V2 now has one public home for learning the framework, installing its
standalone CLI, and generating a web application that looks and feels like it
belongs to the same project.

The framework remains `2.0.0-beta.2`. The companion Amber CLI `2.0.3` updates
the generated web starter and is the minimum version used throughout the new
site and V2 guides.

## Install the CLI

On Apple Silicon macOS or x86_64 Linux with Homebrew:

```bash
brew install amberframework/amber_cli/amber_cli
amber --version
```

Verified archives and checksum files are available from the
[Amber CLI v2.0.3 release](https://github.com/amberframework/amber_cli/releases/tag/v2.0.3).

## Generate the new web starter

```bash
amber new my_app
cd my_app
crystal spec
amber watch
```

Web is the default application type; `amber new my_app --type web` is the
explicit equivalent. The generated application pins the official Amber
`2.0.0-beta.2` framework release and starts with ECR, typed configuration,
locally served CSS and JavaScript, and a browser-native import map. It does not
require Node, npm, a bundler, a UI library, a CDN, an ORM, or a database.

## Learn the Amber way

The new [Amber's Way](/amber-way) page explains the beliefs behind the code:
controllers coordinate work, `respond_with` makes HTML and JSON
representations explicit, ECR owns server-rendered HTML, and local browser
assets provide a complete front end before another dependency is added.

The V2 documentation now includes the exact generated file system, complete
ECR and import-map examples, supported and preview boundaries, deployment
guidance, and benchmark evidence with its workload and limitations.

Start with [Installation](/docs/v2/getting-started/installation/), build the
[first web application](/docs/v2/getting-started/), and keep the
[beta support matrix](/docs/v2/beta-support/) nearby while evaluating other
generators.

## What we need from beta testers

Try the complete path on a supported Mac or Linux machine. When something
breaks or reads ambiguously, report the operating system and architecture,
Crystal version, Amber CLI version, install method, exact command, and complete
output.

- [Framework issues](https://github.com/amberframework/amber/issues)
- [CLI and generator issues](https://github.com/amberframework/amber_cli/issues)
- [Homebrew installation issues](https://github.com/amberframework/homebrew-amber_cli/issues)

Amber V2 is still a beta. Persistence-backed generators, Grant, Gemma, the
separate Asset Pipeline, and native generation remain clearly labeled preview
surfaces. The public web path is narrower on purpose: it is the path we can
document, reproduce, and improve together.
