-- lua/db-viewer/connection/db.lua
-- SQLite database access helpers for db-viewer.

local M = {}

local state = {
  db_path = vim.fn.getcwd() .. "/.nvim/db-viewer.db",
}

---Ensure the directory containing the DB file exists.
---@param path string
local function ensure_parent_dir(path)
  local parent = vim.fn.fnamemodify(path, ":h")
  if parent and parent ~= "." and parent ~= "" then
    vim.fn.mkdir(parent, "p")
  end
end

---Execute SQL against the current DB path via sqlite3 CLI.
---A fresh sqlite3 process is used for each call.
---@param args string[] CLI arguments passed to sqlite3 (for example `-json`)
---@param sql string SQL statement(s) to execute
---@return string output stdout emitted by sqlite3
local function run_sql(args, sql)
  local command = { "sqlite3", state.db_path }
  for _, arg in ipairs(args) do
    command[#command + 1] = arg
  end
  command[#command + 1] = sql

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    error(("sqlite3 error (%s): %s"):format(state.db_path, output))
  end
  return output
end

---Render a Lua scalar as a SQL literal for sqlite3 `.parameter set`.
---@param value any
---@return string
local function to_sql_literal(value)
  if value == nil then
    return "NULL"
  end

  local value_type = type(value)
  if value_type == "number" then
    return tostring(value)
  end
  if value_type == "boolean" then
    return value and "1" or "0"
  end

  local as_string = tostring(value)
  as_string = as_string:gsub("'", "''")
  return "'" .. as_string .. "'"
end

---Build a sqlite script that enables FKs and binds @p1/@p2 style params.
---@param sql string
---@param params any[]
---@return string
local function build_parameterized_sql(sql, params)
  local lines = {
    "PRAGMA foreign_keys = ON;",
    ".parameter init",
    ".parameter clear",
  }

  for index, value in ipairs(params) do
    lines[#lines + 1] = string.format(".parameter set @p%d %s", index, to_sql_literal(value))
  end

  lines[#lines + 1] = sql
  return table.concat(lines, "\n")
end

---Set the file path used for SQLite storage.
---@param path string
function M.set_path(path)
  assert(type(path) == "string" and path ~= "", "db path must be a non-empty string")
  state.db_path = path
end

---Get the current SQLite DB file path.
---@return string
function M.get_path()
  return state.db_path
end

---Initialize the database file and verify sqlite3 access.
function M.init()
  ensure_parent_dir(state.db_path)
  run_sql({}, "PRAGMA foreign_keys = ON;\nSELECT 1;")
end

---Execute SQL that does not require parsing a row result set.
---@param sql string
function M.exec(sql)
  run_sql({}, "PRAGMA foreign_keys = ON;\n" .. sql)
end

---Execute SQL with @p1/@p2 bound parameters (safe values, fixed SQL text).
---@param sql string
---@param params any[]|nil
function M.exec_prepared(sql, params)
  local script = build_parameterized_sql(sql, params or {})
  run_sql({}, script)
end

---Execute SQL and decode the `-json` result into a Lua array of rows.
---@param sql string
---@return table[]
function M.query(sql)
  local output = run_sql({ "-json" }, "PRAGMA foreign_keys = ON;\n" .. sql)
  if output == nil or output == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

---Execute SQL with bound parameters and decode `-json` result rows.
---@param sql string
---@param params any[]|nil
---@return table[]
function M.query_prepared(sql, params)
  local script = build_parameterized_sql(sql, params or {})
  local output = run_sql({ "-json" }, script)
  if output == nil or output == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, output)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

---Delete the database file if it exists.
function M.reset_file()
  local path = state.db_path
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
end

return M
