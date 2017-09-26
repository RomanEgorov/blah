local class = require "lib.middleclass"

local Entity = class("Entity")

function Entity:initialize(world, x, y)
	self.world = world

	self.x = x
	self.y = y
	self.w = 20
	self.h = 20
	self.speed = 80

	-- brain
end

return Entity