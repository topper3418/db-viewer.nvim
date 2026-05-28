local connection = require("db-viewer.connection")
local connection_editor = require("db-viewer.ui.connection_editor")

local M = {}

local registered = false

local function complete_connection_names(arglead)
  local matches = {}
  for _, conn in ipairs(connection.list()) do
    if arglead == "" or vim.startswith(conn.name, arglead) then
      matches[#matches + 1] = conn.name
    end
  end
  return matches
end

function M.setup()
  if registered then
    return
  end

  vim.api.nvim_create_user_command("DbViewerConnectionNew", function()
    connection_editor.open_new()
  end, {
    desc = "Open a new db-viewer connection config buffer",
  })

  vim.api.nvim_create_user_command("DbViewerConnectionEdit", function(opts)
    connection_editor.open_existing(opts.args)
  end, {
    nargs = 1,
    complete = complete_connection_names,
    desc = "Open an existing db-viewer connection config buffer",
  })

  registered = true
end

return M
