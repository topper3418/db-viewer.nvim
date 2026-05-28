-- tests/spec/saved_queries_spec.lua

local connection = require("db-viewer.connection")

if vim.fn.executable("sqlite3") == 0 then
  describe("db-viewer.connection.saved_queries", function()
    pending("sqlite3 CLI is required for storage tests")
  end)
  return
end

describe("db-viewer.connection.saved_queries", function()
  local db_path

  before_each(function()
    db_path = vim.fn.tempname() .. ".sqlite3"
    connection.set_db_path(db_path)
    connection.reset()

    connection.add({ name = "dev", driver = "postgres", database = "mydb" })
  end)

  after_each(function()
    vim.fn.delete(db_path)
  end)

  it("stores and lists queries for a connection", function()
    connection.saved_queries.add("dev", "select * from users where id = ?", { 42 })
    connection.saved_queries.add("dev", "select now()", {})

    local list = connection.saved_queries.list("dev")
    assert.equals(2, #list)
    assert.equals("select * from users where id = ?", list[1].query)
    assert.same({ 42 }, list[1].args)
    assert.equals("select now()", list[2].query)
  end)

  it("raises when adding query to unknown connection", function()
    assert.has_error(function()
      connection.saved_queries.add("unknown", "select 1", {})
    end)
  end)

  it("deletes saved queries by id", function()
    connection.saved_queries.add("dev", "select 1", {})
    local list = connection.saved_queries.list("dev")
    assert.equals(1, #list)

    connection.saved_queries.remove(list[1].id)
    local after = connection.saved_queries.list("dev")
    assert.equals(0, #after)
  end)

  it("cascades delete when connection is removed", function()
    connection.saved_queries.add("dev", "select 1", {})
    connection.remove("dev")

    local rows = connection.saved_queries.list("dev")
    assert.equals(0, #rows)
  end)
end)
