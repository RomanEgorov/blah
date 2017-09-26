local class = require "lib.middleclass"

local EntityBrain = require "entity.AI.EntityBrain"
local PathGraph = require "PathGraph"

local Entity = class("Entity")

function Entity:initialize(world, x, y)
	self.world = world

	self.x = x
	self.y = y
	self.w = 0
	self.h = 0
	self.speed = 0

	self.brain = EntityBrain:new()

	-- self.pathGraph = PathGraph:new(world:getItems())
end

return Entity