require('util')
require('log')
require('dispatcher')
Brain = require('brain')
Worker = require('worker')
Task = require('task')

function on_load() end

function on_init()
    global.workers = {}
    global.brain_step = 1
end

script.on_load(on_load)

script.on_init(on_init)

commands.add_command('bw-global', nil,
                     function(command) li(game.table_to_json(global)) end)

commands.add_command('bw-workers', nil, function(command)
    for k, v in pairs(global.workers) do li(k, v) end
end)

commands.add_command('bwb-circle', nil, function(command) Brain.circle(10) end)

commands.add_command('bwd-come', nil, function(command)
    local p = game.get_player(command.player_index)
    local t = Task.walk(p.position)
    dispatch_task(t)
end)

commands.add_command('bw-start', nil, function(command) Brain.step() end)

commands.add_command('waila', nil, function(command)
    game.print(game.players[1].selected.type)
end)

commands.add_command('bw-test', nil, function(command)
    lv(Brain.recipe_to_raw_items(game.recipe_prototypes['steam-engine']))
    lv(Brain.recipe_to_raw_items(game.recipe_prototypes['boiler']))
    lv(Brain.recipe_to_raw_items(game.recipe_prototypes['offshore-pump']))
end)

commands.add_command('bww-come', nil, function(command)
    local p = game.get_player(command.player_index)
    local id = tonumber(command.parameter)
    if not id then
        le('argument', command.parameter, '" is not numeric')
        return
    end
    local worker = global.workers[id]
    if not worker then
        le('id ', id, ' is not valid worker id')
        return
    end
    t = Task.walk(p.position)
    Worker.enqueue(global.workers[id], t)
end)

script.on_event(defines.events.on_tick, function()
    for _, v in pairs(global.workers) do Worker.tick(v) end
end)

script.on_event(defines.events.on_entity_died, function(e)
    for k, v in pairs(global.workers) do
        if e.entity == v.entity then
            Worker.death(v)
            break
        end
    end
end, {LuaEntityDiedEventFilter = {filter = 'name', name = 'beltwiz-character'}})

