--rocks and stuff
--object you can collide with, pickup, and increase nutrients count
local pd <const> = playdate
local gfx <const> = pd.graphics

class('barrier').extends(gfx.sprite)


function barrier:init(x, y)
local barrierImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Medium_01") 
	barrierSprite = gfx.sprite.new(barrierImage)
	barrierSprite:setCenter(0,0)
	barrierSprite:setCollideRect(0,0,barrierSprite:getSize())
    barrierSprite:moveTo(x, y)
    barrierSprite:setTag(2)
	barrierSprite:add()
end