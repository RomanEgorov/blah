local class = require "lib.middleclass"

local Entity = require "entity.Entity"

local BehaviorSystem = require "entity.AI.behavior.BehaviorSystem"
local PatrolBehavior = require "entity.AI.behavior.PatrolBehavior"
local AvoidBehavior = require "entity.AI.behavior.AvoidBehavior"
local SeekerBehavior = require "entity.AI.behavior.SeekerBehavior"

local SeekerMob = class("SeekerMob", Entity)

function SeekerMob:initialize(world, x, y)
	Entity.initialize(self, "SeekerMob", world, x, y)

    self.drawColor = {r = 255, g = 0, b = 255}

	self.w = 10
	self.h = 10
	self.speed = 100

    local viewBoxW, viewBoxH = 100, 100
	self.viewBox = {
		x = (self.x + self.w / 2) - viewBoxW/2,
		y = (self.y + self.h / 2) - viewBoxH/2,
		w = viewBoxW,
		h = viewBoxH
	}


    self.resourceSpawner = nil
    self.colonyBase = {}
	self.carryingResource = false
    self.resource = {}

    local patrolPoints = {{x = 650, y = 400}, {x = 60, y = 450}, {x = 300, y = 60}}
    local patrolBehavior = PatrolBehavior:new(patrolPoints)
    local secondBehavior = SeekerBehavior:new()
--    local thirdBehavior = AvoidBehavior:new('player')

    self.behaviorSystem = BehaviorSystem:new({patrolBehavior, secondBehavior})
end

function SeekerMob:update(dt)
    self.behaviorSystem:behave(dt, self)
end


return SeekerMob