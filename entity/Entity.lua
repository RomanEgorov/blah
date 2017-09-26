local class = require "lib.middleclass"

local EntityBrain = require "entity.AI.EntityBrain"
local PathGraph = require "PathGraph"

local Entity = class("Entity")

function Entity:initialize(id, world, x, y)
	self.id = id

	self.world = world

	self.x = x
	self.y = y
	self.w = 0
	self.h = 0
	self.speed = 0

	self.brain = EntityBrain:new()

	self.pathGraph = PathGraph:new(world.staticObjects)
end

function Entity:move(dx, dy)
  	if dx ~= 0 or dy ~= 0 then
  	  	self.x, self.y, cols, cols_len = self.world:move(self, self.x + dx, self.y + dy)
  	end
end

return Entity