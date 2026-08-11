---
title: "Installation"
section: "getting-started"
order: 10
description: "Install Amber CLI 2.0.3 on supported macOS, x86_64 Linux, and Linux ARM64 systems"
---

# Install Amber V2 Beta

The supported onboarding path uses the standalone Amber CLI. The framework
itself remains a shard dependency generated into each application.

## Supported systems

- Apple Silicon macOS — release-gated; Homebrew and direct archive
- x86_64 Linux — release-gated; Homebrew and direct archive
- Linux ARM64 — clean web app compile-verified; source install for CLI 2.0.3

Linux ARM64 is supported for the clean web source-build path, but it is not a
beta release gate and CLI 2.0.3 does not publish an ARM64 archive. The release
workflow now builds and smoke-tests that archive for the next CLI version.
Intel macOS and Windows are not release-gated. Amber 2.0.0-beta.2 currently has
a Windows ECR path defect; the candidate fix passes the Windows compile job but
has not shipped. Follow [Beta Support](../beta-support/) rather than treating a
successful Crystal installation as application compatibility.

## Prerequisites

Install Crystal 1.20 or newer, but earlier than 2.0, using the
[official Crystal instructions](https://crystal-lang.org/install/). You also
need Git and `shards`. Treat 1.20 as the compatibility floor; for a new Amber
application, use the latest stable Crystal release that satisfies this range.

```bash
crystal --version
shards --version
git --version
```

A database is not required for the generated core web app.

## Homebrew

The tap and formula use an underscore. Install the official formula with its
fully qualified name, then verify the `amber` executable:

```bash
brew install amberframework/amber_cli/amber_cli
amber --version
```

The fully qualified command follows Homebrew's tap-trust model and trusts only
the requested formula. The formula is `amber_cli` and the installed executable
is `amber`.

Expect Amber CLI `2.0.3` or newer. Version 2.0.3 includes the branded V2 web
starter and its browser-native import map.

## Direct archive

Choose `darwin-arm64` on Apple Silicon macOS or `linux-x86_64` on x86_64 Linux:

```bash
version=v2.0.3
platform=darwin-arm64
asset="amber_cli-${platform}.tar.gz"

curl -fLO "https://github.com/amberframework/amber_cli/releases/download/${version}/${asset}"
curl -fLO "https://github.com/amberframework/amber_cli/releases/download/${version}/${asset}.sha256"
shasum -a 256 -c "${asset}.sha256"
tar -xzf "${asset}"
install -m 0755 amber amber-lsp /usr/local/bin/
amber --version
```

On Linux, use `sha256sum -c`. Prefix only the `install` command with `sudo` if
needed.

## Linux ARM64 source install

CLI 2.0.3 has no `linux-arm64` release archive. Until the next CLI release,
build the tagged CLI source on the ARM64 machine instead of downloading the
x86_64 archive.

**Run from: a directory where the temporary `amber_cli/` checkout can be
created.**

```bash
sudo apt-get update
sudo apt-get install -y libsqlite3-dev
git clone --branch v2.0.3 --depth 1 https://github.com/amberframework/amber_cli.git
cd amber_cli
shards install --production
crystal build src/amber_cli.cr -o amber --release
crystal build src/amber_lsp.cr -o amber-lsp --release
sudo install -m 0755 amber amber-lsp /usr/local/bin/
amber --version
```

This produces native ARM64 executables because Crystal builds for the current
host. The platform CI uses a GitHub-hosted ARM64 Linux machine to generate,
spec, and compile the clean web app. Source installation is a narrower promise
than the release-gated x86_64 archive path: report the distribution, Crystal
version, and `uname -m` with any issue.

## Verify the installation

```bash
amber new amber_beta_smoke --type web
cd amber_beta_smoke
crystal spec
crystal build src/amber_beta_smoke.cr -o bin/amber_beta_smoke
amber watch
```

In another terminal:

```bash
curl --fail http://127.0.0.1:3000/
curl --fail http://127.0.0.1:3000/css/app.css
```

Both requests must succeed. The generated `shard.yml` pins
`amberframework/amber` at `2.0.0-beta.2`; it must not reference a personal fork.

## Manual framework dependency

For an existing Crystal app:

```yaml
dependencies:
  amber:
    github: amberframework/amber
    version: 2.0.0-beta.2

crystal: ">= 1.20.0, < 2.0"
```

Do not use the moving `v2-dev` branch in a reproducible beta application.

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
`otool -L "$(command -v amber)"` in an issue.

If there is no archive for another architecture, the platform is not
release-gated. Linux ARM64 is the documented source-build exception because its
generated web compile job is part of CI.
