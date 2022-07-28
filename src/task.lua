require('util')
Task = {}

function Task.walk(pos) return {type = 'walk', pos = pos} end

function Task.place(item, pos, dir)
    local item_prototype = game.item_prototypes[item]
    if not item_prototype then lp('"' .. item .. '" is not valid item name') end
    if not item_prototype.place_result then
        lp('"' .. item .. '" is not placeable')
    end

    dir = dir or defines.direction.north
    return {type = 'place', pos = pos, item = item, dir = dir}
end

function Task.mine(entity)
    return {type = 'mine', pos = entity.position, entity = entity}
end

-- group can be dispatched between many workers
function Task.group(tasks) return {type = 'group', tasks = tasks} end

-- seq has to be done by the same worker in seqence
function Task.seq(tasks)
    local pos = false
    for i = #tasks, 1, -1 do -- the last task that has a position
        pos = tasks[i].pos
        if pos then break end
    end
    return {type = 'seq', tasks = tasks, pos = pos}
end

function Task.craft(item, count)
    local recipe = game.recipe_prototypes[item]
    if not recipe then lp('"' .. item .. '" is not recipe') end
    return {type = 'craft', item = item, count = count or 1}
end

function Task.put(item, count, entity, slot)
    local it = game.item_prototypes[item]
    if not it then lp('"' .. item .. '" is not item') end
    return {
        type = 'put',
        pos = entity.position,
        item = item,
        count = count,
        entity = entity,
        slot = slot
    }
end

-- TODO
-- take item

return Task

