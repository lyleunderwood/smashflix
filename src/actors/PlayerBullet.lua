require "Rig"

local MAX_SPEED = 200.0

pc = Rig:new({
  spritesheetName = "spritesheets/playerBullet",
  pos = {x = -0, y = -0},
  angle = 0,
  size = {w = 32, h = 32},
  behavior = {
    movement = {
      up = false,
      down = false,
      left = false,
      right = false
    },
    start = function(self, rig)
      self.movementThread = MOAIThread:new()
      self.lastFrameTime = MOAISim:getDeviceTime()

      self.movementThread:run(function()
          while not (self.state == "Stopped") do
            self:updateMovement()
            coroutine:yield()
          end
        end
      )
      self.rig = rig
      self:setState("Fly")

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
      
    end
  }
})

return pc
