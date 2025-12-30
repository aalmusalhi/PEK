-- buttons.lua
local buttons = {}
buttons.__index = buttons -- inheritance

function buttons:init(xpos, ypos, scale, func, img, px, py)

    -- load button animations
    local image = love.graphics.newImage(img)
    local grid = anim8.newGrid(px, py, image:getWidth(), image:getHeight())

    -- initialise button properties with provided values
    local self =  {
        x = xpos, -- x position of the button
        y = ypos, -- y position of the button
        s = scale, -- scale of the button
        w = image:getWidth(), -- scale of the button image
        fn = func, -- what we want the button to do when pressed
        now = love.mouse.isDown(1),
        sheet = image, -- sprite sheet for animated button image
        anims = { -- animation for on/off states of button
            off = anim8.newAnimation(grid(1, '1-2'), 0.2),
            on = anim8.newAnimation(grid(1, '3-4'), 0.2)
        }
    }

    -- setup object-oriented behaviour
    setmetatable(self, buttons)

    return self
end

-- checks whether the cursor is on the button
function buttons:hover(mx, my)
    local r = self.w * self.s / 2
    local x0 = self.x + r
    local y0 = self.y + r
    return ((mx - x0)^2 + (my - y0)^2) <= r^2
end

-- specified function happens with a click only if hovering on button
function buttons:click(mx, my)
    if self:hover(mx, my) then
        self.fn()
    end
end

-- update button animation states with time
function buttons:update(dt)
    self.anims.off:update(dt)
    self.anims.on:update(dt)
end

-- draw the button differently based on whether cursor is hovering on it or not
function buttons:draw()
    local mx, my = love.mouse.getPosition()
    if self:hover(mx, my) then
        self.anims.on:draw(self.sheet, self.x, self.y, nil, self.s)
    else
        self.anims.off:draw(self.sheet, self.x, self.y, nil, self.s)
    end
end

return buttons