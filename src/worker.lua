require('util')
require('log')

Worker = {}

function Worker.new()
    local self = {}

    self.entity = game.surfaces[1].create_entity {
        name = 'beltwiz-character',
        position = {0, 0},
        direction = 3,
        force = 'player'
    }
    self.entity.insert({name = 'burner-mining-drill', count = 1}) -- the starting inventory
    self.entity.insert({name = 'stone-furnace', count = 1})
    self.entity.color = {r = 103 / 255, g = 176 / 255, b = 232 / 255}

    self.active_task = false
    self.queue = {}
    self.dead = false
    self.pos_acc = self.entity.position
    self.time_acc = game.tick
    self.crafting = false

    self.mining = false
    self.last_mine_progress = 2

    self.index = #global.workers

    self.tag = self.entity.force.add_chart_tag(game.surfaces[1], {
        position = self.entity.position,
        text = tostring(self.index),
        icon = {type = 'virtual', name = 'signal-dot'}
    })

    table.insert(global.workers, self)

    return self
end

function Worker.enqueue(self, task)
    front = front or false
    local time_cost = Worker.relative_task_price(self, task)
    self.time_acc = self.time_acc + time_cost
    self.pos_acc = task.pos or {0, 0}
    table.insert(self.queue, task)
end

function Worker.death(self, e)
    self.dead = true
    li('Worker died')
end

function Worker.predict_travel_time(self, pos, pos_override)
    if not pos then return 0 end
    local self_pos = pos_override or self.pos_acc
    local x1, y1 = self_pos.x or self_pos[1], self_pos.y or self_pos[2]
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

function Worker.predict_mine_time(self, entity)
    local mining_speed = entity.prototype.mineable_properties.mining_time
    local mining_time = self.entity.prototype.mining_speed
    return (mining_speed / mining_time) * 60
end

function Worker.predict_craft_time(self, item)
    local craft_speed = 1
    local recipe = game.recipe_prototypes[item]
    local craft_time = recipe.energy
    return (craft_time / craft_speed) * 60
end

function Worker.relative_single_task_price(self, task, pos_override)
    local t = 0.0
    t = t + Worker.predict_travel_time(self, task.pos, pos_override)
    if task.type == 'craft' then
        t = t + Worker.predict_craft_time(self, task.item)
    elseif task.type == 'mine' then
        t = t + Worker.predict_mine_time(self, task.entity)
    end
    return t
end

function Worker.relative_task_price(self, task, pos_override)
    if task.type == 'seq' then
        local t = 0
        local pos_ac = pos_override
        for i, st in ipairs(task.tasks) do
            t = t + Worker.relative_task_price(self, st, pos_ac)
            pos_ac = st.pos or pos_ac
        end
        return t
    else
        return Worker.relative_single_task_price(self, task, pos_override)
    end
end

function Worker.absolute_task_price(self, task)
    local time_base = math.max(self.time_acc, game.tick)
    return time_base + Worker.relative_task_price(self, task)
end

function Worker.prepare_task(self)
    if not self.active_task then return false end
    if not self.active_task.pos then return true end -- can be done anywhere
    if self.active_task.type == 'seq' then return true end

    local distance = dist(self.entity.position, self.active_task.pos)
    local too_far = distance > 0.3
    self.entity.walking_state = {
        walking = too_far,
        direction = dir(self.entity.position, self.active_task.pos)
    }
    if not too_far then self.entity.teleport(self.active_task.pos) end

    return not too_far
end

function Worker.place(self, item, pos, dir)
    local item_count = self.entity.get_inventory(defines.inventory
                                                     .character_main)
                           .get_item_count(item)
    if item_count < 1 then
        lp('Trying to place', item,
           'but worker doesn\'t have it in his inventory')
    end

    local surface = game.surfaces[1]
    if surface.can_place_entity {name = item, position = pos, direction = dir} then
        if surface.create_entity {
            name = item,
            position = pos,
            direction = dir,
            force = 'player',
            move_stuck_players = true
        } then self.entity.remove_item({name = item, count = 1}) end
    else
        lp('cannot place', item, 'at', pos)
    end
    return true
end

function Worker.mine(self, entity)
    if not self.mining then -- start mining
        self.last_mine_progress = 0
        if not (entity and entity.valid) then
            le('entity gone!')
            return true
        end
        self.entity.selected = entity
        self.entity.mining_state = {mining = true, position = entity.position}
        self.mining = true
        return false
    else -- keep mining
        local curr_mine_progress = self.entity.character_mining_progress
        if curr_mine_progress > self.last_mine_progress and curr_mine_progress ~=
            0 then
            self.last_mine_progress = curr_mine_progress
            self.entity.selected = entity
            self.entity.mining_state = {
                mining = true,
                position = entity.position
            }
            return false
        else -- mine done
            self.entity.mining_state = {mining = false}
            self.mining = false
            return true
        end
    end
end

function Worker.craft(self, item, count)
    if not self.crafting then -- start crafting
        local c = self.entity.begin_crafting {recipe = item, count = count}
        if c ~= count then
            lp('wanted to craft', item, count, 'times but can only', c)
        end
        self.crafting = true
        return false
    else -- wait until it is done
        if self.entity.crafting_queue_progress > 0 then
            return false
        else
            self.crafting = false
            return true
        end
    end
end

function Worker.put(self, item, count, entity, slot)
    local selfinv = self.entity.get_inventory(defines.inventory.character_main)
    local trginv = entity.get_inventory(slot)

    local c = selfinv.get_item_count(item)
    if c < count then lp('cant put', count, 'of', item, '. I only have', c) end
    self.entity.selected = entity
    self.entity.remove_item {name = item, count = count}
    entity.get_inventory(slot).insert {name = item, count = count}
    return true
end

function Worker.do_task(self)
    local t = self.active_task
    local tt = t.type

    if tt == 'place' then
        return Worker.place(self, t.item, t.pos, t.dir)
    elseif tt == 'mine' then
        return Worker.mine(self, t.entity)
    elseif tt == 'craft' then
        return Worker.craft(self, t.item, t.count)
    elseif tt == 'put' then
        return Worker.put(self, t.item, t.count, t.entity, t.slot)
    elseif tt == 'walk' then
        return true
    elseif tt == 'seq' then
        for i = #t.tasks, 1, -1 do
            table.insert(self.queue, 1, t.tasks[i])
        end
        return true
    else
        lp('invalid task type: ', tt)
    end
end

function Worker.is_idle(self)
    return (not self.active_task) and (not self.queue[1])
end

function Worker.tick(self)
    if self.dead then return end

    if not self.active_task then
        if self.queue[1] then
            self.active_task = table.remove(self.queue, 1)
        else
            Brain.on_worker_queue_done()
        end
    else
        if not Worker.prepare_task(self) then
            -- waiting for task preparation
        else
            local done = Worker.do_task(self)
            if done then self.active_task = false end
        end
    end

    local b = self.entity
    local r = settings.global['worker-chart-radius'].value
    b.force.chart(b.surface, {
        {b.position.x - r, b.position.y - r},
        {b.position.x + r, b.position.y + r}
    })

    self.tag.destroy()
    self.tag = self.entity.force.add_chart_tag(game.surfaces[1], {
        position = self.entity.position,
        text = tostring(self.index),
        icon = {type = 'virtual', name = 'signal-dot'}
    })
end

return Worker

