require('util')
require('dispatcher')
require('task')
require('worker')

Brain = {}

function Brain.init()
    Brain.spawn_bots(16)
    Brain.init_storage()
    Brain.clean_ship()
    Brain.circle()
end

function Brain.spawn_bots(n) for i = 1, n do Worker.new() end end

function Brain.clean_ship()
    for _, e in ipairs(game.surfaces[1].find_entities_filtered {
        type = {'container', 'simple-entity-with-owner'}
    }) do dispatch_task(Task.mine(e)) end
end

function Brain.circle(c)
    c = c or 0
    for _ = 0, c do
        Brain.circle_s = (Brain.circle_s or 0) + 1
        local n = #global.workers
        for i, w in ipairs(global.workers) do
            Worker.enqueue(w, Task.walk {
                x = math.sin(((i + Brain.circle_s) / n) * 2 * math.pi) * 10 + 10,
                y = math.cos(((i + Brain.circle_s) / n) * 2 * math.pi) * 10 + 10
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
    Worker.enqueue(global.workers[1], Task.place('wooden-chest', {10, 10}))
end

return Brain
