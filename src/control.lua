require('util')
require('log')
Worker = require('worker')
Task = require('task')
Multiplexer = require('multiplexer')

function on_load() end

function on_init() global.workers = {} end

script.on_load(on_load)

script.on_init(on_init)

commands.add_command("bw-global", nil,
                     function(command) li(game.table_to_json(global)) end)
commands.add_command("bw-spawn", nil, function(command) li(Worker:new()) end)

commands.add_command("bw-workers", nil, function(command)
    for k, v in pairs(global.workers) do li(k, v) end
end)

commands.add_command("bww-come", nil, function(command)
    local p = game.get_player(command.player_index)
    local id = tonumber(command.parameter)
    t = Task:new({}, p.position)
    global.workers[id]:enqueue(t)
end)

script.on_event(defines.events.on_tick, function()
    for k, v in pairs(global.workers) do v:tick() end
end)

script.on_event(defines.events.on_entity_died, function(e)
    for k, v in pairs(global.workers) do
        if e.entity == v.entity then
            v:death()
            break
        end
    end
end, {LuaEntityDiedEventFilter = {filter = "name", name = "beltwiz-character"}})

