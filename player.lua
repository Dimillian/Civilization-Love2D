-- player.lua - Player entity and UI

require("tile")
require("settlement")
local love = require("love")

Player = {}
Player.__index = Player

function Player.new(grid)
    local self = setmetatable({}, Player)

    -- Player position
    self.gridX = nil
    self.gridY = nil

    -- Player yields
    self.yields = {
        food = 0,
        production = 0,
        gold = 0
    }

    -- Sight range (how many tiles the player can see in each direction)
    self.sightRange = 4

    -- Track discovered tiles using a 2D table
    self.discoveredTiles = {}
    for y = 1, grid.height do
        self.discoveredTiles[y] = {}
        for x = 1, grid.width do
            self.discoveredTiles[y][x] = false
        end
    end

    -- Player settlements
    self.settlements = {}

    -- Find a random valid starting position (non-water tile)
    self:findRandomStartPosition(grid)

    -- Discover tiles around the starting position
    self:discoverTilesInRange(grid)

    return self
end

function Player:findRandomStartPosition(grid)
    local validTiles = {}

    -- Collect all non-water tiles as potential starting positions
    for y = 1, grid.height do
        for x = 1, grid.width do
            local tile = grid.tiles[y][x]
            if tile.type ~= TileType.WATER then
                table.insert(validTiles, {x = x, y = y})
            end
        end
    end

    -- Select a random valid tile
    if #validTiles > 0 then
        local randomIndex = math.random(1, #validTiles)
        self.gridX = validTiles[randomIndex].x
        self.gridY = validTiles[randomIndex].y
    else
        -- Fallback to a random position if no valid tiles found
        self.gridX = math.random(1, grid.width)
        self.gridY = math.random(1, grid.height)
    end
end

function Player:getCurrentTile(grid)
    if self.gridX and self.gridY then
        return grid:getTileAt(self.gridX, self.gridY)
    end
    return nil
end

function Player:moveTo(x, y, grid)
    -- Check if the target position is valid
    if x >= 1 and x <= grid.width and y >= 1 and y <= grid.height then
        local tile = grid.tiles[y][x]
        -- Only allow movement to non-water tiles
        if tile.type ~= TileType.WATER then
            self.gridX = x
            self.gridY = y

            -- Discover tiles in range after moving
            self:discoverTilesInRange(grid)

            return true
        end
    end
    return false
end

-- Discover tiles within the player's sight range
function Player:discoverTilesInRange(grid)
    if not self.gridX or not self.gridY then return end

    -- Calculate the range of tiles to check
    local startX = math.max(1, self.gridX - self.sightRange)
    local endX = math.min(grid.width, self.gridX + self.sightRange)
    local startY = math.max(1, self.gridY - self.sightRange)
    local endY = math.min(grid.height, self.gridY + self.sightRange)

    -- Check each tile in the rectangular area
    for y = startY, endY do
        for x = startX, endX do
            -- Calculate distance from player (using Euclidean distance for a circular sight)
            local distance = math.sqrt((x - self.gridX)^2 + (y - self.gridY)^2)

            -- If within sight range, mark as discovered
            if distance <= self.sightRange then
                self.discoveredTiles[y][x] = true
            end
        end
    end
end

-- Check if a tile is discovered by this player
function Player:isTileDiscovered(x, y)
    -- Make sure coordinates are valid
    if not x or not y then return false end

    -- Convert to integers in case they're floats
    x, y = math.floor(x), math.floor(y)

    -- Check if coordinates are within bounds
    if x < 1 or y < 1 or x > #self.discoveredTiles[1] or y > #self.discoveredTiles then
        return false
    end

    return self.discoveredTiles[y][x]
end

function Player:updateYields(grid)
    -- Reset yields
    self.yields = {
        food = 0,
        production = 0,
        gold = 0
    }

    -- Calculate yields from all tiles within settlements
    for _, settlement in ipairs(self.settlements) do
        for _, tilePos in ipairs(settlement.tiles) do
            -- Make sure the tile position is valid
            if tilePos.x >= 1 and tilePos.x <= grid.width and
               tilePos.y >= 1 and tilePos.y <= grid.height then

                local tile = grid.tiles[tilePos.y][tilePos.x]

                -- Get the total yield from this tile
                local tileYield = tile:getTotalYield()

                -- Add tile yields to player yields
                self.yields.food = self.yields.food + tileYield.food
                self.yields.production = self.yields.production + tileYield.production
                self.yields.gold = self.yields.gold + tileYield.gold
            end
        end
    end
end

function Player:draw()
    -- Draw player UI at the top of the screen
    local screenWidth = love.graphics.getWidth()
    local barHeight = 40

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenWidth, barHeight)

    -- Draw yields with icons and better formatting
    local iconSize = 20
    local padding = 10
    local textOffset = 25

    -- Food (green)
    love.graphics.setColor(0.2, 0.8, 0.2)
    -- Draw food icon (simple circle for now)
    love.graphics.circle("fill", padding + iconSize/2, barHeight/2, iconSize/2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Food: " .. self.yields.food, padding + textOffset, 10)

    -- Production (brown)
    love.graphics.setColor(0.8, 0.6, 0.2)
    -- Draw production icon (hammer shape)
    love.graphics.rectangle("fill", 150 + padding, barHeight/2 - iconSize/2, iconSize/2, iconSize)
    love.graphics.polygon("fill",
        150 + padding + iconSize/2, barHeight/2 - iconSize/2,
        150 + padding + iconSize, barHeight/2 - iconSize/4,
        150 + padding + iconSize, barHeight/2 + iconSize/4,
        150 + padding + iconSize/2, barHeight/2 + iconSize/2
    )
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Production: " .. self.yields.production, 150 + padding + textOffset, 10)

    -- Gold (yellow)
    love.graphics.setColor(1, 0.9, 0.2)
    -- Draw gold icon (coin)
    love.graphics.circle("fill", 300 + padding + iconSize/2, barHeight/2, iconSize/2)
    love.graphics.setColor(0.8, 0.7, 0.1)
    love.graphics.circle("line", 300 + padding + iconSize/2, barHeight/2, iconSize/3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Gold: " .. self.yields.gold, 300 + padding + textOffset, 10)

    -- Draw settlement count
    love.graphics.setColor(1, 1, 1)

    -- Count total tiles in all settlements
    local totalTiles = 0
    for _, settlement in ipairs(self.settlements) do
        totalTiles = totalTiles + #settlement.tiles
    end

    love.graphics.print("Settlements: " .. #self.settlements .. " (" .. totalTiles .. " tiles)", 450 + padding, 10)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Player:drawOnMap(tileSize)
    if not self.gridX or not self.gridY then return end

    local screenX = (self.gridX - 1) * tileSize
    local screenY = (self.gridY - 1) * tileSize

    -- Draw player avatar (a simple circle for now)
    love.graphics.setColor(1, 0, 0)  -- Red color for player
    love.graphics.circle("fill", screenX + tileSize/2, screenY + tileSize/2, tileSize/3)
    love.graphics.setColor(1, 1, 1)  -- Reset color
end

-- Create a new settlement at the specified position
function Player:createSettlement(x, y)
    -- Check if there's already a settlement at this position
    if self:getSettlementAt(x, y) then
        return false
    end

    -- Check if there's a settlement too close (within 4 tiles)
    for _, settlement in ipairs(self.settlements) do
        local distance = math.sqrt((x - settlement.centerX)^2 + (y - settlement.centerY)^2)
        if distance < 4 then
            return false
        end
    end

    -- Create the new settlement
    local settlement = Settlement.new(x, y, self)
    table.insert(self.settlements, settlement)

    return true
end

-- Get a settlement at the specified position
function Player:getSettlementAt(x, y)
    for _, settlement in ipairs(self.settlements) do
        if settlement.centerX == x and settlement.centerY == y then
            return settlement
        end
    end
    return nil
end

-- Check if a tile is within any of the player's settlements
function Player:isTileInSettlement(x, y)
    for _, settlement in ipairs(self.settlements) do
        if settlement:containsTile(x, y) then
            return true, settlement
        end
    end
    return false, nil
end

-- Draw all settlements
function Player:drawSettlements(tileSize, grid)
    for _, settlement in ipairs(self.settlements) do
        settlement:draw(tileSize, grid)
    end
end

return Player
