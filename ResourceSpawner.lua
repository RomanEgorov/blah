local class = require "lib.middleclass"

local ResourceSpawner = class("ResourceSpawner")

function ResourceSpawner:initialize(world)
	self.world = world

	self.resources = {}
	self.resourcesNum = 10
	self.lastResourceSpawn = 0
	self.resourceSpawnInterval = 0.01
end

function ResourceSpawner:spawnResource()
    for i = 1, self.resourcesNum do
        if self.resources[i] == nil then
            local resource = {
                id = "resource",
                resourceId = i,
                x = math.random(40, 650),
                y = math.random(40, 450),
                w = 10,
                h = 10
            }

            local items, len = self.world:queryRect(resource.x, resource.y, resource.w, resource.h)

            if len == 0 then
                self.resources[i] = resource
            end

            break
        end
    end
end

function ResourceSpawner:update(dt)
	self.lastResourceSpawn = self.lastResourceSpawn + dt

	if self.lastResourceSpawn >= self.resourceSpawnInterval then
		self.lastResourceSpawn = self.lastResourceSpawn - self.resourceSpawnInterval

		self:spawnResource()
	end
end

return ResourceSpawner