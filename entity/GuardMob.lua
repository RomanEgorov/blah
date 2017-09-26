local class = require "lib.middleclass"

local Entity = require "entity.Entity"

local GuardMob = class("GuardMob", Entity)

function GuardMob:initialize(world, x, y)
    Entity.initialize(self, "GuardMob", world, x, y)

	self.w = 20
	self.h = 20
	self.speed = 180

	self.xDirection = 'none'
	self.yDirection = 'down'

	self.viewBox = {
		x = (self.x + self.w / 2) - 50,
		y = (self.y + self.h / 2) - 50,
		w = 100,
		h = 100
	}

	-- self.brain:pushState(GuardMob.walk)
    self.brain:pushState(GuardMob.patrol)

    self.patrolPoints = {{x = 650, y = 100}, {x = 650, y = 500}, {x = 100, y = 500}}
    self.nextPatrolPoint = self.patrolPoints[1]
    self.nextPatrolPointIndex = 1
end

function GuardMob:update(dt)
	self.brain:update(dt, self)
end

function GuardMob:patrol(dt)
    -- print("patrol()")
    if self:findPlayer() then
        self.brain:pushState(GuardMob.followThatBastard)
    end

    if self.x == self.nextPatrolPoint.x and self.y == self.nextPatrolPoint.y then
        if self.nextPatrolPointIndex == #self.patrolPoints then
            self.nextPatrolPointIndex = 1
        else
            self.nextPatrolPointIndex = self.nextPatrolPointIndex + 1
        end

        self.nextPatrolPoint = self.patrolPoints[self.nextPatrolPointIndex]

        self.pathGraph:findPath(self, {self.nextPatrolPoint.x, self.nextPatrolPoint.y})
    end

    local dx, dy = 0, 0

    if #self.pathGraph.path > 0 then
        -- print("#path > 0")

        local pointX, pointY = self.pathGraph.path[1][1], self.pathGraph.path[1][2]
        -- print(pointX, pointY)

        if #self.pathGraph.path then
            -- dx = (pointX - self.x - self.w / 2)
            -- dy = (pointY - self.y - self.h / 2)
            dx = (pointX - self.x)
            dy = (pointY - self.y)
            local dxy = (dx^2 + dy^2)^0.5
            if dxy < 10 then
                table.remove(self.pathGraph.path, 1)
                if not #self.pathGraph.path then
                    -- goToPoint = false
                    return
                end
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
    else
        -- print("path == 0")
    end

    self:move(dx, dy)
end

function GuardMob:walk(dt)
    if self:findPlayer() then
        self.brain:popState()
        self.brain:pushState(GuardMob.followThatBastard)
    end

    local dx, dy = 0, 0

    if self.y >= 500 then
        self.yDirection = 'up'
    elseif self.y <= 100 then
        self.yDirection = 'down'
    end
    if self.x < 650 then
        self.xDirection = 'right'
    elseif self.x > 650 then
        self.xDirection = 'left'
    end

    if self.xDirection == 'right' then
        dx = self.speed * dt
    elseif self.xDirection == 'left' then
        dx = -self.speed * dt
    end
    if self.yDirection == 'up' then
        dy = -self.speed * dt
    elseif self.yDirection == 'down' then
        dy = self.speed * dt
    end

    if dx ~= 0 or dy ~= 0 then
        self.x, self.y, cols, cols_len = self.world:move(self, self.x + dx, self.y + dy)
    end
end

function GuardMob:watchThatBastard(dt)
	self.viewBox.x = (self.x + self.w / 2) - 40
	self.viewBox.y = (self.y + self.h / 2) - 40
	local viewX = self.viewBox.x
	local viewY = self.viewBox.y
	local viewW = self.viewBox.w
	local viewH = self.viewBox.h

  local items, len = self.world:queryRect(viewX, viewY, viewW, viewH)
  local playerFound = false

  for _, object in ipairs(items) do
  	if object.id == "player" then
  		playerFound = true
  	end
  end

  if playerFound == false then
  		self.brain:popState()
  		self.brain:pushState(GuardMob.walk)
  end
end	

function GuardMob:followThatBastard(dt)
	self.speed = 70

	self.viewBox.x = (self.x + self.w / 2) - 40
	self.viewBox.y = (self.y + self.h / 2) - 40
	local viewX = self.viewBox.x
	local viewY = self.viewBox.y
	local viewW = self.viewBox.w
	local viewH = self.viewBox.h

  local items, len = self.world:queryRect(viewX, viewY, viewW, viewH)
  local playerFound = false
  local playerObject = {}

  for _, object in ipairs(items) do
  	if object.id == "player" then
  		playerFound = true
  		playerObject = object
  	end
  end

  if playerFound then
  	local dx, dy = 0, 0

  	if self.x - playerObject.x > 0 then
	    dx = -self.speed * dt
	  else
	    dx = self.speed * dt
	  end
	  if self.y - playerObject.y > 0 then
	    dy = -self.speed * dt
	  else
	    dy = self.speed * dt
	  end

	  if dx ~= 0 or dy ~= 0 then
	    self.x, self.y, cols, cols_len = self.world:move(self, self.x + dx, self.y + dy)
	  end
  else
  	self.brain:popState()
  	self.brain:pushState(GuardMob.walk)
  end
end

function GuardMob:findPlayer()
    self.viewBox.x = (self.x + self.w / 2) - 45
    self.viewBox.y = (self.y + self.h / 2) - 45
    local viewX = self.viewBox.x
    local viewY = self.viewBox.y
    local viewW = self.viewBox.w
    local viewH = self.viewBox.h

    local items, len = self.world:queryRect(viewX, viewY, viewW, viewH)

    for _, object in ipairs(items) do
        if object.id == "player" then
        -- print("player")
            -- self.brain:popState()
            -- self.brain:pushState(GuardMob.followThatBastard)
            return true
        end
    end

    return false
end

function GuardMob:move(dx, dy)
    if dx ~= 0 or dy ~= 0 then
        self.x, self.y, cols, cols_len = self.world:move(self, self.x + dx, self.y + dy)
    end
end

return GuardMob