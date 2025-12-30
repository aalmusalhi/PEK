-- player.lua
local player = {}

-- define default quantities
x0 = (love.graphics.getWidth() - (image_scale * pixel_scale)) / 5 -- default player x position
y0 = 250 -- default player y position
v0 = 300 -- base player speed
vz = 1500 -- power-up player speed
d0 = 'down' -- direction faced
p0 = 40 * image_scale -- peck region radius
hbx = 190 * image_scale -- hitbox x-offset
hby = 200 * image_scale -- hitbox y-offset
powerTime = 2 -- how long should a power-up last?

function player.load()

    -- set player quantities
    player.x = x0
    player.y = y0
    player.speed = v0
    player.score = 0
    player.hiscore = 0
    player.orientation = d0
    player.pecked = false -- has the player just pecked?
    player.peckTime = 0 -- time since last peck
    player.peckDelay = 0.05 -- how quickly the player can peck
    player.peckPitch = 1 -- pitch scaling on peck sound
    player.zoomies = 0 -- remaining time for power-up
    player.flying = false -- whether flight animation is enabled

     -- load player sprites and set animations
    player.spriteSheet = love.graphics.newImage('assets/sprites/pigeon-sheet.png')
    player.grid = anim8.newGrid(pixel_scale, pixel_scale,
                                player.spriteSheet:getWidth(),
                                player.spriteSheet:getHeight())
    player.flightSheet = love.graphics.newImage('assets/sprites/flying.png')
    player.flightGrid = anim8.newGrid(pixel_scale, pixel_scale,
                                      player.flightSheet:getWidth(),
                                      player.flightSheet:getHeight())
    player.animations = {
        left = {
            move = anim8.newAnimation(player.grid('1-3', 1), 0.1),
            peck = anim8.newAnimation(player.grid(4, 1), 1)
        },
        right = {
            move = anim8.newAnimation(player.grid('1-3', 2), 0.1),
            peck = anim8.newAnimation(player.grid(4, 2), 1)
        },
        up = {
            move = anim8.newAnimation(player.grid('1-3', 3), 0.2),
            peck = anim8.newAnimation(player.grid(4, 3), 1)
        },
        down = {
            move = anim8.newAnimation(player.grid('1-3', 4), 0.2),
            peck = anim8.newAnimation(player.grid(4, 4), 1)
        },
        fly = anim8.newAnimation(player.flightGrid('1-3', 1), 0.05)
    }
    player.anim = player.animations[player.orientation].move

    -- create a collider for the player sprite (octagon-like rectangle)
    player.collider = world:newBSGRectangleCollider(player.x + hbx, player.y + hby,
                                                    150 * image_scale, 160 * image_scale, 14) 
    player.collider:setFixedRotation(true) -- don't let the sprite rotate

    -- define circular peck hitbox as offsets from position that change with orientation
    player.peckSize = p0 -- radius
    player.peckBox = {
        right = {
            x0 = (pixel_scale * image_scale) - 2 * player.peckSize,
            y0 = (pixel_scale * image_scale) - 2 * player.peckSize
        },
        left = {
            x0 = 2 * player.peckSize,
            y0 = (pixel_scale * image_scale) - 2 * player.peckSize
        },
        up = {
            x0 = (pixel_scale * image_scale) / 2,
            y0 = 3 * player.peckSize
        },
        down = {
            x0 = (pixel_scale * image_scale) / 2,
            y0 = (pixel_scale * image_scale) - player.peckSize
        }
    }
end

function player.update(dt, food)

    -- movement parameters
    local isMoving = false
    local vx = 0
    local vy = 0

    -- rightward movement
    if love.keyboard.isDown('d') then
        vx = player.speed
        player.anim = player.animations.right.move
        player.orientation = 'right'
        isMoving = true
    end

    -- leftward movement
    if love.keyboard.isDown('a') then
        vx = -player.speed
        player.anim = player.animations.left.move
        player.orientation = 'left'
        isMoving = true
    end

    -- upward movement
    if love.keyboard.isDown('w') then
        vy = -player.speed
        player.anim = player.animations.up.move
        player.orientation = 'up'
        isMoving = true
    end

    -- downward movement
    if love.keyboard.isDown('s') then
        vy = player.speed
        player.anim = player.animations.down.move
        player.orientation = 'down'
        isMoving = true
    end

    -- update speed based on power-up
    if player.zoomies > 0 then
        player.speed = (vz * player.zoomies / powerTime) + v0
        player.zoomies = player.zoomies - dt
        for i, f in pairs(food) do
            if f.breakHits == 1 then player.attract(f) end
        end
    end

    -- check if the player has pecked (allow some animation delay)
    player.checkPecked(food)
    if player.pecked then
        player.anim = player.animations[player.orientation].peck
        if player.peckTime >= player.peckDelay then
            player.pecked = false
            player.peckTime = 0
        else
            player.peckTime = player.peckTime + dt
        end

    -- if the player is mid-flight then update that instead
    elseif player.flying then
        player.anim = player.animations.fly

    -- otherwise, pick static pose frame if stationary
    elseif not isMoving then
        player.anim = player.animations[player.orientation].move
        player.anim:gotoFrame(2)
    end

    -- update animation for this time step
    player.anim:update(dt)

    -- update player hitbox and match sprite position
    world:update(dt)
    player.collider:setLinearVelocity(vx, vy)
    player.updatePos(dt)
end

-- updates player position based on collider or flight transition
function player.updatePos(dt)

    -- move the player based on collider position (plus some offset)
    if not player.flying then
        player.x = player.collider:getX() - hbx
        player.y = player.collider:getY() - hby

    -- otherwise make player move to top-right if flying
    else
        player.x = player.x + ((love.graphics.getWidth() * 1.5) - player.x) * dt
        player.y = player.y - (10 + dt)
    end
end

-- pecking mechanism: if player has just pecked, check which foods
-- are within range of peck hitbox and update accordingly; treat
-- power-up food as requiring multiple pecks and scale sound pitch up
function player.checkPecked(food)
    if player.pecked and (player.peckTime == 0) then
        local peckPitch = math.random(0.8e4, 1.2e4) / 1e4 -- add variety to peck sound
        for i, f in pairs(food) do
            local d = f.sprite:getWidth() * f.size / 2 -- assumes sprite is square
            for j = #f.set, 1, -1 do -- loop backwards to avoid removal skips
                local p = f.set[j]
                local x1 = player.x + player.peckBox[player.orientation].x0
                local y1 = player.y + player.peckBox[player.orientation].y0
                local inRange = ((x1 - p.x - d)^2 + (y1 - p.y - d)^2) < (d + player.peckSize)^2
                if inRange then
                    if p.h - 1 > 0 then
                        peckPitch = 2 - (1.5 * p.h / f.breakHits)
                        p.h = p.h - 1
                    else
                        table.remove(f.set, j)
                        f.nPellets = f.nPellets - 1
                        if f.breakHits > 1 then
                            player.zoomies = powerTime
                            peckPitch = 2
                        end
                    end
                    player.score = player.score + 1
                end
            end
        end
        sounds.peck:setPitch(peckPitch)
        sounds.peck:play()

        -- fade remaining instruction keys if tutorial food was just pecked
        local tutorialFades = (states.gameState == 'tutorial') and
                              (keyCaps.space.alpha == 1) and
                              (player.score == 1)
        if tutorialFades then
            for i, k in pairs(keyCaps) do
                if (k.alpha == 1) then k.alpha = 0.999 end
            end
        end
    end
end

-- power-up effect: make all input food gravitate towards 
-- player sprite and vanish when overlapping player hitbox
function player.attract(food)
    local px = player.collider:getX()
    local py = player.collider:getY()
    local set = food.set
    for i = #set, 1, -1 do -- loop backwards when removing
        set[i].x = set[i].x + (px - set[i].x) / (player.zoomies * 5)
        set[i].y = set[i].y + (py - set[i].y) / (player.zoomies * 5)
        if ((set[i].x - px)^2 + (set[i].y - py)^2) < (player.peckSize)^2 then
            table.remove(set, i)
            player.score = player.score + 1
            food.nPellets = food.nPellets - 1
        end
    end
end

-- resert player attributes (for when game restarts)
function player.reset()
    player.x = x0
    player.y = y0
    player.speed = v0
    player.zoomies = 0
    player.collider:setX(x0 + hbx)
    player.collider:setY(y0 + hby)
    player.orientation = d0
    player.anim = player.animations[player.orientation]
end

-- draw the player sprite
function player.draw()
    local sheet = player.flying and player.flightSheet or player.spriteSheet
    player.anim:draw(sheet, player.x, player.y, nil, image_scale)
end

-- draw hitboxes for debugging purposes
function player.draw_debug()

    -- outline and position of player sprite
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle('line', player.x, player.y,
                            pixel_scale * image_scale,
                            pixel_scale * image_scale)
    love.graphics.circle('fill', player.x, player.y, 5)

    -- midpoint of screen
    love.graphics.rectangle('line', love.graphics.getWidth()/2, 0, 1, 600)

    -- peck hitbox
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle('line',
        player.x + player.peckBox[player.orientation].x0,
        player.y + player.peckBox[player.orientation].y0,
        player.peckSize)

    -- physical hitboxes
    world:draw()
end

-- draw player score in main stage (centred based on number of digits)
function player.printScore()
    local x0 = 125
    if player.score > 99 then
        x0 = 100
    elseif player.score > 9 then
        x0 = 110
    end
    love.graphics.print(player.score, x0, 70, nil, 0.25)
end

return player