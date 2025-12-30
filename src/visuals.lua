-- visuals.lua
visuals = {}

function visuals.load()

    -- load background images
    backgrounds = {
        intro = love.graphics.newImage('assets/sprites/intro_bg.png'),
        main = love.graphics.newImage('assets/sprites/game_bg.png'),
        outro = love.graphics.newImage('assets/sprites/outro_bg.png')
    }
    love.window.setMode(backgrounds.main:getWidth(), backgrounds.main:getHeight())

    -- PEK title animation
    pekSheet = love.graphics.newImage('assets/sprites/PEK.png')
    pekGrid = anim8.newGrid(400, 200, pekSheet:getWidth(), pekSheet:getHeight())
    pek_anim = anim8.newAnimation(pekGrid(1, '1-3'), 0.2)

    -- logo animation
    logoSheet = love.graphics.newImage('assets/sprites/jayhamade.png')
    logoGrid = anim8.newGrid(300, 200, logoSheet:getWidth(), logoSheet:getHeight())
    logo_anim = anim8.newAnimation(logoGrid(1, '1-2'), 0.3)

    -- resting pigeon animation
    restSheet = love.graphics.newImage('assets/sprites/rest.png')
    restGrid = anim8.newGrid(200, 200, restSheet:getWidth(), restSheet:getHeight())
    rest_anim = anim8.newAnimation(restGrid(1, '1-2'), 0.8)

    -- custom shader for power-up state
    shader = love.graphics.newShader('src/shader.glsl')

    -- custom font for score numbers
    font = love.graphics.newImageFont('assets/sprites/numbers.png','0123456789')
    love.graphics.setFont(font)

    -- ending text animation
    endTextSheet = love.graphics.newImage('assets/sprites/pek_again.png')
    endTextGrid = anim8.newGrid(384, 200, endTextSheet:getWidth(), endTextSheet:getHeight())
    endText_anim = anim8.newAnimation(endTextGrid(1, '1-2'), 0.2)

    -- high-score label text
    hs_label = love.graphics.newImage('assets/sprites/highscore.png')

    -- animated keys for tutorial instructions
    keySheet = love.graphics.newImage('assets/sprites/wasd.png')
    spaceSheet = love.graphics.newImage('assets/sprites/space.png')
    keyGrid = anim8.newGrid(pixel_scale, pixel_scale, keySheet:getWidth(), keySheet:getHeight())
    spaceGrid = anim8.newGrid(pixel_scale * 2, pixel_scale, spaceSheet:getWidth(), spaceSheet:getHeight())
    keyScale = 0.25
    keyCaps = {
        w = {
            anim = anim8.newAnimation(keyGrid(1, '1-2'), 0.2),
            xoffset = (image_scale - keyScale) * pixel_scale / 2,
            yoffset = -0.75 * keyScale * pixel_scale,
            alpha = 1
        },
        a = {
            anim = anim8.newAnimation(keyGrid(2, '1-2'), 0.2),
            xoffset = -keyScale * pixel_scale / 2,
            yoffset = (image_scale - keyScale) * pixel_scale / 2,
            alpha = 1
        },
        s = {
            anim = anim8.newAnimation(keyGrid(3, '1-2'), 0.2),
            xoffset = (image_scale - keyScale) * pixel_scale / 2,
            yoffset = (image_scale + keyScale) * 1.1 * pixel_scale / 2,
            alpha = 1
        },
        d = {
            anim = anim8.newAnimation(keyGrid(4, '1-2'), 0.2),
            xoffset = (image_scale - keyScale / 2) * pixel_scale,
            yoffset = (image_scale - keyScale) * pixel_scale / 2,
            alpha = 1
        },
        space = {
            anim = anim8.newAnimation(spaceGrid(1, '1-2'), 0.2),
            xoffset = - keyScale * pixel_scale,
            yoffset = - keyScale * pixel_scale,
            alpha = 1
        }
    }
end

return visuals