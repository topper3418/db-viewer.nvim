-- db-viewer.lua
-- Plugin entry point. Loaded automatically by Neovim on startup.

if vim.g.loaded_db_viewer then
  return
end
vim.g.loaded_db_viewer = true

require("db-viewer").setup()
