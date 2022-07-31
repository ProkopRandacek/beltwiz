require('util')
require('log')
require('dispatcher')
Brain = require('brain')
Worker = require('worker')
Task = require('task')

local function on_load() end

local function on_init()
	global.workers = {}
	global.brain_step = 1
end

script.on_load(on_load)

script.on_init(on_init)

commands.add_command('bw-global', nil, function() li(game.table_to_json(global)) end)

commands.add_command('bw-workers', nil, function()
	for k, v in pairs(global.workers) do li(k, v) end
end)

commands.add_command('bwb-circle', nil, function() Brain.circle(10) end)

commands.add_command('bwd-come', nil, function(command)
	local p = game.get_player(command.player_index)
	local t = Task.walk(p.position)
	dispatch_task(t)
end)

commands.add_command('bw-start', nil, function()
	Brain.step()
end)

commands.add_command('waila', nil, function()
	game.print(game.players[1].selected.type)
end)

commands.add_command('bw-test', nil, function()
	lv(Brain.recipe_to_raw_items('electric-mining-drill', 1))
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
	local t = Task.walk(p.position)
	Worker.enqueue(global.workers[id], t)
end)

script.on_event(defines.events.on_tick, function()
	for _, v in pairs(global.workers) do Worker.tick(v) end
end)

script.on_event(defines.events.on_entity_died, function(e)
	for _, v in pairs(global.workers) do
		if e.entity == v.entity then
			Worker.death(v)
			break
		end
	end
end, { LuaEntityDiedEventFilter = { filter = 'name', name = 'beltwiz-character' } })
