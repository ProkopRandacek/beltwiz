require('util')

function bwlog(level, ...)
    line = 'bw' .. level .. ': '
    for i, v in ipairs({...}) do
        if type(v) == 'table' then v = game.table_to_json(v) end
        line = line .. '\t' .. tostring(v)
    end
    game.print(line)
    print(line)
end

function le(...) bwlog('err', table.unpack({...})) end
function lw(...) bwlog('war', table.unpack({...})) end
function li(...) bwlog('inf', table.unpack({...})) end
function lv(...) bwlog('ver', table.unpack({...})) end

