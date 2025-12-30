-- sounds.lua
sounds = {}

function sounds.load()

    -- ambient street noises
    sounds.ambient = love.audio.newSource('assets/sounds/street_ambient.mp3', 'static')
    sounds.ambient:play()
    sounds.ambient:setLooping(true)
    sounds.ambient:setVolume(0.05)

    -- background music
    sounds.music = love.audio.newSource('assets/sounds/pek_theme.mp3', 'static')
    sounds.music:play()
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)

    -- pigeon cooing noises
    sounds.coo = love.audio.newSource('assets/sounds/pigeon_coo.mp3', 'static')
    sounds.coo:play()
    sounds.coo:setLooping(true)
    sounds.coo:setVolume(0.05)

    -- pecking sound effect
    sounds.peck = love.audio.newSource('assets/sounds/peck.mp3', 'static')

    -- flying sound effects (entering and exiting main stage)
    sounds.inflight = love.audio.newSource('assets/sounds/inflight.mp3', 'static')
    sounds.outflight = love.audio.newSource('assets/sounds/outflight.mp3', 'static')
    sounds.inflight:setVolume(0.5)
    sounds.outflight:setVolume(0.1)
end

-- adjust volumes and sound cues based on game state
function sounds.adjust(state)

    -- pause coo in main game and make street noises louder
    if state == 'play' or state == 'tutorial' then
        sounds.coo:pause()
        sounds.ambient:setVolume(0.2)
        sounds.inflight:play()

    -- reverse the above otherwise
    elseif state == 'finish' then
        sounds.ambient:setVolume(0.05)
        sounds.coo:play()
        sounds.outflight:play()
    end
end

return sounds