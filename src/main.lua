ResourceManager = require "ResourceManager"
LevelScreen = require "LevelScreen"

level = ResourceManager:get("levels/one", "Level")

MOAISim.openWindow("Smashflix", 640, 480)

viewport = MOAIViewport.new ()
viewport:setSize(640, 480)
viewport:setScale(640, 480)


backgroundLayer = MOAILayer2D.new ()
backgroundLayer:setViewport(viewport)

foregroundLayer = MOAILayer2D.new ()
foregroundLayer:setViewport(viewport)

levelScreen = LevelScreen:new({layers = {
  background = backgroundLayer, foreground = foregroundLayer
}})

levelScreen:runLevel("levels/one")

renderLayers = {backgroundLayer, foregroundLayer}

MOAIRenderMgr.setRenderTable(renderLayers)

local cb = function(...)
  levelScreen:handleKey(...)
end

MOAIInputMgr.device.keyboard:setCallback(cb)