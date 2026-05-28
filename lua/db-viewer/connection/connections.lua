-- lua/db-viewer/connection/connections.lua
-- CRUD access for the connections table.

local db = require("db-viewer.connection.db")

local M = {}

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

local function validate(conn)
  assert(type(conn.name) == "string" and conn.name ~= "", "connection.name is required")
  assert(type(conn.driver) == "string" and conn.driver ~= "", "connection.driver is required")
  assert(type(conn.database) == "string" and conn.database ~= "", "connection.database is required")
end

function M.upsert(conn)
  validate(conn)
  M.ensure_table()

  db.exec(string.format(
    [[
      INSERT INTO connections (name, driver, host, port, database_name, username, password)
      VALUES (%s, %s, %s, %s, %s, %s, %s)
      ON CONFLICT(name) DO UPDATE SET
        driver=excluded.driver,
        host=excluded.host,
        port=excluded.port,
        database_name=excluded.database_name,
        username=excluded.username,
        password=excluded.password;
    ]],
    db.quote(conn.name),
    db.quote(conn.driver),
    db.quote(conn.host),
    db.quote(conn.port),
    db.quote(conn.database),
    db.quote(conn.user),
    db.quote(conn.password)
  ))
end

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

function M.get_by_name(name)
  M.ensure_table()
  local rows = db.query(string.format(
    [[
      SELECT id, name, driver, host, port, database_name, username, password
      FROM connections
      WHERE name = %s
      LIMIT 1;
    ]],
    db.quote(name)
  ))

  return from_row(rows[1])
end

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

function M.delete_by_name(name)
  M.ensure_table()
  db.exec(string.format("DELETE FROM connections WHERE name = %s;", db.quote(name)))
end

function M.delete_all()
  M.ensure_table()
  db.exec("DELETE FROM connections;")
end

return M
