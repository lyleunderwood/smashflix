require "Rig"
local util = require "util"

return function()
return util.deepcopy({
  spritesheetName = "spritesheets/kornpop",
  pos = {x = -0, y = -0},
  angle = 0,
  size = {w = 10, h = 7},
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
      rig.fixture:setFilter(COL_PC_BULLET, util.bor(COL_WALL, COL_ENEMY))
      rig.fixture.behavior = self

      local behavior = self
      rig.fixture:setCollisionHandler(function(phase, bullet, other, arbiter)
        behavior:impact(other)
      end, MOAIBox2DArbiter.BEGIN, util.bor(COL_WALL, COL_ENEMY))

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
      local mov = self.movement
      local anim
      if (mov.up and mov.right) or (mov.down and mov.left) then
        anim = "diagright"
      elseif (mov.up and mov.left) or (mov.down and mov.right) then
        anim = "diagleft"
      elseif mov.up or mov.down then
        anim = "vertical"
      else
        anim = "horizontal"
      end

      self.rig:playAnimation(anim)
    end,

    doImpactState = function(self)

    end,

    updateMovement = function(self, length)
      if not self.rig.body then
        return
      end

      local mov = self.movement
      local delta = MOAITransform:new()

      local angular = math.sqrt(PC_BULLET_SPEED * PC_BULLET_SPEED / 2)

      if mov.up and mov.right then
        self.rig.body:setLinearVelocity(angular, angular)
      elseif mov.up and mov.left then
        self.rig.body:setLinearVelocity(-angular, angular)
      elseif mov.up then
        self.rig.body:setLinearVelocity(0, PC_BULLET_SPEED)
      elseif mov.down and mov.right then
        self.rig.body:setLinearVelocity(angular, -angular)
      elseif mov.down and mov.left then
        self.rig.body:setLinearVelocity(-angular, -angular)
      elseif mov.down then
        self.rig.body:setLinearVelocity(0, -PC_BULLET_SPEED)
      elseif mov.right then
        self.rig.body:setLinearVelocity(PC_BULLET_SPEED, 0)
      elseif mov.left then
        self.rig.body:setLinearVelocity(-PC_BULLET_SPEED, 0)
      else
        self.rig.body:setLinearVelocity(0, 0)
      end

      return delta
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
      if self.state == "Stopped" then
        return
      end

      self:setState("Stopped")
      self.rig:destroy()
    end,

    getDamage = function(self)
      return PC_BULLET_DAMAGE * self.damageBoost
    end
  }
})
end
