local class = require "lib.middleclass"
local Behavior = require "entity.AI.behavior.Behavior"

local BehaviorSystem = class("BehaviorSystem")

function BehaviorSystem:initialize(behaviors)
    self.behaviors = behaviors
end

function BehaviorSystem:behave(dt, entity)
    for i=1,  #self.behaviors do
        self.behaviors[i]:behave(dt, entity)
    end
end

return BehaviorSystem