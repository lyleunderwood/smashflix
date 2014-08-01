-- moai setup stuff
require "constants"
MOAISim.openWindow("Smashflix", 640, 480)

print("MAC ATTACK!")

viewportX = 640
viewportY = 480
viewportRatio = viewportY / viewportX

viewport = MOAIViewport.new ()
viewport:setSize(viewportX, viewportY)
viewport:setScale(640, 480)
--viewport:setOffset(0.5, 0)
-- MOAISim.enterFullscreenMode()

MOAIUntzSystem.initialize(44100, 2000)

local performResize = function(key, value)
  viewportX = MOAIEnvironment.horizontalResolution
  viewportY = MOAIEnvironment.verticalResolution
  print("environment callback, w: "..viewportX.." h: "..viewportY)

  newRatio = viewportY / viewportX

  if newRatio > viewportRatio then
    viewportY = viewportX * viewportRatio
  else
    viewportX = viewportY / viewportRatio
  end
  viewport:setSize(viewportX, viewportY)
end

MOAIEnvironment.setListener(0, performResize)

performResize()

backgroundLayer = MOAILayer2D.new ()
backgroundLayer:setViewport(viewport)

foregroundLayer = MOAILayer2D.new ()
foregroundLayer:setViewport(viewport)

renderLayers = {backgroundLayer, foregroundLayer}
MOAIRenderMgr.setRenderTable(renderLayers)

world = MOAIBox2DWorld.new()
world:setGravity(0,0)
world:setUnitsToMeters(1/30)
world:setDebugDrawEnabled(0)
world:start()

foregroundLayer:setBox2DWorld(world)

-- game stuff
ResourceManager = require "ResourceManager"
LevelScreen = require "LevelScreen"

levelScreen = LevelScreen:new({
  firstLevel = "one",
  layers = {
    background = backgroundLayer, foreground = foregroundLayer
  }
})

levelScreen:setWindowCoords(viewportX, viewportY)

levelScreen.complete = function()
  os.exit()
end

levelScreen:start()

local theme = ResourceManager:get("sounds/theme.wav", "Sound")
theme:setLooping(true)
theme:setLoopPoints(6.12, 76.9)
theme:play()

