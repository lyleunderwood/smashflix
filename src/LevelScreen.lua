local ResourceManager = require "ResourceManager"
local util = require "util"

-- private methods are local functions here

-- class boilerplate stuff
LevelScreen = {}

local keymap

if util.getKBLayout() == "dvorak" then
  keymap = {
    [44] = "MoveUp",
    [111] = "MoveDown",
    [101] = "MoveRight",
    [97] = "MoveLeft",
    [99] = "AimUp",
    [116] = "AimDown",
    [110] = "AimRight",
    [104] = "AimLeft",
    [32] = "Fire"
  }
else
  keymap = {
    [119] = "MoveUp",
    [115] = "MoveDown",
    [100] = "MoveRight",
    [97] = "MoveLeft",
    [105] = "AimUp",
    [107] = "AimDown",
    [108] = "AimRight",
    [106] = "AimLeft",
    [32] = "Fire"
  }
end

local function fieldChangedListener(self, key, value)
  getmetatable(self).__object[key] = value
  self = getmetatable(self).__object

  -- add property setters here
end


local function fieldAccessListener(self, key)
    local object = getmetatable(self).__object

  -- add property getters here

    return getmetatable(self).__object[key]
end

function LevelScreen:new(o)
  local tab = LevelScreen:innerNew(o)
  local proxy = setmetatable({}, {__newindex = fieldChangedListener, __index = fieldAccessListener, __object = tab})

  return proxy, tab
end

function LevelScreen:innerNew(o)
  o = o or {
    -- property defaults
    layers = nil,
    level = nil,
    inputPaused = true
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

function LevelScreen:start()
  if self.firstLevel then
    local key = "levels/"..(self.firstLevel)
    self:runLevel(key)
  end

  if MOAIInputMgr.device.keyboard then
    MOAIInputMgr.device.keyboard:setCallback(function(...)
      self:handleKey(...)
    end)
  end

  if MOAIInputMgr.device.touch then
    MOAIInputMgr.device.touch:setCallback(function(...)
      self:handleTouch(...)
    end)
  end
end

-- instance methods

function LevelScreen:runLevel(key)
  if key then
    self.currentLevelKey = key
  end

  print("running level: "..self.currentLevelKey)

  self:stopLevel()
  self.level = ResourceManager:get(self.currentLevelKey, "Level")
  self:startLevel()
end

function LevelScreen:stopLevel()
  if self.level then
    self.layers.background:removeProp(self.backgroundProp)
    self.level:destroy()
  end


  self.level = nil
end

function LevelScreen:startLevel()
  self.level.sendEvent = function(name, opts)
    self:handleEvent(name, opts)
  end

  self.level.layers = self.layers
  self.level:init()
  self.backgroundProp = MOAIProp2D.new()
  self.backgroundProp:setDeck(self.level.background)
  self.layers.background:insertProp(self.backgroundProp)
  self.level:start()
end

function LevelScreen:setWindowCoords(width, height)
  self.windowCoords = {
    width = width,
    height = height
  }
end

function LevelScreen:handleEvent(name, opts)
  if name == "levelStarted" then
    self.inputPaused = false
  elseif name == "levelStopped" then
    self.inputPaused = true
    if opts and opts.success then
      if opts.nextLevel then
        self:runLevel("levels/"..opts.nextLevel)
      end
    else
      self:runLevel()
    end
  end
end

function LevelScreen:handleKey(code, down)
  --io.stdout:write(string.format(code, down))
  --print(code)
  --print(down)

  if self.inputPaused then
    return
  end

  action = keymap[code]
  if not action then
    return
  end

  prefix = down and "start" or "stop"

  method = prefix .. action

  method = self[method]

  if not method then
    return
  end

  method(self)
end

function LevelScreen:handleTouch(eventType, idx, x, y, tapCount)
  if not self.touches then
    self.touches = {}
  end

  if eventType == MOAITouchSensor.TOUCH_DOWN then
    self:touchStart(idx, x, y)
  elseif eventType == MOAITouchSensor.TOUCH_MOVE then
    self:touchMove(idx, x, y)
  elseif eventType == MOAITouchSensor.TOUCH_UP or eventType == MOAITouchSensor.TOUCH_CANCEL then
    self:touchStop(idx, x, y)
  end
end

function LevelScreen:touchStart(idx, x, y)
  print("touchStart: "..tostring(idx).." x: "..tostring(x).." y: "..tostring(y))
  self.touches[idx] = {
    start = {x = x, y = y},
    current = {x = x, y = y}
  }

  if x < self.windowCoords.width / 2 then
    self.movementTouchId = idx
  else
    self.aimTouchId = idx
  end
end

function LevelScreen:touchMove(idx, x, y)
  print("touchMove: "..tostring(idx).." x: "..tostring(x).." y: "..tostring(y))
  local touch = self.touches[idx]
  touch.current = {x = x, y = y}

  if idx == self.movementTouchId then
    local mov = self:getMovementFromTouches(touch.start, touch.current)
    if not self:movementCompare(self.level.pc.behavior.movement, mov) then
      self.level.pc.behavior:setMovement(mov)
    end
  elseif idx == self.aimTouchId then
    local mov = self:getMovementFromTouches(touch.start, touch.current)
    if not self:movementCompare(self.level.pc.behavior.movement, mov) then
      self.level.pc.behavior:setAim(mov)
    end
  end
end

function LevelScreen:movementCompare(movA, movB)
  return movA.up == movB.up and movA.down == movB.down and movA.left == movA.left and movA.right == movB.right
end

function LevelScreen:touchStop(idx, x, y)
  print("touchStop: "..tostring(idx).." x: "..tostring(x).." y: "..tostring(y))
  local touch = self.touches[idx]

  if idx == self.movementTouchId then
    self.level.pc.behavior:setMovement({})
  elseif idx == self.aimTouchId then
    self.level.pc.behavior:setAim({})
  end
end

function LevelScreen:getAngleFromTouches(start, current)
  local xDist = current.x - start.x
  local yDist = start.y - current.y
  return math.atan2(yDist, xDist) + math.pi - math.pi / 8
end

function LevelScreen:getMovementFromTouches(start, current)
  return self:getMovementFromAngle(self:getAngleFromTouches(start, current))
end

function LevelScreen:getMovementFromAngle(angle)
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
end

function LevelScreen:startMoveUp()
  self.level.pc.behavior:startMovement("up")
end

function LevelScreen:stopMoveUp()
  self.level.pc.behavior:stopMovement("up")
end

function LevelScreen:startMoveDown()
  self.level.pc.behavior:startMovement("down")
end

function LevelScreen:stopMoveDown()
  self.level.pc.behavior:stopMovement("down")
end

function LevelScreen:startMoveLeft()
  self.level.pc.behavior:startMovement("left")
end

function LevelScreen:stopMoveLeft()
  self.level.pc.behavior:stopMovement("left")
end

function LevelScreen:startMoveRight()
  self.level.pc.behavior:startMovement("right")
end

function LevelScreen:stopMoveRight()
  self.level.pc.behavior:stopMovement("right")
end

function LevelScreen:startAimUp()
  self.level.pc.behavior:startAim("up")
end

function LevelScreen:stopAimUp()
  self.level.pc.behavior:stopAim("up")
end

function LevelScreen:startAimDown()
  self.level.pc.behavior:startAim("down")
end

function LevelScreen:stopAimDown()
  self.level.pc.behavior:stopAim("down")
end

function LevelScreen:startAimLeft()
  self.level.pc.behavior:startAim("left")
end

function LevelScreen:stopAimLeft()
  self.level.pc.behavior:stopAim("left")
end

function LevelScreen:startAimRight()
  self.level.pc.behavior:startAim("right")
end

function LevelScreen:stopAimRight()
  self.level.pc.behavior:stopAim("right")
end

function LevelScreen:startFire()
  --self.level.pc.behavior:fire()
end

return LevelScreen
