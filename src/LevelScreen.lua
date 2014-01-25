
-- private methods are local functions here

-- class boilerplate stuff
LevelScreen = {}

local keymap = {
  [44] = "MoveUp",
  [111] = "MoveDown",
  [101] = "MoveRight",
  [97] = "MoveLeft"
}

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
    level = nil
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

-- instance methods

function LevelScreen:runLevel(key)
  self:stopLevel()
  self.level = ResourceManager:get(key, "Level")
  self:startLevel()
end

function LevelScreen:stopLevel()
  if self.level then
    self.layers.background:removeProp(self.backgroundProp)
  end

  self.level = nil
end

function LevelScreen:startLevel()
  self.level.layers = self.layers
  self.level:init()
  self.backgroundProp = MOAIProp2D.new()
  self.backgroundProp:setDeck(self.level.background)
  self.layers.background:insertProp(self.backgroundProp)
  self.level:start()
end

function LevelScreen:handleKey(code, down)
  --io.stdout:write(string.format(code, down))
  --print(code)
  --print(down)

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

function LevelScreen:startMoveUp()
  print("start moving up")
end

function LevelScreen:stopMoveUp()
  print("stop moving up")
end

function LevelScreen:startMoveDown()
  print("start moving down")
end

function LevelScreen:stopMoveDown()
  print("stop moving down")
end

function LevelScreen:startMoveLeft()
  print("start moving left")
end

function LevelScreen:stopMoveLeft()
  print("stop moving left")
end

function LevelScreen:startMoveRight()
  print("start moving right")
end

function LevelScreen:stopMoveRight()
  print("stop moving right")
end

return LevelScreen
