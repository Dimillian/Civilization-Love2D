local love = require("love")

-- tilemenu.lua - Handles the tile interaction menu system

-- Menu level enum
MenuLevel = {
    MAIN = "main",
    BUILD = "build"
}

-- TileMenu class
TileMenu = {}
TileMenu.__index = TileMenu

-- Initialize the tile menu system
function TileMenu.new()
    local self = setmetatable({}, TileMenu)
    self.visible = false
    self.options = {}
    self.x = 0
    self.y = 0
    self.width = 200
    self.optionHeight = 25
    self.currentLevel = MenuLevel.MAIN
    self.buildOptions = {}
    self.selectedTile = nil
    return self
end

-- Draw the menu
function TileMenu:draw()
    if not self.visible then
        return
    end

    local options = self.currentLevel == MenuLevel.MAIN and self.options or self.buildOptions
    local totalHeight = #options * self.optionHeight

    -- Draw menu background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, totalHeight)

    -- Draw menu border
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("line", self.x, self.y, self.width, totalHeight)

    -- Draw menu options
    for i, option in ipairs(options) do
        local y = self.y + (i-1) * self.optionHeight

        -- Highlight on hover
        if self:isMouseOverOption(i) then
            love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
            love.graphics.rectangle("fill", self.x, y, self.width, self.optionHeight)
        end

        -- Draw option text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(option.text, self.x + 10, y + 5)
    end
end

-- Check if mouse is over a menu option
function TileMenu:isMouseOverOption(optionIndex)
    if not self.visible then return false end

    local mx, my = love.mouse.getPosition()
    local options = self.currentLevel == MenuLevel.MAIN and self.options or self.buildOptions

    if optionIndex < 1 or optionIndex > #options then return false end

    local optionY = self.y + (optionIndex-1) * self.optionHeight

    return mx >= self.x and mx <= self.x + self.width and
           my >= optionY and my <= optionY + self.optionHeight
end

-- Handle mouse press on menu
function TileMenu:handleMousePress(x, y)
    if not self.visible then return false end

    local options = self.currentLevel == MenuLevel.MAIN and self.options or self.buildOptions

    for i, option in ipairs(options) do
        if self:isMouseOverOption(i) then
            option.action()
            return true
        end
    end

    -- If click is outside menu, hide it
    self.visible = false
    return true
end

-- Handle escape key
function TileMenu:handleEscape()
    if not self.visible then return false end

    if self.currentLevel == MenuLevel.BUILD then
        -- Go back to main menu
        self.currentLevel = MenuLevel.MAIN
    else
        -- Hide menu
        self.visible = false
    end

    return true
end

-- Show menu for a tile
function TileMenu:showForTile(tile, x, y)
    -- The discovery check is now handled in main.lua before calling this function

    self.selectedTile = tile
    self.x = x
    self.y = y
    self.visible = true
    self.currentLevel = MenuLevel.MAIN

    -- Create main menu options
    self.options = {}

    -- Get the grid coordinates of the selected tile
    local gridX, gridY = game.camera:worldToGrid(x + game.camera.x, y + game.camera.y, game.tileSize)

    -- Check if the tile is within a settlement
    local inSettlement, settlement = game.player:isTileInSettlement(gridX, gridY)

    if inSettlement then
        -- Inside settlement - show building options
        local tileDef = TileDefinitions.types[tile.type]
        if #tile.buildings < tileDef.maxBuildings and #tileDef.allowedBuildings > 0 then
            table.insert(self.options, {
                text = "Build",
                action = function() self:showBuildMenu() end
            })
        end
    else
        -- Outside settlement - only allow settlement creation
        -- Check if the tile is suitable for a settlement (not water)
        if tile.type ~= TileType.WATER then
            table.insert(self.options, {
                text = "Found Settlement",
                action = function()
                    if game.player:createSettlement(gridX, gridY) then
                        self.visible = false
                    end
                end
            })
        end
    end

    -- Add "Close" option
    table.insert(self.options, {
        text = "Close",
        action = function() self.visible = false end
    })

    -- Create build menu options
    self:createBuildOptions()
end

-- Show build submenu
function TileMenu:showBuildMenu()
    self.currentLevel = MenuLevel.BUILD
end

-- Create build options
function TileMenu:createBuildOptions()
    self.buildOptions = {}

    local tile = self.selectedTile
    if not tile then return end

    local tileDef = TileDefinitions.types[tile.type]

    -- Add building options
    for _, buildingType in ipairs(tileDef.allowedBuildings) do
        local buildings = Buildings.new()
        if buildings:canAddToTile(tile, buildingType) then
            local buildingDef = buildings.definitions[buildingType]
            local yieldStr = buildings:getYieldString(buildingType)

            table.insert(self.buildOptions, {
                text = buildingDef.name .. " (" .. yieldStr .. ")",
                action = function()
                    buildings:addToTile(tile, buildingType)
                    -- Update player yields after adding a building
                    game.player:updateYields(game.grid)
                    self.visible = false
                end
            })
        end
    end

    -- Add "Back" option
    table.insert(self.buildOptions, {
        text = "Back",
        action = function() self.currentLevel = MenuLevel.MAIN end
    })
end

return TileMenu
