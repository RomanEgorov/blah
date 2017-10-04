local class = require "lib.middleclass"

local Entity = require "entity.Entity"
local BehaviorSystem = require "entity.AI.behavior.BehaviorSystem"
local PatrolBehavior = require "entity.AI.behavior.PatrolBehavior"
local GuardBehavior = require "entity.AI.behavior.GuardBehavior"

local TestMob = class("TestMob", Entity)

function TestMob:initialize(world, x, y)
    Entity.initialize(self, "TestMob", world, x, y)

    self.drawColor = {r = 64, g = 192, b = 32}

    self.w = 20
    self.h = 20
    self.speed = 180

    self.viewBox = {
        x = (self.x + self.w / 2) - 50,
        y = (self.y + self.h / 2) - 50,
        w = 100,
        h = 100
    }

    local patrolPoints = {{x = 650, y = 100}, {x = 650, y = 500}, {x = 60, y = 350}}
    local patrolBehavior = PatrolBehavior:new(patrolPoints)
    local guardBehavior = GuardBehavior:new('player')

    self.behaviorSystem = BehaviorSystem:new({patrolBehavior, guardBehavior})


end

function TestMob:update(dt)
    self.behaviorSystem:behave(dt, self)
end

return TestMob