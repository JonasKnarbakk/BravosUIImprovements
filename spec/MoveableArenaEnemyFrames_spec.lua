---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.BUIICharacterDatabase = {}

pcall(dofile, "MoveableArenaEnemyFrames.lua")

describe("BravosUIImprovements MoveableArenaEnemyFrames", function()
  -- reset state
  before_each(function()
    _G.BUIIDatabase = {}
    _G.BUIICharacterDatabase = {}
  end)

  describe("BUII_MoveableArenaEnemyFrames_InitDB", function()
    it("initializes missing database values", function()
      BUII_MoveableArenaEnemyFrames_InitDB()
      assert.is_false(_G.BUIIDatabase["moveable_arena_frames"])
    end)
  end)

  describe("BUII_MoveableArenaEnemyFrames_Enable", function()
    it("initializes without crashing given standard mocks", function()
      BUII_MoveableArenaEnemyFrames_Enable()
    end)
  end)

  describe("BUII_MoveableArenaEnemyFrames_Disable", function()
    it("disables without crashing", function()
      BUII_MoveableArenaEnemyFrames_Disable()
    end)
  end)
end)
