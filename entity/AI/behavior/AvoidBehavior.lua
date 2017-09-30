local class = require "lib.middleclass"
local Behavior = require "entity.AI.behavior.Behavior"

local AvoidBehavior = class("AvoidBehavior")

function AvoidBehavior:initialize(target_id)
    Behavior.initialize(self)
    self.target_id = target_id
    self.states_descriptors = {}
    self.states_descriptors[AvoidBehavior.lookupTarget] = {priority = 1}
    self.states_descriptors[AvoidBehavior.followTarget] = {priority = 2, dependencies = {'move'}}
    self.current_state = AvoidBehavior.lookupTarget
end

function AvoidBehavior:behave(dt, entity)
    Behavior.behave(self, dt, entity)
end

function AvoidBehavior:lookupTarget(dt, entity)
    local viewX = entity.viewBox.x
    local viewY = entity.viewBox.y
    local viewW = entity.viewBox.w
    local viewH = entity.viewBox.h

    local items, len = entity.world:queryRect(viewX, viewY, viewW, viewH)
    local targetFound = false

    for _, object in ipairs(items) do
        if object.id == self.target_id then
            targetFound = true

        end
    end

    if targetFound then
        self.current_state = AvoidBehavior.followTarget
    end
end

function AvoidBehavior:followTarget(dt, entity)
    entity.speed = 100
    local targetFound, targetObject = self:findTarget(entity)
    if targetFound then
        local entityX, entityY = entity:getCenterCoords()
        local targetX, targetY = targetObject:getCenterCoords()
        local dx = - (targetX - entityX)
        local dy = - (targetY - entityY)
        local dxy = (dx^2 + dy^2)^0.5
        dx = entity.speed * dt * dx / dxy
        dy = entity.speed * dt * dy / dxy
        entity:move(dx, dy)
    else
        self.current_state = AvoidBehavior.lookupTarget
    end
end

function AvoidBehavior:findTarget(entity)
    local viewX = entity.viewBox.x
    local viewY = entity.viewBox.y
    local viewW = entity.viewBox.w
    local viewH = entity.viewBox.h

    local items, len = entity.world:queryRect(viewX, viewY, viewW, viewH)

    for _, object in ipairs(items) do
        if object.id == self.target_id then
            return true, object
        end
    end

    return false, {}
end

return AvoidBehavior