require "Rig"

local MAX_SPEED = 120.0

pc = Rig:new({
  spritesheetName = "spritesheets/pc",
  pos = {x = -0, y = -0},
  size = {w = 32, h = 32},
  behavior = {
    movement = {
      up = false,
      down = false,
      right = false,
      left = false
    },

    start = function(self, rig)
      self.movementAction = MOAIAction:new():start()
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
      self:setState("Idle")

    end,

    setState = function(self, state)
      self.state = state
      method = self["do"..state.."State"]

      if not method then
        return
      end

      method(self)
    end,

    doIdleState = function(self)
      self.rig:playAnimation("idle")
    end,

    doMovingState = function(self)

    end,

    startMovement = function(self, dir)
      if self.movement[dir] then
        return
      end

      self.movement[dir] = true

      self:updateMovementAnim()
    end,

    stopMovement = function(self, dir)
      if not self.movement[dir] then
        return
      end

      self.movement[dir] = false

      self:updateMovementAnim()
    end,

    updateMovementAnim = function(self)
      local mov = self.movement

      if mov.up then
        self.rig:playAnimation("up")
      elseif mov.down then
        self.rig:playAnimation("down")
      elseif mov.right then
        self.rig:playAnimation("right")
      elseif mov.left then
        self.rig:playAnimation("left")
      end
    end,

    updateMovement = function(self)
      local time = MOAISim:getDeviceTime()

      local length = (time - self.lastFrameTime) * MAX_SPEED

      self.rig:moveByDelta(self:buildMovementTransform(length))

      self.lastFrameTime = time
    end,

    buildMovementTransform = function(self, length)
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

    moveProp = function(self, delta)
      local x, y, z = delta:getLoc()
      local prop = self.rig.prop
      local px, py, pz = prop:getLoc()
      prop:setLoc(px + x, py + y, pz)
    end
  }
})

return pc
