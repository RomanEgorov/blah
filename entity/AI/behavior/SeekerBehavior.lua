local class = require "lib.middleclass"
local Behavior = require "entity.AI.behavior.Behavior"

local SeekerBehavior = class("SeekerBehavior")

function SeekerBehavior:initialize()
    Behavior.initialize(self)
    self.states_descriptors = {}
    self.states_descriptors[SeekerBehavior.seekResource] = {priority = 1 }
    self.states_descriptors[SeekerBehavior.grabResource] = {priority = 2, dependencies = {'move'} }
    self.states_descriptors[SeekerBehavior.returnResource] = {priority = 2, dependencies = {'move'} }
    self.current_state = SeekerBehavior.seekResource
end

function SeekerBehavior:behave(dt, entity)
    Behavior.behave(self, dt, entity)
end

--- Поиск ресурса
function SeekerBehavior:seekResource(dt, entity)
    local resourceFound, resource = self:_findResource(entity)
    if resourceFound then
        entity.rebuildPath = true
        entity.resource = resource
        self.current_state = SeekerBehavior.grabResource
        return
    end
end

--- Сбор найденному ресурсу
function SeekerBehavior:grabResource(dt, entity)
    local d = entity:moveTo(entity.resource, dt)
    if  d > 5 then
        -- 123
    else
        entity.carryingResource = true
        entity.resourceSpawner:removeResource(entity.resource)
        entity.resource = {}
        entity.rebuildPath = true
        self.current_state = SeekerBehavior.returnResource
    end
end


function SeekerBehavior:returnResource(dt, entity)
    if entity.rebuildPath then
        entity.rebuildPath = false
        entity.pathGraph:buildPath(entity, {x = entity.colonyBase.x, y = entity.colonyBase.y})
    end

    local centerX, centerY = entity:getCenterCoords()
    local dx = entity.colonyBase.x - centerX
    local dy = entity.colonyBase.y - centerY
    local dxy = (dx^2 + dy^2)^0.5
    if dxy < 40 then
        entity.colonyBase:addEnergy()
        entity.carryingResource = false
        entity.rebuildPath = true
        entity.resource = {}
        self.current_state = SeekerBehavior.seekResource
        return
    end
    entity:followPath(dt)
end

function SeekerBehavior:_findResource(entity)
    local res = entity.resourceSpawner:checkResourcesIn(entity.viewBox)
    if res == nil then
        return false, {}
    else
        return true, res
    end
end

return SeekerBehavior