Spritesheet = require "Spritesheet"

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
  local spritesheet = Spritesheet:new(data)
  return spritesheet
end

return ResourceManager
