local love = require("love")

-- camera.lua - Handles camera movement and viewport calculations

Camera = {}
Camera.__index = Camera

function Camera.new(gridWidth, gridHeight, tileSize)
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.speed = 500  -- pixels per second
    self.gridWidth = gridWidth
    self.gridHeight = gridHeight
    self.tileSize = tileSize
    self.zoomLevel = 1.0  -- Default zoom level (1.0 = 100%)
    self.minZoom = 0.5    -- Minimum zoom level (50%)
    self.maxZoom = 2.0    -- Maximum zoom level (200%)
    self.zoomSpeed = 0.1  -- How much to zoom per mouse wheel movement
    return self
end

function Camera:update(dt)
    -- Camera movement with bounds checking
    local newX = self.x
    local newY = self.y

    if love.keyboard.isDown('left') then
        newX = newX - self.speed * dt
    end
    if love.keyboard.isDown('right') then
        newX = newX + self.speed * dt
    end
    if love.keyboard.isDown('up') then
        newY = newY - self.speed * dt
    end
    if love.keyboard.isDown('down') then
        newY = newY + self.speed * dt
    end

    -- Calculate effective grid size with zoom
    local effectiveGridWidth = self.gridWidth * self.tileSize * self.zoomLevel
    local effectiveGridHeight = self.gridHeight * self.tileSize * self.zoomLevel

    -- Clamp camera position to grid boundaries
    self.x = math.max(0, math.min(newX, effectiveGridWidth - love.graphics.getWidth()))
    self.y = math.max(0, math.min(newY, effectiveGridHeight - love.graphics.getHeight()))
end

function Camera:zoom(amount)
    -- Calculate new zoom level
    local newZoom = self.zoomLevel + amount * self.zoomSpeed

    -- Clamp zoom level to min/max values
    newZoom = math.max(self.minZoom, math.min(newZoom, self.maxZoom))

    -- Get mouse position for zoom centering
    local mx, my = love.mouse.getPosition()

    -- Calculate world position of mouse before zoom
    local worldX = mx + self.x
    local worldY = my + self.y

    -- Calculate grid position (stays constant during zoom)
    local gridX = worldX / (self.tileSize * self.zoomLevel)
    local gridY = worldY / (self.tileSize * self.zoomLevel)

    -- Apply new zoom level
    self.zoomLevel = newZoom

    -- Calculate new world position after zoom
    local newWorldX = gridX * (self.tileSize * self.zoomLevel)
    local newWorldY = gridY * (self.tileSize * self.zoomLevel)

    -- Adjust camera position to keep mouse position fixed on same grid cell
    self.x = self.x + (newWorldX - worldX)
    self.y = self.y + (newWorldY - worldY)

    -- Ensure camera stays within bounds after zooming
    local effectiveGridWidth = self.gridWidth * self.tileSize * self.zoomLevel
    local effectiveGridHeight = self.gridHeight * self.tileSize * self.zoomLevel

    self.x = math.max(0, math.min(self.x, effectiveGridWidth - love.graphics.getWidth()))
    self.y = math.max(0, math.min(self.y, effectiveGridHeight - love.graphics.getHeight()))
end

function Camera:getEffectiveTileSize()
    return self.tileSize * self.zoomLevel
end

function Camera:isOnScreen(x, y, width, height)
    return  x + width > self.x and
            x < self.x + love.graphics.getWidth() and
            y + height > self.y and
            y < self.y + love.graphics.getHeight()
end

function Camera:worldToGrid(x, y, tileSize)
    -- Convert screen coordinates to world coordinates
    -- Note: x and y are already in world coordinates if they include camera.x and camera.y
    local effectiveTileSize = tileSize * self.zoomLevel
    local gridX = math.floor(x / effectiveTileSize) + 1
    local gridY = math.floor(y / effectiveTileSize) + 1
    return gridX, gridY
end

return Camera
