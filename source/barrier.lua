--rocks and stuff
--object you can collide with, pickup, and increase nutrients count
local pd <const> = playdate
local gfx <const> = pd.graphics

class('barrier').extends(gfx.sprite)


function barrier:init(x, y)
local barrierImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Medium_01") 
	sidewalkSprite = gfx.sprite.new(barrierImage)
	sidewalkSprite:setCenter(0,0)
	sidewalkSprite:setCollideRect(0,0,sidewalkSprite:getSize())
    sidewalkSprite:moveTo(x, y)
    sidewalkSprite:setTag(2)
	sidewalkSprite:add()
end