-- tests/minimal_init.lua
-- Minimal Neovim init used only during `make test`.
-- Adds the plugin root and plenary to the runtime path.

local plenary_path = os.getenv("PLENARY_PATH") or vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.runtimepath:append(plenary_path)
vim.opt.runtimepath:append(vim.fn.getcwd())
