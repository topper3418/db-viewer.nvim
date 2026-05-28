std = "lua51+vim"
globals = { "vim" }
ignore = { "212" }   -- unused argument (common in Neovim callbacks)

files["tests/spec/**"] = {
    globals = { "describe", "it", "before_each", "after_each", "assert", "pending" }
}
