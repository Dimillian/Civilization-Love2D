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

    -- Animation state
    self.isMoving = false
    self.moveStartX = nil
    self.moveStartY = nil
    self.moveTargetX = nil
    self.moveTargetY = nil
    self.moveProgress = 0
    self.moveSpeed = 8 -- Tiles per second (increased from 5)

    -- Visual position (for smooth movement)
    self.visualX = nil
    self.visualY = nil

    -- Tile discovery animation
    self.discoveringTiles = {} -- Table to track tiles being discovered
    self.discoveryDuration = 0.5 -- How long the discovery animation takes (reduced from 0.8)
    self.discoveryWaveSpeed = 10 -- How fast the discovery wave spreads (increased from 3)

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

    -- Initialize visual position to match grid position
    self.visualX = self.gridX
    self.visualY = self.gridY

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
    -- Don't allow movement if already moving
    if self.isMoving then
        return false
    end

    -- Check if the target position is valid
    if x >= 1 and x <= grid.width and y >= 1 and y <= grid.height then
        local tile = grid.tiles[y][x]
        -- Only allow movement to non-water tiles
        if tile.type ~= TileType.WATER then
            -- Start animation
            self.isMoving = true
            self.moveStartX = self.gridX
            self.moveStartY = self.gridY
            self.moveTargetX = x
            self.moveTargetY = y
            self.moveProgress = 0

            return true
        end
    end
    return false
end

-- Update player animation
function Player:update(dt, grid)
    if self.isMoving then
        -- Update movement progress
        self.moveProgress = self.moveProgress + dt * self.moveSpeed

        -- Update visual position
        self.visualX = self.moveStartX + (self.moveTargetX - self.moveStartX) * math.min(1, self.moveProgress)
        self.visualY = self.moveStartY + (self.moveTargetY - self.moveStartY) * math.min(1, self.moveProgress)

        -- Smoothly follow player with camera during movement
        local effectiveTileSize = game.camera:getEffectiveTileSize()
        local centerX = (self.visualX - 1) * effectiveTileSize
        local centerY = (self.visualY - 1) * effectiveTileSize
        game:centerCameraOn(centerX, centerY)

        -- Check if movement is complete
        if self.moveProgress >= 1 then
            -- Finalize movement
            self.gridX = self.moveTargetX
            self.gridY = self.moveTargetY
            self.visualX = self.gridX
            self.visualY = self.gridY
            self.isMoving = false

            -- Discover tiles in range after moving
            self:discoverTilesInRange(grid)

            -- Increment turn counter when movement is complete
            game:nextTurn()
        end
    end

    -- Update tile discovery animations
    local i = 1
    while i <= #self.discoveringTiles do
        local tile = self.discoveringTiles[i]

        -- Only start animating after the delay
        if tile.delay <= 0 then
            tile.progress = tile.progress + dt / self.discoveryDuration

            -- Remove completed animations
            if tile.progress >= 1 then
                table.remove(self.discoveringTiles, i)
            else
                i = i + 1
            end
        else
            -- Decrease delay
            tile.delay = tile.delay - dt
            i = i + 1
        end
    end
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

            -- If within sight range and not already discovered, start discovery animation
            if distance <= self.sightRange and not self.discoveredTiles[y][x] then
                -- Calculate delay based on distance from player
                local delay = distance / self.discoveryWaveSpeed

                -- Add to discovering tiles list
                table.insert(self.discoveringTiles, {
                    x = x,
                    y = y,
                    progress = 0,
                    delay = delay,
                    distance = distance
                })

                -- Mark as discovered immediately in the data structure
                self.discoveredTiles[y][x] = true
            end
        end
    end
end

-- Check if a tile is being discovered (for rendering)
function Player:getTileDiscoveryProgress(x, y)
    for _, tile in ipairs(self.discoveringTiles) do
        if tile.x == x and tile.y == y then
            -- Return progress if delay is over, otherwise 0
            return tile.delay <= 0 and tile.progress or 0
        end
    end
    return -1 -- Not being discovered
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

    -- Draw turn counter
    love.graphics.setColor(0.7, 0.7, 1.0)  -- Light blue for turn counter
    love.graphics.print("Turn: " .. game.turn, screenWidth - 180, 10)

    -- Draw End Turn button
    self:drawEndTurnButton(screenWidth - 80, 5, 70, 30)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Draw the End Turn button
function Player:drawEndTurnButton(x, y, width, height)
    -- Check if mouse is hovering over the button
    local mx, my = love.mouse.getPosition()
    local isHovering = mx >= x and mx <= x + width and my >= y and my <= y + height

    -- Draw button background
    if isHovering then
        love.graphics.setColor(0.4, 0.4, 0.8, 0.9)  -- Brighter when hovering
    else
        love.graphics.setColor(0.3, 0.3, 0.7, 0.8)  -- Normal color
    end
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw button border
    love.graphics.setColor(0.5, 0.5, 1.0, 0.9)
    love.graphics.rectangle("line", x, y, width, height)

    -- Draw button text
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local text = "End Turn"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, x + width/2 - textWidth/2, y + height/2 - textHeight/2)
end

-- Handle mouse press for the End Turn button
function Player:handleMousePress(x, y)
    -- Check if the End Turn button was clicked
    local screenWidth = love.graphics.getWidth()
    local buttonX = screenWidth - 80
    local buttonY = 5
    local buttonWidth = 70
    local buttonHeight = 30

    if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
        -- End the current turn
        game:nextTurn()
        return true
    end

    return false
end

function Player:drawOnMap(tileSize)
    if not self.visualX or not self.visualY then return end

    -- Get the effective tile size based on zoom level
    local effectiveTileSize = game.camera:getEffectiveTileSize()

    -- Draw movement path indicator if moving
    if self.isMoving then
        -- Draw a line from start to target
        love.graphics.setColor(1, 1, 1, 0.7) -- Brighter line
        local startX = (self.moveStartX - 1) * effectiveTileSize + effectiveTileSize/2
        local startY = (self.moveStartY - 1) * effectiveTileSize + effectiveTileSize/2
        local targetX = (self.moveTargetX - 1) * effectiveTileSize + effectiveTileSize/2
        local targetY = (self.moveTargetY - 1) * effectiveTileSize + effectiveTileSize/2

        -- Draw dashed line with animation
        local dashLength = 6
        local gapLength = 4
        local dx = targetX - startX
        local dy = targetY - startY
        local distance = math.sqrt(dx * dx + dy * dy)
        local steps = math.floor(distance / (dashLength + gapLength))

        -- Animate the dashes by shifting them based on time
        local shift = (love.timer.getTime() * 10) % (dashLength + gapLength)

        for i = -1, steps do
            local t1 = math.max(0, (i * (dashLength + gapLength) + shift) / distance)
            local t2 = math.min(1, ((i * (dashLength + gapLength)) + dashLength + shift) / distance)

            if t1 < t2 then
                local x1 = startX + dx * t1
                local y1 = startY + dy * t1
                local x2 = startX + dx * t2
                local y2 = startY + dy * t2

                love.graphics.setLineWidth(2) -- Thicker line
                love.graphics.line(x1, y1, x2, y2)
                love.graphics.setLineWidth(1)
            end
        end

        -- Draw target indicator with pulsing effect
        local pulseScale = 0.8 + 0.2 * math.sin(love.timer.getTime() * 6)
        love.graphics.circle("line", targetX, targetY, tileSize/4 * pulseScale)

        -- Draw a small arrow at the end
        local arrowSize = tileSize/6
        local angle = math.atan2(dy, dx)
        local arrowX1 = targetX - arrowSize * math.cos(angle - math.pi/6)
        local arrowY1 = targetY - arrowSize * math.sin(angle - math.pi/6)
        local arrowX2 = targetX - arrowSize * math.cos(angle + math.pi/6)
        local arrowY2 = targetY - arrowSize * math.sin(angle + math.pi/6)

        love.graphics.setLineWidth(2)
        love.graphics.line(targetX, targetY, arrowX1, arrowY1)
        love.graphics.line(targetX, targetY, arrowX2, arrowY2)
        love.graphics.setLineWidth(1)
    end

    local screenX = (self.visualX - 1) * effectiveTileSize
    local screenY = (self.visualY - 1) * effectiveTileSize

    -- Draw player avatar (a simple circle for now)
    love.graphics.setColor(1, 0, 0)  -- Red color for player
    love.graphics.circle("fill", screenX + effectiveTileSize/2, screenY + effectiveTileSize/2, effectiveTileSize/3)
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

    -- Show a notification for the new settlement
    game:showNotification(NotificationType.ACHIEVEMENT, "New settlement founded: " .. settlement.name)

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

-- Handle end of turn updates for the player
function Player:onTurnEnd()
    -- Update player yields
    self:updateYields(game.grid)

    -- Here you can add other end-of-turn logic like:
    -- - Resource accumulation
    -- - Building progress
    -- - Settlement growth
    -- - Research progress
    -- - Unit healing
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
    -- Get the effective tile size based on zoom level
    local effectiveTileSize = game.camera:getEffectiveTileSize()

    for _, settlement in ipairs(self.settlements) do
        settlement:draw(effectiveTileSize, grid)
    end
end

return Player
