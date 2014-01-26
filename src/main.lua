-- moai setup stuff
MOAISim.openWindow("Smashflix", 640, 480)

viewport = MOAIViewport.new ()
viewport:setSize(640, 480)
viewport:setScale(640, 480)

backgroundLayer = MOAILayer2D.new ()
backgroundLayer:setViewport(viewport)

foregroundLayer = MOAILayer2D.new ()
foregroundLayer:setViewport(viewport)

renderLayers = {backgroundLayer, foregroundLayer}
MOAIRenderMgr.setRenderTable(renderLayers)

world = MOAIBox2DWorld.new()
world:setGravity(0,0)
world:setUnitsToMeters(1/30)
--world:setDebugDrawEnabled(0)
world:start()

foregroundLayer:setBox2DWorld(world)

-- game stuff
ResourceManager = require "ResourceManager"
LevelScreen = require "LevelScreen"

level = ResourceManager:get("levels/one", "Level")

levelScreen = LevelScreen:new({layers = {
  background = backgroundLayer, foreground = foregroundLayer
}})

levelScreen:runLevel("levels/one")

local cb = function(...)
  levelScreen:handleKey(...)
end

MOAIInputMgr.device.keyboard:setCallback(cb)