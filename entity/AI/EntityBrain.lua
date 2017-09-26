local class = require "lib.middleclass"
local Stack = require "lib.Stack"

local EntityBrain = class("EntityBrain")

function EntityBrain:initialize()
	self.stack = Stack:Create()
end

function EntityBrain:popState()
	return self.stack:pop()
end

function EntityBrain:pushState(stateFunction)
	if self:getCurrentState() ~= stateFunction then
		self.stack:push(stateFunction)
	end
end

function EntityBrain:getCurrentState()
	if self.stack:getn() > 0 then
		return self.stack:head()
	else
		return nil
	end
end

function EntityBrain:update(dt, entity)
	local currentStateFunction = self:getCurrentState()

	if currentStateFunction ~= nil then
		currentStateFunction(entity, dt)
	end
end

return EntityBrain