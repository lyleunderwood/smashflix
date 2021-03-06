Spritesheet = require "Spritesheet"
TpSpritesheet = require "TpSpritesheet"
Level = require "Level"

-- private methods are local functions here

-- class boilerplate stuff
ResourceManager = {
  cache = {}
}

function ResourceManager:get(resourceKey, resourceType)
  if self.cache[resourceKey] then
    return self.cache[resourceKey]
  end

  local resource = self["load"..resourceType](self, resourceKey)
  self.cache[resourceKey] = resource
  return resource
end

function ResourceManager:loadSpritesheet(key)
  local data = require(key)
  local spritesheet
  spritesheet = TpSpritesheet:new({def = data})
  spritesheet:init()
  return spritesheet
end

function ResourceManager:loadImage(key)
  local quad = MOAIGfxQuad2D.new()
  quad:setTexture(key)
  return quad
end

function ResourceManager:loadLevel(key)
  local data = require(key)
  local level = Level:new(data)
  return level
end

function ResourceManager:loadSound(key)
  local sound = MOAIUntzSound.new()
  sound:load(key)

  return sound
end

return ResourceManager
