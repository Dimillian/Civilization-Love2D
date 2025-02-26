local love = require("love")

-- game.lua - Main game state and initialization

Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.tileSize = 30
    self.gridWidth = 300
    self.gridHeight = 300

    -- Initialize components
    self.grid = Grid.new(self.gridWidth, self.gridHeight, self.tileSize)
    self.camera = Camera.new(self.gridWidth, self.gridHeight, self.tileSize)
    self.ui = {
        tileMenu = TileMenu.new()
    }

    -- Initialize player
    self.player = Player.new(self.grid)

    -- Set camera to player position
    if self.player.gridX and self.player.gridY then
        local centerX = (self.player.gridX - 1) * self.tileSize
        local centerY = (self.player.gridY - 1) * self.tileSize
        self:centerCameraOn(centerX, centerY)
    end

    return self
end

function Game:getTileAtMouse(x, y)
    -- Convert screen coordinates to grid coordinates
    local gridX, gridY = self.camera:worldToGrid(x + self.camera.x, y + self.camera.y, self.tileSize)
    return self.grid:getTileAt(gridX, gridY)
end

function Game:centerCameraOn(x, y)
    -- Center the camera on the given world coordinates
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    self.camera.x = x - screenWidth / 2
    self.camera.y = y - screenHeight / 2

    -- Clamp camera position to grid boundaries
    self.camera.x = math.max(0, math.min(self.camera.x, self.gridWidth * self.tileSize - screenWidth))
    self.camera.y = math.max(0, math.min(self.camera.y, self.gridHeight * self.tileSize - screenHeight))
end

return Game
