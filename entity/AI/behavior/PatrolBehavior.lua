local class = require "lib.middleclass"
local Behavior = require "entity.AI.behavior.Behavior"

local PatrolBehavior = class("PatrolBehavior")

function PatrolBehavior:initialize(patrolPoints)
    Behavior.initialize(self)
    self.patrolPoints = patrolPoints
    self.nextPatrolPoint = self.patrolPoints[1]
    self.nextPatrolPointIndex = 1
    self.states_descriptors = {}
    self.states_descriptors[PatrolBehavior.patrol] = {priority = 1, dependencies = {'move'} }
    self.current_state = PatrolBehavior.patrol
end

function PatrolBehavior:behave(dt, entity)
    Behavior.behave(self, dt, entity)
end

function PatrolBehavior:patrol(dt, entity)
    entity.speed = 180

    if entity.rebuildPath then
        entity.pathGraph:buildPath(entity, self.nextPatrolPoint)
        entity.rebuildPath = false
    end

    local centerX, centerY = entity:getCenterCoords()
    local dx = self.nextPatrolPoint.x - centerX
    local dy = self.nextPatrolPoint.y - centerY
    local dxy = (dx^2 + dy^2)^0.5

    -- Проверка перехода к следующей точке патрулируемого маршрута
    if dxy < 5 then
        if self.nextPatrolPointIndex == #self.patrolPoints then
            self.nextPatrolPointIndex = 1
        else
            self.nextPatrolPointIndex = self.nextPatrolPointIndex + 1
        end
        self.nextPatrolPoint = self.patrolPoints[self.nextPatrolPointIndex]
        entity.pathGraph:buildPath(entity, self.nextPatrolPoint)
    end

    -- Движение по промежуточному маршруту от одной патрулируемой точки к другой
    if #entity.pathGraph.path > 0 then
        local pointX, pointY = entity.pathGraph.path[1][1], entity.pathGraph.path[1][2]

        if #entity.pathGraph.path then
            dx = pointX - centerX
            dy = pointY - centerY
            dxy = (dx^2 + dy^2)^0.5

            if dxy < 5 then
                table.remove(entity.pathGraph.path, 1)
            else
                dx = dx / dxy
                dy = dy / dxy
                if entity.speed * dt < dxy then
                    dxy = entity.speed * dt
                end
                dx = dx * dxy
                dy = dy * dxy
            end
        end
    end

    entity:move(dx, dy)
end

return PatrolBehavior