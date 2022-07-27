require('util')
require('dispatcher')
require('task')
require('worker')

Brain = {}

function Brain.boot_cleanup()
    for i = 1, 16 do Worker.new() end
    Brain.clean_ship()
end

function Brain.boot_chest_fill()
    global.chest = game.surfaces[1].find_entities_filtered{
        name = 'wooden-chest'
    }[1]
    for _, w in ipairs(global.workers) do
        for name, count in pairs(w.entity.get_inventory(defines.inventory
                                                            .character_main)
                                     .get_contents()) do
            Worker.enqueue(w, Task.put(name, count, global.chest,
                                       defines.inventory.chest))
        end
    end
    Brain.circle()
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

function Brain.circle(c)
    c = c or 0
    for _ = 0, c do
        Brain.circle_s = (Brain.circle_s or 0) + 1
        local n = #global.workers
        for i, w in ipairs(global.workers) do
            Worker.enqueue(w, Task.walk {
                x = math.sin(((i + Brain.circle_s) / n) * 2 * math.pi) * 5 + 0.5,
                y = math.cos(((i + Brain.circle_s) / n) * 2 * math.pi) * 5 + 0.5
            })
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
    Worker.enqueue(global.workers[1], Task.mine(b_tree))
    Worker.enqueue(global.workers[1], Task.craft('wooden-chest'))
    Worker.enqueue(global.workers[1], Task.place('wooden-chest', {0, 0}))
end

function Brain.step()
    local steps = {
        [1] = Brain.boot_cleanup,
        [2] = Brain.init_storage,
        [3] = Brain.boot_chest_fill
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
