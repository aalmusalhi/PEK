-- main.lua

-- game settings
duration = 20 -- [s]; how much time is allowed?
debug = false -- draw certain hitboxes for debugging purposes

-- define image constants
image_scale = 0.5 -- how much to scale pigeon sprites by
pixel_scale = 400 -- expected dimensions of sprites in sheet (pixels)

-- imports
anim8 = require 'lib/anim8' -- animation library
wf = require 'lib/windfield' -- physics library
world = wf.newWorld(0, 0) -- game world (no gravity)
states = require 'src/states' -- game state manager
visuals = require 'src/visuals' -- backgrounds and non-player animations
sounds = require 'src/sounds' -- sound effects and music
buttons = require 'src/buttons' -- button objects
player = require 'src/player' -- player object
pellets = require 'src/pellets' -- food objects

function love.load()

    -- smooth graphics (no blur)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set a new RNG seed every time
    math.randomseed(os.time())

    -- define game states
    states.load()
    renders = { -- for drawing different states
        start = function() states.drawStart() end,
        tutorial = function() states.drawTutorial() end,
        play = function() states.drawGame() end,
        finish = function() states.drawEnd() end,
    }

    -- load backgrounds and non-player animations
    visuals.load()

    -- load sound effects and background music
    sounds.load()

    -- load player object (pigeon)
    player.load()

    -- define foods; {nmax, tmin, tmax, nhits, size, image}
    pelletGroup = {
        crumbs = pellets:init(20, 0, 1, 1, 0.3,
                              love.graphics.newImage('assets/sprites/crumb.png')),
        breads = pellets:init(1, 5, 10, 8, 1,
                              love.graphics.newImage('assets/sprites/bread.png'))
    }

    -- define start and retry button objects
    buttonGroup = {
        start = buttons:init(0.62 * love.graphics.getWidth(), 0.5 *  love.graphics.getHeight(),
                             0.45, states.start, 'assets/sprites/go_button.png', 200, 200),
        retry = buttons:init(0.78 * love.graphics.getWidth(), 0.49 *  love.graphics.getHeight(),
                             0.45, states.restart, 'assets/sprites/retry.png', 200, 200)
    }
end

function love.update(dt)

    -- update fading between scenes if game state recently changed
    if not (states.fadeState == 'none') then
        states.updateStateFade(dt)
    end

    -- title screen animations
    if states.gameState == 'start' then
        buttonGroup.start:update(dt)
        pek_anim:update(dt)
        logo_anim:update(dt)
        rest_anim:update(dt)

    -- game tutorial
    elseif states.gameState == 'tutorial' then

        -- animate each instruction key
        for i, key in pairs(keyCaps) do
            key.anim:update(dt)

            -- if the key started fading, keep it going until 0
            if key.alpha < 0 then
                key.alpha = 0
            elseif (key.alpha > 0) and (key.alpha < 1) then
                key.alpha = key.alpha - dt
            end
        end

        -- spawn a single tutorial pellet and float space bar above it
        if (pelletGroup.crumbs.nPellets == 0) and (player.score == 0) then
            pelletGroup.crumbs:createPellet(600, player.y + pixel_scale * image_scale / 2)
            pelletGroup.crumbs.nPellets = 1
            keyCaps.space.xoffset = keyCaps.space.xoffset + pelletGroup.crumbs.set[1].x
            keyCaps.space.yoffset = keyCaps.space.yoffset + pelletGroup.crumbs.set[1].y

        -- if the player has pecked the tutorial pellet, start the game
        elseif player.score == 1 and keyCaps.space.alpha == 0 then
            states.gameState = 'play' -- not changeState as we don't want to fade here
            t0 = love.timer.getTime() -- start the timer
        end

        -- update player state and movement
        player.update(dt, pelletGroup)

    -- main gameplay section
    elseif states.gameState == 'play' then

        -- this needs to happen here to preserve game score when fading back from end screen
        if states.prevState == 'finish' and states.fadeState == 'in' then
            player.score = 0
        end

        -- update player movement and food pecking
        player.update(dt, pelletGroup)
        
        -- pellet spawning
        for i, f in pairs(pelletGroup) do
            f:spawn(dt)
        end

        -- apply shader if power-up is ongoing
        if player.zoomies > 0 then
            shader:send("time", player.zoomies)
        end

        -- end the game if elapsed time exceeds limit
        local t1 = love.timer.getTime()
        if (t1 - t0) >= duration then
            states.changeGameState('finish')
        end

    -- end screen animations
    elseif states.gameState == 'finish' then
        buttonGroup.retry:update(dt)
        endText_anim:update(dt)
        rest_anim:update(dt)
        if states.fadeState == 'out' then
            player.update(dt, pelletGroup)
        end
    end
end

function love.draw()

    -- set colour to default
    love.graphics.setColor(1, 1, 1, 1)

    -- keep drawing a scene until fading out
    if (states.fadeState == 'out') and not (states.prevState == nil) then
        renders[states.prevState]()
    else
        renders[states.gameState]()
    end

    -- fade between game states if changing
    if not (states.fadeState == 'none') then
        states.drawTransition()
    end
end