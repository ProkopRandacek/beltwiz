Task = {}

function Task.walk(pos) return {type = "walk", pos = pos} end

function Task.place(item, pos, dir)
    return {type = "place", pos = entity.position, item = item, direction = dir}
end

function Task.mine(entity)
    return {type = "mine", pos = entity.position, entity = entity}
end

-- TODO
-- take item
-- put item

return Task

