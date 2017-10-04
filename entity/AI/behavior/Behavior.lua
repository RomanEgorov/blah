local class = require "lib.middleclass"

local Behavior = class("Behavior")

function Behavior:initialize()
    self.states_descriptors = {}
    self.current_state = nil
end

function Behavior:behave(dt, entity)
    if self.current_state ~= nil then
        self:current_state(dt, entity)
    end
end

return Behavior