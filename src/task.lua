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

function Task.group(tasks)
    return {type = 'group', tasks = tasks}
end

-- TODO
-- take item
-- put item

return Task

