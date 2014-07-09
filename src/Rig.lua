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
  -- self.spritesheet:init()
  self.prop = MOAIProp2D:new()
  self.prop:setDeck(self.spritesheet.deck)
  self.body = world:addBody(MOAIBox2DBody.DYNAMIC)
  self.fixture = self.body:addRect(
    -self.size.w / 2,
    self.size.h / 2,
    self.size.w / 2, 
    -self.size.h / 2
  )
  self.body:setTransform(self.pos.x, self.pos.y, 0)
  self.prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, self.body, MOAIProp2D.TRANSFORM_TRAIT)
  self.fixture:setCollisionHandler(function(...)
    self:handleCollision(...)
  end)

  if self.initBehavior then
    self.initBehavior(self.behavior)
  end
end

function Rig:handleCollision(...)
  if self.behavior.handleCollision then
    self.behavior:handleCollision(...)
  end
end

function Rig:start()
  self.behavior:start(self)
end

function Rig:playAnimation(key)
  local anim = self.spritesheet:buildAnimationForProp(key, self.prop)
  anim:start()
end

function Rig:moveByDelta(delta)
  local x, y, z = delta:getLoc()
  local prop = self.prop
  local px, py, pz = prop:getLoc()
  --prop:setLoc(px + x, py + y, pz)
  --self.body:setTransform(prop:getLoc())
end

function Rig:destroy()
  if self.behavior.cleanup then
    self.behavior:cleanup()
  end

  self.behavior:setState("Stopped")
  self.fixture:destroy()
  self.body:destroy()
  self.body = nil
  self.fixture = nil
  self.sendEvent("destroyRig", {
    rig = self
  })
end

return Rig
