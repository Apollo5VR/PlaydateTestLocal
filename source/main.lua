import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/crank"

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

local gridview = playdate.ui.gridview.new(24,24)

gridview:setNumberOfColumns(16)
gridview:setNumberOfRows(8)
--gridview:setCellPadding(0, 0, -2, -2)

local gridviewSprite = gfx.sprite.new()
gridviewSprite:setCenter(0, 0)
gridviewSprite:moveTo(8, 40)
gridviewSprite:add()
local gridviewImage = gfx.image.new(400, 240)

local dogImage

--controls which image is grabbed next in the anim sequence
rootState = 0;


local function resetTimer()
	playTimer = playdate.timer.new(playTime, playTime, 0, playdate.easingFunctions.linear)
end

--TODO replace the image file locations for the root variations
local function getNextRootVariation()
	if rootState == 0 then
		rootState += 1
		return "images/castlebackground"
	end
	if rootState == 1 then
		rootState += 1
		return "images/spacebackground"
	end
	if rootState == 2 then
		rootState = 0
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

local function switch(value)
  -- Handing `cases` to the returned function allows the `switch()` function to be used with a syntax closer to c code (see the example below).
  -- This is because lua allows the parentheses around a table type argument to be omitted if it is the only argument.
  return function(cases)
    local f = cases[value]
    if (f) then
      f()
    end
  end
end



local function nextLevel()
    level = level + 1
    if level > maxLevel then
        -- game over, show a message or go to the main menu

        return
	end

    -- set the background image and other level-specific properties
	if level == 1 then
		--[[
        local backgroundImage = gfx.image.new("images/spacebackground")
        assert(backgroundImage)
        gfx.sprite.setBackgroundDrawingCallback(
            function(x, y, width, height)
                backgroundImage:draw(0, 0)
            end
        )
		--]]

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

	dogImage = gfx.image.new("images/allSprites/dog")
	dogSprite = gfx.sprite.new(dogImage)
	dogSprite:setCenter(0, 0)
	dogSprite:setCollideRect(0,0,dogSprite:getSize())
	dogSprite:add()

	local boneImage = gfx.image.new("images/allSprites/bone")
	boneSprite = gfx.sprite.new(boneImage)
	boneSprite:setCollideRect(0,0,boneSprite:getSize())
	boneSprite:add()

	local playerImage = gfx.image.new("images/allSprites/player")
	assert( playerImage )
	dogSprite:setCenter(0, 0)
	playerSprite = gfx.sprite.new(playerImage)
	playerSprite:setCollideRect(0,0,playerSprite:getSize())
	playerSprite:add()

	nextLevel()

	resetTimer()
end



initialize()

--use this to draw the root in the cell
local gfx = playdate.graphics
function gridview:drawCell(section, row, column, selected, x, y, width, height)
    gfx.drawRect(x, y, width, height)

	if selected then
		dogImage:draw(x, y)
		--gfx.fillRect(x, y, width, height)
		dogSprite:moveTo(x + 8,y + 40) 
		--playerSprite:drawInRect(x, y, width, height)
        --gfx.drawCircleInRect(x, y, width+4, height+4)
		--dogSprite:drawInRect(x, y, width, height)
    end
    --local cellText = ""..row.."-"..column
    --gfx.drawTextInRect(cellText, x, y+14, width, 20, nil, nil, kTextAlignment.center)
end

--TODO - add sprite rotation here sprite:setRotation(angle, [scale, [yScale]])
local function isPressedMove()
	if playdate.buttonIsPressed( playdate.kButtonUp ) then
		gridview:selectPreviousRow(true)
	elseif playdate.buttonIsPressed(playdate.kButtonDown) then
		gridview:selectNextRow(true)
	elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
		gridview:selectPreviousColumn(false)
	elseif playdate.buttonIsPressed(playdate.kButtonRight) then
		gridview:selectNextColumn(false)
	end
end


function playdate.update()
	
	gfx.sprite.update()
	playdate.timer.updateTimers()
	--gridview:drawInRect(8, 48, 400, 240)


	--crank ticks basically means during each update will give you a return value of 1 as the crank 
	--turns past each 120 degree increment. (Since we passed in a 6, each tick represents 360 ÷ 3 = 120 degrees.) 
	--TODO will need to adjust crank tick param (smaller value requires more rotation) for barriers / rocks
	local crankTicks = playdate.getCrankTicks(3)
    if crankTicks == 1 then
			--TODO how to disable moving forward if at bottom of grid, it currently goes to top
        isPressedMove()
		--TODO decrement nutrients count here by X
		nutrients -= 1
	elseif crankTicks == -1 then
		--TODO will need some kind of logic that erases print in existing row...tricky, then below
		--gridview:selectPreviousColumn(false)
		--gridview:selectPreviousRow(false)
	elseif crankTicks == (1/3) then
		--TODO art
		getNextRootVariation()
		gridview:drawCell()
    end

	if gridview.needsDisplay then
        gfx.pushContext(gridviewImage)
            gridview:drawInRect(0, 0, 400, 240)
    		gfx.popContext() --this might be what we can do to "go backwards"
        gridviewSprite:setImage(gridviewImage)
    end

	gfx.drawText("Nutrients: " .. nutrients, 45, 0)


	--[[
	
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
	--]]
end


