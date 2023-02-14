--controls creating the 8x16 (24x24 spaces) grid
--controls instantiating barriers and nutrients
--keeps list of the barriers and nutrients instantiated

grid_columns = 16
local grid_rows = 9

function GenerateGridObjects()
  -- Define the grid system as a 2D array (matches the gridview size)
  --create this in init / initial setup of level game
  math.randomseed(playdate.getSecondsSinceEpoch())

  --small comment to pickup PR and more and still more
  grid = {}
    for x=1, grid_rows do
      grid[x] = {}
      for y=1, grid_columns do
        grid[x][y] = math.random(0, 100)
      end
    end

    return grid
end
