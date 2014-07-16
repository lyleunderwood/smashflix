local util = require("util")

-- private methods are local functions here

-- class boilerplate stuff
TpSpritesheet = {}

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

function TpSpritesheet:new(o)
  local tab = TpSpritesheet:innerNew(o)
  local proxy = setmetatable({}, {__newindex = fieldChangedListener, __index = fieldAccessListener, __object = tab})

  return proxy, tab
end

function TpSpritesheet:innerNew(o)
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

function TpSpritesheet:init()
  self.deck = MOAIGfxQuadListDeck2D.new()
  self.deck:setTexture("spritesheets/"..self.def.texture)

  self.animations = {}

  local frames = self.def.frames
  local idx

  self.deck:reserveUVQuads(#frames)
  self.deck:reserveQuads(#frames)
  self.deck:reservePairs(#frames)
  self.deck:reserveLists(#frames)

  for i, frame in pairs(frames) do
    idx = util.split(frame.name, '/')[1]

    local uv = frame.uvRect
    self.deck:setUVRect(i, uv.u0, uv.v0, uv.u1, uv.v1)

    local quad = frame.spriteColorRect
    self.deck:setRect(i, quad.x - quad.width / 2, quad.y + quad.height / 2, quad.width / 2, -quad.height / 2)

    self.deck:setPair(i, i, i)
    self.deck:setList(i, i, 1)

    self.animations[idx] = self.animations[idx] or {frames = {}}
    table.insert(self.animations[idx].frames, {
      idx = i,
      delay = 0.1
    })
  end

end

function TpSpritesheet:buildAnimationForProp(animIdx, prop)
  local curve = self:getCurveForAnimation(animIdx)
  local anim = MOAIAnim:new()
  anim:reserveLinks(1)
  anim:setLink(1, curve, prop, MOAIProp2D.ATTR_INDEX)
  anim:setMode(MOAITimer.LOOP)
  return anim
end

function TpSpritesheet:getCurveForAnimation(idx)
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

return TpSpritesheet
