require('util')
require('log')

Worker = {}

function Worker.new()
    local self = {}

    self.entity = game.surfaces[1].create_entity {
        name = "beltwiz-character",
        position = {0, 0},
        direction = 3,
        force = "player",
        fast_replace = true
    }
    self.entity.insert({name = "burner-mining-drill", count = 1}) -- the starting inventory
    self.entity.insert({name = "stone-furnace", count = 1})
    self.entity.color = {r = 103 / 255, g = 176 / 255, b = 232 / 255}

    self.active_task = false
    self.queue = {}
    self.dead = false
    self.pos_acc = self.entity.position
    self.time_acc = game.tick

    table.insert(global.workers, self)
    self.index = #global.workers

    return self
end

function Worker.enqueue(self, task)
    local time_cost = Worker.relative_task_price(self, task)
    self.time_acc = self.time_acc + time_cost
    self.pos_acc = task.pos
    lv('New acc state', self.time_acc, self.pos_acc)
    table.insert(self.queue, task)
end

function Worker.death(self, e)
    self.dead = true
    li('Worker died')
end

function Worker.predict_travel_time(self, pos)
    local x1, y1 = self.pos_acc.x or self.pos_acc[1],
                   self.pos_acc.y or self.pos_acc[2]
    local x2, y2 = pos.x or pos[1], pos.y or pos[2]
    local dx = math.abs(x1 - x2)
    local dy = math.abs(y1 - y2)
    local shorter_side = math.min(dx, dy)
    local longer_side = math.max(dx, dy)
    local diagonal_path = math.sqrt((shorter_side ^ 2) * 2)
    local straight_path = longer_side - shorter_side
    local path = diagonal_path + straight_path
    local time = path / self.entity.character_running_speed
    return time
end

function Worker.predict_mine_time(self, entity) return 0 end

function Worker.relative_task_price(self, task)
    return Worker.predict_travel_time(self, task.pos)
end

function Worker.absolute_task_price(self, task)
    return math.max(self.time_acc, game.tick) +
               Worker.relative_task_price(self, task)
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
            -- do task
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

