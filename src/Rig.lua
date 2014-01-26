-- private methods are local functions here

-- class boilerplate stuff
Rig = {}

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

function Rig:new(o)
  local tab = Rig:innerNew(o)
  local proxy = setmetatable({}, {__newindex = fieldChangedListener, __index = fieldAccessListener, __object = tab})

  return proxy, tab
end

function Rig:innerNew(o)
  o = o or {
    -- property defaults
    spritesheetName = nil,
    spritesheet = nil,
    prop = nil,
    behavior = nil
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

-- instance methods

function Rig:init()
  self.spritesheet = ResourceManager:get(self.spritesheetName, "Spritesheet")
  self.spritesheet:init()
  self.prop = MOAIProp2D:new()
  self.prop:setDeck(self.spritesheet.deck)
end

function Rig:start()
  self.behavior:start(self)
end

function Rig:playAnimation(key)
  local anim = self.spritesheet:buildAnimationForProp(key, self.prop)
  anim:start()
end

return Rig
