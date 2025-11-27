# Amber CLI

The Amber CLI is a command-line tool that helps you create and manage Amber Framework V2 applications. It provides scaffolding, code generation, and development utilities.

## Installation

### Via Homebrew (Recommended for macOS)

```bash
brew tap crimson-knight/amber-v2
brew install --HEAD amber-v2
```

> **Note:** The `--HEAD` flag installs from the latest Git source. This will be updated when versioned releases are available.

### From Source

```bash
git clone https://github.com/amberframework/amber_cli.git
cd amber_cli
shards install
shards build --release
```

The binary will be available at `bin/amber`.

## Available Commands

| Command | Description |
|---------|-------------|
| `new` | Generate a new Amber V2 application |
| `watch` | Run the application with auto-reload on file changes |
| `routes` | Display all registered routes |
| `generate` | Generate scaffolds, models, and migrations |

## Getting Help

For help with any command:

```bash
amber --help
amber new --help
```

## V2 CLI Changes

The Amber V2 CLI has been updated to support the new V2 ecosystem:

- **Grant ORM**: Generated applications use Grant instead of Granite for database access
- **Native Asset Pipeline**: No Webpack or npm dependencies required
- **Simplified Configuration**: Cleaner configuration files aligned with V2 settings API
