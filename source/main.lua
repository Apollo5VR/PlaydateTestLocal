import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx<const> = playdate.graphics
local playerSprite = nil

local dogSprite = nil

local boneSprite = nil

playerSpeed = 5;

playTimer = nil
playTime = 15 * 1000
endTime = 0

hasBone = false
dogGotBone = false

level = 0
maxLevel = 5

--pando vars
nutrients = 100
treeNutrientsMin = 50
movementNutrientsMin = 1

weakRockStr = 2
mediumRockStr = 7
strongRockStr = 15


local function resetTimer()
	playTimer = playdate.timer.new(playTime, playTime, 0, playdate.easingFunctions.linear)
end

--TODO replace the image file locations for the root variations
local function getNextRootVariation()
	if level == 1 then
		return "images/castlebackground"
	end
	if level == 2 then
		return "images/spacebackground"
	end
	if level == 3 then
		return "images/desertbackground"
	end
end

--1 check treeMinimum, 2 check movementMinimum, etc
local function isEnoughNutrients(checkArg)	
	switch (checkArg) {
		[1] = function()
			if nutrients < treeNutrientsMin then
				-- can not build a tree, TODO notify user

				return false
			else
				return true
			end
		end,
		[2] = function()
			if nutrients < movementNutrientsMin then
				-- game over, TODO show a message or go to the main menu

				return false
			else
				return true
			end
		end
	}
end 

local function nextLevel()
    level = level + 1
    if level > maxLevel then
        -- game over, show a message or go to the main menu

        return
	end

    -- set the background image and other level-specific properties
	if level == 1 then
        local backgroundImage = gfx.image.new(getLevelToImage())
        assert(backgroundImage)
        gfx.sprite.setBackgroundDrawingCallback(
            function(x, y, width, height)
                backgroundImage:draw(0, 0)
            end
        )
		--specific starting locations for first level
		playerSprite:moveTo(300,200)
		dogSprite:moveTo(315,125)
		boneSprite:moveTo(80,190)

	elseif level > 1 then		
		--randomize position
		math.randomseed(playdate.getSecondsSinceEpoch())
		local x = math.random(100, 300)
		local y = math.random(50, 150)
		playerSprite:moveTo(x,y)
		local x = math.random(100, 300)
		local y = math.random(50, 150)
		boneSprite:moveTo(x,y)
		local x = math.random(100, 300)
		local y = math.random(50, 150)
		dogSprite:moveTo(x,y)

		local backgroundImage = gfx.image.new(getLevelToImage())
			assert(backgroundImage)
			gfx.sprite.setBackgroundDrawingCallback(
			function(x, y, width, height)
				backgroundImage:draw(0, 0)
				end
			)
			-- add new obstacles or enemies for this level
		elseif level == 5 then

			--restart level sequence
			level = 0
		end
end

local function initialize()
	hasBone = false
	dogGotBone = false
	endTime = 0

	if (boneSprite == nil) == false then
		boneSprite.remove(boneSprite)
	end

	if(playerSprite == nil) == false then
		playerSprite.remove(playerSprite)
	end

	if(dogSprite == nil) == false then
		dogSprite.remove(dogSprite)
	end

	local dogImage = gfx.image.new("images/allSprites/dog")
	dogSprite = gfx.sprite.new(dogImage)
	dogSprite:setCollideRect(0,0,dogSprite:getSize())
	dogSprite:add()

	local boneImage = gfx.image.new("images/allSprites/bone")
	boneSprite = gfx.sprite.new(boneImage)
	boneSprite:setCollideRect(0,0,boneSprite:getSize())
	boneSprite:add()

	local playerImage = gfx.image.new("images/allSprites/player")
	assert( playerImage )
	playerSprite = gfx.sprite.new(playerImage)
	playerSprite:setCollideRect(0,0,playerSprite:getSize())
	playerSprite:add()

	nextLevel()

	resetTimer()
end



initialize()

function playdate.update()
	gfx.sprite.update()
	
	if (playTimer.value == 0) or dogGotBone then
		gfx.drawText("'A' to for next level. Time: " ..endTime, 45, 210)
		if(playerSprite == nil) == false then
			playerSprite.remove(playerSprite)
		end

		if playdate.buttonJustPressed(playdate.kButtonA) then
			resetTimer()
			playerSprite.remove(playerSprite)
			initialize()
		end
	else
		if playdate.buttonIsPressed( playdate.kButtonUp ) then
			playerSprite:moveBy( 0, -playerSpeed )
		end
		if playdate.buttonIsPressed( playdate.kButtonRight ) then
			playerSprite:moveBy( playerSpeed, 0 )
		end
		if playdate.buttonIsPressed( playdate.kButtonDown ) then
			playerSprite:moveBy( 0, playerSpeed )
		end
		if playdate.buttonIsPressed( playdate.kButtonLeft ) then
			playerSprite:moveBy( -playerSpeed, 0 )
		end
	end

	local collisions = playerSprite:overlappingSprites()
	if(#collisions >=1) then
		if collisions[0] == boneSprite or collisions[1] == boneSprite then
			hasBone = true
			boneSprite.remove(boneSprite)
		elseif (hasBone == true) and (collisions[0] == dogSprite or collisions[1] == dogSprite) then
			dogSprite.remove(dogSprite)	
			dogGotBone = true
			endTime = playTimer.value/1000
		else	
			gfx.drawText("Ouch!", 120, 25)
		end
	end

	if dogGotBone then
		gfx.drawText("YOU WIN!", 120, 45)	
	end

	playdate.timer.updateTimers()

	gfx.drawText("Time: " .. math.ceil(playTimer.value/1000), 45, 0)

	if hasBone then
		gfx.drawText("You picked up bone", 120, 5)
	end
end


