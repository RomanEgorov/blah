local class = require "lib.middleclass"

local Entity = require "entity.Entity"
local SeekerMob = require "entity.SeekerMob"

local ColonyBase = class("ColonyBase", Entity)

function ColonyBase:initialize(world, x, y)
	Entity.initialize(self, "ColonyBase", world, x, y)

	self.w = 40
	self.h = 40

	self.energy = 95
	self.energyConsumptionInterval = 2
	self.timeAfterTick = 0.
end

function ColonyBase:update(dt)
	if self.energy <= 0 then
		self.alive = false

		return
	end

	if self.energy > 100 then
		self:spawnSeeker()
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

function ColonyBase:spawnSeeker()
    local mob = SeekerMob(self.world, self.x - (self.w * 2), self.y - (self.h * 2))
    mob.colonyBase = self
    mob.patrolPoints = {}

    local x, y = 0, 0

    while #mob.patrolPoints < 2 do
        x = math.random(40, 650)
        y = math.random(40, 450)
	    -- for _, point in ipairs(mob.patrolPoints) do
	    -- 	print(x, y)
	    -- end

        local items, len = self.world:queryRect(x - (mob.w / 2), y - (mob.h / 2), mob.w + (mob.w / 2), mob.h + (mob.h / 2))

        if len == 0 then
        	table.insert(mob.patrolPoints, {x = x, y = y})
        end
    end

    mob.resourceSpawner = resourceSpawner
    print("new mob patrolPoints: ")
    for _, point in ipairs(mob.patrolPoints) do
    	print(point.x, point.y)
    end
    enemies[#enemies+1] = mob
    self.world:add(mob, mob.x, mob.y, mob.w, mob.h)

    self.energy = self.energy - 50
end	

return ColonyBase