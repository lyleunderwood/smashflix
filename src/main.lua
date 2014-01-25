ResourceManager = require "ResourceManager"
LevelScreen = require "LevelScreen"

Rig = require "Rig"
rig = Rig:new()

ss = ResourceManager:get("spritesheets/pc", "Spritesheet")
level = ResourceManager:get("levels/one", "Level")

ss:init()

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

local prop = MOAIProp2D.new()
prop:setDeck(ss.deck)
--foregroundLayer:insertProp(prop)

local anim = ss:buildAnimationForProp(1, prop)
anim:start()


renderLayers = {backgroundLayer, foregroundLayer}

MOAIRenderMgr.setRenderTable(renderLayers)

local cb = function(...)
  screen:handleKey(...)
end

MOAIInputMgr.device.keyboard:setCallback(cb)