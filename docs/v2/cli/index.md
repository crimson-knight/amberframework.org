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

The binary will be available at `bin/amber`. You can move it to a directory in your PATH:

```bash
sudo mv bin/amber /usr/local/bin/
```

## Global Options

These options are available for all commands:

| Option | Description |
|--------|-------------|
| `--no-color` | Disable colored output |
| `-h`, `--help` | Show help information |

## Available Commands

| Command | Alias | Description |
|---------|-------|-------------|
| [`new`](new.md) | `n` | Generate a new Amber V2 application |
| `watch` | `w` | Run the application with auto-reload on file changes |
| `routes` | `r` | Display all registered routes |
| `generate` | `g` | Generate scaffolds, models, and migrations |

### Quick Reference

```bash
# Create a new application
amber new my_app

# Create with specific database and template
amber new my_app -d sqlite -t ecr

# Start development server with auto-reload
amber watch

# View all routes
amber routes

# Generate a scaffold
amber generate scaffold Post title:string body:text
```

## Getting Help

For help with any command:

```bash
amber --help
amber new --help
amber generate --help
```

## V2 CLI Changes from V1

The Amber V2 CLI has been updated to support the new V2 ecosystem:

| Feature | V1 | V2 |
|---------|----|----|
| **ORM** | Granite | Grant |
| **Asset Pipeline** | Webpack/npm | Native Crystal (no npm required) |
| **Configuration** | YAML-based | Settings API |
| **Dependencies** | amberframework org | crimson-knight org |

### Key Differences

1. **Grant ORM**: Generated applications use Grant instead of Granite for database access. Grant provides an ActiveRecord-style API with improved Crystal integration.

2. **Native Asset Pipeline**: No Webpack or npm dependencies required. The native Crystal asset pipeline handles JavaScript bundling and CSS processing.

3. **Simplified Configuration**: Cleaner configuration files aligned with V2 Settings API. Environment-specific settings are handled through Crystal code rather than YAML files.

4. **Immediate Functionality**: New applications include a working homepage out of the box - just compile and run.

## Command Documentation

- **[amber new](new.md)** - Complete guide to creating new applications, including all options for name interpretation, database selection, and template engines.
