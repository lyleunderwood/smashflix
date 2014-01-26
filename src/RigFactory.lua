require "Rig"
-- private methods are local functions here

-- class boilerplate stuff
RigFactory = {cache = {}}

function RigFactory:build(key)
  if self.cache[key] then
    return self.cache[key]
  end

  local rig = nil

  --if key == "pc" then
    rig = self:buildRig(key)
  --end

  self.cache[key] = rig

  return rig
end

function RigFactory:buildRig(key)
  return require(key)
end

return RigFactory
