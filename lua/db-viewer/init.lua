-- lua/db-viewer/init.lua
-- Public API and setup entry point.

local M = {}

local commands = require("db-viewer.commands")
local config = require("db-viewer.config")

---@param opts? DbViewerConfig
function M.setup(opts)
  config.apply(opts or {})
  commands.setup()
end

return M
