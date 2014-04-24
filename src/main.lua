-- moai setup stuff
MOAISim.openWindow("Smashflix", 640, 480)

viewportX = 640
viewportY = 480
viewportRatio = viewportY / viewportX

viewport = MOAIViewport.new ()
viewport:setSize(viewportX, viewportY)
viewport:setScale(640, 480)

MOAIEnvironment.setListener(0, function(key, value)
  viewportX = MOAIEnvironment.horizontalResolution
  viewportY = MOAIEnvironment.verticalResolution

  newRatio = viewportY / viewportX

  if newRatio > viewportRatio then
    viewportY = viewportX * viewportRatio
  else
    viewportX = viewportY / viewportRatio
  end
  viewport:setSize(viewportX, viewportY)
end)

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

MOAIUntzSystem.initialize(44100)
song1 = MOAIUntzSound.new()
song1:load("sounds/44100.wav")
song1:setLooping(true)
song1:setLoopPoints(0, song1:getLength())
song1:play()
