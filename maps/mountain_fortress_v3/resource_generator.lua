local Functions = require 'maps.mountain_fortress_v3.functions'

local types = {
    'assembling-machine',
    'furnace'
}

local science_loot = {
    {
        stack = {
            recipe = 'automation-science-pack',
            output = {item = 'automation-science-pack', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 5 / 60 / 512}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'logistic-science-pack',
            output = {item = 'logistic-science-pack', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 15 / 60 / 512}
        },
        weight = 2
    },
    {
        stack = {
            recipe = 'military-science-pack',
            output = {item = 'military-science-pack', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 25 / 60 / 512}
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'chemical-science-pack',
            output = {item = 'chemical-science-pack', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 33 / 60 / 512}
        },
        weight = 0.20
    },
    {
        stack = {
            recipe = 'production-science-pack',
            output = {item = 'production-science-pack', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 45 / 60 / 512}
        },
        weight = 0.10
    },
    {
        stack = {
            recipe = 'utility-science-pack',
            output = {item = 'utility-science-pack', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 55 / 60 / 512}
        },
        weight = 0.010
    }
}

local ammo_loot = {
    {
        stack = {
            recipe = 'piercing-rounds-magazine',
            output = {item = 'piercing-rounds-magazine', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 10 / 60 / 512}
        },
        weight = 1
    },
    {
        stack = {
            recipe = 'firearm-magazine',
            output = {item = 'firearm-magazine', min_rate = 1 / 4 / 60, distance_factor = 1 / 4 / 60 / 512}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'shotgun-shell',
            output = {item = 'shotgun-shell', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 6 / 60 / 512}
        },
        weight = 4
    },
    {
        stack = {
            recipe = 'uranium-rounds-magazine',
            output = {item = 'uranium-rounds-magazine', min_rate = 0.1 / 8 / 60, distance_factor = 1 / 25 / 60 / 512}
        },
        weight = 0.25
    }
}

local resource_loot = {
    {
        stack = {
            recipe = 'stone-wall',
            output = {item = 'stone-wall', min_rate = 1 / 4 / 60, distance_factor = 1 / 8 / 60 / 512}
        },
        weight = 2
    },
    {
        stack = {
            recipe = 'iron-gear-wheel',
            output = {item = 'iron-gear-wheel', min_rate = 1 / 4 / 60, distance_factor = 1 / 6 / 60 / 512}
        },
        weight = 3
    }
}

local furnace_loot = {
    {
        stack = {
            furance_item = 'iron-plate',
            output = {item = 'iron-plate', min_rate = 1 / 4 / 60, distance_factor = 1 / 6 / 60 / 512}
        },
        weight = 4
    },
    {
        stack = {
            furance_item = 'copper-plate',
            output = {item = 'copper-plate', min_rate = 1 / 4 / 60, distance_factor = 1 / 6 / 60 / 512}
        },
        weight = 4
    },
    {
        stack = {
            furance_item = 'steel-plate',
            output = {item = 'steel-plate', min_rate = 0.5 / 8 / 60, distance_factor = 1 / 25 / 60 / 512}
        },
        weight = 1
    }
}

local science_weights = Functions.prepare_weighted_loot(science_loot)
local building_weights = Functions.prepare_weighted_loot(ammo_loot)
local resource_weights = Functions.prepare_weighted_loot(resource_loot)
local furnace_weights = Functions.prepare_weighted_loot(furnace_loot)

local science_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = science_loot,
        weights = science_weights
    }
}

local building_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = ammo_loot,
        weights = building_weights
    }
}

local resource_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = resource_loot,
        weights = resource_weights
    }
}

local furnace_callback = {
    callback = Functions.magic_item_crafting_callback_weighted,
    data = {
        loot = furnace_loot,
        weights = furnace_weights
    }
}

local science_list = {
    [1] = {name = 'assembling-machine-1', callback = science_callback},
    [2] = {name = 'assembling-machine-2', callback = science_callback},
    [3] = {name = 'assembling-machine-3', callback = science_callback}
}

local ammo_list = {
    [1] = {name = 'assembling-machine-1', callback = building_callback},
    [2] = {name = 'assembling-machine-2', callback = building_callback},
    [3] = {name = 'assembling-machine-3', callback = building_callback}
}

local resource_list = {
    [1] = {name = 'assembling-machine-1', callback = resource_callback},
    [2] = {name = 'assembling-machine-2', callback = resource_callback},
    [3] = {name = 'assembling-machine-3', callback = resource_callback}
}

local furnace_list = {
    [1] = {name = 'stone-furnace', callback = furnace_callback},
    [2] = {name = 'steel-furnace', callback = furnace_callback},
    [3] = {name = 'electric-furnace', callback = furnace_callback}
}

local function spawn_science_buildings(entities, p, probability)
    entities[#entities + 1] = {
        name = science_list[probability].name,
        position = p,
        force = 'player',
        callback = science_list[probability].callback,
        collision = true,
        e_type = types
    }
end

local function spawn_ammo_building(entities, p, probability)
    entities[#entities + 1] = {
        name = ammo_list[probability].name,
        position = p,
        force = 'player',
        callback = ammo_list[probability].callback,
        collision = true,
        e_type = types
    }
end

local function spawn_resource_building(entities, p, probability)
    entities[#entities + 1] = {
        name = resource_list[probability].name,
        position = p,
        force = 'player',
        callback = resource_list[probability].callback,
        collision = true,
        e_type = types
    }
end

local function spawn_furnace_building(entities, p, probability)
    entities[#entities + 1] = {
        name = furnace_list[probability].name,
        position = p,
        force = 'player',
        callback = furnace_list[probability].callback,
        collision = true,
        e_type = types
    }
end

local buildings = {
    [1] = spawn_ammo_building,
    [2] = spawn_resource_building,
    [3] = spawn_furnace_building,
    [4] = spawn_science_buildings
}

local function spawn_random_buildings(entities, p, depth)
    local randomizer = math.random(1, #buildings)
    local low = math.random(1, 2)
    local medium = math.random(2, 3)
    local high = 3

    if math.abs(p.y) < depth * 1.5 then
        if math.random(1, 16) == 1 then
            return buildings[randomizer](entities, p, low)
        else
            return buildings[randomizer](entities, p, low)
        end
    elseif math.abs(p.y) < depth * 2.5 then
        if math.random(1, 8) == 1 then
            return buildings[randomizer](entities, p, medium)
        else
            return buildings[randomizer](entities, p, medium)
        end
    elseif math.abs(p.y) < depth * 3.5 then
        if math.random(1, 4) == 1 then
            return buildings[randomizer](entities, p, high)
        else
            return buildings[randomizer](entities, p, medium)
        end
    elseif math.abs(p.y) < depth * 4.5 then
        if math.random(1, 4) == 1 then
            return buildings[randomizer](entities, p, high)
        else
            return buildings[randomizer](entities, p, high)
        end
    elseif math.abs(p.y) < depth * 5.5 then
        if math.random(1, 4) == 1 then
            return buildings[randomizer](entities, p, high)
        elseif math.random(1, 2) == 1 then
            return buildings[randomizer](entities, p, high)
        elseif math.random(1, 8) == 1 then
            return buildings[randomizer](entities, p, high)
        end
    end
    if math.abs(p.y) > depth * 5.5 then
        if math.random(1, 32) == 1 then
            return buildings[randomizer](entities, p, medium)
        end
    end
end

return spawn_random_buildings
