function dist(pos1, pos2)
    local x1 = pos1.x or pos1[1]
    local y1 = pos1.y or pos1[2]
    local x2 = pos2.x or pos2[1]
    local y2 = pos2.y or pos2[2]
    return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
end

function dir(a, b)
    local x1 = a.x or a[1]
    local y1 = a.y or a[2]
    local x2 = b.x or b[1]
    local y2 = b.y or b[2]

    local delta_x = x2 - x1
    local delta_y = y2 - y1

    local eps = 0.2

    if delta_x > eps then
        if delta_y > eps then
            return defines.direction.southeast
        elseif delta_y < -eps then
            return defines.direction.northeast
        else
            return defines.direction.east
        end
    elseif delta_x < -eps then
        if delta_y > eps then
            return defines.direction.southwest
        elseif delta_y < -eps then
            return defines.direction.northwest
        else
            return defines.direction.west
        end
    else
        if delta_y > eps then
            return defines.direction.south
        elseif delta_y < -eps then
            return defines.direction.north
        else
            return defines.direction.north
        end
    end
end

