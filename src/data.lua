local bwc = table.deepcopy(data.raw["character"]["character"])
bwc.name = "beltwiz-character"
bwc.collision_mask = {}

data:extend{bwc}

