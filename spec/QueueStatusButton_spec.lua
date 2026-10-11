---@diagnostic disable: undefined-global, undefined-field
require("spec.setup")

_G.BUIIDatabase = {}
_G.MicroMenu = CreateFrame("Frame", "MicroMenu")
_G.MicroMenuContainer = CreateFrame("Frame", "MicroMenuContainer")

describe("QueueStatusButton", function()
  local overlay
  local nextFrame
  local setPointCalls
  local queueHookCount
  local containerSize
  local combatLeaveCallback
  local inCombat
  local containerProtected

  before_each(function()
    _G.BUIIDatabase = {}
    overlay = nil
    nextFrame = nil
    setPointCalls = 0
    queueHookCount = 0
    containerSize = nil
    combatLeaveCallback = nil
    inCombat = false
    containerProtected = false

    _G.QueueStatusButton = CreateFrame("Frame", "QueueStatusButton")
    QueueStatusButton.parent = MicroMenuContainer
    QueueStatusButton.SetParent = function(self, parent)
      self.parent = parent
    end
    QueueStatusButton.GetParent = function(self)
      return self.parent
    end
    QueueStatusButton.SetPoint = function(self, ...)
      setPointCalls = setPointCalls + 1
      self.point = { ... }
    end
    MicroMenuContainer.Layout = function(self)
      QueueStatusButton:SetPoint("LEFT", self, "RIGHT", 0, 0)
    end
    MicroMenuContainer.SetSize = function(_, width, height)
      containerSize = { width, height }
    end
    MicroMenuContainer.IsProtected = function()
      return containerProtected
    end
    _G.InCombatLockdown = function()
      return inCombat
    end
    _G.RunNextFrame = function(callback)
      nextFrame = callback
    end
    BUII_EditModeUtils.RegisterSystem = function(_, frame, _, _, _, dbKey)
      if dbKey == "queue_status_button" then
        overlay = frame
      end
    end
    EventRegistry.RegisterFrameEventAndCallback = function(_, event, callback)
      if event == "PLAYER_REGEN_ENABLED" then
        combatLeaveCallback = callback
      end
    end
    _G.hooksecurefunc = function(target, method, callback)
      if target == QueueStatusButton or target == MicroMenuContainer then
        -- Match WoW's validation and execute the post-hook, including reentry.
        assert.is_function(target[method])
        local original = target[method]
        target[method] = function(...)
          original(...)
          callback(...)
        end
        if target == QueueStatusButton then
          queueHookCount = queueHookCount + 1
        end
      end
    end
    dofile("Modules/DefaultUI/QueueStatusButton/QueueStatusButton.lua")
  end)

  it("detaches the button and keeps it on the overlay when Blizzard repositions it", function()
    assert.is_nil(QueueStatusButton.UpdatePosition)
    BUII_QueueStatusButton_Enable()
    nextFrame()
    assert.are.equal(UIParent, QueueStatusButton:GetParent())
    assert.are.equal(overlay, QueueStatusButton.point[2])

    setPointCalls = 0
    QueueStatusButton:SetPoint("LEFT", MicroMenuContainer, "RIGHT", 0, 0)
    assert.are.equal(2, setPointCalls)
    assert.are.equal("CENTER", QueueStatusButton.point[1])
    assert.are.equal(overlay, QueueStatusButton.point[2])
  end)

  it("shrinks MicroMenuContainer to the Micro Menu after detaching", function()
    BUII_QueueStatusButton_Enable()
    nextFrame()
    assert.are.same({ 100, 20 }, containerSize)
  end)

  it("allows Blizzard to restore the normal anchor on disable", function()
    BUII_QueueStatusButton_Enable()
    nextFrame()
    BUII_QueueStatusButton_Disable()
    assert.are.equal(MicroMenuContainer, QueueStatusButton:GetParent())
    assert.are.equal(MicroMenuContainer, QueueStatusButton.point[2])

    BUII_QueueStatusButton_Enable()
    nextFrame()
    assert.are.equal(1, queueHookCount)
    assert.are.equal(overlay, QueueStatusButton.point[2])
  end)

  it("does not detach the button if disabled before the deferred setup", function()
    BUII_QueueStatusButton_Enable()
    BUII_QueueStatusButton_Disable()
    nextFrame()
    assert.are.equal(MicroMenuContainer, QueueStatusButton:GetParent())
    assert.are.equal(MicroMenuContainer, QueueStatusButton.point[2])
  end)

  it("also tolerates a client without MicroMenuContainer.Layout", function()
    MicroMenuContainer.Layout = nil
    BUII_QueueStatusButton_Enable()
    nextFrame()
    assert.are.equal(overlay, QueueStatusButton.point[2])
    BUII_QueueStatusButton_Disable()
    assert.are.equal(MicroMenuContainer, QueueStatusButton:GetParent())
  end)

  it("does not call QueueStatusButton:UpdatePosition() without arguments in Disable", function()
    -- Mock UpdatePosition to simulate Blizzard's failing code if arguments are missing
    QueueStatusButton.UpdatePosition = function(_, pos)
      if pos == nil then
        error("offsetX will be nil in Blizzard code because arguments are missing!")
      end
    end

    BUII_QueueStatusButton_Enable()
    nextFrame()
    local status, err = pcall(BUII_QueueStatusButton_Disable)
    assert.is_true(status, "BUII_QueueStatusButton_Disable should not crash: " .. (err or ""))
  end)

  describe("when Blizzard supports moving the button natively", function()
    before_each(function()
      -- WoW Forever: QueueStatusButton is its own Edit Mode system ("Group Finder")
      QueueStatusButton.system = 27
      QueueStatusButton.parent = UIParent
    end)

    it("does not take over the button on enable", function()
      BUII_QueueStatusButton_Enable()
      assert.is_nil(nextFrame)
      assert.is_nil(overlay)
      assert.are.equal(0, queueHookCount)
      assert.are.equal(UIParent, QueueStatusButton:GetParent())
    end)

    it("does not move the button back into the Micro Menu on disable", function()
      BUII_QueueStatusButton_Enable()
      BUII_QueueStatusButton_Disable()
      assert.are.equal(UIParent, QueueStatusButton:GetParent())
      assert.are.equal(0, setPointCalls)
    end)
  end)

  describe("during combat with a protected MicroMenuContainer", function()
    it("waits until combat ends to resize the container", function()
      BUII_QueueStatusButton_Enable()
      nextFrame()
      containerSize = nil

      inCombat = true
      containerProtected = true
      MicroMenuContainer:Layout()
      assert.is_nil(containerSize)

      inCombat = false
      combatLeaveCallback()
      assert.are.same({ 100, 20 }, containerSize)
    end)

    it("waits until combat ends to detach the button", function()
      inCombat = true
      containerProtected = true
      BUII_QueueStatusButton_Enable()
      nextFrame()
      assert.are.equal(MicroMenuContainer, QueueStatusButton:GetParent())

      inCombat = false
      combatLeaveCallback()
      assert.are.equal(UIParent, QueueStatusButton:GetParent())
      assert.are.equal(overlay, QueueStatusButton.point[2])
    end)

    it("drops pending changes when disabled during combat", function()
      inCombat = true
      containerProtected = true
      BUII_QueueStatusButton_Enable()
      nextFrame()
      BUII_QueueStatusButton_Disable()

      inCombat = false
      combatLeaveCallback()
      assert.are.equal(MicroMenuContainer, QueueStatusButton:GetParent())
    end)
  end)
end)
