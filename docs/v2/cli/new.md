# amber new

The `amber new` command creates a new Amber V2 application with a complete directory structure and configuration.

## Usage

```bash
amber new [OPTIONS] NAME
```

## Arguments

| Argument | Description |
|----------|-------------|
| `NAME` | Name of the project (also used as directory name). Use `.` to create in current directory. |

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-d DATABASE`, `--database=DATABASE` | Select the database engine: `pg`, `mysql`, or `sqlite` | `pg` |
| `-t TEMPLATE`, `--template=TEMPLATE` | Select the template engine: `slang` or `ecr` | `slang` |
| `-r RECIPE`, `--recipe=RECIPE` | Use a named recipe for scaffolding | - |
| `-y`, `--assume-yes` | Assume yes to disable interactive mode | `false` |
| `--no-deps` | Don't run `shards install` after creation | `false` |
| `-h`, `--help` | Show help information | - |

## Examples

### Create a new application with PostgreSQL and Slang

```bash
amber new my_blog
cd my_blog
shards install
crystal build src/my_blog.cr -o bin/my_blog
./bin/my_blog
```

### Create with MySQL and ECR templates

```bash
amber new my_app -d mysql -t ecr
```

### Create with SQLite (great for development)

```bash
amber new quick_app -d sqlite
```

### Create in current directory

```bash
mkdir my_project
cd my_project
amber new .
```

## Generated Structure

The `amber new` command generates the following directory structure:

```
my_app/
├── config/
│   ├── application.cr      # Main application configuration
│   ├── routes.cr           # Route definitions
│   ├── environments/       # Environment-specific configs
│   └── initializers/       # Initialization code
├── db/
│   └── migrations/         # Database migrations
├── public/
│   ├── css/               # Static CSS files
│   ├── js/                # Static JavaScript files
│   └── img/               # Static images
├── spec/                   # Test files
├── src/
│   ├── controllers/
│   │   ├── application_controller.cr
│   │   └── home_controller.cr
│   ├── models/            # Grant ORM models
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.slang
│   │   └── home/
│   │       └── index.slang
│   └── my_app.cr          # Main entry point
├── .amber.yml             # Amber CLI configuration
└── shard.yml              # Crystal dependencies
```

## Generated Dependencies

New V2 applications include these dependencies by default:

```yaml
dependencies:
  # Amber Framework V2
  amber:
    github: crimson-knight/amber
    branch: master

  # Grant ORM (replaces Granite in V2)
  grant:
    github: crimson-knight/grant
    branch: main

  # Native Asset Pipeline (no Webpack required)
  asset_pipeline:
    github: amberframework/asset_pipeline

  # File uploads
  gemma:
    github: crimson-knight/gemma

  # Database adapters
  pg:
    github: will/crystal-pg
  mysql:
    github: crystal-lang/crystal-mysql
  sqlite3:
    github: crystal-lang/crystal-sqlite3
```

## Quick Start

After creating a new application:

```bash
# Install dependencies
shards install

# Build the application
crystal build src/my_app.cr -o bin/my_app

# Run the server
./bin/my_app

# Visit http://localhost:3000
```

The homepage displays a welcome message confirming your application is running successfully.

## Configuration File (.amber.yml)

The `.amber.yml` file is created in your project root and stores metadata used by the CLI:

```yaml
app: my_app
author: Your Name
email: your.email@example.com
database: pg
language: crystal
model: grant
recipe_source: amberframework/recipes
template: slang
```

## V2 Changes from V1

- **Grant ORM** instead of Granite for database access
- **No npm/Webpack** - native Crystal asset pipeline
- **Simplified configuration** - aligned with V2 Settings API
- **Default welcome page** - applications work immediately after compile
