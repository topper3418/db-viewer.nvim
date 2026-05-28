-- lua/db-viewer/connection/saved_queries.lua
-- CRUD access for saved SQL queries tied to a connection.

local db = require("db-viewer.connection.db")

local M = {}

---Create the `saved_queries` table if it does not already exist.
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

    -- Supports list_for_connection_id WHERE connection_id = ? ORDER BY id.
    CREATE INDEX IF NOT EXISTS idx_saved_queries_connection_id_id
      ON saved_queries(connection_id, id);

    -- Useful for future "recent queries" views.
    CREATE INDEX IF NOT EXISTS idx_saved_queries_created_at
      ON saved_queries(created_at);
  ]])
end

---Decode stored JSON args text into a Lua list.
---@param args_text string|nil
---@return table
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

---Insert a saved query row for an existing connection id.
---@param connection_id integer
---@param query_text string
---@param args table|nil
function M.add(connection_id, query_text, args)
  assert(type(connection_id) == "number", "connection id is required")
  assert(type(query_text) == "string" and query_text ~= "", "query text is required")

  M.ensure_table()
  local args_text = vim.json.encode(args or {})

  db.exec_prepared(
    "INSERT INTO saved_queries (connection_id, query_text, args_text) VALUES (@p1, @p2, @p3);",
    { connection_id, query_text, args_text }
  )
end

---List saved queries for a connection id.
---@param connection_id integer
---@return table[]
function M.list_for_connection_id(connection_id)
  assert(type(connection_id) == "number", "connection id is required")

  M.ensure_table()
  local rows = db.query_prepared(
    [[
      SELECT sq.id, sq.connection_id, sq.query_text, sq.args_text
      FROM saved_queries sq
      WHERE sq.connection_id = @p1
      ORDER BY sq.id ASC;
    ]],
    { connection_id }
  )

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

---Delete a saved query by its id.
---@param id integer
function M.delete(id)
  M.ensure_table()
  db.exec_prepared("DELETE FROM saved_queries WHERE id = @p1;", { id })
end

---Delete all saved queries.
function M.delete_all()
  M.ensure_table()
  db.exec("DELETE FROM saved_queries;")
end

return M
