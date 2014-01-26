RigFactory = require "RigFactory"
-- private methods are local functions here

-- class boilerplate stuff
Level = {}

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

function Level:new(o)
  local tab = Level:innerNew(o)
  local proxy = setmetatable({}, {__newindex = fieldChangedListener, __index = fieldAccessListener, __object = tab})

  return proxy, tab
end

function Level:innerNew(o)
  o = o or {
    -- property defaults
    behaviorName = nil,
    behavior = nil,
    backgroundFilename = nil,
    background = nil,
    layers = nil
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

-- instance methods

function Level:init()
  self.background = ResourceManager:get(self.backgroundFilename, "Image")
  self.background:setRect(-320, -240, 320, 240)
  self:initObjects()
end

function Level:initObjects()
  for i = 1, #self.objects do
    local body = world:addBody(MOAIBox2DBody.STATIC)
    body:addRect(unpack(self.objects[i].bb))
  end
end

function Level:loadPc(x, y)
  self.pc = RigFactory:build("pc")
  self.pc:init()
  self.layers.foreground:insertProp(self.pc.prop)
  self.pc:start()
end

function Level:start()
  self.behavior.start(self)
end

return Level
