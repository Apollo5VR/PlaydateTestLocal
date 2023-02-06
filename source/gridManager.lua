--controls creating the 8x16 (24x24 spaces) grid
--controls instantiating barriers and nutrients
--keeps list of the barriers and nutrients instantiated

grid_columns = 16
grid_rows = 9

-- Define the grid system as a 2D array (matches the gridview size)
--create this in init / initial setup of level game
grid = {}
for i=1, grid_rows do
  grid[i] = {}
  for j=1, grid_columns do
    grid[i][j] = math.random(0, 100) --TODO correct this to actual function
  end
end

-- Define the number of objects to place
nutrientsLimit = 5

--as it goes through the grid drawing cells
if(runNutrientsEveryX ~= 0) then 
    if grid[row][column] > 50 then --50% chance
        nurtrients(x + 8, y + 24)
        runNutrientsEveryX -= 1 --will decrement from 9, each time when a random success down to 0, then will no longer check random (allows controlling exact amount of nutrients, just placed dif)
    end
end