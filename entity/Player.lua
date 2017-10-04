local class = require "lib.middleclass"

local Entity = require "entity.Entity"
local PathGraph = require "PathGraph"

local Player = class("Player", Entity)


function Player:initialize(world, x, y)
    Entity.initialize(self, "player", world, x, y)

    self.id = 'player'

    self.world = world

    self.drawColor = {r = 0, g = 0, b = 0}

    self.x = x
    self.y = y
    self.w = 20
    self.h = 20
    self.speed = 120

    self.alive = true

    self.viewBox = {x = 0, y = 0, w = 0, h = 0}           -- костыль

    self.gotoPoint = false
    self.pathGraph = PathGraph:new(world.staticObjects)

    self.destinationPoint = {}
end

function Player:update(dt)
    local dx, dy = 0, 0

    if love.keyboard.isDown('1') and #self.pathGraph.path then
        self.gotoPoint = true
    end

    if love.keyboard.isDown('2') then
        self.gotoPoint = false
    end

    if love.keyboard.isDown('3') then
    end

    self:followPath(dt)

    if love.keyboard.isDown('right') then
        dx = self.speed * dt
    elseif love.keyboard.isDown('left') then
        dx = -self.speed * dt
    end
    if love.keyboard.isDown('down') then
        dy = self.speed * dt
    elseif love.keyboard.isDown('up') then
        dy = -self.speed * dt
    end

    self:move(dx, dy)
end

function Player:goTo(x, y)
    self.gotoPoint = true

    self.pathGraph:buildPath(self, {x = x, y = y})
end

-- function Player:getCenterCoords()
--     local x = self.x + (self.w / 2)
--     local y = self.y + (self.h / 2)

--     return x, y
-- end

-- function Player:move(dx, dy)
--     local dxy = 0.0
--     if dx ~= 0 or dy ~= 0 then
--         local old_x, old_y = self.x, self.y
--         self.x, self.y, _, _ = self.world:move(self, self.x + dx, self.y + dy)
--         dxy = ((self.x - old_x)^2 + (self.y - old_y)^2)^0.5 -- расчёт реального перемещения
--         self.viewBox.x = (self.x + self.w / 2) - self.viewBox.w /2
--         self.viewBox.y = (self.y + self.h / 2) - self.viewBox.h /2
--     end
--     return dxy
-- end

return Player