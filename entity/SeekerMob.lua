local class = require "lib.middleclass"

local Entity = require "entity.Entity"

local SeekerMob = class("SeekerMob", Entity)

function SeekerMob:initialize(world, x, y)
	Entity.initialize(self, "SeekerMob", world, x, y)

	self.w = 20
	self.h = 20
	self.speed = 80

	self.viewBox = {
		x = (self.x + self.w / 2) - 50,
		y = (self.y + self.h / 2) - 50,
		w = 100,
		h = 100
	}

	self.carryingResource = false

	self.brain:pushState(SeekerMob.seekResource)
end

function SeekerMob:update(dt)
	self.brain:update(dt, self)
end

function SeekerMob:seekResource(dt) 
	self.viewBox.x = (self.x + self.w / 2) - 45
	self.viewBox.y = (self.y + self.h / 2) - 45
	local viewX = self.viewBox.x
	local viewY = self.viewBox.y
	local viewW = self.viewBox.w
	local viewH = self.viewBox.h

  	local items, len = self.world:queryRect(viewX, viewY, viewW, viewH)

  	for _, object in ipairs(items) do
  		if object.id == "resource" then
  		-- print("player")
  		self.brain:popState()
  		self.brain:pushState(SeekerMob.grabResource)
  		end
  	end

  	local dx, dy = self:_randomNavigation(dt)

  	if dx ~= 0 or dy ~= 0 then
  	  	self.x, self.y, cols, cols_len = self.world:move(self, self.x + dx, self.y + dy)
  	end
end

function SeekerMob:grabResource(dt)
	print("SeekerMob:grabResource()")
end

function SeekerMob:returnResouce(dt)

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

return SeekerMob