require "Rig"

local MAX_SPEED = 120.0

pc = Rig:new({
  spritesheetName = "spritesheets/pc",
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

      self:moveProp(self:buildMovementTransform(length))

      self.lastFrameTime = time
    end,

    buildMovementTransform = function(self, length)
      local mov = self.movement
      local delta = MOAITransform:new()

      if mov.up then
        delta:setLoc(0, length, 0)
      elseif mov.down then
          delta:setLoc(0, -1 * length, 0)
      elseif mov.right then
          delta:setLoc(length, 0, 0)
      elseif mov.left then
          delta:setLoc(-1 * length, 0, 0)
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
