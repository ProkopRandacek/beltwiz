require('util')
require('log')

Worker = {}

function Worker.new(o)
    local o = o or {}

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

    o.active_task = false
    o.queue = {}
    o.dead = false

    table.insert(global.workers, o)

    return o
end

function Worker.enqueue(self, task)
    local travel_time = Worker.predict_walk_time(self, task.pos)
    li("I will be there in " .. travel_time .. "s")
    table.insert(self.queue, task)
end

function Worker.death(self, e)
    self.dead = true
    li('Worker died')
end

function Worker.predict_walk_time(self, pos)
    local x1, y1 = self.entity.position.x, self.entity.position.y
    local x2, y2 = pos.x or pos[1], pos.y or pos[2]
    local dx = math.abs(x1 - x2)
    local dy = math.abs(y1 - y2)
    local shorter_side = math.min(dx, dy)
    local longer_side = math.max(dx, dy)
    local diagonal_path = math.sqrt((shorter_side ^ 2) * 2)
    local straight_path = longer_side - shorter_side
    local path = diagonal_path + straight_path
    local speed = self.entity.character_running_speed * 60 -- tiles per second
    local time = path / speed
    return time
end

function Worker.prepare_task(self)
    if not self.active_task then return false end

    local distance = dist(self.entity.position, self.active_task.pos)
    local too_far = distance > 1
    self.entity.walking_state = {
        walking = too_far,
        direction = dir(self.entity.position, self.active_task.pos)
    }

    return not too_far
end

function Worker.tick(self)
    if self.dead then return end

    if not self.active_task then
        if self.queue[1] then
            self.active_task = table.remove(self.queue, 1)
        end
    else
        if not Worker.prepare_task(self) then
            -- waiting for task preparation
        else
            self.active_task = false
        end
    end

    local b = self.entity
    local r = settings.global['worker-chart-radius'].value
    b.force.chart(b.surface, {
        {b.position.x - r, b.position.y - r},
        {b.position.x + r, b.position.y + r}
    })
end

return Worker

