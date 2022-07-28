require('util')
require('dispatcher')
require('task')
require('worker')

Brain = {}

function Brain.boot1()
    for i = 1, 16 do Worker.new() end
    Brain.clean_ship()
    Brain.init_storage()
end

function Brain.clean_ship()
    for _, e in ipairs(game.surfaces[1].find_entities_filtered {
        type = {'container', 'simple-entity-with-owner'}
    }) do dispatch_task(Task.mine(e)) end
    for _, e in ipairs(game.surfaces[1].find_entities_filtered {
        position = {0, 0},
        radius = 10
    }) do
        if e.prototype.mineable_properties.minable then
            dispatch_task(Task.mine(e))
        end
    end
end

function Brain.init_storage()
    local surface = game.surfaces[1]
    local rad = 2
    local b_tree = false
    local b_dist = 999999
    while not b_tree do
        rad = rad * 2
        for _, e in pairs(surface.find_entities_filtered {
            position = {0, 0},
            radius = rad,
            type = 'tree'
        }) do
            local dst = dist(e.position, {0, 0})
            if dst < b_dist then
                b_tree = e
                b_dist = dst
            end
        end
    end
    dispatch_task(Task.seq {
        [1] = Task.mine(b_tree),
        [2] = Task.craft('wooden-chest'),
        [3] = Task.place('wooden-chest', {0, 0})
    })
end

function Brain.boot2()
    global.chest = game.surfaces[1].find_entities_filtered{
        name = 'wooden-chest'
    }[1]
    Brain.dump_workers()
    Brain.circle()
end

function Brain.dump_workers()
    for _, w in ipairs(global.workers) do
        for name, count in pairs(w.entity.get_inventory(defines.inventory
                                                            .character_main)
                                     .get_contents()) do
            local t = Task.put(name, count, global.chest,
                               defines.inventory.chest)
            Worker.enqueue(w, t)
        end
    end
end

function Brain.circle(c)
    c = c or 0
    for _ = 0, c do
        Brain.circle_s = (Brain.circle_s or 0) + 1
        local n = #global.workers
        for i, w in ipairs(global.workers) do
            Worker.enqueue(w, Task.walk {
                x = math.sin(((i + Brain.circle_s) / n) * 2 * math.pi) * 2 + 0.5,
                y = math.cos(((i + Brain.circle_s) / n) * 2 * math.pi) * 2 + 0.5
            })
        end
    end
end

function Brain.electricity()
    local target_items = {
        ['steam-engine'] = 1,
        ['boiler'] = 1,
        ['offshore-pump'] = 1
    }

    local raw_items = {}
    for r, a in pairs(target_items) do
        for k, v in pairs(Brain.recipe_to_raw_items(game.recipe_prototypes[r])) do
            raw_items[k] = (raw_items[k] or 0) + v * a
        end
    end
    for item, amount in pairs(raw_items) do Brain.gather(item, amount) end
end

function Brain.recipe_to_raw_items(recipe)
    local ings = recipe.ingredients
    local raw = {}
    for _, ing in ipairs(ings) do
        local ingprot = game.recipe_prototypes[ing.name]
        if ingprot and ingprot.allow_decomposition then
            for k, v in pairs(Brain.recipe_to_raw_items(ingprot)) do
                raw[k] = (raw[k] or 0) + v * ing.amount
            end
        else
            raw[ing.name] = (raw[ing.name] or 0) + ing.amount
        end
    end
    return raw
end

function Brain.gather(ore, amount)
    local ores = game.surfaces[1].find_entities_filtered {name = ore}
    table.sort(ores, function(a, b)
        return dist(a.position, {0, 0}) < dist(b.position, {0, 0})
    end)
    for i, e in ipairs(ores) do
        local can_mine = math.min(e.amount, amount)
        for i = 1, can_mine do dispatch_task(Task.mine(e)) end
        amount = amount - can_mine
        if amount == 0 then break end
    end
end

function Brain.step()
    local steps = {
        [1] = Brain.boot1,
        [2] = Brain.boot2,
        [3] = Brain.electricity,
        [4] = Brain.dump_workers,
        [5] = Brain.circle
    }
    (steps[global.brain_step] or function() end)()
    global.brain_step = global.brain_step + 1
end

function Brain.on_worker_queue_done()
    for i, w in ipairs(global.workers) do
        if not Worker.is_idle(w) then return end
    end
    Brain.step()
end

return Brain
