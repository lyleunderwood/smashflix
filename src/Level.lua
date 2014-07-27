RigFactory = require "RigFactory"
local util = require "util"
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
  o.rigs = {}

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
  self.worldObjects = {}
  for i = 1, #self.objects do
    local body = world:addBody(MOAIBox2DBody.STATIC)
    local fixture = body:addRect(unpack(self.objects[i].bb))
    if self.objects[i].playerOnly then
      fixture:setFilter(COL_WALL, util.bor(
        COL_PC,
        COL_PC_BULLET,
        COL_ENEMY_BULLET,
        COL_PICKUP
      ))
    else
      fixture:setFilter(COL_WALL, util.bor(
        COL_PC,
        COL_PC_BULLET,
        COL_ENEMY,
        COL_ENEMY_BULLET,
        COL_PICKUP
      ))
    end
    table.insert(self.worldObjects, body)
    table.insert(self.worldObjects, fixture)
  end
end

function Level:loadPc(x, y)
  self.pc = self:buildRig("actors/Pc", function(rig)

  end)
end

function Level:buildEnemy(key, init)
  local rig = self:buildRig(key, function(rig)
    rig.behavior.target = self.pc.pos
    init(rig)
  end)
  table.insert(self.enemies, rig)
  print("adding enemy:", #self.enemies)
  -- rig:playAnimation("walk")

  return rig
end

function Level:killEnemy(rig)
  for k,v in pairs(self.enemies) do
    if v == rig then
      table.remove(self.enemies, k)
    end
  end
  print("removing enemy:", #self.enemies)
end

function Level:buildRig(key, init)
  local rig = RigFactory:build(key)
  table.insert(self.rigs, rig)
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
  for k,v in pairs(self.rigs) do
    if v == rig then
      table.remove(self.rigs, k)
    end
  end
end

function Level:handleEvent(name, opts)
  if name == "buildRig" then
    self:buildRig(opts.key, opts.init)
  elseif name == "destroyRig" then
    self:destroyRig(opts.rig);
  elseif name == "killEnemy" then
    self:killEnemy(opts.rig);
  elseif name == "pcDied" then
    self:failure()
  end
end

function Level:failure()
  util.afterDelay(2, function()
    self:stop()
  end)
end

function Level:success(opts)
  util.afterDelay(2, function()
    opts.success = true
    self:stop(opts)
  end)
end

function Level:start()
  self.behavior:start(self)
  self.sendEvent("levelStarted")
end

function Level:stop(opts)
  self.behavior:stop()

  for k = #self.rigs, 1, -1 do
    local v = self.rigs[k]
    if v then
      if v.destroy and v.destroy then
        v:destroy()
      else
        self:destroyRig(v)
      end
    end
  end

  self.enemies = {}

  self.sendEvent("levelStopped", opts)
end

function Level:destroy()
  for k,v in pairs(self.worldObjects) do
    v:destroy()
  end
end

return Level
