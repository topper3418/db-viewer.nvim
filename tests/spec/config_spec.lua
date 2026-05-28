-- tests/spec/config_spec.lua

local config = require("db-viewer.config")

describe("db-viewer.config", function()
  before_each(function()
    config.apply({})
  end)

  it("has sensible defaults", function()
    assert.equals("rounded", config.values.float.border)
    assert.equals(0.8, config.values.float.width)
    assert.equals(0.8, config.values.float.height)
    assert.same({}, config.values.connections)
  end)

  it("merges user options without mutating defaults", function()
    config.apply({ float = { border = "single" } })
    assert.equals("single", config.values.float.border)
    assert.equals(0.8, config.values.float.width)
  end)

  it("accepts a connections list", function()
    config.apply({
      connections = {
        { name = "local", driver = "postgres", database = "dev", host = "localhost", port = 5432 },
      },
    })
    assert.equals(1, #config.values.connections)
    assert.equals("local", config.values.connections[1].name)
  end)
end)
