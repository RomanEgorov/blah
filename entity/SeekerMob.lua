local class = require "lib.middleclass"

local Entity = require "entity.Entity"

local SeekerMob = class("SeekerMob", Entity)

function SeekerMob:initialize(world, x, y)
	Entity.initialize(self, "SeekerMob", world, x, y)

    self.resourceSpawner = nil

    self.drawColor = {r = 255, g = 0, b = 255}

	self.w = 20
	self.h = 20
	self.speed = 100

	self.viewBox = {
		x = (self.x + self.w / 2) - 50,
		y = (self.y + self.h / 2) - 50,
		w = 100,
		h = 100
	}

    self.colonyBase = {}

	self.carryingResource = false
    self.resource = {}

    self.patrolPoints = {{x = 650, y = 100}, {x = 650, y = 500}, {x = 60, y = 350}}
    self.nextPatrolPoint = self.patrolPoints[1]
    self.nextPatrolPointIndex = 1
    self.rebuildPath = true -- костыль

	self.brain:pushState(SeekerMob.seekResource)
end

function SeekerMob:update(dt)
	self.brain:update(dt, self)
end

function SeekerMob:seekResource(dt) 
    local resourceFound, resource = self:_findResource()

    if resourceFound then
        -- self.rebuildPath = true
        -- self.brain:pushState(GuardMob.followThatBastard)

        self.resource = resource

        self.brain:popState()
        self.brain:pushState(SeekerMob.grabResource)

        return
    end

    if self.rebuildPath then
        self.pathGraph:findPath(self, {self.nextPatrolPoint.x, self.nextPatrolPoint.y})
        self.rebuildPath = false
    end

    local dx, dy = 0, 0
    local dxy = 0

    dx = self.nextPatrolPoint.x - (self.x + self.w / 2)
    dy = self.nextPatrolPoint.y - (self.y + self.h / 2)
    dxy = (dx^2 + dy^2)^0.5

    if dxy < 5 then
        if self.nextPatrolPointIndex == #self.patrolPoints then
            self.nextPatrolPointIndex = 1
        else
            self.nextPatrolPointIndex = self.nextPatrolPointIndex + 1
        end

        self.nextPatrolPoint = self.patrolPoints[self.nextPatrolPointIndex]

        self.pathGraph:findPath(self, {self.nextPatrolPoint.x, self.nextPatrolPoint.y})
    end

    if #self.pathGraph.path > 0 then
        local pointX, pointY = self.pathGraph.path[1][1], self.pathGraph.path[1][2]

        if #self.pathGraph.path then
            dx = pointX - (self.x + self.w / 2)
            dy = pointY - (self.y + self.h / 2)
            dxy = (dx^2 + dy^2)^0.5
            
            if dxy < 5 then
                table.remove(self.pathGraph.path, 1)
            else
                dx = dx / dxy
                dy = dy / dxy
                if self.speed * dt < dxy then
                    dxy = self.speed * dt
                end
                dx = dx * dxy
                dy = dy * dxy
            end
        end
    end

    self:move(dx, dy)
end

function SeekerMob:grabResource(dt)
	-- print("SeekerMob:grabResource()")

    -- print(self.resource.x, self.resource.y)
    if self:moveTo(self.resource, dt) > 2 then
        -- print("moving to")
    else
        -- print("stop")
        self.carryingResource = true

        -- local items, len = self.world:queryRect(self.resource.x, self.resource.y, self.resource.w, self.resource.h)

        -- if len > 0 then
        --     for _, item in ipairs(items) do
        --         if item.id == "resource" then
        --             self.world:remove(item)
        --             resources[item.resourceId] = nil

        --         end
        --     end
        -- end

        self.resourceSpawner:removeResource(self.resource)

        self.brain:popState()
        self.rebuildPath = true
        self.brain:pushState(SeekerMob.returnResouce)
    end
end

function SeekerMob:returnResouce(dt)
    -- print("SeekerMob:returnResouce")

    local centerX, centerY = self:getCenterCoords()
    local dx = self.colonyBase.x - centerX
    local dy = self.colonyBase.y - centerY
    local dxy = (dx^2 + dy^2)^0.5

    if dxy < 40 then
        self.colonyBase:addEnergy()
        self.carryingResource = false
        self.rebuildPath = true
        self.brain:popState()
        self.brain:pushState(SeekerMob.seekResource)

        return
    end

    -- print("base coords: ", self.colonyBaseCoords.x, self.colonyBaseCoords.y)
    if self.rebuildPath then
        self.rebuildPath = false
        self.pathGraph:findPath(self, {self.colonyBase.x, self.colonyBase.y})
    end

    self:followPath(dt)
end

function SeekerMob:fleeToBase(dt)
-- координаты базы?
end

function SeekerMob:_randomNavigation(dt)
  	local xRand = math.random(1, 90)
  	local yRand = math.random(1, 90)
  	local dx, dy = 0, 0

  	if xRand > 0 and xRand < 31 then
  		dx = self.speed * dt
  	elseif xRand > 30 and xRand < 61 then
  		dx = -self.speed * dt
  	end
  	if yRand > 0 and xRand < 31 then
  		dy = -self.speed * dt
  	elseif yRand > 30 and xRand < 61 then
  		dy = self.speed * dt
  	end

  	return dx, dy
end

function SeekerMob:_findResource()
    self.viewBox.x = (self.x + self.w / 2) - 45
    self.viewBox.y = (self.y + self.h / 2) - 45

    local res = self.resourceSpawner:checkResourcesIn(self.viewBox)

    if res == nil then
        return false, {}
    else
        return true, res
    end
end

return SeekerMob