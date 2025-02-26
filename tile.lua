require("types")
require("buildings")
require("resources")

-- Tile definitions
TileDefinitions = {
    types = {
        [TileType.PLAINS] = {
            name = "Plains",
            color = {0.7, 0.9, 0.4},
            bonuses = {food = 2, production = 1, gold = 0},
            maxBuildings = 2,
            allowedBuildings = {BuildingType.FARM, BuildingType.MARKET}
        },
        [TileType.FOREST] = {
            name = "Forest",
            color = {0.2, 0.5, 0.2},
            bonuses = {food = 1, production = 2, gold = 0},
            maxBuildings = 1,
            allowedBuildings = {BuildingType.MINE, BuildingType.MARKET}
        },
        [TileType.MOUNTAIN] = {
            name = "Mountain",
            color = {0.5, 0.5, 0.5},
            bonuses = {food = 0, production = 3, gold = 0},
            maxBuildings = 1,
            allowedBuildings = {BuildingType.MINE}
        },
        [TileType.WATER] = {
            name = "Water",
            color = {0.3, 0.6, 0.9},
            bonuses = {food = 2, production = 0, gold = 1},
            maxBuildings = 1,
            allowedBuildings = {BuildingType.FISHERY, BuildingType.MARKET}
        }
    }
}

-- Resource definitions
ResourceDefinitions = {
    types = {
        [ResourceType.IRON] = {
            name = "Iron",
            bonuses = {food = 0, production = 2, gold = 1},
            validTiles = {TileType.MOUNTAIN, TileType.PLAINS},
            rarity = 0.1  -- 10% chance on valid tiles
        },
        [ResourceType.GOLD_ORE] = {
            name = "Gold Ore",
            bonuses = {food = 0, production = 1, gold = 3},
            validTiles = {TileType.MOUNTAIN},
            rarity = 0.05  -- 5% chance on valid tiles
        },
        [ResourceType.HORSES] = {
            name = "Horses",
            bonuses = {food = 1, production = 1, gold = 1},
            validTiles = {TileType.PLAINS},
            rarity = 0.15  -- 15% chance on valid tiles
        },
        [ResourceType.FISH] = {
            name = "Fish",
            bonuses = {food = 3, production = 0, gold = 1},
            validTiles = {TileType.WATER},
            rarity = 0.2  -- 20% chance on valid tiles
        },
        [ResourceType.WHEAT] = {
            name = "Wheat",
            bonuses = {food = 3, production = 0, gold = 1},
            validTiles = {TileType.PLAINS},
            rarity = 0.2  -- 20% chance on valid tiles
        }
    }
}

-- Tile class
Tile = {}
Tile.__index = Tile

function Tile.new(type)
    local self = setmetatable({}, Tile)
    self.type = type
    self.buildings = {}
    self.resource = ResourceType.NONE
    return self
end

function Tile:canAddBuilding(buildingType)
    local buildings = Buildings.new()
    return buildings:canAddToTile(self, buildingType)
end

function Tile:addBuilding(buildingType)
    local buildings = Buildings.new()
    return buildings:addToTile(self, buildingType)
end

function Tile:setResource(resourceType)
    self.resource = resourceType
end

function Tile:getTotalYield()
    local tileDef = TileDefinitions.types[self.type]
    local yield = {food = tileDef.bonuses.food, production = tileDef.bonuses.production, gold = tileDef.bonuses.gold}

    -- Add resource bonuses if present
    if self.resource ~= ResourceType.NONE then
        local resources = Resources.new()
        local resourceBonuses = resources:getBonuses(self.resource)
        yield.food = yield.food + resourceBonuses.food
        yield.production = yield.production + resourceBonuses.production
        yield.gold = yield.gold + resourceBonuses.gold
    end

    -- Add building bonuses
    local buildings = Buildings.new()
    local buildingBonuses = buildings:getBonuses(self)
    yield.food = yield.food + buildingBonuses.food
    yield.production = yield.production + buildingBonuses.production
    yield.gold = yield.gold + buildingBonuses.gold

    return yield
end
