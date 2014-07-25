require "Rig"
local util = require "util"

return function()
  return util.deepcopy({
    spritesheetName = "spritesheets/bum1",
    pos = {x = -0, y = -0},
    size = {w = 15, h = 30},
    behavior = {
      movement = {
        up = false,
        down = false,
        right = false,
        left = false
      },

      startHealth = ZOMBIE_HEALTH,

      currentHealth = ZOMBIE_HEALTH,

      target = {x = 360, y = 240},

      isEnemy = true,

      dead = false,

      speedBoost = 1,

      canCharge = true,

      start = function(self, rig)
        self.lastFrameTime = MOAISim:getDeviceTime()
        rig.fixture:setFilter(COL_ENEMY, util.bor(COL_WALL, COL_PC, COL_PC_BULLET, COL_ENEMY))
        rig.fixture.behavior = self

        self.deathSound = ResourceManager:get("sounds/scream.wav", "Sound")

        self.currentHealth = self.startHealth

        local behavior = self
        rig.fixture:setCollisionHandler(function(phase, me, other, arbiter)
          behavior:takeDamage(other)
        end, MOAIBox2DArbiter.BEGIN, COL_PC_BULLET)

        self.rig = rig
        self:setState("Walk")

        self.movementThread = MOAIThread:new()
        self.movementThread:run(function()
            while not (self.state == "Stopped") do
              self:updateMovement()
              coroutine:yield()
            end
          end
        )

        self.rig:playAnimation("walk")
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

      doWalkState = function(self)
        print("walk")
        self.autoMove = true
        self.speedBoost = 1
        self.rig:playAnimation("walk")
      end,

      doPauseState = function(self)
        print("pause")
        self.autoMove = false
        self.movement = {
          up = false,
          down = false,
          left = false,
          right = false
        }

        self.rig:playAnimation("idle")

        if not self.pauseTimer then
          self.pauseTimer = MOAITimer:new()
          self.pauseTimer:setSpan(ZOMBIE_PAUSE_DELAY)
          self.pauseTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function()
            self:setState("Charge")
          end)
        end

        self.pauseTimer:start()
      end,

      doChargeState = function(self)
        self:setDirectionTowardPc()
        self.speedBoost = ZOMBIE_CHARGE_MULT
        self.canCharge = false

        self.rig:playAnimation("walk")

        if not self.chargeTimer then
          self.chargeTimer = MOAITimer:new()
          self.chargeTimer:setSpan(ZOMBIE_CHARGE_DELAY)
          self.chargeTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function()
            self:setState("Walk")
            self.cooldownTimer:start()
          end)
        end

        if not self.cooldownTimer then
          self.cooldownTimer = MOAITimer:new()
          self.cooldownTimer:setSpan(ZOMBIE_COOLDOWN_TIME)
          self.cooldownTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function()
            self.canCharge = true
          end)
        end

        self.chargeTimer:start()
      end,

      withinPlayerRange = function(self)
        local x, y = self.rig.body:getPosition()
        local xDist = self.target.x - x
        local yDist = self.target.y - y
        local dist = math.sqrt(math.pow(xDist, 2) + math.pow(yDist, 2))

        return dist < 200
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

      getAngleToPc = function(self)
        local x, y = self.rig.body:getPosition()
        self.rig.pos.x = x
        self.rig.pos.y = y
        local pos = self.rig.pos

        local xDist = self.target.x - pos.x
        local yDist = self.target.y - pos.y

        return math.atan2(yDist, xDist) + math.pi - math.pi / 8
      end,

      getMoveToPc = function(self)
        local angle = self:getAngleToPc()

        local mov = {}
        if angle > 0 and angle < math.pi / 4 then
          mov.down = true
          mov.left = true
        elseif angle >= math.pi / 4 and angle < math.pi / 2 then
          mov.down = true
        elseif angle >= math.pi / 2 and angle < 3 * math.pi / 4 then
          mov.down = true
          mov.right = true
        elseif angle >= 3 * math.pi / 4 and angle < math.pi then
          mov.right = true
        elseif angle >= math.pi and angle < math.pi * 1.25 then
          mov.right = true
          mov.up = true
        elseif angle >= math.pi * 1.25 and angle < math.pi * 1.5 then
          mov.up = true
        elseif angle >= math.pi * 1.5 and angle < math.pi * 1.75 then
          mov.up = true
          mov.left = true
        elseif angle >= math.pi * 1.75 or angle <= 0 then
          mov.left = true
        end

        return mov
      end,

      setDirectionTowardPc = function(self)
        self.movement = self:getMoveToPc()
      end,

      updateMovementAnim = function(self)
        if not self.rig.body then
          return
        end

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

        local length = (time - self.lastFrameTime) * ZOMBIE_BASE_SPEED

        x, y = self.rig.body:getPosition()
        self.rig.pos.x = x
        self.rig.pos.y = y
        local pos = self.rig.pos

        if self.autoMove then
          self:setDirectionTowardPc()
          if self.withinPlayerRange(self) and self.canCharge then
            self:setState("Pause")
          end
        end

        self.rig:moveByDelta(self:buildMovementTransform(length))

        self.lastFrameTime = time
      end,

      buildMovementTransform = function(self, length)
        local mov = self.movement
        local delta = MOAITransform:new()

        local angular = math.sqrt(ZOMBIE_BASE_SPEED * ZOMBIE_BASE_SPEED / 2)

        local speed = ZOMBIE_BASE_SPEED * self.speedBoost
        local angularSpeed = angular * self.speedBoost

        if mov.up and mov.right then
          self.rig.body:setLinearVelocity(angularSpeed, angularSpeed)
        elseif mov.up and mov.left then
          self.rig.body:setLinearVelocity(-angularSpeed, angularSpeed)
        elseif mov.up then
          self.rig.body:setLinearVelocity(0, speed)
        elseif mov.down and mov.right then
          self.rig.body:setLinearVelocity(angularSpeed, -angularSpeed)
        elseif mov.down and mov.left then
          self.rig.body:setLinearVelocity(-angularSpeed, -angularSpeed)
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

      takeDamage = function(self, bullet)
        self.currentHealth = self.currentHealth - bullet.behavior:getDamage()
        if self.currentHealth <= 0 then
          self.die(self)
        end
      end,

      nextTick = function(self, cb)
        MOAIThread:new():run(function()
          cb(self)
        end)
      end,

      die = function(self)
        if self.dead then
          return
        end

        self.dead = true

        self.movementThread:stop()

        local drop = util.randInt(ZOMBIE_DROP_SIDES)
        if drop == 0 then
          local px, py, z = self.rig.body:getPosition()
          util.nextTick(self, function(self)
            self.rig.sendEvent("buildRig", {
              key = "actors/GasCan",
              init = function(gasCanRig)

                gasCanRig.pos = {x = px, y = py}
              end
            })
          end)
        elseif drop == 1 then
          local px, py, z = self.rig.body:getPosition()
          util.nextTick(self, function(self)
            self.rig.sendEvent("buildRig", {
              key = "actors/Gun",
              init = function(gasCanRig)

                gasCanRig.pos = {x = px, y = py}
              end
            })
          end)
        end

        self.rig.sendEvent("killEnemy", {
          rig = self.rig
        })

        self.rig:destroy()
      end,

      cleanup = function(self)
        self.movementThread:stop()
        if self.pauseTimer then
          self.pauseTimer:stop()
        end
        if self.chargeTimer then
          self.chargeTimer:stop()
        end
        if self.cooldownTimer then
          self.cooldownTimer:stop()
        end
      end
    }
  })
end
