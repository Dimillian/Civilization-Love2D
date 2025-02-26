-- types.lua - Shared type definitions for the game

-- Tile type enum
TileType = {
    PLAINS = "plains",
    FOREST = "forest",
    MOUNTAIN = "mountain",
    WATER = "water"
}

-- Building type enum
BuildingType = {
    FARM = "farm",
    MINE = "mine",
    MARKET = "market",
    FISHERY = "fishery"
}

-- Resource type enum
ResourceType = {
    NONE = "none",
    IRON = "iron",
    GOLD_ORE = "gold_ore",
    HORSES = "horses",
    FISH = "fish",
    WHEAT = "wheat"
}

return {
    TileType = TileType,
    BuildingType = BuildingType,
    ResourceType = ResourceType
}
