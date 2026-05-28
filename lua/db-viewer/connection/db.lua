-- lua/db-viewer/connection/db.lua
-- SQLite database access helpers for db-viewer.

local M = {}

local state = {
  db_path = vim.fn.stdpath("data") .. "/db-viewer/db-viewer.sqlite3",
}

local function ensure_parent_dir(path)
  local parent = vim.fn.fnamemodify(path, ":h")
  if parent and parent ~= "." and parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end
end

local function run_sql(args, sql)
  local command = { "sqlite3", state.db_path }
  for _, arg in ipairs(args) do
    command[#command + 1] = arg
  end
  -- Enable FK checks on every command because sqlite3 CLI opens a new process each call.
  command[#command + 1] = "PRAGMA foreign_keys = ON; " .. sql

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    error(("sqlite3 error (%s): %s"):format(state.db_path, output))
  end
  return output
end

function M.set_path(path)
  assert(type(path) == "string" and path ~= "", "db path must be a non-empty string")
  state.db_path = path
end

function M.get_path()
  return state.db_path
end

function M.quote(value)
  if value == nil then
    return "NULL"
  end
  if type(value) == "number" then
    return tostring(value)
  end

  local as_string = tostring(value)
  as_string = as_string:gsub("'", "''")
  return "'" .. as_string .. "'"
end

function M.init()
  ensure_parent_dir(state.db_path)
  run_sql({}, "SELECT 1;")
end

function M.exec(sql)
  run_sql({}, sql)
end

function M.query(sql)
  local output = run_sql({ "-json" }, sql)
  if output == nil or output == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

function M.reset_file()
  local path = state.db_path
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
end

return M
