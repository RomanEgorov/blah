local EnemyBase = {}
EnemyBase.__index = EnemyBase

setmetatable(EnemyBase, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:_init(...)

		self.energy = 10
		self.energyConsumptionInterval = 1.
		self.timeAfterTick = 0.

		return self
	end
})

function EnemyBase:_init(world, x, y, w, h)
	self.world = world
	self.x = x
	self.y = y
	self.w = w
	self.h = h
end

function EnemyBase:update(dt)
	if self.energy <= 0 then
		return
	end

	self.timeAfterTick = self.timeAfterTick + dt

	if self.timeAfterTick >= 1 then
		self.energy = self.energy - 1
		self.timeAfterTick = self.timeAfterTick - 1
		print(self.energy)
	end
end

return EnemyBase