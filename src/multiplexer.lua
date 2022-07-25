Multiplexer = {}

function Multiplexer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Multiplexer:eatTask(t) end

return Multiplexer
