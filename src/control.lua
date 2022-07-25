require('util')
require('log')
require('dispatcher')
Worker = require('worker')
Task = require('task')

function on_load() end

function on_init() global.workers = {} end

script.on_load(on_load)

script.on_init(on_init)

commands.add_command("bw-global", nil,
                     function(command) li(game.table_to_json(global)) end)
commands.add_command("bw-spawn", nil, function(command) li(Worker.new()) end)

commands.add_command("bw-workers", nil, function(command)
    for k, v in pairs(global.workers) do li(k, v) end
end)

commands.add_command("bwd-come", nil, function(command)
    local p = game.get_player(command.player_index)
    t = Task.walk(p.position)
    dispatch_task(t)
end)

commands.add_command("bww-come", nil, function(command)
    local p = game.get_player(command.player_index)
    local id = tonumber(command.parameter)
    if not id then
        game.print('argument "' .. (command.parameter or "") ..
                       '" is not numeric')
        return
    end
    local worker = global.workers[id]
    if not worker then
        game.print('id ' .. tostring(id) .. ' is not valid worker id')
        return
    end
    t = Task.walk(p.position)
    Worker.enqueue(global.workers[id], t)
end)

script.on_event(defines.events.on_tick, function()
    for k, v in pairs(global.workers) do Worker.tick(v) end
end)

script.on_event(defines.events.on_entity_died, function(e)
    for k, v in pairs(global.workers) do
        if e.entity == v.entity then
            Worker.death(v)
            break
        end
    end
end, {LuaEntityDiedEventFilter = {filter = "name", name = "beltwiz-character"}})

