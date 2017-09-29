local class = require "lib.middleclass"

local EntityBrain = require "entity.AI.EntityBrain"
local PathGraph = require "PathGraph"

local Entity = class("Entity")

function Entity:initialize(id, world, x, y)
	self.id = id

	self.world = world

	self.drawColor = {r = 0, g = 0, b = 0}

	self.x = x
	self.y = y
	self.w = 0
	self.h = 0
	self.speed = 0

	self.alive = true
	self.energy = 20

	self.brain = EntityBrain:new()

	self.pathGraph = PathGraph:new(world.staticObjects)

	self.destinationPoint = {}
end

function Entity:getCenterCoords()
	local x = self.x + (self.w / 2)
	local y = self.y + (self.h / 2)

	return x, y
end

function Entity:move(dx, dy)
    self.viewBox.x = (self.x + self.w / 2) - 45
    self.viewBox.y = (self.y + self.h / 2) - 45
    local viewX = self.viewBox.x
    local viewY = self.viewBox.y
    local viewW = self.viewBox.w
    local viewH = self.viewBox.h
	

  	if dx ~= 0 or dy ~= 0 then
  	  	self.x, self.y, cols, cols_len = self.world:move(self, self.x + dx, self.y + dy)
        -- self.destinationPoint = {x = self.x, y = self.y}
  	end
end

function Entity:moveTo(dest, dt)
	if dest.x == nil or dest.y == nil then
		return false
	end

    local pointX, pointY = dest.x, dest.y
    local centerX, centerY = self:getCenterCoords()

    local dx = pointX - centerX
    local dy = pointY - centerY
    local dxy = (dx^2 + dy^2)^0.5
    
    if dxy < 5 then
        return dxy
    else
        dx = dx / dxy
        dy = dy / dxy

        if self.speed * dt < dxy then
            dxy = self.speed * dt
        end

        dx = dx * dxy
        dy = dy * dxy
    end

    self:move(dx, dy)

    return dxy
end

function Entity:followPath(dt)
	local dx, dy = 0, 0

    if #self.pathGraph.path > 0 then
        local pointX, pointY = self.pathGraph.path[1][1], self.pathGraph.path[1][2]
        -- print("going to: ", pointX, pointY)
        self.destinationPoint = {x = pointX, y = pointY}

        if #self.pathGraph.path then
            dx = pointX - (self.x + self.w / 2)
            dy = pointY - (self.y + self.h / 2)
            local dxy = (dx^2 + dy^2)^0.5
            
            if dxy < 5 then
                table.remove(self.pathGraph.path, 1)
            else
                dx = dx / dxy
                dy = dy / dxy
                if self.speed * dt < dxy then
                    dxy = self.speed * dt
                end
                dx = dx * dxy
                dy = dy * dxy
            end
        end
    end

    self:move(dx, dy)
end

return Entity