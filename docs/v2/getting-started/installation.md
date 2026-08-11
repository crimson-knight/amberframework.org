---
title: "Installation"
section: "getting-started"
order: 10
description: "Install Amber CLI 2.0.4 on supported macOS, x86-64 Linux, and ARM64 Linux systems"
---

# Install Amber V2 Beta

The supported onboarding path uses the standalone Amber CLI. The framework is
an exact shard dependency generated into each application.

## Supported systems

- Apple Silicon macOS — release-gated; Homebrew and `darwin-arm64` archive
- x86-64 Linux — release-gated; Homebrew and `linux-x86_64` archive
- ARM64 Linux — release-gated; `linux-arm64` archive
- Windows x86-64 — generated database-backed app compile-verified in CI; no CLI
  release archive yet

Intel macOS is not currently verified. Windows is not a release gate until it
has a supported installation artifact, but its CI job installs SQLite, builds
the CLI, generates the web app, applies its development and test migrations,
runs the generated specs, and compiles the application. Follow [Beta Support](../beta-support/)
rather than treating a successful Crystal installation as the complete support
claim.

## Prerequisites

Install Crystal 1.20 or newer, but earlier than 2.0, using the
[official Crystal instructions](https://crystal-lang.org/install/). You also
need Git, `shards`, and SQLite development headers because the default web app
compiles the SQLite driver.

For a new application, use the latest stable Crystal release that satisfies
that range.

On Debian or Ubuntu Linux:

```bash
sudo apt-get update
sudo apt-get install -y libsqlite3-dev
```

Then verify the toolchain:

```bash
crystal --version
shards --version
git --version
```

SQLite needs no running database server. Choose PostgreSQL or MySQL only when
the application needs one of those servers.

## Homebrew on macOS or Linux

The tap and formula use an underscore. Install the official formula with its
fully qualified name, then verify the `amber` executable:

```bash
brew install amberframework/amber_cli/amber_cli
amber --version
```

The formula is `amber_cli`; the installed executable is `amber`. Expect Amber
CLI `2.0.4` or newer.

## Direct archive

Choose `darwin-arm64`, `linux-x86_64`, or `linux-arm64` for the current host.

```bash
version=v2.0.4
platform=darwin-arm64
asset="amber_cli-${platform}.tar.gz"

curl -fLO "https://github.com/amberframework/amber_cli/releases/download/${version}/${asset}"
curl -fLO "https://github.com/amberframework/amber_cli/releases/download/${version}/${asset}.sha256"
shasum -a 256 -c "${asset}.sha256"
tar -xzf "${asset}"
install -m 0755 amber amber-lsp /usr/local/bin/
amber --version
```

On Linux, set `platform` to the matching value and use `sha256sum -c`. Prefix
only the `install` command with `sudo` when `/usr/local/bin` is not writable.
Never run a differently named architecture archive through emulation and call
that native support.

## Verify a database-backed application

**Run from: a parent directory where `amber_beta_smoke/` can be created.**

```bash
amber new amber_beta_smoke --type web
cd amber_beta_smoke
amber generate scaffold Pet name:string:required species:string:required adopted:bool
amber database migrate
AMBER_ENV=test amber database migrate
crystal spec
crystal build src/amber_beta_smoke.cr -o bin/amber_beta_smoke
amber watch
```

Open <http://127.0.0.1:3000/>, then create a record at
<http://127.0.0.1:3000/pets/new>. The generated `shard.yml` pins Amber
`2.0.0-beta.3`, includes Grant and only the selected database driver, and does
not use a personal Amber fork or a moving framework branch.

From another terminal:

```bash
curl --fail http://127.0.0.1:3000/
curl --fail http://127.0.0.1:3000/css/app.css
curl --fail http://127.0.0.1:3000/pets/new
```

## Manual framework dependency

For an existing Crystal application that only needs the runtime upgrade:

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.3

crystal: ">= 1.20.0, < 2.0"
```

Do not replace an existing application's working persistence stack merely to
upgrade the framework. Read the [V1-to-V2 migration guide](../migration-guide/)
and keep the first upgrade bounded.

## Update or remove

```bash
brew update
brew upgrade amberframework/amber_cli/amber_cli
# or
brew uninstall amberframework/amber_cli/amber_cli
brew untap amberframework/amber_cli
```

## Troubleshooting

If the wrong executable runs, inspect every match:

```bash
type -a amber
amber --version
```

Remove or rename an old Amber V1 executable, or put Homebrew earlier in `PATH`.
On macOS, the beta binary must not require `openssl@1.1`; include
`otool -L "$(command -v amber)"` in an install issue.

For generated-app failures, include the operating system and architecture,
`crystal --version`, `amber --version`, the exact command, and complete output.
Framework behavior belongs in the Amber issue tracker; CLI, generator,
migration-command, and install behavior belongs in Amber CLI.
