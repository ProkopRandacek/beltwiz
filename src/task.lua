Task = {}

function Task.new(self, pos, items)
    self = self or {}
    self.pos = pos
    self.pre_items = items
    return self
end

function Task.dependencies(self) end

return Task

