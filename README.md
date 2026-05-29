# db-viewer

Manage SQL connection metadata and saved query history from Neovim.

## Current Functionality

- Persistent project-local storage in `.nvim/db-viewer.db`.
- Connection records stored in SQLite (`connections` table).
- Saved queries stored in SQLite (`saved_queries` table) with foreign key to `connections.id`.
- Safe value binding for CRUD operations using sqlite parameter binding (`@p1`, `@p2`, ...).
- Built-in editor workflow for SQLite connection configs.
- User commands for creating and editing saved connection configs.
- Basic schema/index bootstrap on first use.

### Commands

- `:DbViewerConnectionNew`
Creates an editable `acwrite` buffer for a new connection config. Save with `:write`.

- `:DbViewerConnectionEdit {name}`
Opens an existing connection config for editing by saved connection name.

### Connection Editor Format

The editor uses a simple key/value format:

```ini
name = "local"
driver = "sqlite"
path = "/absolute/path/to/database.db"
```

Current editor support is SQLite-only (`driver = "sqlite"`).

### Storage Notes

- State is project-scoped by current working directory.
- Opening Neovim in different project roots gives each project its own `.nvim/db-viewer.db`.
- `saved_queries.connection_id` references `connections.id` and cascades on connection delete.

## Installation

Example with `lazy.nvim`:

```lua
{
  "travisopperud/db-viewer",
  config = function()
    require("db-viewer").setup({})
  end,
}
```

## Programmatic API (Current)

```lua
local connection = require("db-viewer.connection")

-- upsert connection
connection.add({
  name = "local",
  driver = "sqlite",
  database = "/absolute/path/to/database.db",
})

local row = connection.get("local")
local connection_id = row.id

-- saved queries are keyed by connection_id
connection.saved_queries.add(connection_id, "select * from users where id = ?", { 42 })
local queries = connection.saved_queries.list(connection_id)
```

## Development Setup

### 1. Clone

```sh
git clone https://github.com/travisopperud/db-viewer.git
cd db-viewer
```

### 2. Dependencies

- Neovim 0.9+
- `sqlite3` CLI
- `plenary.nvim` available at:

```sh
$(nvim --headless -u NONE -c 'lua print(vim.fn.stdpath("data"))' -c q 2>&1 | tail -1)/lazy/plenary.nvim
```

Optional:

```sh
luarocks install luacheck
cargo install stylua
```

### 3. Checks

```sh
make test
make lint
make fmt
```

SQLite-backed specs are marked pending when `sqlite3` is unavailable.

## Development Roadmap

### Near-Term

- Query runner UI (buffer-based results view with headers and row pagination).
- Connection list picker (open/edit/delete from one command).
- Saved query manager UI (list, run, rename, delete).
- Validation and UX polish in editor buffers (inline errors, required field hints).

### Mid-Term

- Driver adapters for PostgreSQL and MySQL query execution paths.
- Secrets strategy for credentials (avoid plaintext persistence by default).
- Query argument UX (prompt + typed arg serialization).
- Better completion and discoverability for user commands.

### Longer-Term

- Schema browser (tables/views/columns, constraints, indexes).
- Result actions (copy row/cell, export CSV/JSON, re-run with modified args).
- Async execution/cancellation and long-query status notifications.
- Optional telescope/fzf integrations.
