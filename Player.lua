local class = require "lib.middleclass"
local PathGraph = require "PathGraph"

local Player = class("Player")


function Player:initialize(world, x, y)
    self.id = 'player'

    self.world = world

    self.drawColor = {r = 0, g = 0, b = 0}

    self.x = x
    self.y = y
    self.w = 20
    self.h = 20
    self.speed = 120

    self.alive = true


    self.pathGraph = PathGraph:new(world.staticObjects)

    self.destinationPoint = {}
end

function Player:getCenterCoords()
    local x = self.x + (self.w / 2)
    local y = self.y + (self.h / 2)

    return x, y
end

function Player:move(dx, dy)
    local dxy = 0.0
    if dx ~= 0 or dy ~= 0 then
        local old_x, old_y = self.x, self.y
        self.x, self.y, _, _ = self.world:move(self, self.x + dx, self.y + dy)
        dxy = ((self.x - old_x)^2 + (self.y - old_y)^2)^0.5 -- расчёт реального перемещения
        self.viewBox.x = (self.x + self.w / 2) - self.viewBox.w /2
        self.viewBox.y = (self.y + self.h / 2) - self.viewBox.h /2
    end
    return dxy
end

return Player