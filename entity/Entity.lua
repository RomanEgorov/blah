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

return Entity