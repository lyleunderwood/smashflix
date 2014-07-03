require "Rig"
require("../bit")

local MAX_SPEED = 280.0

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return function()
return deepcopy({
  spritesheetName = "spritesheets/playerBullet",
  pos = {x = -0, y = -0},
  angle = 0,
  size = {w = 10, h = 7},
  behavior = {
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
      rig.fixture:setFilter(0x02, 0x14)
      rig.fixture.behavior = self

      local behavior = self
      rig.fixture:setCollisionHandler(function(phase, bullet, other, arbiter)
        behavior:impact(other)
      end, MOAIBox2DArbiter.BEGIN, 0x14)

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
      self.rig:playAnimation("fly")
    end,

    doImpactState = function(self)

    end,

    updateMovement = function(self, length)
      if not self.rig.body then
        return
      end

      local mov = self.movement
      local delta = MOAITransform:new()

      local angular = math.sqrt(MAX_SPEED * MAX_SPEED / 2)

      if mov.up and mov.right then
        self.rig.body:setLinearVelocity(angular, angular)
      elseif mov.up and mov.left then
        self.rig.body:setLinearVelocity(-angular, angular)
      elseif mov.up then
        self.rig.body:setLinearVelocity(0, MAX_SPEED)
      elseif mov.down and mov.right then
        self.rig.body:setLinearVelocity(angular, -angular)
      elseif mov.down and mov.left then
        self.rig.body:setLinearVelocity(-angular, -angular)
      elseif mov.down then
        self.rig.body:setLinearVelocity(0, -MAX_SPEED)
      elseif mov.right then
        self.rig.body:setLinearVelocity(MAX_SPEED, 0)
      elseif mov.left then
        self.rig.body:setLinearVelocity(-MAX_SPEED, 0)
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

      self.rig.fixture:destroy()
      self.rig.body:destroy()
      self.rig.body = nil
      self.rig.fixture = nil
      self:setState("Stopped")
      self.rig.sendEvent("destroyRig", {
        rig = self.rig
      })
    end,

    getDamage = function(self)
      return 5
    end
  }
})
end
