-- states.lua
states = {}

function states.load()

    -- initialise the game state and fading between states
    states.gameState = 'start' -- ['start', 'tutorial', 'play', 'finish']
    states.prevState = nil -- previous game state
    states.fadeState = 'none' -- ['none', 'in', 'out']
    states.fadeDuration = 0.4 -- [s]
    states.fadeAlpha = 0 -- opacity of fade screen

     -- create static colliders for back wall and frame edges
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local walls = {
        backWall = world:newRectangleCollider(0, 0, w, 160),
        botEdge = world:newRectangleCollider(0, h, w, 20),
        leftEdge = world:newRectangleCollider(-20, 0, 20, h),
        rightEdge = world:newRectangleCollider(w, 0, 20, h)
    }
    for k, wall in pairs(walls) do
        wall:setType('static') -- don't let the walls move
    end
end

function states.changeGameState(newState)

    -- set off fading transition when game state changes
    states.prevState = states.gameState
    states.gameState = newState
    states.fadeState = 'out'

    -- adjust sounds based on new state
    sounds.adjust(newState)

    -- set the high score when the game ends (before end screen renders)
    if newState == 'finish' then
        player.flying = true
        player.zoomies = 0
        if (player.score > player.hiscore) then
            player.hiscore = player.score
        end
    else
        player.flying = false
    end
end

function states.updateStateFade(dt)

    -- fading out to leave the scene
    if states.fadeState == 'out' then
        states.fadeAlpha = states.fadeAlpha + (dt / states.fadeDuration)
        if states.fadeAlpha > 1 then
            states.fadeAlpha = 1
            states.fadeState = 'in'
        end

    -- fading in to enter the scene
    elseif states.fadeState == 'in' then
        states.fadeAlpha = states.fadeAlpha - (dt / states.fadeDuration)
        if states.fadeAlpha < 0 then
            states.fadeAlpha = 0
            states.fadeState = 'none' -- settled into a new scene, no fading
        end 
    end
end

-- sets game into motion when called
function states.start()
    states.changeGameState('tutorial')
end

-- resets the game when called
function states.restart()
    states.changeGameState('play')
    player.reset()
    t0 = love.timer.getTime()
    for i, f in pairs(pelletGroup) do
        f.set = {}
        f.nPellets = 0
    end
end

-- draws black screen with some opacity for transition
function states.drawTransition()
    if (states.fadeAlpha > 0) then
        love.graphics.setColor(0, 0, 0, states.fadeAlpha)
        love.graphics.rectangle('fill', 0, 0,
                                love.graphics.getWidth(),
                                love.graphics.getHeight())
    end
end

-- draws the title screen
function states.drawStart()
    love.graphics.draw(backgrounds.intro, 0, 0, nil, scale)
    rest_anim:draw(restSheet, 120, 400, nil, 0.5)
    pek_anim:draw(pekSheet, 370, 140, nil, 0.9)
    logo_anim:draw(logoSheet, 555, 410, nil, 0.85)
    buttonGroup.start:draw()
end

-- draws the tutorial scene
function states.drawTutorial()

    -- draw main scene
    love.graphics.draw(backgrounds.main, 0, 0, nil, scale)

    -- draw current score with centring based on number of digits
    player.printScore()

    -- draw tutorial crumb
    pelletGroup.crumbs:draw()

    -- draw tutorial instructions
    for i, key in pairs(keyCaps) do
        love.graphics.setColor(1, 1, 1, key.alpha)
        if i == 'space' then
            key.anim:draw(spaceSheet, key.xoffset, key.yoffset, nil, keyScale)
        else
            key.anim:draw(keySheet, player.x + key.xoffset, player.y + key.yoffset, nil, keyScale)
        end
    end
    love.graphics.setColor(1, 1, 1, 1) -- reset palette

    -- draw the player last
    player.draw()

    -- draw hitboxes if in debug mode
    if debug then player.draw_debug() end
end

-- draw the main gameplay
function states.drawGame()

    -- draw main scene
    love.graphics.draw(backgrounds.main, 0, 0, nil, scale)

    -- draw current score with centring based on number of digits
    player.printScore()

    -- draw all foods
    for i, f in pairs(pelletGroup) do
        f:draw()
    end

    -- draw player last, with shader if power-up active
    if player.zoomies > 0 then
        love.graphics.setShader(shader)
    end
    player.draw()
    love.graphics.setShader() -- reset shader

    -- draw hitboxes if in debug mode
    if debug then player.draw_debug() end
end

-- draw end screen
function states.drawEnd()

    -- draw end scene
    love.graphics.draw(backgrounds.outro, 0, 0, nil, scale)

    -- apply light shading on resting pigeon then reset palette
    love.graphics.setColor(0.87, 0.87, 0.64, 1)
    rest_anim:draw(restSheet, 120, 400, nil, 0.5)
    love.graphics.setColor(1, 1, 1, 1)

    -- draw high-score header
    love.graphics.draw(hs_label, 590, 155, nil, 0.5)

    -- draw current score with centring based on number of digits
    local x0 = 455
    if player.score > 99 then
        x0 = 395
    elseif player.score > 9 then
        x0 = 425
    end
    love.graphics.print(player.score, x0, 155, nil, 0.65)

    -- draw high-score with centring based on number of digits
    local x1 = 635
    if player.hiscore > 99 then
        x1 = 610
    elseif player.hiscore > 9 then
        x1 = 620
    end
    love.graphics.print(player.hiscore, x1, 210, nil, 0.25)

    -- draw retry text and button
    endText_anim:draw(endTextSheet, 390, 275, nil, 0.6)
    buttonGroup.retry:draw()
end

-- checks if mouse was clicked once
function love.mousepressed(x, y, button, istouch, presses)

    -- check for left click on existing buttons
    if button == 1 then
        if states.gameState == 'start' then
            buttonGroup.start:click(x, y)
        elseif states.gameState == 'finish' then
            buttonGroup.retry:click(x, y)
        end
    end
end

-- check if a key was pressed once
function love.keypressed(key)

    -- player peck action
    if (key == 'space') and 
    not (states.gameState == 'finish') and
    not (states.gameState == 'start') then
        player.pecked = true
        player.peckTime = 0
    end

    -- fading keys in tutorial instructions
    if states.gameState == 'tutorial' then
        for i, k in pairs(keyCaps) do

            -- space key shouldn't fade just when pressed
            if (i == key) and (k.alpha == 1) and not (key == 'space') then
                k.alpha = 0.999 -- if less than 1 then it starts to fade
            end
        end
    end
end

return states