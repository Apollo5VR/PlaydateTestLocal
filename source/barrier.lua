--rocks and stuff
--object you can collide with, pickup, and increase nutrients count
local pd <const> = playdate
local gfx <const> = pd.graphics

class('barrier').extends(gfx.sprite)


function barrier:init(x, y)
local barrierImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Medium_01") 
	stoneSprite = gfx.sprite.new(barrierImage)
	stoneSprite:setCenter(0,0)
	stoneSprite:setCollideRect(0,0,stoneSprite:getSize())
    stoneSprite:moveTo(x, y)
    stoneSprite:setTag(2)
	stoneSprite:add()
end