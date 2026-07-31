# Amber 2.0 Beta 2: a complete first-run path

Amber `2.0.0-beta.2` is ready for evaluation together with Amber CLI `2.0.2`.
It supersedes beta.1 for new applications by fixing server startup with
Crystal 1.21's default multithreaded runtime.
This beta is focused on one thing that has to work before broader ecosystem
claims mean much: a new user on a supported Mac or Linux machine can install
the CLI, generate an Amber V2 web app, test it, build it, and run it.

## Install the new standalone CLI

On Apple Silicon macOS or x86_64 Linux with Homebrew:

```bash
brew install amberframework/amber_cli/amber_cli
amber --version
```

The tap and formula are named `amber_cli`; the executable remains `amber`.
Verified direct archives and checksum files are also available from the
[Amber CLI v2.0.2 release](https://github.com/amberframework/amber_cli/releases/tag/v2.0.2).

## Create the beta web app

```bash
amber new my_app --type web
cd my_app
crystal spec
crystal build src/my_app.cr -o bin/my_app
amber watch
```

The generated app pins Amber `2.0.0-beta.2` from the official framework
repository, uses ECR and typed configuration, serves its generated static
assets, and does not pull an ORM or every database driver into a hello-world
build.

## What this beta guarantees

The release gate covers Apple Silicon macOS and x86_64 Linux, using Homebrew or
the matching release archive. On both platforms we verify the CLI executable,
dependency installation, generated app specs, compilation, server startup, the
homepage, and generated CSS.

The framework beta includes its controller/router core, Schema API, jobs,
mailer, WebSockets, adapters, testing support, and typed configuration.

## What is still preview

Persistence-backed model, scaffold, API-resource, and auth generators remain
preview. Grant, Gemma, the separate Asset Pipeline, and native application
generation also have independent dependency and platform work left. Their
documentation is labeled preview so that useful work-in-progress material is
not mistaken for the supported zero-setup path.

Amber V2 removes Kilt and Slang; new and generated V2 views use ECR.

## Read the guides and help us test

Start with the [installation guide](/docs/v2/getting-started/installation/),
then work through [Getting Started](/docs/v2/getting-started/) and the
[beta support matrix](/docs/v2/beta-support/).

When reporting a problem, include your OS and architecture, Crystal version,
Amber CLI version, install method, exact command, and complete output. Use the
[framework issue tracker](https://github.com/amberframework/amber/issues) for
framework behavior, the [CLI issue tracker](https://github.com/amberframework/amber_cli/issues)
for generators or binaries, and the [tap issue tracker](https://github.com/amberframework/homebrew-amber_cli/issues)
for Homebrew installation.

This is a beta, not the finish line. But it is the first V2 release with one
documented path that is meant to be followed exactly and tested end to end.
