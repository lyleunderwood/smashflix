require "Rig"
local util = require "../util"

return function()
return util.deepcopy({
  spritesheetName = "spritesheets/kornpop",
  pos = {x = -0, y = -0},
  angle = 0,
  size = {w = 150, h = 150},
  behavior = {
    damageBoost = 1,
    handleCollision = function(self, phase, us, them, arbiter)
      print(self, phase, us, them, arbiter)
    end,
    movement = {
      up = false,
      down = false,
      left = false,
      right = false
    },
    start = function(self, rig)
      self.movementThread = MOAIThread:new()
      self.lastFrameTime = MOAISim:getDeviceTime()
      rig.fixture:setFilter(COL_ENEMY_BULLET, COL_PC)
      rig.fixture.behavior = self

      local behavior = self
      rig.fixture:setCollisionHandler(function(phase, bullet, other, arbiter)
        behavior:impact(other)
      end, MOAIBox2DArbiter.BEGIN, COL_PC)

      self.movementThread:run(function()
          while not (self.state == "Stopped") do
            self:updateMovement()
            coroutine:yield()
          end
        end
      )
      self.rig = rig
      self:setState("Fly")
      self.rig.fixture:setSensor(true)

      self.expireTimer = MOAITimer:new()
      self.expireTimer:setSpan(1.5)
      self.expireTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function()
        if self.state == "Stopped" then
          return
        end

        self:setState("Stopped")
        self.rig:destroy()
      end)

      self.expireTimer:start()
    end,

    setPos = function(self, pos)
      self.pos = pos
    end,

    setMovement = function(self, mov)
      self.movement = mov
    end,

    setState = function(self, state)
      self.state = state
      method = self["do"..state.."State"]

      if not method then
        return
      end

      method(self)
    end,

    doFlyState = function(self)
      self.rig:playAnimation("horizontal")
    end,

    doImpactState = function(self)

    end,

    updateMovement = function(self, length)
    end,

    isMoving = function(self)
      local mov = self.movement
      return mov.up or mov.down or mov.right or mov.left
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
    end,

    getDamage = function(self)
      return PC_BULLET_DAMAGE * self.damageBoost
    end,

    cleanup = function(self)
      self.expireTimer:stop()
    end,
  }
})
end
