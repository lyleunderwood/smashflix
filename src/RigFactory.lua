require "Rig"
-- private methods are local functions here

-- class boilerplate stuff
RigFactory = {cache = {}}

function RigFactory:build(key)
  if self.cache[key] then
    return self.cache[key]
  end

  local rig = nil

  if key == "pc" then
    rig = self:buildPc()
  end

  self.cache[key] = rig

  return rig
end

function RigFactory:buildPc()
  return require "Pc"
end

return RigFactory
