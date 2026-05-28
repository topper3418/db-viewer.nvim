-- lua/db-viewer/connection/connections.lua
-- CRUD access for the connections table.

local db = require("db-viewer.connection.db")

local M = {}

---Create the `connections` table if it does not already exist.
function M.ensure_table()
  db.exec([[ 
    CREATE TABLE IF NOT EXISTS connections (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL UNIQUE,
      driver TEXT NOT NULL,
      host TEXT,
      port INTEGER,
      database_name TEXT NOT NULL,
      username TEXT,
      password TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
  ]])
end

---Validate required user-facing fields for connection records.
---@param conn DbViewerConnection
local function validate(conn)
  assert(type(conn.name) == "string" and conn.name ~= "", "connection.name is required")
  assert(type(conn.driver) == "string" and conn.driver ~= "", "connection.driver is required")
  assert(type(conn.database) == "string" and conn.database ~= "", "connection.database is required")
end

---Insert or update a connection keyed by unique `name`.
---When `name` already exists, values from the attempted insert (`excluded.*`)
---replace the stored row.
---@param conn DbViewerConnection
function M.upsert(conn)
  validate(conn)
  M.ensure_table()

  db.exec_prepared(
    [[
      INSERT INTO connections (name, driver, host, port, database_name, username, password)
      VALUES (@p1, @p2, @p3, @p4, @p5, @p6, @p7)
      ON CONFLICT(name) DO UPDATE SET
        driver=excluded.driver,
        host=excluded.host,
        port=excluded.port,
        database_name=excluded.database_name,
        username=excluded.username,
        password=excluded.password;
    ]],
    { conn.name, conn.driver, conn.host, conn.port, conn.database, conn.user, conn.password }
  )
end

---Map raw DB row column names to the plugin's connection shape.
---@param row table|nil
---@return DbViewerConnection|nil
local function from_row(row)
  if not row then
    return nil
  end

  return {
    id = row.id,
    name = row.name,
    driver = row.driver,
    host = row.host,
    port = row.port,
    database = row.database_name,
    user = row.username,
    password = row.password,
  }
end

---Fetch one connection by its unique name.
---@param name string
---@return DbViewerConnection|nil
function M.get_by_name(name)
  M.ensure_table()
  local rows = db.query_prepared(
    [[
      SELECT id, name, driver, host, port, database_name, username, password
      FROM connections
      WHERE name = @p1
      LIMIT 1;
    ]],
    { name }
  )

  return from_row(rows[1])
end

---List all stored connections sorted by name.
---@return DbViewerConnection[]
function M.list_all()
  M.ensure_table()
  local rows = db.query([[ 
    SELECT id, name, driver, host, port, database_name, username, password
    FROM connections
    ORDER BY name ASC;
  ]])

  local results = {}
  for _, row in ipairs(rows) do
    results[#results + 1] = from_row(row)
  end
  return results
end

---Delete a connection by name.
---@param name string
function M.delete_by_name(name)
  M.ensure_table()
  db.exec_prepared("DELETE FROM connections WHERE name = @p1;", { name })
end

---Delete all connections.
function M.delete_all()
  M.ensure_table()
  db.exec("DELETE FROM connections;")
end

return M
