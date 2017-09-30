local class = require "lib.middleclass"
local Behavior = require "entity.AI.behavior.Behavior"

local GuardBehavior = class("GuardBehavior")

function GuardBehavior:initialize(target_id)
    Behavior.initialize(self)
    self.target_id = target_id
    self.states_descriptors = {}
    self.states_descriptors[GuardBehavior.lookupTarget] = {priority = 1}
    self.states_descriptors[GuardBehavior.followTarget] = {priority = 2, dependencies = {'move'}}
    self.current_state = GuardBehavior.lookupTarget
end

function GuardBehavior:behave(dt, entity)
    if self.current_state ~= nil then
        self:current_state(dt, entity)
    end
end

function GuardBehavior:lookupTarget(dt, entity)
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
        self.current_state = GuardBehavior.followTarget
    end
end

function GuardBehavior:followTarget(dt, entity)
    entity.speed = 70

    local targetFound, targetObject = self:findTarget(entity)

    if targetFound then
        local dx, dy = 0, 0

        local entityX, entityY = entity:getCenterCoords()
        local targetX, targetY = targetObject:getCenterCoords()

        if entityX - targetX > 0 then
            dx = -entity.speed * dt
        else
            dx = entity.speed * dt
        end
        if entityY - targetY > 0 then
            dy = -entity.speed * dt
        else
            dy = entity.speed * dt
        end

        entity:move(dx, dy)
    else
        self.current_state = GuardBehavior.lookupTarget
    end
end

function GuardBehavior:findTarget(entity)
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

return GuardBehavior