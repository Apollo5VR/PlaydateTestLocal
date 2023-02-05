import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/crank"

import "nurtients"
import "barrier"

local gfx<const> = playdate.graphics

local rootLeadingSprite = nil

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
--gridview:setCellPadding(0, 0, -2, -2)

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

--for reseting to a cell before overlap
local previousSection;
local previousRowsArray = {}
local previousColumnsArray = {}

local previousX0
local previousX1
local previousY0
local previousY1

local crankDifficulty = 1;

--used for stopping grid draw when collision
canMove = true

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
		brokenRockSprite:moveTo(300,200)
		--rootLeadingSprite:moveTo(315,125)
		boneSprite:moveTo(80,190)

	elseif level > 1 then		
		--randomize position
		math.randomseed(playdate.getSecondsSinceEpoch())
		local x = math.random(100, 300)
		local y = math.random(50, 150)
		--brokenRockSprite:moveTo(x,y)
		local x = math.random(100, 300)
		local y = math.random(50, 150)
		boneSprite:moveTo(x,y)
		local x = math.random(100, 300)
		local y = math.random(50, 150)
		--rootLeadingSprite:moveTo(x,y)

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

	if(rootLeadingSprite == nil) == false then
		rootLeadingSprite.remove(rootLeadingSprite)
	end

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
	dirtImage = gfx.image.new("images/Pando/Cells/Dirt/Dirt_01")
	rootLeadingSprite = gfx.sprite.new(rootLeadingImageUp)
	rootLeadingSprite:setCollideRect(0,0,rootLeadingSprite:getSize())
	rootLeadingSprite:setCenter(0, 0)
	rootLeadingSprite:add()

	local boneImage = gfx.image.new("images/allSprites/bone")
	boneSprite = gfx.sprite.new(boneImage)
	boneSprite:setCollideRect(0,0,boneSprite:getSize())
	boneSprite:add()

	local stoneWeakImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Weak_01")
	stoneSprite = gfx.sprite.new(stoneWeakImage)
	stoneSprite:setCenter(0,0)
	stoneSprite:setCollideRect(0,0,stoneSprite:getSize())
	stoneSprite:add()

	--used repeatedly, has no collider
	local brokenRockImage = gfx.image.new("images/Pando/Cells/Rock/Stone_Medium_Broken_01")
	brokenRockSprite = gfx.sprite.new(brokenRockImage)
	brokenRockSprite:setCenter(0,0)
	brokenRockSprite:moveTo(120,120)
	brokenRockSprite:add()

	--nextLevel()
	
	local backgroundImage = gfx.image.new("images/Pando/Cells/Dirt/Dirt_02")
	assert(backgroundImage)
	gfx.sprite.setBackgroundDrawingCallback(
		function(x, y, width, height)
			backgroundImage:draw(8, 24)
		end
	)

	resetTimer()
end



initialize()

--start the player in middle of grid
local section, row, column = gridview:getSelection()
previousSection = section
previousX0 = 120
previousX1 = 120
previousY0 = 200
previousY1 = 200
gridview:setSelection(section, 4, 8)

--TODO than random values between grid size for spawning barriers and nutrients,using drawCell specifying the row column

--use this to draw the root in the cell
local gfx = playdate.graphics
local runOnce = 0
function gridview:drawCell(section, row, column, selected, x, y, width, height)
	--TODO too heavy to have here
	--math.randomseed(playdate.getSecondsSinceEpoch())
	--randomVal = math.random(0, 100)
	if selected then
		--rootLeadingSprite:moveWithCollisions(x + 8, y + 40) --offset of grid in screen
		--gfx.fillRect(x, y, width, height)
		
		--TODO collision check was originally here

		--dont draw if player cant actually move
		--if(canMove) then
			--if(rootLeadingSprite:getImage() == rootLeadingImageUp or rootLeadingSprite:getImage() == rootLeadingImageDown) then
				--rootImageVertical:draw(x, y) --TODO we need something to draw the curve rotations	
			--else	
				--rootImageHorizontal:draw(x, y)
			--end
		--end

		--use previous values to determine image to draw in previous cell
		--should be 8 combos + the straight vert / hori
		
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

		
		--TODO i want these to all be different values
		print("x: " ..x .. "x1: "  ..previousX1.. "x0: "  ..previousX0 .. "y: " ..y .. "y1: "  ..previousY1.. "y0: "  ..previousY0)

		--cache previous values
		previousSection = section

		previousX0 = previousX1
		previousY0 = previousY1
		previousX1 = x
		previousY1 = y
		
		rootLeadingSprite:moveTo(x + 8, y + 24) --offset of grid in screen
		--if you got here it means you cranked enough on the new settings
		--TODO decrement nutrients count here by X
		nutrientsCount -= nutrientsCost

		--reset the cranks required to walking, until another barrier hit
		nutrientsCost = noBarrierStr
		print("nutrients returned to 1")


    elseif (row == 4 and column == 2) or (row == 6 and column == 3) then
		if runOnce == 1 then
			return
		end
		--randomly instantiate rock
		--instantiate rock
		--instantiate nutrients
		--print("random happened" .. randomVal)
		--stoneSprite:moveTo(x, y)
		nurtients(x + 8, y + 24)
		print("spawned random" ..row .. column)
	elseif (row == 3 and column == 9) or (row == 8 and column == 3) then
		if runOnce == 1 then
			return
		end
		table.insert(barrier(x + 8, y + 24), #barrier)
	elseif (row == 9) then
		runOnce = 1			
	end

	gfx.drawRect(x, y, width, height)
end

local barriers = {}

--TODO add the option for "overlap" here for nutrients
function rootLeadingSprite:collisionResponse(other)
	--if other:isA(Barrier) then
		--return "freeze"
	--elseif other:isA(Nutrients) then
		--return "overlap"
	--else
		--return "freeze"
	--end
	--TODO some can move bool
	--canMove = false
	--return "overlap"
	end

--TODO - add sprite rotation here sprite:setRotation(angle, [scale, [yScale]])
local buttonLastPressed = playdate.kButtonUp
local function isPressedMove()
	if canMove == false then
		print("can not move")
		--return
	end

	if playdate.buttonJustPressed( playdate.kButtonUp ) then
		buttonLastPressed = playdate.kButtonUp
		--gridview:selectPreviousRow(false)
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		buttonLastPressed = playdate.kButtonDown
		--gridview:selectNextRow(false)
	elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
		buttonLastPressed = playdate.kButtonLeft
		--gridview:selectPreviousColumn(false)
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		buttonLastPressed = playdate.kButtonRight
		--gridview:selectNextColumn(false)
	end
end


local function doMove()
	--TODO - use this to set can move, and if can not move, then reset position/selected to previous[1]
	local collisions = rootLeadingSprite:overlappingSprites()
	--[[
	for key, sprite in pairs( collisions ) do
		if ( sprite:getTag() == 1) then
			--nutrients
			nutrientsCount += 3
			sprite:remove()
		elseif ( sprite:getTag() == 2 and nutrientsCost ~= 3) then
			--barrier
			nutrientsCost = 3
				print("nutrients set to 3")
				gfx.drawText("Keep Cranking!", 120, 25)
			--if a collision dont continue till they beat the crank
			return
		end
	end
--]]
	if(#collisions >=1) then
		
		--loop through barriers?
		if (collisions[1]:getTag() == 2) and nutrientsCost ~= 3 then --collisions[0] == stoneSprite or collisions[1] == stoneSprite
			--make them work for it, the crank increase
			--will lose nutrients when they are cranking
				nutrientsCost = 3
				print("nutrients set to 3")
				gfx.drawText("Keep Cranking!", 120, 25)
				--brokenRockSprite:moveTo(collisions[1].x, collisions[1].y) -- need 8 and 24?
				collisions[1].remove(collisions[1])
				--TODO not getting remove because its getting reinstantiated onMove
				--TODO instantiate new broken that deletes on leave?
			--if a collision dont continue till they beat the crank
			return
		elseif (collisions[1]:getTag() == 1) then
			--TODO refactor to nutrients sprite
			nutrientsCount += 3
			collisions[1].remove(collisions[1])
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
		--rootLeadingSprite:setRotation(0)
	elseif playdate.buttonIsPressed(playdate.kButtonDown) then
		rootLeadingSprite:setImage(rootLeadingImageDown)
		buttonLastPressed = playdate.kButtonDown
		--rootLeadingSprite:setRotation(180)
	elseif playdate.buttonIsPressed(playdate.kButtonLeft) then
		rootLeadingSprite:setImage(rootLeadingImageLeft)
		buttonLastPressed = playdate.kButtonLeft
		--rootLeadingSprite:setRotation(270)
	elseif playdate.buttonIsPressed(playdate.kButtonRight) then
		rootLeadingSprite:setImage(rootLeadingImageRight)
		buttonLastPressed = playdate.kButtonRight
		--rootLeadingSprite:setRotation(90)
	end
end


function playdate.update()
	
	gfx.sprite.update()
	playdate.timer.updateTimers()
	--gridview:drawInRect(8, 48, 400, 240)


	--crank ticks basically means during each update will give you a return value of 1 as the crank 
	--turns past each 120 degree increment. (Since we passed in a 3, each tick represents 360 ÷ 3 = 120 degrees.) 
	--TODO will need to adjust crank tick param (smaller value requires more rotation) for barriers / rocks
	--higher number is easier
	crankDifficulty = 1 / nutrientsCost
	local crankTicks = playdate.getCrankTicks(crankDifficulty)
    if crankTicks == 1 then
			--TODO how to disable moving forward if at bottom of grid, it currently goes to top
        --isPressedMove()
		doMove()
		--TODO move this to doMove? since thats the only time we need to update? AND RUN 1x ON START
		if gridview.needsDisplay then
			gfx.pushContext(gridviewImage)
				gridview:drawInRect(0, 0, 400, 240)
				gfx.popContext() --this might be what we can do to "go backwards"
			gridviewSprite:setImage(gridviewImage)
		end
	--elseif crankTicks == -1 then
		--TODO will need some kind of logic that erases print in existing row...tricky, then below
		--gridview:selectPreviousColumn(false)
		--gridview:selectPreviousRow(false)
	--elseif crankTicks == (1/3) then
		--TODO art
		--getNextRootVariation()
		--gridview:drawCell()
	
	end

	isPressedRotate()


	gfx.drawText("Nutrients: " .. nutrientsCount, 45, 0)


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


