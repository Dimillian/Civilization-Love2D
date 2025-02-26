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

    -- Clamp camera position to grid boundaries
    self.x = math.max(0, math.min(newX, self.gridWidth * self.tileSize - love.graphics.getWidth()))
    self.y = math.max(0, math.min(newY, self.gridHeight * self.tileSize - love.graphics.getHeight()))
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
    local gridX = math.floor(x / tileSize) + 1
    local gridY = math.floor(y / tileSize) + 1
    return gridX, gridY
end

return Camera
