ResourceManager = require "ResourceManager"

Rig = require "Rig"
rig = Rig:new()

ss = ResourceManager:get("spritesheets/pc", "Spritesheet")

ss:init()

MOAISim.openWindow("Smashflix", 640, 480)

viewport = MOAIViewport.new ()
viewport:setSize(640, 480)
viewport:setScale(640, 480)


backgroundLayer = MOAILayer2D.new ()
backgroundLayer:setViewport(viewport)

foregroundLayer = MOAILayer2D.new ()
foregroundLayer:setViewport(viewport)

local prop = MOAIProp2D.new()
prop:setDeck(ss.deck)
foregroundLayer:insertProp(prop)

local anim = ss:buildAnimationForProp(1, prop)
anim:start()


renderLayers = {backgroundLayer, foregroundLayer}

MOAIRenderMgr.setRenderTable(renderLayers)

myQuad = MOAIGfxQuad2D.new()
myQuad:setTexture("background.jpg")
myQuad:setRect(-320, -240, 320, 240)

myImage = MOAIProp2D.new()
myImage:setDeck(myQuad)
backgroundLayer:insertProp(myImage)

LevelScreen = require "LevelScreen"
screen = LevelScreen:new()

local cb = function(...)
  screen:handleKey(...)
end

MOAIInputMgr.device.keyboard:setCallback(cb)