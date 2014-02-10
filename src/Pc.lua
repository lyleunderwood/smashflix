require "Rig"

local MAX_SPEED = 120.0

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
    spritesheetName = "spritesheets/pc",
    pos = {x = -0, y = -0},
    size = {w = 15, h = 30},
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
        rig.fixture:setFilter(0x01, 0x14)

        local behavior = self
        rig.fixture:setCollisionHandler(function(phase, pc, other, arbiter)
          behavior:die()
        end, MOAIBox2DArbiter.BEGIN, 0x04)

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

        if mov.right then
          self.rig:playAnimation("right")
        elseif mov.left then
          self.rig:playAnimation("left")
        elseif mov.up then
          self.rig:playAnimation("up")
        elseif mov.down then
          self.rig:playAnimation("down")
        end

        if not self:isMoving() then
          self.rig:playAnimation("idle")
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
        self.rig.sendEvent("buildRig", {
          key = "actors/PlayerBullet",
          init = function(bulletRig)
            local px, py, z = self.rig.body:getPosition()

            mov = {}
            mov.left = self.movement.left
            mov.right = self.movement.right
            mov.up = self.movement.up
            mov.down = self.movement.down

            bulletRig.pos = {x = px, y = py}
            bulletRig.behavior.movement = mov
            bulletRig.initBehavior = function(behavior)

            end
          end
        })
      end,

      die = function(self)
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
