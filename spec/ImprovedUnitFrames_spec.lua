require("spec.setup")

_G.unpack = _G.unpack or table.unpack

local function makeRegion(name)
  local region = CreateFrame("Frame", name)
  region.alpha = 1
  region.SetAlpha = function(self, alpha)
    self.alpha = alpha
  end
  region.SetTexture = function() end
  region.SetTexCoord = function() end
  region.GetNumPoints = function()
    return 0
  end
  return region
end

describe("ImprovedUnitFrames with missing class resource bars", function()
  local db
  local manaBar
  local onSettingChanged

  before_each(function()
    db = { PlayerFrame = { hide_power = false } }
    BUII_EditModeUtils.GetDB = function()
      return db
    end
    _G.AlternatePowerBar = makeRegion("AlternatePowerBar")
    _G.DemonHunterSoulFragmentsBar = nil
    _G.EvokerEbonMightBar = nil
    _G.InsanityBarFrame = nil
    _G.MonkStaggerBar = nil
    manaBar = makeRegion("ManaBar")

    local healthBars = makeRegion("HealthBarsContainer")
    healthBars.HealthBar = makeRegion("HealthBar")
    healthBars.HealthBarMask = makeRegion("HealthBarMask")
    healthBars.LeftText = makeRegion("LeftText")
    healthBars.HealthBarText = makeRegion("HealthBarText")
    healthBars.RightText = makeRegion("RightText")
    _G.PlayerFrame = makeRegion("PlayerFrame")
    PlayerFrame.PlayerFrameContainer = {
      FrameTexture = makeRegion("FrameTexture"),
      AlternatePowerFrameTexture = makeRegion("AlternatePowerFrameTexture"),
      FrameFlash = makeRegion("FrameFlash"),
    }
    PlayerFrame.PlayerFrameContent = {
      PlayerFrameContentMain = {
        ManaBarArea = { ManaBar = manaBar },
        HealthBarsContainer = healthBars,
      },
    }
    EditModeSystemSettingsDialog.attachedToSystem = PlayerFrame
    onSettingChanged = nil
    _G.hooksecurefunc = function(target, method, callback)
      if target == EditModeSystemSettingsDialog and method == "OnSettingValueChanged" then
        onSettingChanged = callback
      end
    end
  end)

  local function enable()
    dofile("Modules/DefaultUI/UnitFrames/ImprovedUnitFrames.lua")
    BUII_ImprovedUnitFramesEnable()
  end

  local function setHidePower(value)
    onSettingChanged(EditModeSystemSettingsDialog, 20, value)
  end

  it("hides and restores the mana bar beyond missing class bars", function()
    enable()
    setHidePower(1)
    assert.are.equal(0, AlternatePowerBar.alpha)
    assert.are.equal(0, manaBar.alpha)

    setHidePower(0)
    assert.are.equal(1, AlternatePowerBar.alpha)
    assert.are.equal(1, manaBar.alpha)
  end)

  it("also hides and restores an existing class bar between gaps", function()
    _G.EvokerEbonMightBar = makeRegion("EvokerEbonMightBar")
    enable()
    setHidePower(1)
    assert.are.equal(0, EvokerEbonMightBar.alpha)
    assert.are.equal(0, manaBar.alpha)

    setHidePower(0)
    assert.are.equal(1, EvokerEbonMightBar.alpha)
    assert.are.equal(1, manaBar.alpha)
  end)

  it("restores existing bars when disabling the module", function()
    db.PlayerFrame.hide_power = true
    enable()
    assert.are.equal(0, manaBar.alpha)

    BUII_ImprovedUnitFramesDisable()
    assert.are.equal(1, AlternatePowerBar.alpha)
    assert.are.equal(1, manaBar.alpha)
  end)
end)
