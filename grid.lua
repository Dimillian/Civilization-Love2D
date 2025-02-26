-- Grid class
Grid = {}
Grid.__index = Grid

function Grid.new(width, height, tileSize)
    local self = setmetatable({}, Grid)
    self.width = width
    self.height = height
    self.tileSize = tileSize
    self.tiles = {}
    self:initialize()
    return self
end

function Grid:initialize()
    math.randomseed(os.time())

    -- Create a heightmap for more natural terrain generation
    local heightMap = self:generateHeightMap()

    -- Create tiles based on the heightmap
    for y = 1, self.height do
        self.tiles[y] = {}
        for x = 1, self.width do
            local height = heightMap[y][x]
            local tileType

            -- Determine tile type based on height
            if height < 0.3 then
                tileType = TileType.WATER -- Deep water (oceans, lakes)
            elseif height < 0.35 then
                tileType = TileType.WATER -- Shallow water (shores, rivers)
            elseif height < 0.5 then
                tileType = TileType.PLAINS -- Plains (low elevation)
            elseif height < 0.7 then
                tileType = TileType.FOREST -- Forests (medium elevation)
            else
                tileType = TileType.MOUNTAIN -- Mountains (high elevation)
            end

            -- Create the tile
            local tile = Tile.new(tileType)

            -- Add resources based on tile type
            self:addResourcesToTile(tile)

            self.tiles[y][x] = tile
        end
    end

    -- Generate rivers
    self:generateRivers(heightMap, 5) -- Generate 5 rivers
end

-- Generate a heightmap using simplex noise for natural-looking terrain
function Grid:generateHeightMap()
    local heightMap = {}
    local scale = 0.1 -- Controls the scale of the terrain features
    local persistence = 0.5 -- Controls how much detail is added at each octave
    local octaves = 4 -- Number of layers of noise

    -- Initialize the heightmap
    for y = 1, self.height do
        heightMap[y] = {}
        for x = 1, self.width do
            heightMap[y][x] = 0
        end
    end

    -- Generate multiple octaves of noise
    for octave = 1, octaves do
        local frequency = 2^(octave-1)
        local amplitude = persistence^(octave-1)

        for y = 1, self.height do
            for x = 1, self.width do
                -- Use simple noise approximation since LÖVE doesn't have built-in simplex noise
                local nx = x / self.width * frequency * scale
                local ny = y / self.height * frequency * scale
                local noise = self:noise2D(nx, ny)

                heightMap[y][x] = heightMap[y][x] + noise * amplitude
            end
        end
    end

    -- Normalize the heightmap to 0-1 range
    local min, max = 1, 0
    for y = 1, self.height do
        for x = 1, self.width do
            min = math.min(min, heightMap[y][x])
            max = math.max(max, heightMap[y][x])
        end
    end

    for y = 1, self.height do
        for x = 1, self.width do
            heightMap[y][x] = (heightMap[y][x] - min) / (max - min)
        end
    end

    return heightMap
end

-- Simple 2D noise function (not true simplex noise, but good enough for our purposes)
function Grid:noise2D(x, y)
    -- Use a different approach that doesn't rely on bitwise operations
    x = x * 12.9898
    y = y * 78.233
    local value = math.sin(x + y) * 43758.5453
    return value - math.floor(value)
end

-- Generate rivers flowing from high to low elevation, preferably toward oceans
function Grid:generateRivers(heightMap, count)
    -- First, identify ocean tiles (water tiles at the edges of the map)
    local oceanTiles = {}
    for y = 1, self.height do
        for x = 1, self.width do
            -- Consider water tiles near the edge as ocean
            local isEdge = x <= 5 or x >= self.width - 5 or y <= 5 or y >= self.height - 5
            if heightMap[y][x] < 0.3 and isEdge then
                table.insert(oceanTiles, {x = x, y = y})
            end
        end
    end

    for i = 1, count do
        -- Start at a random high point (mountain)
        local x, y
        local attempts = 0
        repeat
            x = math.random(1, self.width)
            y = math.random(1, self.height)
            attempts = attempts + 1
        until (heightMap[y][x] > 0.7 or attempts > 100)

        -- Trace the river path downhill
        local riverLength = math.random(20, 100) -- Longer rivers to reach oceans
        local currentX, currentY = x, y
        local riverTiles = {}
        local reachedOcean = false

        for j = 1, riverLength do
            -- Mark the current tile as part of the river
            if currentX >= 1 and currentX <= self.width and currentY >= 1 and currentY <= self.height then
                table.insert(riverTiles, {x = currentX, y = currentY})

                -- Check if we've reached an ocean
                for _, ocean in ipairs(oceanTiles) do
                    if math.abs(currentX - ocean.x) <= 1 and math.abs(currentY - ocean.y) <= 1 then
                        reachedOcean = true
                        break
                    end
                end

                if reachedOcean then
                    break
                end

                -- Find the next tile to flow to
                local nextX, nextY = self:findNextRiverTile(heightMap, currentX, currentY, oceanTiles)

                -- If we can't flow anymore, break
                if nextX == currentX and nextY == currentY then
                    -- Create a small lake at the end of the river
                    self:createLake(currentX, currentY, math.random(2, 5))
                    break
                end

                -- Move to the next tile
                currentX, currentY = nextX, nextY
            else
                break
            end
        end

        -- Now actually create the river tiles
        for _, tile in ipairs(riverTiles) do
            self.tiles[tile.y][tile.x] = Tile.new(TileType.WATER)

            -- Add fish resources to some river tiles
            if math.random() < 0.1 then
                self.tiles[tile.y][tile.x]:setResource(ResourceType.FISH)
            end
        end
    end
end

-- Find the next tile for a river to flow to, with a bias toward oceans
function Grid:findNextRiverTile(heightMap, x, y, oceanTiles)
    local lowestX, lowestY = x, y
    local lowestHeight = heightMap[y][x]
    local oceanBias = 0.05 -- Bias toward flowing to oceans

    -- Find the closest ocean tile
    local closestOcean = nil
    local closestDist = math.huge

    for _, ocean in ipairs(oceanTiles) do
        local dist = math.sqrt((x - ocean.x)^2 + (y - ocean.y)^2)
        if dist < closestDist then
            closestDist = dist
            closestOcean = ocean
        end
    end

    -- Check all neighboring tiles
    for dy = -1, 1 do
        for dx = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local nx, ny = x + dx, y + dy
                if nx >= 1 and nx <= #heightMap[1] and ny >= 1 and ny <= #heightMap then
                    local height = heightMap[ny][nx]

                    -- Apply ocean bias if we have a closest ocean
                    if closestOcean then
                        local oceanDir = {
                            x = closestOcean.x - x,
                            y = closestOcean.y - y
                        }
                        local dotProduct = dx * oceanDir.x + dy * oceanDir.y
                        local oceanInfluence = dotProduct > 0 and oceanBias or 0
                        height = height - oceanInfluence
                    end

                    if height < lowestHeight then
                        lowestHeight = height
                        lowestX, lowestY = nx, ny
                    end
                end
            end
        end
    end

    return lowestX, lowestY
end

-- Create a lake of a given radius centered at (x, y)
function Grid:createLake(x, y, radius)
    -- Increase the base lake size
    radius = radius + 2 -- Make all lakes bigger by default

    -- Check if we're near the edge of the map - if so, make an even larger lake
    local isNearEdge = x <= 10 or x >= self.width - 10 or y <= 10 or y >= self.height - 10
    if isNearEdge then
        radius = radius + 3 -- Larger lakes near edges to represent seas
    end

    -- Add some randomness to lake shape for more natural appearance
    local baseRadius = radius

    for dy = -radius-2, radius+2 do
        for dx = -radius-2, radius+2 do
            local nx, ny = x + dx, y + dy
            if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
                -- Use distance formula with some noise for irregular lake shapes
                local distance = math.sqrt(dx*dx + dy*dy)

                -- Add noise to the radius check for more natural lake shapes
                local noiseValue = self:noise2D(nx/10, ny/10) * 2 - 0.5
                local adjustedRadius = baseRadius + noiseValue

                if distance <= adjustedRadius then
                    self.tiles[ny][nx] = Tile.new(TileType.WATER)

                    -- Add fish resources to some lake tiles
                    if math.random() < 0.3 then
                        self.tiles[ny][nx]:setResource(ResourceType.FISH)
                    end
                end
            end
        end
    end

    -- Sometimes create a second connected lake for more complex water bodies
    if math.random() < 0.4 then
        local offsetX = math.random(-radius, radius)
        local offsetY = math.random(-radius, radius)
        local secondX = x + offsetX
        local secondY = y + offsetY

        -- Make sure the second lake center is within map bounds
        if secondX >= 1 and secondX <= self.width and secondY >= 1 and secondY <= self.height then
            local secondRadius = math.random(radius-1, radius+1)

            for dy = -secondRadius, secondRadius do
                for dx = -secondRadius, secondRadius do
                    local nx, ny = secondX + dx, secondY + dy
                    if nx >= 1 and nx <= self.width and ny >= 1 and ny <= self.height then
                        -- Use distance formula with some noise for irregular lake shapes
                        local distance = math.sqrt(dx*dx + dy*dy)

                        -- Add noise to the radius check for more natural lake shapes
                        local noiseValue = self:noise2D(nx/10, ny/10) * 2 - 0.5
                        local adjustedRadius = secondRadius + noiseValue

                        if distance <= adjustedRadius then
                            self.tiles[ny][nx] = Tile.new(TileType.WATER)

                            -- Add fish resources to some lake tiles
                            if math.random() < 0.3 then
                                self.tiles[ny][nx]:setResource(ResourceType.FISH)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Add resources to a tile based on its type
function Grid:addResourcesToTile(tile)
    -- Only add resources with a random chance based on rarity
    if math.random() > 0.2 then return end  -- 20% chance to have any resource

    local resources = Resources.new()

    -- Get all possible resources for this tile type
    local possibleResources = {}
    for resourceType, resource in pairs(resources.definitions) do
        if resources:canPlaceOnTile(resourceType, tile.type) then
            -- Weight by rarity
            for i = 1, math.floor(resource.rarity * 100) do
                table.insert(possibleResources, resourceType)
            end
        end
    end

    -- If there are possible resources, randomly select one
    if #possibleResources > 0 then
        local selectedResource = possibleResources[math.random(#possibleResources)]
        tile:setResource(selectedResource)
    end
end

function Grid:getTileAt(x, y)
    if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
        return self.tiles[y][x]
    end
    return nil
end
