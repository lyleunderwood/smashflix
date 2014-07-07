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

  o.enemies = {}

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
    local fixture = body:addRect(unpack(self.objects[i].bb))
    fixture:setFilter(0x10, 0x000007)
  end
end

function Level:loadPc(x, y)
  self.pc = RigFactory:build("actors/Pc")
  self.pc.sendEvent = function(name, opts)
    self:handleEvent(name, opts)
  end
  self.pc:init()
  self.layers.foreground:insertProp(self.pc.prop)
  self.pc:start()
end

function Level:buildEnemy(key, init)
  local rig = self:buildRig(key, init)
  table.insert(self.enemies, rig)
  print("adding enemy:", #self.enemies)
  rig:playAnimation("left")
  rig.behavior.target = self.pc.pos

  return rig
end

function Level:killEnemy(rig)
  for k,v in pairs(self.enemies) do
    if v == rig then
      table.remove(self.enemies, k)
    end
  end
  print("removing enemy:", #self.enemies)

  return self:destroyRig(rig)
end

function Level:buildRig(key, init)
  local rig = RigFactory:build(key)
  rig.sendEvent = function(name, opts)
    self:handleEvent(name, opts)
  end
  init(rig)
  rig:init()
  self.layers.foreground:insertProp(rig.prop)
  rig:start()

  return rig
end

function Level:destroyRig(rig)
  self.layers.foreground:removeProp(rig.prop)
end

function Level:handleEvent(name, opts)
  if name == "buildRig" then
    self:buildRig(opts.key, opts.init)
  elseif name == "destroyRig" then
    self:destroyRig(opts.rig);
  elseif name == "killEnemy" then
    self:killEnemy(opts.rig);
  end
end

function Level:start()
  self.behavior:start(self)
end

return Level
