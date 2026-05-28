-- lua/db-viewer/config.lua
-- Default configuration and user-supplied overrides.

---@class DbViewerConfig
---@field connections DbViewerConnection[]  List of named database connections
---@field float      DbViewerFloatConfig    Settings for the floating window

---@class DbViewerConnection
---@field name     string  Human-readable label shown in the UI
---@field driver   string  One of: "postgres" | "mysql" | "sqlite"
---@field host?    string
---@field port?    integer
---@field database string
---@field user?    string
---@field password? string  Stored in memory only; never written to disk

---@class DbViewerFloatConfig
---@field width      number  0–1 fraction of editor width, or absolute column count
---@field height     number  0–1 fraction of editor height, or absolute row count
---@field border     string  Border style passed to nvim_open_win

local M = {}

---@type DbViewerConfig
local defaults = {
  connections = {},
  float = {
    width  = 0.8,
    height = 0.8,
    border = "rounded",
  },
}

---@type DbViewerConfig
M.values = vim.deepcopy(defaults)

---Merge user-supplied options over the defaults.
---@param opts DbViewerConfig
function M.apply(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
end

return M
