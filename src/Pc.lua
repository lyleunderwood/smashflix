require "Rig"

local BASE_SPEED = 120.0
local FIRE_DELAY = 0.25
local SPEEDBOOST_DURATION = 5
local SPEEDBOOST_MULTIPLIER = 2

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

      aim = {
        up = false,
        down = false,
        right = false,
        left = false
      },

      firing = false,

      firingTimer = nil,

      speedBoost = 1,

      start = function(self, rig)
        self.movementAction = MOAIAction:new():start()
        self.movementThread = MOAIThread:new()
        self.lastFrameTime = MOAISim:getDeviceTime()
        rig.fixture:setFilter(0x01, 0x34)

        self.fireSound = ResourceManager:get("sounds/fire.wav", "Sound")

        self.firingTimer = MOAITimer:new()
        self.firingTimer:setSpan(FIRE_DELAY)
        self.firingTimer:setMode(MOAITimer.LOOP)
        self.firingTimer:setListener(MOAITimer.EVENT_TIMER_BEGIN_SPAN, function()
          if not self.firing then
            return self.firingTimer:stop()
          end
          self:fire()
        end)

        self.speedBoostTimer = MOAITimer:new()
        self.speedBoostTimer:setSpan(SPEEDBOOST_DURATION)
        --self.speedBoostTimer:setMode(MOAITimer.LOOP)
        self.speedBoostTimer:setListener(MOAITimer.EVENT_TIMER_BEGIN_SPAN, function()
          self.speedBoost = SPEEDBOOST_MULTIPLIER
        end)

        self.speedBoostTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function()
          self.speedBoost = 1
        end)

        local behavior = self
        rig.fixture:setCollisionHandler(function(phase, pc, other, arbiter)
          if other.behavior.isPickup then
            behavior:pickup(other)
          else
            behavior:die()
          end
        end, MOAIBox2DArbiter.BEGIN, 0x24)

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

      startAim = function(self, dir)
        if self.aim[dir] then
          return
        end

        self.aim[dir] = true

        self:updateMovementAnim()

        self:startFiring()
      end,

      stopAim = function(self, dir)
        if not self.aim[dir] then
          return
        end

        self.aim[dir] = false

        self:updateMovementAnim()

        if not self:shouldBeFiring() then
          self:stopFiring()
        end
      end,

      shouldBeFiring = function(self)
        return self.aim.up or self.aim.down or self.aim.right or self.aim.left
      end,

      startFiring = function(self)
        if self.firing then
          return
        end

        self.firing = true

        --self:fire()
        self.firingTimer:start()
      end,

      stopFiring = function(self)
        if not self.firing then
          return
        end

        self.firing = false
        --self.firingTimer:stop()
      end,

      updateMovementAnim = function(self)
        local mov = self.movement

        local key
        local movkey
        local aimkey = ""

        if mov.right then
          movkey = "right"
        elseif mov.left then
          movkey = "left"
        elseif mov.up then
          movkey = "up"
        elseif mov.down then
          movkey = "down"
        end

        if self.aim.up then
          aimkey = "up"
        elseif self.aim.down then
          aimkey = "down"
        end

        if self.aim.right then
          aimkey = aimkey.."right"
        elseif self.aim.left then
          aimkey = aimkey.."left"
        end

        if movkey and not (aimkey == "") then
          key = movkey.."_"..aimkey
        elseif movkey then
          key = movkey.."_"..movkey
        end

        if key then
          self.rig:playAnimation(key)
        end

        if not self:isMoving() then
          self.rig:playAnimation("idle")
        end
      end,

      updateMovement = function(self)
        local time = MOAISim:getDeviceTime()

        local length = (time - self.lastFrameTime) * BASE_SPEED

        x, y = self.rig.body:getPosition()
        self.rig.pos.x = x
        self.rig.pos.y = y

        self.rig:moveByDelta(self:buildMovementTransform(length))

        self.lastFrameTime = time
      end,

      buildMovementTransform = function(self, length)
        local mov = self.movement
        local delta = MOAITransform:new()

        local speed = BASE_SPEED * self.speedBoost

        local angular = math.sqrt(speed * speed / 2)

        if mov.up and mov.right then
          self.rig.body:setLinearVelocity(angular, angular)
        elseif mov.up and mov.left then
          self.rig.body:setLinearVelocity(-angular, angular)
        elseif mov.up then
          self.rig.body:setLinearVelocity(0, speed)
        elseif mov.down and mov.right then
          self.rig.body:setLinearVelocity(angular, -angular)
        elseif mov.down and mov.left then
          self.rig.body:setLinearVelocity(-angular, -angular)
        elseif mov.down then
          self.rig.body:setLinearVelocity(0, -speed)
        elseif mov.right then
          self.rig.body:setLinearVelocity(speed, 0)
        elseif mov.left then
          self.rig.body:setLinearVelocity(-speed, 0)
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
        self.fireSound:play()

        self.rig.sendEvent("buildRig", {
          key = "actors/PlayerBullet",
          init = function(bulletRig)
            local px, py, z = self.rig.body:getPosition()

            mov = {}
            mov.left = self.aim.left
            mov.right = self.aim.right
            mov.up = self.aim.up
            mov.down = self.aim.down

            bulletRig.pos = {x = px, y = py}
            bulletRig.behavior.movement = mov
            bulletRig.initBehavior = function(behavior)

            end
          end
        })
      end,

      pickup = function(self, item)
        if item.behavior.itemType == "speedboost" then
          print("speedboost!")
          self.speedBoostTimer:setTime(0)
          self.speedBoostTimer:start()
        end
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
