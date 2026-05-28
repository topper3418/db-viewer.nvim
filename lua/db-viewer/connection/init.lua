-- lua/db-viewer/connection/init.lua
-- Public storage API for persistent connections and saved queries.

local db = require("db-viewer.connection.db")
local connections = require("db-viewer.connection.connections")
local saved_queries = require("db-viewer.connection.saved_queries")

local M = {}

local initialized = false

local function ensure_ready()
  if initialized then
    return
  end

  db.init()
  connections.ensure_table()
  saved_queries.ensure_table()
  initialized = true
end

function M.set_db_path(path)
  db.set_path(path)
  initialized = false
end

function M.add(conn)
  ensure_ready()
  connections.upsert(conn)
end

function M.remove(name)
  ensure_ready()
  connections.delete_by_name(name)
end

function M.get(name)
  ensure_ready()
  return connections.get_by_name(name)
end

function M.list()
  ensure_ready()
  return connections.list_all()
end

function M.reset(opts)
  if opts and opts.db_path then
    db.set_path(opts.db_path)
  end
  db.reset_file()
  initialized = false
  ensure_ready()
end

M.saved_queries = {
  add = function(connection_name, query_text, args)
    ensure_ready()
    saved_queries.add(connection_name, query_text, args)
  end,
  list = function(connection_name)
    ensure_ready()
    return saved_queries.list_for_connection(connection_name)
  end,
  remove = function(id)
    ensure_ready()
    saved_queries.delete(id)
  end,
  clear = function()
    ensure_ready()
    saved_queries.delete_all()
  end,
}

return M
