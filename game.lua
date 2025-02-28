local love = require("love")

-- game.lua - Main game state and initialization

Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.tileSize = 30
    self.gridWidth = 300
    self.gridHeight = 300
    self.turn = 1  -- Initialize turn counter

    -- Initialize components
    self.grid = Grid.new(self.gridWidth, self.gridHeight, self.tileSize)
    self.camera = Camera.new(self.gridWidth, self.gridHeight, self.tileSize)
    self.ui = {
        tileMenu = TileMenu.new()
    }

    -- Initialize player
    self.player = Player.new(self.grid)

    -- Initialize minimap
    self.minimap = Minimap.new(self.grid, self.tileSize)

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

    -- Calculate effective grid size with zoom
    local effectiveGridWidth = self.gridWidth * self.tileSize * self.camera.zoomLevel
    local effectiveGridHeight = self.gridHeight * self.tileSize * self.camera.zoomLevel

    -- Clamp camera position to grid boundaries
    self.camera.x = math.max(0, math.min(self.camera.x, effectiveGridWidth - screenWidth))
    self.camera.y = math.max(0, math.min(self.camera.y, effectiveGridHeight - screenHeight))
end

-- Increment the turn counter and handle turn-based updates
function Game:nextTurn()
    self.turn = self.turn + 1

    -- Show turn notification
    self:showNotification(NotificationType.TURN, "Turn " .. self.turn)

    -- Update player for the new turn
    self.player:onTurnEnd()
end

-- Helper function to show different types of game notifications
function Game:showNotification(notificationType, text, additionalOptions)
    local options = additionalOptions or {}

    -- Set default options based on notification type
    if notificationType == NotificationType.TURN then
        options.color = options.color or {0.7, 0.7, 1.0}  -- Light blue for turn notifications
        options.position = options.position or NotificationPosition.TOP
    elseif notificationType == NotificationType.RESOURCE then
        options.color = options.color or {0.2, 0.8, 0.2}  -- Green for resource notifications
        options.position = options.position or NotificationPosition.MIDDLE
    elseif notificationType == NotificationType.WARNING then
        options.color = options.color or {0.8, 0.2, 0.2}  -- Red for warnings
        options.position = options.position or NotificationPosition.TOP
    elseif notificationType == NotificationType.ACHIEVEMENT then
        options.color = options.color or {1.0, 0.8, 0.2}  -- Gold for achievements
        options.position = options.position or NotificationPosition.BOTTOM
        options.duration = options.duration or 3.0  -- Longer duration for achievements
    end

    -- Show the notification using the global notification system
    return notificationSystem:show(text, options)
end

return Game
