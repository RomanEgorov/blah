local class = require "lib.middleclass"
local Behavior = require "entity.AI.behavior.Behavior"

local BehaviorSystem = class("BehaviorSystem")

function BehaviorSystem:initialize(behaviors)
    self.behaviors = behaviors
end

function BehaviorSystem:behave(dt, entity)
    -- сортировка с приоритетами
    table.sort(self.behaviors,
        function(a, b)
            return a.states_descriptors[a.current_state].priority > b.states_descriptors[b.current_state].priority
        end)

    local dependencies = {}

    -- вызов в соответсвии с приоритетом
    for i=1,  #self.behaviors do
        local behavior = self.behaviors[i]
        local beh_dep = behavior.states_descriptors[behavior.current_state].dependencies
        if beh_dep ~= nil then
            local available = true
            for bh = 1, #beh_dep do
                if dependencies[beh_dep[bh]] == true then
                    available = false
                    break
                end
            end
            if available == true then
                for bh = 1, #beh_dep do
                    dependencies[beh_dep[bh]] = true
                end
                self.behaviors[i]:behave(dt, entity)
            end
        else
            self.behaviors[i]:behave(dt, entity)
        end
    end
end

return BehaviorSystem