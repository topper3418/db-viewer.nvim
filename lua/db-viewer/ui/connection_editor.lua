local connection = require("db-viewer.connection")

local M = {}
local escaped_backslash_sentinel = "__DB_VIEWER_ESCAPED_BACKSLASH_f5d95c6d_faf5_4f29_a2a1_5f76bdba4465__"

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_lines(text)
  local lines = vim.split(text, "\n", { plain = true })
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines, #lines)
  end
  return lines
end

local function default_config_text()
  return table.concat({
    "# db-viewer connection config",
    "name = \"local-sqlite\"",
    "driver = \"sqlite\"",
    "path = \"/absolute/path/to/database.sqlite\"",
    "",
  }, "\n")
end

local function serialize_connection(conn)
  if type(conn.config_text) == "string" and conn.config_text ~= "" then
    return conn.config_text
  end

  return table.concat({
    "# db-viewer connection config",
    string.format("name = \"%s\"", conn.name or ""),
    string.format("driver = \"%s\"", conn.driver or "sqlite"),
    string.format("path = \"%s\"", conn.database or ""),
    "",
  }, "\n")
end

local function parse_value(raw)
  local value = trim(raw)
  local quote = value:sub(1, 1)
  if (quote == '"' or quote == "'") and value:sub(-1) == quote and #value >= 2 then
    local inner = value:sub(2, -2)
    inner = inner:gsub("\\\\", escaped_backslash_sentinel)
    inner = inner:gsub("\\" .. quote, quote)
    inner = inner:gsub(escaped_backslash_sentinel, "\\")
    return inner
  end
  return value
end

local function parse_connection_text(text)
  local parsed = {}
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    local trimmed = trim(line)
    if trimmed ~= "" and not trimmed:match("^#") then
      local key, raw = trimmed:match("^([%w_]+)%s*=%s*(.*)$")
      if key then
        parsed[key] = parse_value(raw)
      end
    end
  end

  local name = parsed.name
  local driver = parsed.driver or "sqlite"
  local path = parsed.path or parsed.database

  assert(type(name) == "string" and name ~= "", "connection config requires non-empty 'name' field")
  assert(
    driver == "sqlite",
    "only SQLite connections are supported in this editor. For other database types, add connections programmatically. Got: "
      .. tostring(driver)
  )
  assert(type(path) == "string" and path ~= "", "connection config requires non-empty 'path' field")

  return {
    name = name,
    driver = "sqlite",
    database = path,
    config_text = text,
  }
end

local function save_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")

  local ok, conn_or_err = pcall(parse_connection_text, text)
  if not ok then
    vim.notify(conn_or_err, vim.log.levels.ERROR)
    error(conn_or_err)
  end

  local state = vim.b[bufnr].db_viewer_connection_editor or {}
  if state.original_name and state.original_name ~= conn_or_err.name then
    connection.remove(state.original_name)
  end

  connection.add(conn_or_err)

  vim.b[bufnr].db_viewer_connection_editor = { original_name = conn_or_err.name }
  vim.api.nvim_buf_set_name(bufnr, "db-viewer://connection/" .. conn_or_err.name)
  vim.bo[bufnr].modified = false
  vim.notify("db-viewer connection saved: " .. conn_or_err.name)
end

local function open_editor(opts)
  local text = opts.text or default_config_text()
  local display_name = opts.display_name or "new"

  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, "db-viewer://connection/" .. display_name)
  vim.bo[bufnr].buftype = "acwrite"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "dosini"

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, split_lines(text))
  vim.api.nvim_set_current_buf(bufnr)

  vim.b[bufnr].db_viewer_connection_editor = {
    original_name = opts.original_name,
  }

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = bufnr,
    callback = function()
      save_buffer(bufnr)
    end,
  })
end

function M.open_new()
  open_editor({})
end

---@param name string
function M.open_existing(name)
  assert(type(name) == "string" and name ~= "", "connection name is required")

  local conn = connection.get(name)
  if not conn then
    error("connection not found: " .. name)
  end

  open_editor({
    text = serialize_connection(conn),
    original_name = conn.name,
    display_name = conn.name,
  })
end

return M
