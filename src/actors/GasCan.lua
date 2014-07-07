require "Rig"
local util = require "util"

return function()
return util.deepcopy({
  spritesheetName = "spritesheets/gasCan",
  pos = {x = -0, y = -0},
  angle = 0,
  size = {w = 22, h = 29},
  behavior = {
    itemType = "speedboost",
    isPickup = true,

    start = function(self, rig)
      self.movementThread = MOAIThread:new()
      self.lastFrameTime = MOAISim:getDeviceTime()
      rig.fixture:setFilter(COL_PICKUP, COL_PC)
      rig.fixture.behavior = self

      local behavior = self
      rig.fixture:setCollisionHandler(function(phase, bullet, other, arbiter)
        behavior:impact(other)
      end, MOAIBox2DArbiter.BEGIN, COL_PC)

      self.rig = rig
      self:setState("Idle")
      self.rig.fixture:setSensor(true)
    end,

    setPos = function(self, pos)
      self.pos = pos
    end,

    setState = function(self, state)
      self.state = state
      method = self["do"..state.."State"]

      if not method then
        return
      end

      method(self)
    end,

    doImpactState = function(self)

    end,

    moveProp = function(self, delta)
      local x, y, z = delta:getLoc()
      local prop = self.rig.prop
      local px, py, pz = prop:getLoc()
      prop:setLoc(px + x, py + y, pz)
    end,

    fire = function(self)

    end,

    impact = function(self, target)
      if self.state == "Stopped" then
        return
      end

      self.rig.fixture:destroy()
      self.rig.body:destroy()
      self.rig.body = nil
      self.rig.fixture = nil
      self:setState("Stopped")
      self.rig.sendEvent("destroyRig", {
        rig = self.rig
      })
    end
  }
})
end
