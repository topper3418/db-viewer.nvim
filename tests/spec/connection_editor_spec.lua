local connection = require("db-viewer.connection")

if vim.fn.executable("sqlite3") == 0 then
  describe("db-viewer.ui.connection_editor", function()
    pending("sqlite3 CLI is required for editor tests")
  end)
  return
end

describe("db-viewer.ui.connection_editor", function()
  local db_path
  local sqlite_path

  before_each(function()
    db_path = vim.fn.tempname() .. ".sqlite3"
    sqlite_path = vim.fn.tempname() .. ".db"

    connection.set_db_path(db_path)
    connection.reset()

    package.loaded["db-viewer"] = nil
    require("db-viewer").setup({})
  end)

  after_each(function()
    vim.cmd("silent! bwipeout!")
    vim.fn.delete(db_path)
    vim.fn.delete(sqlite_path)
  end)

  it("saves a new sqlite connection from the editor buffer", function()
    vim.cmd("DbViewerConnectionNew")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'name = "local"',
      'driver = "sqlite"',
      'path = "' .. sqlite_path .. '"',
    })
    local expected_text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

    vim.cmd("write")

    local conn = connection.get("local")
    assert.is_not_nil(conn)
    assert.equals("sqlite", conn.driver)
    assert.equals(sqlite_path, conn.database)
    assert.equals(expected_text, conn.config_text)
  end)

  it("opens and updates an existing connection", function()
    local original_text = table.concat({
      'name = "dev"',
      'driver = "sqlite"',
      'path = "' .. sqlite_path .. '"',
    }, "\n")

    connection.add({
      name = "dev",
      driver = "sqlite",
      database = sqlite_path,
      config_text = original_text,
    })

    vim.cmd("DbViewerConnectionEdit dev")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'name = "dev-renamed"',
      'driver = "sqlite"',
      'path = "' .. sqlite_path .. '"',
    })

    vim.cmd("write")

    assert.is_nil(connection.get("dev"))
    local updated = connection.get("dev-renamed")
    assert.is_not_nil(updated)
    assert.equals(sqlite_path, updated.database)
  end)

  it("errors when required config fields are missing", function()
    vim.cmd("DbViewerConnectionNew")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'name = "broken"',
      'driver = "sqlite"',
    })

    assert.has_error(function()
      vim.cmd("write")
    end)

    assert.is_nil(connection.get("broken"))
  end)

  it("parses escaped quotes in quoted values", function()
    vim.cmd("DbViewerConnectionNew")
    local bufnr = vim.api.nvim_get_current_buf()
    local escaped_path = '/tmp/sample \\\"quoted\\\".db'
    local parsed_path = '/tmp/sample "quoted".db'

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
      'name = "escaped"',
      'driver = "sqlite"',
      'path = "' .. escaped_path .. '"',
    })

    vim.cmd("write")

    local conn = connection.get("escaped")
    assert.is_not_nil(conn)
    assert.equals(parsed_path, conn.database)
  end)
end)
