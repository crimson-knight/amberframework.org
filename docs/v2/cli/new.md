# amber new

The `amber new` command creates a new Amber V2 application with a complete directory structure and configuration.

## Usage

```bash
amber new [OPTIONS] NAME
```

## Arguments

| Argument | Description |
|----------|-------------|
| `NAME` | The project name or path. Can be a simple name, a path, or `.` for the current directory. |

### Name Interpretation

The `NAME` argument determines both **where** the project is created and **what the project is named**:

| Input | Project Name | Location Created |
|-------|--------------|------------------|
| `myapp` | `myapp` | `./myapp/` |
| `projects/myapp` | `myapp` | `./projects/myapp/` |
| `foo/bar/baz` | `baz` | `./foo/bar/baz/` |
| `.` | Current directory's name | Current directory (no new folder created) |

**Key behaviors:**

1. **Simple name** (`amber new myapp`): Creates a directory named `myapp` in the current location. The project name is `myapp`.

2. **Path with directories** (`amber new projects/myapp`): Creates the full directory path `./projects/myapp/`. The project name is extracted from the final component (`myapp`), not the full path.

3. **Dot notation** (`amber new .`): Creates the project in the current directory without creating a new folder. The project name is taken from the current directory's name.

4. **Existing directories**: If the target directory already exists, files will be created/overwritten without warning. Use with caution.

### Naming Restrictions

- **No spaces**: Names and paths cannot contain spaces
- If you attempt to use spaces, you'll see an error with a suggested fix:
  ```
  Error: Path and project name can't contain a space.
  Replace spaces with underscores or dashes.
  /path/my cool app should be /path/my_cool_app
  ```

## Options

| Option | Description | Default | Valid Values |
|--------|-------------|---------|--------------|
| `-d DATABASE`, `--database=DATABASE` | Database engine to configure | `pg` | `pg`, `mysql`, `sqlite` |
| `-t TEMPLATE`, `--template=TEMPLATE` | Template engine for views | `slang` | `slang`, `ecr` |
| `-r RECIPE`, `--recipe=RECIPE` | Use a named recipe for scaffolding | - | Recipe name |
| `-y`, `--assume-yes` | Skip interactive prompts | `false` | - |
| `--no-deps` | Skip running `shards install` | `false` | - |
| `-h`, `--help` | Show help information | - | - |
| `--no-color` | Disable colored output | `false` | - |

### Database Options

| Value | Description |
|-------|-------------|
| `pg` | PostgreSQL (default, recommended for production) |
| `mysql` | MySQL/MariaDB |
| `sqlite` | SQLite (great for development and small applications) |

The database option affects:
- The `database` field in `.amber.yml`
- Configuration suggestions in generated files

### Template Engine Options

| Value | Description |
|-------|-------------|
| `slang` | Slang templates (default) - clean, indentation-based syntax |
| `ecr` | ECR templates - HTML with embedded Crystal (similar to ERB) |

The template option affects:
- The `template` field in `.amber.yml`
- View file extensions (`.slang` or `.ecr`)
- Layout file extensions
- Render calls in generated controllers

## Examples

### Basic Usage

```bash
# Create with defaults (PostgreSQL + Slang)
amber new my_blog

# Create with MySQL and ECR templates
amber new my_app -d mysql -t ecr

# Create with SQLite (great for development)
amber new quick_app -d sqlite
```

### Using Paths

```bash
# Create in a subdirectory (project name: "myapp")
amber new projects/myapp

# Create nested project structure
amber new ~/code/amber/my_new_project
```

### Using Current Directory

```bash
# First create and enter the directory
mkdir my_project
cd my_project

# Then initialize Amber in this directory
amber new .
```

### Non-Interactive Mode

```bash
# Skip all prompts (useful for scripts)
amber new automated_app -y

# Skip dependency installation
amber new quick_test --no-deps
```

### Combined Options

```bash
# SQLite + ECR templates + skip deps
amber new prototype -d sqlite -t ecr --no-deps -y
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
│   │   ├── application_controller.cr  # Base controller
│   │   └── home_controller.cr         # Default homepage controller
│   ├── models/            # Grant ORM models
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.slang      # Main layout
│   │   └── home/
│   │       └── index.slang            # Homepage view
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
    version: ~> 1.4.3
```

## Configuration Files

### .amber.yml

The `.amber.yml` file stores metadata used by the CLI:

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

### shard.yml

The `shard.yml` file defines Crystal dependencies and build targets:

```yaml
name: my_app
version: 0.1.0

targets:
  my_app:
    main: src/my_app.cr
```

## Quick Start

After creating a new application:

```bash
# Navigate to project (if using a name, not ".")
cd my_app

# Install dependencies
shards install

# Build the application
crystal build src/my_app.cr -o bin/my_app

# Run the server
./bin/my_app

# Visit http://localhost:3000
```

The homepage displays a welcome message confirming your application is running successfully.

## V2 Changes from V1

- **Grant ORM** instead of Granite for database access
- **No npm/Webpack** - native Crystal asset pipeline
- **Simplified configuration** - aligned with V2 Settings API
- **Default welcome page** - applications work immediately after compile
- **Updated dependencies** - all V2 libraries from crimson-knight organization

## Troubleshooting

### "Path and project name can't contain a space"

Use underscores or dashes instead of spaces:

```bash
# Wrong
amber new "My Cool App"

# Correct
amber new my_cool_app
amber new my-cool-app
```

### Ameba postinstall fails

This is a known issue with Crystal 1.16. The application will still compile correctly:

```bash
# If shards install shows ameba errors, continue with:
crystal build src/my_app.cr -o bin/my_app
```

### Project name doesn't match directory

If you use a path like `amber new projects/myapp`, remember that:
- The **directory** is created at `./projects/myapp/`
- The **project name** is just `myapp`
- All internal references use `myapp`, not `projects/myapp`
