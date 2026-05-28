-- tests/spec/connection_spec.lua

local connection = require("db-viewer.connection")

if vim.fn.executable("sqlite3") == 0 then
  describe("db-viewer.connection", function()
    pending("sqlite3 CLI is required for storage tests")
  end)
  return
end

describe("db-viewer.connection", function()
  local db_path

  before_each(function()
    db_path = vim.fn.tempname() .. ".sqlite3"
    connection.set_db_path(db_path)
    connection.reset()
  end)

  after_each(function()
    vim.fn.delete(db_path)
  end)

  it("registers a connection", function()
    connection.add({ name = "dev", driver = "postgres", database = "mydb" })
    local c = connection.get("dev")
    assert.is_not_nil(c)
    assert.equals("postgres", c.driver)
  end)

  it("replaces an existing connection with the same name", function()
    connection.add({ name = "dev", driver = "postgres", database = "old" })
    connection.add({ name = "dev", driver = "mysql",    database = "new" })
    local c = connection.get("dev")
    assert.equals("mysql",  c.driver)
    assert.equals("new",    c.database)
  end)

  it("removes a connection", function()
    connection.add({ name = "dev", driver = "sqlite", database = "test.db" })
    connection.remove("dev")
    assert.is_nil(connection.get("dev"))
  end)

  it("returns nil for an unknown name", function()
    assert.is_nil(connection.get("nope"))
  end)

  it("lists connections sorted by name", function()
    connection.add({ name = "zebra", driver = "sqlite",   database = "z.db" })
    connection.add({ name = "alpha", driver = "postgres", database = "a" })
    local list = connection.list()
    assert.equals(2,       #list)
    assert.equals("alpha", list[1].name)
    assert.equals("zebra", list[2].name)
  end)

  it("raises on missing name", function()
    assert.has_error(function()
      connection.add({ driver = "postgres", database = "x" })
    end)
  end)

  it("raises on missing database", function()
    assert.has_error(function()
      connection.add({ name = "dev", driver = "postgres" })
    end)
  end)

  it("persists records in sqlite across module reload", function()
    connection.add({ name = "dev", driver = "postgres", database = "mydb" })

    package.loaded["db-viewer.connection"] = nil
    local reloaded = require("db-viewer.connection")
    reloaded.set_db_path(db_path)

    local row = reloaded.get("dev")
    assert.is_not_nil(row)
    assert.equals("postgres", row.driver)
    assert.equals("mydb", row.database)
  end)
end)
