-- lua/db-viewer/connection/saved_queries.lua
-- CRUD access for saved SQL queries tied to a connection.

local db = require("db-viewer.connection.db")

local M = {}

function M.ensure_table()
  db.exec([[ 
    CREATE TABLE IF NOT EXISTS saved_queries (
      id INTEGER PRIMARY KEY,
      connection_id INTEGER NOT NULL,
      query_text TEXT NOT NULL,
      args_text TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(connection_id) REFERENCES connections(id) ON DELETE CASCADE
    );
  ]])
end

local function decode_args(args_text)
  if args_text == nil or args_text == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, args_text)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

local function get_connection_id_by_name(connection_name)
  local rows = db.query(string.format(
    "SELECT id FROM connections WHERE name = %s LIMIT 1;",
    db.quote(connection_name)
  ))
  if #rows == 0 then
    error(("unknown connection: %s"):format(connection_name))
  end
  return rows[1].id
end

function M.add(connection_name, query_text, args)
  assert(type(connection_name) == "string" and connection_name ~= "", "connection name is required")
  assert(type(query_text) == "string" and query_text ~= "", "query text is required")

  M.ensure_table()
  local connection_id = get_connection_id_by_name(connection_name)
  local args_text = vim.json.encode(args or {})

  db.exec(string.format(
    "INSERT INTO saved_queries (connection_id, query_text, args_text) VALUES (%s, %s, %s);",
    db.quote(connection_id),
    db.quote(query_text),
    db.quote(args_text)
  ))
end

function M.list_for_connection(connection_name)
  assert(type(connection_name) == "string" and connection_name ~= "", "connection name is required")

  M.ensure_table()
  local rows = db.query(string.format(
    [[
      SELECT sq.id, sq.connection_id, sq.query_text, sq.args_text
      FROM saved_queries sq
      JOIN connections c ON c.id = sq.connection_id
      WHERE c.name = %s
      ORDER BY sq.id ASC;
    ]],
    db.quote(connection_name)
  ))

  local results = {}
  for _, row in ipairs(rows) do
    results[#results + 1] = {
      id = row.id,
      connection_id = row.connection_id,
      query = row.query_text,
      args = decode_args(row.args_text),
    }
  end
  return results
end

function M.delete(id)
  M.ensure_table()
  db.exec(string.format("DELETE FROM saved_queries WHERE id = %s;", db.quote(id)))
end

function M.delete_all()
  M.ensure_table()
  db.exec("DELETE FROM saved_queries;")
end

return M
