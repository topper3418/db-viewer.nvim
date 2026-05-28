-- lua/db-viewer/connection/init.lua
-- Public storage API for persistent connections and saved queries.

local db = require("db-viewer.connection.db")
local connections = require("db-viewer.connection.connections")
local saved_queries = require("db-viewer.connection.saved_queries")

local M = {}

local initialized = false

---Initialize DB and required tables once per module lifecycle.
local function ensure_ready()
  if initialized then
    return
  end

  db.init()
  connections.ensure_table()
  saved_queries.ensure_table()
  initialized = true
end

---Override the sqlite DB file path used by this module.
---@param path string
function M.set_db_path(path)
  db.set_path(path)
  initialized = false
end

---Create or update a stored connection.
---@param conn DbViewerConnection
function M.add(conn)
  ensure_ready()
  connections.upsert(conn)
end

---Delete a connection by name.
---@param name string
function M.remove(name)
  ensure_ready()
  connections.delete_by_name(name)
end

---Get a connection by name.
---@param name string
---@return DbViewerConnection|nil
function M.get(name)
  ensure_ready()
  return connections.get_by_name(name)
end

---List all connections sorted by name.
---@return DbViewerConnection[]
function M.list()
  ensure_ready()
  return connections.list_all()
end

---Reset the active DB file, primarily for tests.
---@param opts? {db_path?: string}
function M.reset(opts)
  if opts and opts.db_path then
    db.set_path(opts.db_path)
  end
  db.reset_file()
  initialized = false
  ensure_ready()
end

M.saved_queries = {
  ---Insert a saved query for a connection id.
  ---@param connection_id integer
  ---@param query_text string
  ---@param args table|nil
  add = function(connection_id, query_text, args)
    ensure_ready()
    saved_queries.add(connection_id, query_text, args)
  end,
  ---List saved queries for a connection id.
  ---@param connection_id integer
  ---@return table[]
  list = function(connection_id)
    ensure_ready()
    return saved_queries.list_for_connection_id(connection_id)
  end,
  ---Delete one saved query row by id.
  ---@param id integer
  remove = function(id)
    ensure_ready()
    saved_queries.delete(id)
  end,
  ---Delete all saved query rows.
  clear = function()
    ensure_ready()
    saved_queries.delete_all()
  end,
}

return M
