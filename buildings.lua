-- buildings.lua - Building definitions and rendering
require("types")
local love = require("love")

-- Building type enum
BuildingType = {
    FARM = "farm",
    MINE = "mine",
    MARKET = "market",
    FISHERY = "fishery"
}

-- Buildings class
Buildings = {}
Buildings.__index = Buildings

function Buildings.new()
    local self = setmetatable({}, Buildings)
    return self
end

-- Building definitions
Buildings.definitions = {
    [BuildingType.FARM] = {
        name = "Farm",
        bonuses = {food = 2, production = 0, gold = 0},
        description = "Increases food production on plains and grasslands."
    },
    [BuildingType.MINE] = {
        name = "Mine",
        bonuses = {food = 0, production = 2, gold = 0},
        description = "Extracts production from hills and mountains."
    },
    [BuildingType.MARKET] = {
        name = "Market",
        bonuses = {food = 0, production = 0, gold = 2},
        description = "Generates gold from trade."
    },
    [BuildingType.FISHERY] = {
        name = "Fishery",
        bonuses = {food = 2, production = 0, gold = 1},
        description = "Harvests food from water tiles."
    }
}

-- Check if a building can be added to a tile
function Buildings:canAddToTile(tile, buildingType)
    local tileDef = TileDefinitions.types[tile.type]

    -- Check if we've reached the maximum number of buildings
    if #tile.buildings >= tileDef.maxBuildings then return false end

    -- Check if the building type is allowed on this tile
    local isAllowed = false
    for _, allowed in ipairs(tileDef.allowedBuildings) do
        if allowed == buildingType then
            isAllowed = true
            break
        end
    end
    if not isAllowed then return false end

    -- Check if we already have this building type
    for _, existing in ipairs(tile.buildings) do
        if existing == buildingType then
            return false -- Already have this building type
        end
    end

    return true
end

-- Add a building to a tile
function Buildings:addToTile(tile, buildingType)
    -- If no specific building type is provided, try to add the first allowed building
    if not buildingType then
        local tileDef = TileDefinitions.types[tile.type]
        for _, allowedBuildingType in ipairs(tileDef.allowedBuildings) do
            if self:addToTile(tile, allowedBuildingType) then
                return true
            end
        end
        return false
    end

    -- If a specific building type is provided, check if it can be added
    if self:canAddToTile(tile, buildingType) then
        table.insert(tile.buildings, buildingType)
        return true
    end
    return false
end

-- Get building bonuses for a tile
function Buildings:getBonuses(tile)
    local bonuses = {food = 0, production = 0, gold = 0}

    for _, buildingType in ipairs(tile.buildings) do
        local buildingDef = self.definitions[buildingType]
        bonuses.food = bonuses.food + buildingDef.bonuses.food
        bonuses.production = bonuses.production + buildingDef.bonuses.production
        bonuses.gold = bonuses.gold + buildingDef.bonuses.gold
    end

    return bonuses
end

-- Render buildings on a tile
function Buildings:render(tile, screenX, screenY, tileSize, opacity)
    -- Default opacity to 1 if not provided
    opacity = opacity or 1

    local indicatorSize = tileSize / 4
    local padding = tileSize / 20

    for i, buildingType in ipairs(tile.buildings) do
        -- Position indicators in different corners based on index
        local posX, posY
        if i == 1 then
            -- Top-left
            posX = screenX + padding
            posY = screenY + padding
        elseif i == 2 then
            -- Top-right
            posX = screenX + tileSize - indicatorSize - padding
            posY = screenY + padding
        elseif i == 3 then
            -- Bottom-left
            posX = screenX + padding
            posY = screenY + tileSize - indicatorSize - padding
        else
            -- Bottom-right
            posX = screenX + tileSize - indicatorSize - padding
            posY = screenY + tileSize - indicatorSize - padding
        end

        -- Draw different shapes based on building type
        if buildingType == BuildingType.FARM then
            -- Farm: green triangle (field)
            love.graphics.setColor(0.2, 0.8, 0.2, 0.9 * opacity)
            love.graphics.polygon("fill",
                posX + indicatorSize/2, posY,
                posX, posY + indicatorSize,
                posX + indicatorSize, posY + indicatorSize
            )
            -- Draw outline
            love.graphics.setColor(0, 0, 0, 0.7 * opacity)
            love.graphics.polygon("line",
                posX + indicatorSize/2, posY,
                posX, posY + indicatorSize,
                posX + indicatorSize, posY + indicatorSize
            )
        elseif buildingType == BuildingType.MINE then
            -- Mine: brown square with pickaxe
            love.graphics.setColor(0.6, 0.4, 0.2, 0.9 * opacity)
            love.graphics.rectangle("fill", posX, posY, indicatorSize, indicatorSize)
            -- Draw outline
            love.graphics.setColor(0, 0, 0, 0.7 * opacity)
            love.graphics.rectangle("line", posX, posY, indicatorSize, indicatorSize)
            -- Draw pickaxe
            love.graphics.setColor(0.7, 0.7, 0.7, 0.9 * opacity)
            love.graphics.line(
                posX + indicatorSize * 0.2, posY + indicatorSize * 0.2,
                posX + indicatorSize * 0.8, posY + indicatorSize * 0.8
            )
            love.graphics.line(
                posX + indicatorSize * 0.8, posY + indicatorSize * 0.8,
                posX + indicatorSize * 0.6, posY + indicatorSize * 0.9
            )
        elseif buildingType == BuildingType.MARKET then
            -- Market: gold circle (coin)
            love.graphics.setColor(1, 0.8, 0.2, 0.9 * opacity)
            love.graphics.circle("fill", posX + indicatorSize/2, posY + indicatorSize/2, indicatorSize/2)
            -- Draw outline
            love.graphics.setColor(0, 0, 0, 0.7 * opacity)
            love.graphics.circle("line", posX + indicatorSize/2, posY + indicatorSize/2, indicatorSize/2)
        elseif buildingType == BuildingType.FISHERY then
            -- Fishery: blue wave pattern
            love.graphics.setColor(0.2, 0.6, 0.9, 0.9 * opacity)
            -- Draw waves
            for j = 1, 3 do
                local y = posY + (j * indicatorSize / 4)
                love.graphics.line(
                    posX, y,
                    posX + indicatorSize * 0.3, y - indicatorSize * 0.1,
                    posX + indicatorSize * 0.7, y + indicatorSize * 0.1,
                    posX + indicatorSize, y
                )
            end
            -- Draw outline
            love.graphics.setColor(0, 0, 0, 0.7 * opacity)
            love.graphics.rectangle("line", posX, posY, indicatorSize, indicatorSize)
        end
    end
end

-- Get formatted yield string for a building
function Buildings:getYieldString(buildingType)
    local bonuses = self.definitions[buildingType].bonuses
    local yieldStr = ""

    if bonuses.food > 0 then
        yieldStr = yieldStr .. "+" .. bonuses.food .. " Food "
    end
    if bonuses.production > 0 then
        yieldStr = yieldStr .. "+" .. bonuses.production .. " Prod "
    end
    if bonuses.gold > 0 then
        yieldStr = yieldStr .. "+" .. bonuses.gold .. " Gold"
    end

    -- If there are no bonuses, show "No yield"
    if yieldStr == "" then
        yieldStr = "No yield"
    end

    return yieldStr
end

return Buildings
