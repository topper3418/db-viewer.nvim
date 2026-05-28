-- lua/db-viewer/init.lua
-- Public API and setup entry point.

local M = {}

local config = require("db-viewer.config")

---@param opts? DbViewerConfig
function M.setup(opts)
  config.apply(opts or {})
end

return M
