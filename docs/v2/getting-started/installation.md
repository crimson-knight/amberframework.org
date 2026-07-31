---
title: "Installation"
section: "getting-started"
order: 10
description: "Install Amber CLI 2.0.2 on supported macOS and Linux systems"
---

# Install Amber V2 Beta

The supported onboarding path uses the standalone Amber CLI. The framework
itself remains a shard dependency generated into each application.

## Supported systems

- Apple Silicon macOS
- x86_64 Linux

Intel macOS, Linux ARM64, and Windows are not release-gated in this beta.

## Prerequisites

Install Crystal 1.20 or newer, but earlier than 2.0, using the
[official Crystal instructions](https://crystal-lang.org/install/). You also
need Git and `shards`.

```bash
crystal --version
shards --version
git --version
```

A database is not required for the generated core web app.

## Homebrew

The tap and formula use an underscore. The installed executable is `amber`:

```bash
brew tap amberframework/amber_cli
brew install amber_cli
amber --version
```

Expect Amber CLI `2.0.2` or newer.

## Direct archive

Choose `darwin-arm64` on Apple Silicon macOS or `linux-x86_64` on x86_64 Linux:

```bash
version=v2.0.2
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
brew upgrade amber_cli
# or
brew uninstall amber_cli
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

If there is no archive for your architecture, the platform is not release-gated
yet. A source build can help contributors evaluate it, but is not the supported
installation promise.
