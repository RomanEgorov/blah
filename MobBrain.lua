local Stack = require "stack"

local MobBrain = {}
MobBrain.__index = MobBrain

setmetatable(MobBrain, {
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		-- self:_init(...)
		self.stack = Stack:Create()

		return self
	end
})

function MobBrain:_init(init)
	self.value = init
end

function MobBrain:popState()
	return self.stack:pop()
end

function MobBrain:pushState(stateFunction)
	if self:getCurrentState() ~= stateFunction then
		self.stack:push(stateFunction)
	end
end

function MobBrain:getCurrentState()
	if self.stack:getn() > 0 then
		return self.stack:head()
	else
		return nil
	end
end

function MobBrain:update(dt, entity)
	local currentStateFunction = self:getCurrentState()

	if currentStateFunction ~= nil then
		currentStateFunction(entity, dt)
	end
end

-- function MobBrain.walk(entity)


-- проверка условий для изменения для перехода состояния(входное условие?)

return MobBrain