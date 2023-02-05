--object you can collide with, pickup, and increase nutrients count
local pd <const> = playdate
local gfx <const> = pd.graphics

class('nurtients').extends(gfx.sprite)

local nutrientCountSprite
local nutrients


function nurtients:init(x, y)
local nutrientImage = gfx.image.new("images/Pando/Cells/Nutrients/Nutrients_Medium_01.png") 
	nutrientSprite = gfx.sprite.new(nutrientImage)
	nutrientSprite:setCollideRect(0,0,nutrientSprite:getSize())
    nutrientSprite:moveTo(x, y)
	nutrientSprite:add()
end
