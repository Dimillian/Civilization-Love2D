-- Import modules
require("types")
require("tile")
require("grid")
require("tilemenu")
require("camera")
require("renderer")
require("game")
require("buildings")
require("resources")
require("player")
require("settlement")
require("notification")
require("minimap")
local love = require("love")

-- LÖVE callbacks
function love.load()
    love.window.setTitle("Civilization Grid Prototype")
    love.window.setMode(800, 600, {
        resizable = true,    -- Allow window resizing
        minwidth = 400,      -- Minimum window width
        minheight = 300      -- Minimum window height
    })

    -- Initialize notification system
    notificationSystem = Notification.new()

    game = Game.new()

    -- Show a welcome notification
    game:showNotification(NotificationType.ACHIEVEMENT, "Welcome to Civilization Grid Prototype!")

    -- Test notifications with different text lengths (for debugging)
    -- testNotifications()
end

function love.update(dt)
    game.camera:update(dt)

    -- Update player animation
    game.player:update(dt, game.grid)

    -- Update notifications
    notificationSystem:update(dt)
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(-game.camera.x, -game.camera.y)

    local renderer = Renderer.new()
    renderer:drawGrid(game.grid, game.camera, game.tileSize, game.player)

    -- Draw player settlements
    game.player:drawSettlements(game.tileSize, game.grid)

    -- Draw player on map
    game.player:drawOnMap(game.tileSize)

    love.graphics.pop()

    -- Only show tooltip if menu is not visible
    if not game.ui.tileMenu.visible then
        local mx, my = love.mouse.getPosition()
        local tile = game:getTileAtMouse(mx, my)
        if tile then
            -- Get the grid coordinates
            local gridX, gridY = game.camera:worldToGrid(mx + game.camera.x, my + game.camera.y, game.tileSize)

            if game.player:isTileDiscovered(gridX, gridY) then
                renderer:drawTooltip(tile, mx, my, game.player, gridX, gridY)
            end
        end
    end

    game.ui.tileMenu:draw()

    -- Draw player UI (should be drawn last to appear on top)
    game.player:draw()

    -- Draw minimap
    game.minimap:draw(game.player, game.camera)

    -- Draw notifications
    notificationSystem:draw()
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
        -- Check if the click was handled by the minimap
        if game.minimap:handleMousePress(x, y, game) then
            return
        end

        -- Check if the click was handled by the player UI (End Turn button)
        if game.player:handleMousePress(x, y) then
            return
        end

        -- Check if the click was handled by the tile menu
        if game.ui.tileMenu:handleMousePress(x, y) then
            return
        end

        -- Otherwise, show the menu for the clicked tile
        local tile = game:getTileAtMouse(x, y)
        if tile then
            local gridX, gridY = game.camera:worldToGrid(x + game.camera.x, y + game.camera.y, game.tileSize)
            if game.player:isTileDiscovered(gridX, gridY) then
                game.ui.tileMenu:showForTile(tile, x, y)
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        -- Check if the key was handled by the tile menu
        if game.ui.tileMenu:handleEscape() then
            return
        end

        -- Otherwise, quit the game
        love.event.quit()
    elseif key == "t" then
        -- Test notifications when pressing T
        testNotifications()
    elseif key == "m" then
        -- Toggle minimap visibility when pressing M
        game.minimap.visible = not game.minimap.visible

        -- Show notification about minimap toggle
        if game.minimap.visible then
            game:showNotification(NotificationType.RESOURCE, "Minimap enabled")
        else
            game:showNotification(NotificationType.RESOURCE, "Minimap disabled")
        end
    end

    -- Player movement with WASD keys
    local playerMoved = false

    if key == "z" then -- Move up
        playerMoved = game.player:moveTo(game.player.gridX, game.player.gridY - 1, game.grid)
    elseif key == "s" then -- Move down
        playerMoved = game.player:moveTo(game.player.gridX, game.player.gridY + 1, game.grid)
    elseif key == "q" then -- Move left
        playerMoved = game.player:moveTo(game.player.gridX - 1, game.player.gridY, game.grid)
    elseif key == "d" then -- Move right
        playerMoved = game.player:moveTo(game.player.gridX + 1, game.player.gridY, game.grid)
    end

    -- Camera centering is now handled in the player's update function
end

-- Add window resize callback
function love.resize(w, h)
    -- You can add any additional resize logic here if needed
    -- For example, adjusting UI elements or camera bounds
end

-- Add mouse wheel callback for zooming
function love.wheelmoved(x, y)
    if y ~= 0 then
        game.camera:zoom(y)
    end
end

-- Function to test notifications with different text lengths
function testNotifications()
    -- Short text
    game:showNotification(NotificationType.TURN, "Turn 1")

    -- Medium text
    game:showNotification(NotificationType.RESOURCE, "Found gold near your settlement!")

    -- Long text
    game:showNotification(NotificationType.WARNING, "Enemy units approaching from the north! Prepare your defenses immediately.")
end
