local class = require "lib.middleclass"

local Entity = require "entity.Entity"

local ColonyBase = class("ColonyBase", Entity)

function ColonyBase:initialize(world, x, y)
	Entity.initialize(self, "ColonyBase", world, x, y)

	self.w = 40
	self.h = 40

	self.energy = 10
	self.energyConsumptionInterval = 1.5
	self.timeAfterTick = 0.
end

function ColonyBase:update(dt)
	if self.energy <= 0 then
		self.alive = false

		return
	end

	self.timeAfterTick = self.timeAfterTick + dt

	if self.timeAfterTick >= self.energyConsumptionInterval then
		self.energy = self.energy - 1
		self.timeAfterTick = self.timeAfterTick - self.energyConsumptionInterval
	end
end

function ColonyBase:addEnergy()
	if not self.alive then
		return
	end

	self.energy = self.energy + 10
end

function ColonyBase:takeEnergy()
	if not self.alive then
		return 0
	end

	if self.energy > 10 then
		self.energy = self.energy - 10

		return 10
	else
		return 0
	end
end

return ColonyBase