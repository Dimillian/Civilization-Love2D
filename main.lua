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
local love = require("love")

-- LÖVE callbacks
function love.load()
    love.window.setTitle("Civilization Grid Prototype")
    love.window.setMode(800, 600, {
        resizable = true,    -- Allow window resizing
        minwidth = 400,      -- Minimum window width
        minheight = 300      -- Minimum window height
    })

    game = Game.new()
end

function love.update(dt)
    game.camera:update(dt)

    -- Update player yields
    game.player:updateYields(game.grid)
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
end

function love.mousepressed(x, y, button)
    if button == 1 then -- Left mouse button
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

    -- Center camera on player if they moved
    if playerMoved then
        local centerX = (game.player.gridX - 1) * game.tileSize
        local centerY = (game.player.gridY - 1) * game.tileSize
        game:centerCameraOn(centerX, centerY)
    end
end

-- Add window resize callback
function love.resize(w, h)
    -- You can add any additional resize logic here if needed
    -- For example, adjusting UI elements or camera bounds
end
