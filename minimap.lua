local love = require("love")

Minimap = {}
Minimap.__index = Minimap

function Minimap.new(grid, tileSize)
    local self = setmetatable({}, Minimap)

    -- Configuration
    self.width = 150  -- Width of minimap in pixels
    self.height = 150  -- Height of minimap in pixels
    self.padding = 10  -- Padding from screen edge
    self.borderWidth = 2  -- Border thickness
    self.grid = grid
    self.originalTileSize = tileSize
    self.visible = true  -- Whether the minimap is visible

    -- Calculate the scale factor for the minimap
    self.scaleFactor = math.min(
        self.width / (grid.width * tileSize),
        self.height / (grid.height * tileSize)
    )

    -- Size of each tile on the minimap
    self.minimapTileSize = tileSize * self.scaleFactor

    return self
end

function Minimap:draw(player, camera)
    -- Skip drawing if not visible
    if not self.visible then
        return
    end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Position in bottom left
    local x = self.padding
    local y = screenHeight - self.height - self.padding

    -- Draw background and border
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y, self.width, self.height)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", x, y, self.width, self.height)

    -- Draw the grid tiles
    for gridY = 1, self.grid.height do
        for gridX = 1, self.grid.width do
            -- Only draw if the tile is discovered by the player
            if player:isTileDiscovered(gridX, gridY) then
                local tile = self.grid.tiles[gridY][gridX]

                -- Calculate position on minimap
                local tileX = x + (gridX - 1) * self.minimapTileSize
                local tileY = y + (gridY - 1) * self.minimapTileSize

                -- Set color based on tile type
                if tile.type == TileType.WATER then
                    love.graphics.setColor(0.2, 0.4, 0.8, 0.8)
                elseif tile.type == TileType.PLAINS then
                    love.graphics.setColor(0.5, 0.8, 0.2, 0.8)
                elseif tile.type == TileType.FOREST then
                    love.graphics.setColor(0.1, 0.6, 0.1, 0.8)
                elseif tile.type == TileType.MOUNTAIN then
                    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
                end

                -- Draw the tile
                love.graphics.rectangle("fill", tileX, tileY, self.minimapTileSize, self.minimapTileSize)
            end
        end
    end

    -- Draw settlements
    for _, settlement in ipairs(player.settlements) do
        local settlementX = x + (settlement.centerX - 1) * self.minimapTileSize
        local settlementY = y + (settlement.centerY - 1) * self.minimapTileSize

        -- Draw settlement marker
        love.graphics.setColor(1, 0.8, 0.2, 1)  -- Gold color
        love.graphics.circle("fill",
            settlementX + self.minimapTileSize/2,
            settlementY + self.minimapTileSize/2,
            self.minimapTileSize * 1.5)
    end

    -- Draw player position
    local playerX = x + (player.visualX - 1) * self.minimapTileSize
    local playerY = y + (player.visualY - 1) * self.minimapTileSize

    love.graphics.setColor(1, 0, 0, 1)  -- Red color
    love.graphics.circle("fill",
        playerX + self.minimapTileSize/2,
        playerY + self.minimapTileSize/2,
        self.minimapTileSize)

    -- Draw viewport rectangle - FIXED to properly handle zoom
    local effectiveTileSize = self.originalTileSize * camera.zoomLevel

    -- Calculate the viewport in grid coordinates
    local viewportStartGridX = camera.x / effectiveTileSize
    local viewportStartGridY = camera.y / effectiveTileSize
    local viewportWidthInTiles = love.graphics.getWidth() / effectiveTileSize
    local viewportHeightInTiles = love.graphics.getHeight() / effectiveTileSize

    -- Convert to minimap coordinates
    local viewportX = x + viewportStartGridX * self.minimapTileSize
    local viewportY = y + viewportStartGridY * self.minimapTileSize
    local viewportWidth = viewportWidthInTiles * self.minimapTileSize
    local viewportHeight = viewportHeightInTiles * self.minimapTileSize

    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("line", viewportX, viewportY, viewportWidth, viewportHeight)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle mouse clicks on the minimap
function Minimap:handleMousePress(x, y, game)
    -- Skip if not visible
    if not self.visible then
        return false
    end

    local screenHeight = love.graphics.getHeight()
    local minimapX = self.padding
    local minimapY = screenHeight - self.height - self.padding

    -- Check if click is within minimap bounds
    if x >= minimapX and x <= minimapX + self.width and
       y >= minimapY and y <= minimapY + self.height then

        -- Convert click position to grid coordinates
        local gridX = math.floor((x - minimapX) / self.minimapTileSize) + 1
        local gridY = math.floor((y - minimapY) / self.minimapTileSize) + 1

        -- Ensure coordinates are within grid bounds
        gridX = math.max(1, math.min(gridX, game.grid.width))
        gridY = math.max(1, math.min(gridY, game.grid.height))

        -- Center camera on clicked position, accounting for zoom
        local worldX = (gridX - 0.5) * game.tileSize
        local worldY = (gridY - 0.5) * game.tileSize
        game:centerCameraOn(worldX, worldY)

        -- Show a notification about the navigation
        game:showNotification(NotificationType.RESOURCE, "Navigating to position (" .. gridX .. ", " .. gridY .. ")")

        return true
    end

    return false
end

return Minimap
