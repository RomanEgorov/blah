local class = require "lib.middleclass"

local Behavior = class("Behavior")

function Behavior:initialize()
    self.states_descriptors = {}
    self.current_state = nil
end

function Behavior:behave(dt, entity)
    --
end

return Behavior