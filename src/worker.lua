require('util')
require('log')

Worker = {}

function Worker:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.entity = game.surfaces[1].create_entity {
        name = "beltwiz-character",
        position = {0, 0},
        direction = 3,
        force = "player",
        fast_replace = true
    }
    o.entity.insert({name = "burner-mining-drill", count = 1}) -- the starting inventory
    o.entity.insert({name = "stone-furnace", count = 1})
    o.entity.color = {r = 103 / 255, g = 176 / 255, b = 232 / 255}

    o.queue = {}
    o.dead = false

    table.insert(global.workers, o)

    return o
end

function Worker:enqueue(task) table.insert(self.queue, task) end

function Worker:death(e)
    self.dead = true
    li("Worker died")
end

function Worker:tick()
    if self.dead then return end
    self.entity.walking_state = {
        walking = true,
        direction = defines.direction.southwest
    }
    local b = self.entity
    local r = settings.global["worker-chart-radius"].value
    b.force.chart(b.surface, {
        {b.position.x - r, b.position.y - r},
        {b.position.x + r, b.position.y + r}
    })
end

return Worker

