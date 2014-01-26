
-- private methods are local functions here

-- class boilerplate stuff
Spritesheet = {}

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

function Spritesheet:new(o)
  local tab = Spritesheet:innerNew(o)
  local proxy = setmetatable({}, {__newindex = fieldChangedListener, __index = fieldAccessListener, __object = tab})

  return proxy, tab
end

function Spritesheet:innerNew(o)
  o = o or {
    -- property defaults
    animations = {},
    imageFilename = "",
    deck = nil,
    numCellsX = 1,
    numCellsY = 1,
    cellRect = {x1 = -5, y1 = -5, x2 = 5, y2 = 5}
  }

  setmetatable(o, self)
  self.__index = self
  return o
end

-- instance methods

function Spritesheet:init()
  self.deck = MOAITileDeck2D.new()
  self.deck:setTexture(self.imageFilename)
  self.deck:setSize(self.numCellsX, self.numCellsY)
  local rect = self.cellRect
  self.deck:setRect(rect.x1, rect.y1, rect.x2, rect.y2)
end

function Spritesheet:buildAnimationForProp(animIdx, prop)
  local curve = self:getCurveForAnimation(animIdx)
  local anim = MOAIAnim:new()
  anim:reserveLinks(1)
  anim:setLink(1, curve, prop, MOAIProp2D.ATTR_INDEX)
  anim:setMode(MOAITimer.LOOP)
  return anim
end

function Spritesheet:getCurveForAnimation(idx)
  local curve = MOAIAnimCurve.new()
  local anim = self.animations[idx]
  local frames = anim.frames
  
  curve:reserveKeys(#frames + 1)
  local totalTime = 0
  for i = 1, #frames do
    curve:setKey(i, totalTime, frames[i].idx, MOAIEaseType.FLAT)
    totalTime = totalTime + frames[i].delay
  end

  curve:setKey(#frames + 1, totalTime, 1, MOAIEaseType.FLAT)

  return curve
end

return Spritesheet
