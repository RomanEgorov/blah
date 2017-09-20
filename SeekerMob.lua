local MobBrain = require "MobBrain"

local SeekerMob = {}
SeekerMob.__index = SeekerMob

setmetatable(SeekerMob, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)

		return self
	end
})

function SeekerMob:_init(world, x, y)
	self.brain = MobBrain()

	self.world = world
	self.x = x
	self.y = y
	self.w = 20
	self.h = 20
	self.speed = 80
end

function SeekerMob:seekResource(dt) 

end

function SeekerMob:grabResource(dt)

end

function SeekerMob:returnResouce(dt)

end

function SeekerMob:fleeToBase(dt)
-- координаты базы?
end