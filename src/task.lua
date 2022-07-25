Task = {}

function Task:new(o, pos, items)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.pos = pos
    o.pre_items = items
    return o
end

function Task:dependencies() end

return Task

