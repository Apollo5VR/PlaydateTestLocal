--rocks and stuff
--object you can collide with, pickup, and increase nutrients count
local pd <const> = playdate
local gfx <const> = pd.graphics

class('sidewalk').extends(gfx.sprite)


function sidewalk:init(x, y)
local sidewalkImage = gfx.image.new("images/Pando/Cells/Rock/Sidewalk_01_cell") 
	sidewalkSprite = gfx.sprite.new(sidewalkImage)
	sidewalkSprite:setCenter(0,0)
	sidewalkSprite:setCollideRect(0,0,sidewalkSprite:getSize())
    sidewalkSprite:moveTo(x, y)
    sidewalkSprite:setTag(2)
	sidewalkSprite:add()
end