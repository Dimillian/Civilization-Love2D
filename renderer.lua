require("camera")
require("tile")
require("buildings")
require("resources")
local love = require("love")

-- renderer.lua - Handles rendering of game elements

Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
    local self = setmetatable({}, Renderer)
    return self
end

function Renderer:drawGrid(grid, camera, tileSize, player)
    -- Single pass through the grid
    for y = 1, grid.height do
        for x = 1, grid.width do
            local screenX = (x-1) * tileSize
            local screenY = (y-1) * tileSize

            -- Only draw tiles that are visible on screen
            if camera:isOnScreen(screenX, screenY, tileSize, tileSize) then
                local tile = grid.tiles[y][x]

                -- Draw the tile based on discovery status
                if player:isTileDiscovered(x, y) then
                    -- Draw discovered tile with full details
                    local tileDef = TileDefinitions.types[tile.type]

                    -- Draw base tile
                    love.graphics.setColor(tileDef.color)
                    love.graphics.rectangle("fill", screenX, screenY, tileSize, tileSize)
                    love.graphics.setColor(0, 0, 0, 0.3)
                    love.graphics.rectangle("line", screenX, screenY, tileSize, tileSize)

                    -- Draw resource indicator if present
                    if tile.resource ~= ResourceType.NONE then
                        local resources = Resources.new()
                        resources:render(tile.resource, screenX, screenY, tileSize)
                    end

                    -- Draw building indicators
                    if #tile.buildings > 0 then
                        local buildings = Buildings.new()
                        buildings:render(tile, screenX, screenY, tileSize)
                    end
                else
                    -- Draw undiscovered tile (fog of war)
                    love.graphics.setColor(0.1, 0.1, 0.1)  -- Dark gray for undiscovered
                    love.graphics.rectangle("fill", screenX, screenY, tileSize, tileSize)
                    love.graphics.setColor(0, 0, 0, 0.5)
                    love.graphics.rectangle("line", screenX, screenY, tileSize, tileSize)
                end
            end
        end
    end
end

function Renderer:drawTooltip(tile, x, y, player, gridX, gridY)
    -- We already checked if the tile is discovered in main.lua, so we don't need to check again
    if not tile then return end

    local tileDef = TileDefinitions.types[tile.type]
    local totalYield = tile:getTotalYield()

    -- Get base tile yields
    local baseYield = {
        food = tileDef.bonuses.food,
        production = tileDef.bonuses.production,
        gold = tileDef.bonuses.gold
    }

    -- Get resource yields
    local resourceYield = {food = 0, production = 0, gold = 0}
    if tile.resource ~= ResourceType.NONE then
        local resources = Resources.new()
        resourceYield = resources:getBonuses(tile.resource)
    end

    -- Get building yields
    local buildingYield = {food = 0, production = 0, gold = 0}
    if #tile.buildings > 0 then
        local buildings = Buildings.new()
        buildingYield = buildings:getBonuses(tile)
    end

    -- Check if the tile is in a settlement
    local inSettlement, settlement = player:isTileInSettlement(gridX, gridY)
    local tooltipHeight = inSettlement and 160 or 140

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x + 10, y + 10, 180, tooltipHeight)
    love.graphics.setColor(1, 1, 1)

    local buildingNames = ""
    local buildings = Buildings.new()
    for i, building in ipairs(tile.buildings) do
        buildingNames = buildingNames .. (i > 1 and ", " or "") .. buildings.definitions[building].name
    end

    local resourceName = "None"
    if tile.resource ~= ResourceType.NONE then
        local resources = Resources.new()
        resourceName = resources.definitions[tile.resource].name
    end

    -- Format yields to show base + bonus
    local foodText = string.format("Food: %d (%d+%d+%d)",
        totalYield.food, baseYield.food, resourceYield.food, buildingYield.food)
    local prodText = string.format("Prod: %d (%d+%d+%d)",
        totalYield.production, baseYield.production, resourceYield.production, buildingYield.production)
    local goldText = string.format("Gold: %d (%d+%d+%d)",
        totalYield.gold, baseYield.gold, resourceYield.gold, buildingYield.gold)

    local tooltipText = string.format("Type: %s\nResource: %s\n%s\n%s\n%s\nBuildings: %s",
        tileDef.name,
        resourceName,
        foodText,
        prodText,
        goldText,
        buildingNames ~= "" and buildingNames or "None"
    )

    -- Add settlement information if applicable
    if inSettlement then
        tooltipText = tooltipText .. ("\nSettlement: %s"):format(settlement.name)
        tooltipText = tooltipText .. "\n(All tiles in settlements contribute to yields)"
    end

    -- Add yield explanation
    tooltipText = tooltipText .. "\n(Base+Resource+Building)"

    love.graphics.print(tooltipText, x + 15, y + 15)
end

return Renderer
