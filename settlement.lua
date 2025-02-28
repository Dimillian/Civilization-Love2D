-- settlement.lua - Handles player settlements and their borders

require("tile")
local love = require("love")

Settlement = {}
Settlement.__index = Settlement

function Settlement.new(x, y, owner)
    local self = setmetatable({}, Settlement)

    -- Settlement position (center tile)
    self.centerX = x
    self.centerY = y

    -- Settlement owner
    self.owner = owner

    -- Settlement name (could be randomly generated in the future)
    self.name = "Settlement " .. math.random(1, 1000)

    -- Settlement border radius (initially 1 for a 2x2 area)
    self.borderRadius = 1

    -- Settlement tiles (will be populated in calculateBorder)
    self.tiles = {}

    -- Calculate initial border
    self:calculateBorder()

    return self
end

-- Calculate which tiles are within the settlement's border
function Settlement:calculateBorder()
    self.tiles = {}

    -- Calculate the range of tiles within the border
    local startX = self.centerX - self.borderRadius
    local endX = self.centerX + self.borderRadius
    local startY = self.centerY - self.borderRadius
    local endY = self.centerY + self.borderRadius

    -- Add all tiles within the border to the settlement
    for y = startY, endY do
        for x = startX, endX do
            table.insert(self.tiles, {x = x, y = y})
        end
    end
end

-- Check if a tile is within the settlement's border
function Settlement:containsTile(x, y)
    for _, tile in ipairs(self.tiles) do
        if tile.x == x and tile.y == y then
            return true
        end
    end
    return false
end

-- Calculate the total yields of this settlement
function Settlement:calculateYields(grid)
    local yields = {
        food = 0,
        production = 0,
        gold = 0
    }

    for _, tilePos in ipairs(self.tiles) do
        -- Make sure the tile position is valid
        if tilePos.x >= 1 and tilePos.x <= grid.width and
           tilePos.y >= 1 and tilePos.y <= grid.height then

            local tile = grid.tiles[tilePos.y][tilePos.x]

            -- Get the total yield from this tile
            local tileYield = tile:getTotalYield()

            -- Add tile yields to settlement yields
            yields.food = yields.food + tileYield.food
            yields.production = yields.production + tileYield.production
            yields.gold = yields.gold + tileYield.gold
        end
    end

    return yields
end

-- Draw the settlement border
function Settlement:draw(tileSize, grid)
    -- Draw border for each tile in the settlement
    for _, tile in ipairs(self.tiles) do
        local screenX = (tile.x - 1) * tileSize
        local screenY = (tile.y - 1) * tileSize

        -- Draw a border around the tile
        love.graphics.setColor(1, 1, 1, 0.5)  -- White semi-transparent
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", screenX, screenY, tileSize, tileSize)

        -- Draw corner markers to make the border more visible
        local markerSize = math.max(3, tileSize / 6)  -- Scale marker size with tile size
        love.graphics.setColor(1, 1, 1, 0.8)  -- Brighter white for corners

        -- Top-left corner
        love.graphics.rectangle("fill", screenX, screenY, markerSize, markerSize)
        -- Top-right corner
        love.graphics.rectangle("fill", screenX + tileSize - markerSize, screenY, markerSize, markerSize)
        -- Bottom-left corner
        love.graphics.rectangle("fill", screenX, screenY + tileSize - markerSize, markerSize, markerSize)
        -- Bottom-right corner
        love.graphics.rectangle("fill", screenX + tileSize - markerSize, screenY + tileSize - markerSize, markerSize, markerSize)
    end

    -- Draw settlement center marker
    local centerScreenX = (self.centerX - 1) * tileSize
    local centerScreenY = (self.centerY - 1) * tileSize

    love.graphics.setColor(1, 0.8, 0.2, 0.8)  -- Gold color for settlement center
    love.graphics.circle("fill", centerScreenX + tileSize/2, centerScreenY + tileSize/2, tileSize/4)

    -- Draw settlement name
    love.graphics.setColor(1, 1, 1, 0.9)
    local fontSize = math.max(10, tileSize / 3)  -- Scale font size with tile size
    love.graphics.print(self.name, centerScreenX, centerScreenY - fontSize/2, 0, fontSize/12, fontSize/12)

    -- Calculate and display settlement yields if grid is provided
    if grid then
        local yields = self:calculateYields(grid)
        local yieldText = string.format("F:%d P:%d G:%d", yields.food, yields.production, yields.gold)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(yieldText, centerScreenX, centerScreenY - fontSize, 0, fontSize/12, fontSize/12)

        -- Display tile count
        local tileCountText = string.format("Tiles: %d", #self.tiles)
        love.graphics.print(tileCountText, centerScreenX, centerScreenY - fontSize*1.5, 0, fontSize/12, fontSize/12)
    end

    -- Reset color and line width
    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Settlement
