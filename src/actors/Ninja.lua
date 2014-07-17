require "Rig"
local util = require "util"

return function()
  return util.deepcopy({
    spritesheetName = "spritesheets/ninja",

    pos = {x = -0, y = -0},
    size = {w = 15, h = 30},
    behavior = {
      movement = {
        up = false,
        down = false,
        right = false,
        left = false
      },

      startHealth = BUM_HEALTH,

      currentHealth = BUM_HEALTH,

      target = {x = 360, y = 240},

      isEnemy = true,

      start = function(self, rig)
        self.movementAction = MOAIAction:new():start()
        self.movementThread = MOAIThread:new()
        self.lastFrameTime = MOAISim:getDeviceTime()
        rig.fixture:setFilter(COL_ENEMY, util.bor(COL_WALL, COL_PC, COL_PC_BULLET, COL_ENEMY))
        rig.fixture.behavior = self

        self.deathSound = ResourceManager:get("sounds/scream.wav", "Sound")

        self.currentHealth = self.startHealth

        self.changeDirectionTimer = MOAITimer:new()
        self.changeDirectionTimer:setSpan(0.6)
        self.changeDirectionTimer:setMode(MOAITimer.LOOP)
        self.changeDirectionTimer:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function()
          self:changeDirection()
        end)
        self.changeDirectionTimer:start()

        local behavior = self
        rig.fixture:setCollisionHandler(function(phase, bum, other, arbiter)
          behavior:takeDamage(other)
        end, MOAIBox2DArbiter.BEGIN, COL_PC_BULLET)

        self.movementThread:run(function()
            while not (self.state == "Stopped") do
              self:updateMovement()
              coroutine:yield()
            end
          end
        )
        self.rig = rig
        self:setState("Idle")

        self:setInitialMovement()
        self.rig:playAnimation("flip")
        self.wasMoving = true
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
        if not self.rig.body then
          return
        end

        local mov = self.movement

        if not self:isMoving() then
          self.rig:playAnimation("idle")
        else
          self.rig:playAnimation("flip")
        end
      end,

      setInitialMovement = function(self)
        self:setDirectionTowardPc()
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

      changeDirection = function(self)
        local dirInt = util.randInt(7)

        if self.wasMoving then
          self.movement = {
            up = false,
            down = false,
            right = false,
            left = false
          }
          self.wasMoving = false
          self:fire()
        else
          if util.roll(JUNKYARD_RANDOMNESS) then
            self:setDirectionTowardPc()
          else
            self.movement = {
              up = dirInt == 0 or dirInt == 1 or dirInt == 7,
              right = dirInt == 1 or dirInt == 2 or dirInt == 3,
              down = dirInt == 3 or dirInt == 4 or dirInt == 5,
              left = dirInt == 5 or dirInt == 6 or dirInt == 7
            }
          end
          self.wasMoving = true
        end

        if not self:isMoving() then
          self.rig:playAnimation("idle")
        else
          self.rig:playAnimation("flip")
        end
      end,

      updateMovement = function(self)
        local time = MOAISim:getDeviceTime()

        local length = (time - self.lastFrameTime) * NINJA_BASE_SPEED

        local x, y = self.rig.body:getPosition()
        self.rig.pos.x = x
        self.rig.pos.y = y
        local pos = self.rig.pos

        self.rig:moveByDelta(self:buildMovementTransform(length))

        self.lastFrameTime = time
      end,

      buildMovementTransform = function(self, length)
        local mov = self.movement
        local delta = MOAITransform:new()

        local angular = math.sqrt(NINJA_BASE_SPEED * NINJA_BASE_SPEED / 2)

        if mov.up and mov.right then
          self.rig.body:setLinearVelocity(angular, angular)
        elseif mov.up and mov.left then
          self.rig.body:setLinearVelocity(-angular, angular)
        elseif mov.up then
          self.rig.body:setLinearVelocity(0, NINJA_BASE_SPEED)
        elseif mov.down and mov.right then
          self.rig.body:setLinearVelocity(angular, -angular)
        elseif mov.down and mov.left then
          self.rig.body:setLinearVelocity(-angular, -angular)
        elseif mov.down then
          self.rig.body:setLinearVelocity(0, -NINJA_BASE_SPEED)
        elseif mov.right then
          self.rig.body:setLinearVelocity(NINJA_BASE_SPEED, 0)
        elseif mov.left then
          self.rig.body:setLinearVelocity(-NINJA_BASE_SPEED, 0)
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
        if not self.rig or not self.rig.body then
          return
        end

        local px, py, z = self.rig.body:getPosition()

        local angle = self:getAngleToPc()  - (3 * (math.pi / 8))

        local dir = util.round(angle * 2 / math.pi)

        local mov1 = {
          down = dir == 0,
          right = dir == 1,
          up = dir == 2,
          left = dir >= 3 or dir < 0
        }

        local mov2 = {
          down = dir == 0 or dir == 1,
          right = dir == 1 or dir == 2,
          up = dir == 2 or dir >= 3 or dir < 0,
          left = dir >= 3 or dir <= 0
        }

        local mov3 = {
          down = dir >= 3 or dir <= 0,
          right = dir == 1 or dir == 0,
          up = dir == 2 or dir == 1,
          left = dir >= 3 or dir == 2
        }

        local moves = {mov1, mov2, mov3}

        for k,mov in pairs(moves) do

          self.rig.sendEvent("buildRig", {
            key = "actors/NinjaStar",
            init = function(bulletRig)

              bulletRig.pos = {x = px, y = py}
              bulletRig.behavior.movement = mov
              bulletRig.initBehavior = function(behavior)
              end
            end
          })
        end
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

        self.deathSound:play()

        self.changeDirectionTimer:stop()

        local drop = util.randInt(20)
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
        self.changeDirectionTimer:stop()
      end
    }
  })
end
