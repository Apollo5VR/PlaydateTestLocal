import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/crank"

import "nurtients"
import "barrier"
import "sidewalk"
import "gridManager"

local gfx<const> = playdate.graphics

local boneSprite = nil

playerSpeed = 5;

playTimer = nil
playTime = 15 * 1000
endTime = 0

level = 0
maxLevel = 5

--pando vars
local rootLeadingSprite = nil
nutrientsCount = 100
treeNutrientsMin = 50
movementNutrientsMin = 1
nutrientsCost = 1

noBarrierStr = 1
weakRockStr = 2
mediumRockStr = 5
strongRockStr = 10

local gridview = playdate.ui.gridview.new(24,24)

gridview:setNumberOfColumns(16)
gridview:setNumberOfRows(9)

local gridviewSprite = gfx.sprite.new()
gridviewSprite:setCenter(0, 0)
gridviewSprite:moveTo(8, 24)
gridviewSprite:add()
local gridviewImage = gfx.image.new(400, 240)

local rootLeadingImageUp
local rootLeadingImageRight
local rootLeadingImageDown
local rootLeadingImageLeft

local rootImageVertical
local rootImageHorizontal
local rootImage_LeftDown
local rootImage_RightDown
local rootImage_UpLeft
local rootImage_UpRight
local dirtImage

--vars to help chose the image we should print in root trail
local previousSection;
local previousX0
local previousX1
local previousY0
local previousY1

local crankDifficulty = 1;

local function resetTimer()
	playTimer = playdate.timer.new(playTime, playTime, 0, playdate.easingFunctions.linear)
end

--TODO unused, refactor to use appropriately
local gameState = 0
--[[
function incrementGameState()
	gameState += 1

	print("incremented state" .. gameState)
	--game end, restart game state to title
	if(gameState == 4) then
		gameState = 0
	end
end
--]]

--TODO relocate / organize
local gameplay = 2
local function getBackgroundImage()
	--intro image
	if gameState == 0 then
		return "images/Pando/MenuAssets/Promo_01"
	--tutorial
	elseif gameState == 1 then
		return "images/Pando/MenuAssets/MainMenu_Tutorial_01"
	elseif gameState == gameplay then --2
		return "images/Pando/Cells/Dirt/Dirt_02"
	--game over (text displayed)
	elseif gameState == 3 then
		return "images/Pando/MenuAssets/MainMenu_Blank_01"
	end
end
local backgroundImage = gfx.image.new(getBackgroundImage())

--1 check treeMinimum, 2 check movementMinimum, etc
local function isEnoughNutrients(checkArg)	
	switch (checkArg) {
		[1] = function()
			if nutrientsCount < treeNutrientsMin then
				-- can not build a tree, TODO notify user

				return false
			else
				return true
			end
		end,
		[2] = function()
			if nutrientsCount < movementNutrientsMin then
				-- game over, TODO show a message or go to the main menu

				return false
			else
				return true
			end
		end
	}
end 

--helper function to replicate switchcase
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
	
	end
end

local function initialize()
	endTime = 0

	if (boneSprite == nil) == false then
		boneSprite.remove(boneSprite)
	end

	if(rootLeadingSprite == nil) == false then
		rootLeadingSprite.remove(rootLeadingSprite)
	end

	--root configuratitons
	rootLeadingImageUp = gfx.image.new("images/Pando/Cells/Root/Root_Leading_Up_01")
	rootLeadingImageRight = gfx.image.new("images/Pando/Cells/Root/Root_Leading_Right_01")
	rootLeadingImageDown = gfx.image.new("images/Pando/Cells/Root/Root_Leading_Down_01")
	rootLeadingImageLeft = gfx.image.new("images/Pando/Cells/Root/Root_Leading_Left_01")
	rootImageVertical = gfx.image.new("images/Pando/Cells/Root/Root_Vertical_01")
	rootImageHorizontal = gfx.image.new("images/Pando/Cells/Root/Root_Horizontal_01")
	rootImage_LeftDown = gfx.image.new("images/Pando/Cells/Root/Root_Corner_LeftDown_01")
	rootImage_RightDown = gfx.image.new("images/Pando/Cells/Root/Root_Corner_RightDown_01")
	rootImage_UpLeft = gfx.image.new("images/Pando/Cells/Root/Root_Corner_UpLeft_01")
	rootImage_UpRight = gfx.image.new("images/Pando/Cells/Root/Root_Corner_UpRight_01")
	
	rootLeadingSprite = gfx.sprite.new(rootLeadingImageUp)
	rootLeadingSprite:setCollideRect(0,0,rootLeadingSprite:getSize())
	rootLeadingSprite:setCenter(0, 0)
	rootLeadingSprite:add()

	local boneImage = gfx.image.new("images/allSprites/bone")
	boneSprite = gfx.sprite.new(boneImage)
	boneSprite:setCollideRect(0,0,boneSprite:getSize())
	boneSprite:add()

	local stoneWeakImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Weak_01")
	sidewalkSprite = gfx.sprite.new(stoneWeakImage)
	sidewalkSprite:setCenter(0,0)
	sidewalkSprite:setCollideRect(0,0,sidewalkSprite:getSize())
	sidewalkSprite:add()

	--used repeatedly, has no collider
	local brokenRockImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Medium_Broken_01")
	brokenRockSprite = gfx.sprite.new(brokenRockImage)
	brokenRockSprite:setCenter(0,0)
	brokenRockSprite:moveTo(120,120)
	brokenRockSprite:add()

	--TODO - for future gameplay
	--nextLevel()
	--resetTimer()
end

--start the player in middle of grid
local section, row, column = gridview:getSelection()
previousSection = section
previousX0 = 120
previousX1 = 120
previousY0 = 200
previousY1 = 200
gridview:setSelection(section, 4, 8)

--TODO relocate these vars / clean up
--use this to draw the root in the cell
local gfx = playdate.graphics
local runOnce = 0
local maxNutrientTimes = 7 --max number of  nutrients that will spawn
local maxBarrierTimes = 15
local nutrientsChance = 15 --chance that we'll spawn
local barrierChance = 25
local isFilled = false
-- Define the number of objects to place
nutrientsLimit = 5
local gridChances = GenerateGridObjects()
local gridChances1 = GenerateGridObjects()

--random values between grid size for spawning barriers and nutrients,using drawCell specifying the row column
function gridview:drawCell(section, row, column, selected, x, y, width, height)
	--TODO too heavy to have here, if use need coroutine or other location
	--math.randomseed(playdate.getSecondsSinceEpoch())
	--randomVal = math.random(0, 100)
	if selected then
		--use previous values to determine image to draw in previous cell	
		if((x > previousX0 and x == previousX1 and y < previousY0 and y < previousY1) or (y > previousY0 and y == previousY1 and x < previousX0 and x < previousX1)) then --or (x < previousX0 and x < previousX1 and y < previousY0 and y < previousY1))
			-- in cell [1] draw Root_Corner_RightDown_01
			rootImage_UpRight:draw(previousX1, previousY1)
		elseif((x < previousX0 and x == previousX1 and y > previousY0 and y > previousY1) or (y < previousY0 and y == previousY1 and x > previousX0 and x > previousX1)) then
			--in cell [1] Root_Corner_UpRight_01
			rootImage_LeftDown:draw(previousX1, previousY1)
		elseif((x > previousX0 and x == previousX1 and y > previousY0 and y > previousY1) or (y < previousY0 and y == previousY1 and x < previousX0 and x < previousX1)) then
			--in cell [1] Root_Corner_LeftDown_01
			rootImage_RightDown:draw(previousX1, previousY1)
		elseif((x < previousX0 and x == previousX1 and y < previousY0 and y < previousY1) or (y > previousY0 and y == previousY1 and x > previousX0 and x > previousX1)) then
			--in cell [1] Root_Corner_UpLeft_01
			rootImage_UpLeft:draw(previousX1, previousY1)
		elseif((x > previousX1 or x < previousX1)) then
			--in cell [1] Root_Vertical_01
			rootImageHorizontal:draw(previousX1, previousY1)
		elseif(y > previousY1 or y < previousY1) then
			--in cell [1] Root_Horizontal_01
			rootImageVertical:draw(previousX1, previousY1)
		end

		print("x: " ..x .. "x1: "  ..previousX1.. "x0: "  ..previousX0 .. "y: " ..y .. "y1: "  ..previousY1.. "y0: "  ..previousY0)

		--cache previous values
		previousSection = section
		previousX0 = previousX1
		previousY0 = previousY1
		previousX1 = x
		previousY1 = y
		
		rootLeadingSprite:moveTo(x + 8, y + 24) --offset of grid in screen
		--if you got here it means you cranked enough on the new settings
		nutrientsCount -= nutrientsCost
		--reset the cranks required to walking, until another barrier hit
		nutrientsCost = noBarrierStr
		print("nutrients returned to 1")


	elseif (row == 1) then
		if runOnce == 1 then
			return
		end
		--we want to add the sidewalks to the top layer here, TODO reactivate
		sidewalk(x + 8, y + 24)	
	elseif (row == 9) then
		--once its gotten through the grid on load (last row), dont run instantiate for items
		runOnce = 1	
		--TODO sidewalk barrier, if break, present tree
	else
		if runOnce == 1 then
			return
		end		

		--handle nutrients spawn
		if (gridChances[row][column] < nutrientsChance) and (maxNutrientTimes ~= 0) and (isFilled == false) then --50% chance
			nurtients(x + 8, y + 24)
			maxNutrientTimes -= 1
			isFilled = true
			print("spawned random nutrient" ..row .. column)
		end

		--handle barrier spawn
		if (gridChances[row][column] < barrierChance) and (maxBarrierTimes ~= 0) and (isFilled == false) then --50% chance
			barrier(x + 8, y + 24)
			maxBarrierTimes -= 1
			isFilled = true
			print("spawned random barrier" ..row .. column)
		end
		
		--rest isFilled before moving onto the next grid
		isFilled = false

	--note / deactivated: manual alternative if looking to revert to full control
	--elseif (row == 3 and column == 9) or (row == 8 and column == 3) then
		--if runOnce == 1 then
			--return
		--end
		--table.insert(barrier(x + 8, y + 24), #barrier)
	end
	--for debugging
	--gfx.drawRect(x, y, width, height)
end

--TODO - might want to use this in future for something
local barriers = {}

--note: sprite rotation abandoned here sprite (collider doesnt follow):setRotation(angle, [scale, [yScale]])
local buttonLastPressed = playdate.kButtonUp
local function isPressedMove()
	if playdate.buttonJustPressed( playdate.kButtonUp ) then
		buttonLastPressed = playdate.kButtonUp
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		buttonLastPressed = playdate.kButtonDown
	elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
		buttonLastPressed = playdate.kButtonLeft
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		buttonLastPressed = playdate.kButtonRight
	end
end

--local collisionSound = playdate.sound.sampleplayer.new("audio/Pando_Audio/Pando_Audio/SFX/Mp3/Rock Break True")
local function doMove()
	local collisions = rootLeadingSprite:overlappingSprites()
	if(#collisions >=1) then	
		--TODO - remove barriers array, no longer need
		if (collisions[1]:getTag() == 2) and nutrientsCost ~= 3 then --collisions[0] == stoneSprite or collisions[1] == stoneSprite
			--make them work for it, the crank increase
			--will lose nutrients when they are cranking
				nutrientsCost = 3
				print("nutrients set to 3")
				gfx.drawText("Keep Cranking!", 120, 25)
				collisions[1].remove(collisions[1])
				--collisionSound:play()
			--if a collision dont continue till they beat the crank
			--TODO - this logic not working right now, not increased nutrients cost not delaying
			return
		elseif (collisions[1]:getTag() == 1) then
			--TODO remove magic numbers
			nutrientsCount += 5
			collisions[1].remove(collisions[1])
			--collisionSound:play()
		else	
			
		end
	end

	switch (buttonLastPressed) {
		[playdate.kButtonUp] = function()
			gridview:selectPreviousRow(false)
		end,
		[playdate.kButtonDown] = function()
			gridview:selectNextRow(false)
		end,
		[playdate.kButtonLeft] = function()
			gridview:selectPreviousColumn(false)
		end,
		[playdate.kButtonRight] = function()
			gridview:selectNextColumn(false)
		end,
	}
end

local function isPressedRotate()
	if playdate.buttonIsPressed( playdate.kButtonUp ) then
		rootLeadingSprite:setImage(rootLeadingImageUp)
		buttonLastPressed = playdate.kButtonUp
	elseif playdate.buttonIsPressed(playdate.kButtonDown) then
		rootLeadingSprite:setImage(rootLeadingImageDown)
		buttonLastPressed = playdate.kButtonDown
	elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
		rootLeadingSprite:setImage(rootLeadingImageLeft)
		buttonLastPressed = playdate.kButtonLeft
	elseif playdate.buttonIsPressed(playdate.kButtonRight) then
		rootLeadingSprite:setImage(rootLeadingImageRight)
		buttonLastPressed = playdate.kButtonRight
	end
end

function startScreenLaunch()
	mySound = playdate.sound.fileplayer.new("audio/Pando_Audio/Pando_Audio/Music/Mp3/Pando Title Screen")
	mySound:play()

	assert(backgroundImage)
	gfx.sprite.setBackgroundDrawingCallback(
		function(x, y, width, height)
			--in play mode
			if(gameState == gameplay) then
				backgroundImage:draw(8, 24)
			else
				backgroundImage:draw(0, 0)
			end

		end
	)
end

--function clearAllSprites()

--end

startScreenLaunch()

function playdate.update()
	
	gfx.sprite.update()
	playdate.timer.updateTimers()

	if(gameState == -1 and playdate.buttonJustReleased(playdate.kButtonA)) then
		gameState = 1
		print("Final Game State " .. gameState)
		return;
	elseif(gameState == 0 and playdate.buttonJustReleased(playdate.kButtonA)) then
		gameState = 1
		playdate.graphics.clear()
		backgroundImage = gfx.image.new(getBackgroundImage())
		assert(backgroundImage)
		print("Final Game State " .. gameState)
		return;
	elseif(gameState == 1 and playdate.buttonJustReleased(playdate.kButtonA)) then
		resetTimer()
		gameState = 2
		print("Final Game State " .. gameState)
		playdate.graphics.clear()
		backgroundImage = gfx.image.new(getBackgroundImage())
		assert(backgroundImage)
		initialize()
		if gridview.needsDisplay then
			gfx.pushContext(gridviewImage)
				gridview:drawInRect(0, 0, 400, 240)
				gfx.popContext() --this might be what we can do to "go backwards"
			gridviewSprite:setImage(gridviewImage)
		end
		return;
	end

	--TODO relocate to a more performant location
	if nutrientsCount <= 0 then
		--TODO - need to clear sprites and graphics?
		backgroundImage:draw(0, 0)
		gfx.drawText("You ran out of nutrients!", 60, 190)
		gfx.drawText("Go to Playdate menu and restart game", 60, 210)
		--check game state for if we been here already

		if gameState >= 3 then
			return
		else

		--change local background to end screen
		local allSprites = gfx.sprite.getAllSprites()
		for index, sprite in ipairs(allSprites) do
				sprite:remove()
		end

		playdate.graphics.clear()
		gameState = 3;
		backgroundImage = gfx.image.new("images/Pando/MenuAssets/MainMenu_Blank_01")
		assert(backgroundImage)
		print("gamestate endB" .. gameState)
		--nutrientsCount = 100
		end
	end

	--dont handle below in game logic when in title etc
	if(gameState ~= gameplay) then
		return
	end
	--for debugging
	--gridview:drawInRect(8, 48, 400, 240)


	--crank ticks basically means during each update will give you a return value of 1 as the crank 
	--turns past each 120 degree increment. (Since we passed in a 3, each tick represents 360 ÷ 3 = 120 degrees.) 
	--TODO will need to adjust crank tick param (smaller value requires more rotation) for barriers / rocks
	--higher number is easier
	crankDifficulty = 1 / nutrientsCost
	local crankTicks = playdate.getCrankTicks(crankDifficulty)
    if crankTicks == 1 then
		print("crankDifficulty" ..nutrientsCost)
		doMove()
		if gridview.needsDisplay then
			gfx.pushContext(gridviewImage)
				gridview:drawInRect(0, 0, 400, 240)
				gfx.popContext() --this might be what we can do to "go backwards"
			gridviewSprite:setImage(gridviewImage)
		end
	--TODO for later anim logic
	--elseif crankTicks == -1 then

	--elseif crankTicks == (1/3) then
		--TODO art
		--getNextRootVariation()
		--gridview:drawCell()
	
	end

	isPressedRotate()

	gfx.drawText("ENERGY: " .. nutrientsCount, 45, 0)
end


