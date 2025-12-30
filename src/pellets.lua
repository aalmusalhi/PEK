-- pellets.lua
local pellets = {}
pellets.__index = pellets -- inheritance

function pellets:init(nmax, tmin, tmax, nhits, ps, image)

    local self =  {
        nPellets = 0, -- existing number of pellets
        nMaxPellets = nmax, -- maximum allowed number of pellets
        size = ps, -- radius of pellet
        sprite = image, -- sprite to draw for these pellets
        minSpawnDelay = tmin, -- minimum delay for spawning a pellet
        maxSpawnDelay = tmax, -- maximum delay for spawning a pellet
        spawnDelay = math.random(tmin, tmax),
        spawnTimer = 0, -- time since last spawn
        breakHits = nhits, -- how many hits does this pellet need to break?
        set = {}, -- storage for pellet positions TODO: maybe just make this npecks
    }

    -- setup object-oriented behaviour
    setmetatable(self, pellets)

    return self
end

-- spawns a pellet if deemed appropriate
function pellets:spawn(dt)
    self.spawnTimer = self.spawnTimer + dt
    if (self.nPellets < self.nMaxPellets) and (self.spawnTimer >= self.spawnDelay) then
        self:createPellet()
        self.nPellets = self.nPellets + 1
        self.spawnTimer = 0
        self.spawnDelay = math.random(self.minSpawnDelay, self.maxSpawnDelay)
    elseif self.nPellets == self.nMaxPellets then
        self.spawnTimer = 0
    end
end

-- creates a pellet at some random location (below wall edge), with some health
function pellets:createPellet(X, Y)
    local p = {
        x = X or math.random(0 + self.size, love.graphics.getWidth() - self.size),
        y = Y or math.random(250 + self.size, love.graphics.getHeight() - self.size),
        theta = math.random() * 2 * math.pi, -- varied rotation for drawing
        h = self.breakHits
    }
    table.insert(self.set, p)
end

-- draw pellet sprite with random rotation
function pellets:draw()
    love.graphics.setColor(1, 1, 1, 1)
    local d = self.sprite:getWidth() * self.size
    for i, p in pairs(self.set) do
        love.graphics.draw(self.sprite, p.x, p.y, 0, self.size)
    end
end

return pellets