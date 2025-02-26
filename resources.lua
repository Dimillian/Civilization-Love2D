-- resources.lua - Resource definitions and rendering
require("types")
local love = require("love")

-- Resource type enum
ResourceType = {
    NONE = "none",
    IRON = "iron",
    GOLD_ORE = "gold_ore",
    HORSES = "horses",
    FISH = "fish",
    WHEAT = "wheat"
}

-- Resources class
Resources = {}
Resources.__index = Resources

function Resources.new()
    local self = setmetatable({}, Resources)
    return self
end

-- Resource definitions
Resources.definitions = {
    [ResourceType.IRON] = {
        name = "Iron",
        bonuses = {food = 0, production = 2, gold = 1},
        validTiles = {TileType.MOUNTAIN, TileType.PLAINS},
        rarity = 0.1,  -- 10% chance on valid tiles
        description = "Used for tools and weapons."
    },
    [ResourceType.GOLD_ORE] = {
        name = "Gold Ore",
        bonuses = {food = 0, production = 1, gold = 3},
        validTiles = {TileType.MOUNTAIN},
        rarity = 0.05,  -- 5% chance on valid tiles
        description = "Highly valuable precious metal."
    },
    [ResourceType.HORSES] = {
        name = "Horses",
        bonuses = {food = 1, production = 1, gold = 1},
        validTiles = {TileType.PLAINS},
        rarity = 0.15,  -- 15% chance on valid tiles
        description = "Enables cavalry units and improves mobility."
    },
    [ResourceType.FISH] = {
        name = "Fish",
        bonuses = {food = 3, production = 0, gold = 1},
        validTiles = {TileType.WATER},
        rarity = 0.2,  -- 20% chance on valid tiles
        description = "Abundant source of food from the sea."
    },
    [ResourceType.WHEAT] = {
        name = "Wheat",
        bonuses = {food = 3, production = 0, gold = 1},
        validTiles = {TileType.PLAINS},
        rarity = 0.2,  -- 20% chance on valid tiles
        description = "Staple crop for growing populations."
    }
}

-- Check if a resource can be placed on a tile
function Resources:canPlaceOnTile(resourceType, tileType)
    local resourceDef = self.definitions[resourceType]
    if not resourceDef then return false end

    for _, validTile in ipairs(resourceDef.validTiles) do
        if validTile == tileType then
            return true
        end
    end

    return false
end

-- Get resource bonuses
function Resources:getBonuses(resourceType)
    if resourceType == ResourceType.NONE then
        return {food = 0, production = 0, gold = 0}
    end

    local resourceDef = self.definitions[resourceType]
    return resourceDef.bonuses
end

-- Render a resource on a tile
function Resources:render(resourceType, x, y, tileSize)
    if resourceType == ResourceType.NONE then return end

    -- Center of the tile
    local centerX = x + tileSize / 2
    local centerY = y + tileSize / 2
    local size = tileSize / 5

    -- Draw resource indicator based on type
    if resourceType == ResourceType.IRON then
        -- Iron: Gray hexagon
        love.graphics.setColor(0.6, 0.6, 0.6, 0.9)
        self:drawHexagon(centerX, centerY, size)
    elseif resourceType == ResourceType.GOLD_ORE then
        -- Gold: Yellow star
        love.graphics.setColor(1, 0.9, 0.2, 0.9)
        self:drawStar(centerX, centerY, size)
    elseif resourceType == ResourceType.HORSES then
        -- Horses: Brown horseshoe
        love.graphics.setColor(0.6, 0.4, 0.2, 0.9)
        self:drawHorseshoe(centerX, centerY, size)
    elseif resourceType == ResourceType.FISH then
        -- Fish: Blue fish shape
        love.graphics.setColor(0.2, 0.5, 0.9, 0.9)
        self:drawFish(centerX, centerY, size)
    elseif resourceType == ResourceType.WHEAT then
        -- Wheat: Yellow/brown wheat shape
        love.graphics.setColor(0.9, 0.8, 0.3, 0.9)
        self:drawWheat(centerX, centerY, size)
    end
end

-- Helper function to draw a hexagon
function Resources:drawHexagon(x, y, size)
    local vertices = {}
    for i = 0, 5 do
        local angle = (i * math.pi / 3) - math.pi / 6
        table.insert(vertices, x + size * math.cos(angle))
        table.insert(vertices, y + size * math.sin(angle))
    end
    love.graphics.polygon("fill", vertices)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.polygon("line", vertices)
end

-- Helper function to draw a star
function Resources:drawStar(x, y, size)
    local vertices = {}

    for i = 0, 4 do
        local outerAngle = (i * 2 * math.pi / 5) - math.pi / 2
        local innerAngle = outerAngle + math.pi / 5

        -- Outer point
        table.insert(vertices, x + size * math.cos(outerAngle))
        table.insert(vertices, y + size * math.sin(outerAngle))

        -- Inner point
        table.insert(vertices, x + (size/2) * math.cos(innerAngle))
        table.insert(vertices, y + (size/2) * math.sin(innerAngle))
    end

    love.graphics.polygon("fill", vertices)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.polygon("line", vertices)
end

-- Helper function to draw a horseshoe
function Resources:drawHorseshoe(x, y, size)
    -- Simple horseshoe representation
    love.graphics.setLineWidth(size/3)
    love.graphics.arc("line", x, y, size, math.pi, 0)
    love.graphics.line(x - size, y, x - size, y + size/2)
    love.graphics.line(x + size, y, x + size, y + size/2)
    love.graphics.setLineWidth(1)
end

-- Helper function to draw a fish
function Resources:drawFish(x, y, size)
    -- Simple fish shape
    local vertices = {
        x - size, y,
        x - size/2, y - size/2,
        x + size/2, y - size/2,
        x + size, y,
        x + size/2, y + size/2,
        x - size/2, y + size/2
    }
    love.graphics.polygon("fill", vertices)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.polygon("line", vertices)

    -- Eye
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("fill", x + size/4, y - size/6, size/6)
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.circle("fill", x + size/4, y - size/6, size/10)
end

-- Helper function to draw wheat
function Resources:drawWheat(x, y, size)
    -- Simple wheat representation
    love.graphics.setLineWidth(size/6)

    -- Stem
    love.graphics.line(x, y, x, y + size)

    -- Grains
    local grainLength = size * 0.4
    local grainSpacing = size * 0.2

    for i = 0, 2 do
        local yPos = y + i * grainSpacing
        -- Right side grains
        love.graphics.line(x, yPos, x + grainLength, yPos - grainLength/2)
        -- Left side grains
        love.graphics.line(x, yPos, x - grainLength, yPos - grainLength/2)
    end

    love.graphics.setLineWidth(1)
end

-- Get formatted yield string for a resource
function Resources:getYieldString(resourceType)
    if resourceType == ResourceType.NONE then
        return "No yield"
    end

    local bonuses = self.definitions[resourceType].bonuses
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

return Resources
