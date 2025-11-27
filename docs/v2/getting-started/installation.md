---
title: "Installation"
section: "getting-started"
order: 10
description: "Installing Crystal and setting up your development environment for Amber V2"
---

# Installation

Amber 2.0 takes a different approach from V1. Instead of a CLI tool that generates applications, V2 uses direct shard dependencies. This means:

- **No CLI installation required** - Just add Amber to your `shard.yml`
- **No Node.js/npm required** - Asset Pipeline uses native ESM, no bundler needed
- **No Redis required by default** - Pluggable adapters let you choose your backend

## Prerequisites

Before you begin, ensure you have the following installed:

### Crystal Language

Crystal 1.10.0 or higher is required.

#### macOS

```bash
# Using Homebrew
brew install crystal

# Using MacPorts
sudo port install crystal
```

#### Ubuntu / Debian

```bash
curl -fsSL https://crystal-lang.org/install.sh | sudo bash
```

#### Other Linux Distributions

See the [Crystal Installation Guide](https://crystal-lang.org/install/) for instructions for your distribution.

### Database

Amber works with PostgreSQL (default), MySQL, or SQLite.

#### PostgreSQL (Recommended)

```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib libpq-dev
```

#### MySQL

```bash
# macOS
brew install mysql

# Ubuntu/Debian
sudo apt-get install mysql-server libmysqlclient-dev
```

#### SQLite

```bash
# macOS
brew install sqlite

# Ubuntu/Debian
sudo apt-get install sqlite3 libsqlite3-dev
```

### Git

```bash
# macOS (usually pre-installed, or via Xcode Command Line Tools)
xcode-select --install

# Ubuntu/Debian
sudo apt-get install git
```

## Getting Amber V2

Unlike V1, Amber V2 is added directly to your project's `shard.yml`. There's no global installation step.

### For New Projects

Create a new directory and `shard.yml`:

```bash
mkdir my-app
cd my-app
```

Create `shard.yml` with Amber V2 dependencies:

```yaml
name: my-app
version: 0.1.0
crystal: ">= 1.10.0"

dependencies:
  amber:
    github: crimson-knight/amber
    branch: master

  # ORM
  grant:
    github: crimson-knight/grant
    branch: main

  # Asset Pipeline (optional - for frontend assets)
  asset_pipeline:
    github: amberframework/asset_pipeline

  # Database adapters (all required by Grant at compile time)
  pg:
    github: will/crystal-pg
  mysql:
    github: crystal-lang/crystal-mysql
  sqlite3:
    github: crystal-lang/crystal-sqlite3

targets:
  my-app:
    main: src/my-app.cr
```

Then install dependencies:

```bash
shards install
```

## What's Different from V1?

| Feature | Amber V1 | Amber V2 |
|---------|----------|----------|
| Installation | `brew install amber` or build CLI from source | Add to `shard.yml` |
| Create app | `amber new myapp` | Create `shard.yml` manually |
| Scaffolding | `amber g scaffold Pet name:string` | Create files manually |
| ORM | Granite | Grant (ActiveRecord-style) |
| Assets | Webpack + npm | Asset Pipeline (native ESM) |
| Sessions | Redis required | Cookie, Memory, or Redis adapters |

## V2 Project Dependencies

Here's a complete `shard.yml` for a typical V2 application:

```yaml
name: my-app
version: 0.1.0
crystal: ">= 1.10.0"

dependencies:
  # Core framework
  amber:
    github: crimson-knight/amber
    branch: master

  # ORM with ActiveRecord-style features
  grant:
    github: crimson-knight/grant
    branch: main

  # Native ESM asset pipeline (no Webpack/npm)
  asset_pipeline:
    github: amberframework/asset_pipeline

  # File uploads (optional)
  gemma:
    github: amberframework/gemma

  # Database adapters (all required by Grant at compile time)
  pg:
    github: will/crystal-pg
  mysql:
    github: crystal-lang/crystal-mysql
  sqlite3:
    github: crystal-lang/crystal-sqlite3

development_dependencies:
  ameba:
    github: crystal-ameba/ameba

targets:
  my-app:
    main: src/my-app.cr
```

## Verifying Your Installation

After running `shards install`, verify Crystal and the dependencies:

```bash
# Check Crystal version
crystal version
# Should output: Crystal 1.10.0 or higher

# Check shards installed correctly
shards list
# Should show amber, grant, asset_pipeline, etc.

# Compile a simple test
echo 'require "amber"; puts "Amber loaded!"' > test.cr
crystal run test.cr
rm test.cr
```

## Next Steps

With dependencies installed, you're ready to build your first Amber V2 application:

- **[Getting Started Tutorial](index/)** - Build a complete Pet Tracker app
- **[Grant ORM Guide](../guides/models/grant/)** - Learn the new ActiveRecord-style ORM
- **[Asset Pipeline Guide](../guides/assets/)** - Modern frontend without Webpack
- **[Schema API Guide](../guides/schema-api/)** - Type-safe request validation

## Troubleshooting

### Crystal not found

Ensure Crystal is in your PATH:

```bash
echo $PATH
which crystal
```

If installed via Homebrew, you may need to add it:

```bash
export PATH="/usr/local/opt/crystal/bin:$PATH"
```

### Shard installation fails

Check your `shard.yml` syntax and ensure you have network access to GitHub:

```bash
# Test GitHub access
curl -I https://github.com/crimson-knight/amber

# Clear shard cache and retry
rm -rf lib .shards
shards install
```

### Database connection errors

Ensure your database server is running:

```bash
# PostgreSQL
pg_isready

# MySQL
mysqladmin ping

# Or check service status
brew services list  # macOS
systemctl status postgresql  # Linux
```

### OpenSSL issues on macOS

If you see linker errors related to SSL:

```bash
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
```
