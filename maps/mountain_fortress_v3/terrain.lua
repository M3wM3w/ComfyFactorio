local Event = require 'utils.event'
local Biters = require 'modules.wave_defense.biter_rolls'
local Functions = require 'maps.mountain_fortress_v3.functions'
local Generate_resources = require 'maps.mountain_fortress_v3.resource_generator'
local WPT = require 'maps.mountain_fortress_v3.table'
local get_perlin = require 'utils.get_perlin'

local Public = {}
local random = math.random
local abs = math.abs
local floor = math.floor
local ceil = math.ceil

Public.level_depth = WPT.level_depth
Public.level_width = WPT.level_width
local worm_level_modifier = 0.19

local wagon_raffle = {
    'cargo-wagon',
    'cargo-wagon',
    'cargo-wagon',
    'locomotive',
    'fluid-wagon'
}

local rock_raffle = {
    'sand-rock-big',
    'sand-rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-big',
    'rock-huge'
}

local size_of_rock_raffle = #rock_raffle

local tree_raffle = {
    'dry-tree',
    'tree-01',
    'tree-02-red',
    'tree-04',
    'tree-08-brown'
}
local size_of_tree_raffle = #tree_raffle

local scrap_entities = {
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck',
    'medium-ship-wreck',
    'small-ship-wreck'
}

local scrap_entities_index = #scrap_entities

local scrap_entities_friendly = {
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-chest-1',
    'crash-site-chest-2',
    'crash-site-chest-1',
    'crash-site-chest-2'
}

local scrap_entities_friendly_index = #scrap_entities_friendly

local spawner_raffle = {
    'biter-spawner',
    'biter-spawner',
    'biter-spawner',
    'spitter-spawner'
}

local trees = {
    'dead-tree-desert',
    'dead-dry-hairy-tree',
    'dry-hairy-tree',
    'tree-06',
    'tree-06-brown',
    'dry-tree'
}

local firearm_magazine_ammo = Functions.firearm_magazine_ammo
local piercing_rounds_magazine_ammo = Functions.piercing_rounds_magazine_ammo
local uranium_rounds_magazine_ammo = Functions.uranium_rounds_magazine_ammo
local laser_turrent_power_source = Functions.laser_turrent_power_source
local light_oil_ammo = Functions.light_oil_ammo
local artillery_shell_ammo = Functions.artillery_shell_ammo

local callback = {
    [1] = {callback = Functions.refill_turret_callback, data = firearm_magazine_ammo},
    [2] = {callback = Functions.refill_turret_callback, data = piercing_rounds_magazine_ammo},
    [3] = {callback = Functions.refill_turret_callback, data = uranium_rounds_magazine_ammo},
    [4] = {callback = Functions.power_source_callback, data = laser_turrent_power_source},
    [5] = {callback = Functions.refill_liquid_turret_callback, data = light_oil_ammo},
    [6] = {callback = Functions.refill_artillery_turret_callback, data = artillery_shell_ammo}
}

local turret_list = {
    [1] = {name = 'gun-turret', callback = callback[1]},
    [2] = {name = 'gun-turret', callback = callback[2]},
    [3] = {name = 'gun-turret', callback = callback[3]},
    [4] = {name = 'laser-turret', callback = callback[4]},
    [5] = {name = 'flamethrower-turret', callback = callback[5]},
    [6] = {name = 'artillery-turret', callback = callback[6]}
}

local function get_scrap_mineable_entities()
    local scrap_mineable_entities = {
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-1',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-2',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-3',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-4',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-5',
        'crash-site-spaceship-wreck-small-6'
    }

    local modded = is_game_modded()
    if modded then
        if game.active_mods['MineableWreckage'] then
            scrap_mineable_entities = {'mineable-wreckages'}
        end
    end

    local scrap_mineable_entities_index = #scrap_mineable_entities

    return scrap_mineable_entities, scrap_mineable_entities_index
end

local function get_tiberium_trees(entities, p)
    if is_mod_loaded('Factorio-Tiberium') then
        if random(1, 512) == 1 then
            entities[#entities + 1] = {name = 'tibGrowthNode', position = p, amount = 15000}
        end
    end
end

local function get_imersite_ores(entities, p)
    if is_mod_loaded('Krastorio2') then
        if random(1, 2048) == 1 then
            entities[#entities + 1] = {name = 'imersite', position = p, amount = random(300000, 600000)}
        end
    end
end

local function is_position_near(area, table_to_check)
    local status = false
    local function inside(pos)
        local lt = area.left_top
        local rb = area.right_bottom

        return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
    end

    for i = 1, #table_to_check do
        if inside(table_to_check[i], area) then
            status = true
        end
    end

    return status
end

local function place_wagon(data)
    local placed_trains_in_zone = WPT.get('placed_trains_in_zone')
    if not placed_trains_in_zone.randomized then
        placed_trains_in_zone.limit = random(1, 2)
        placed_trains_in_zone.randomized = true
        placed_trains_in_zone = WPT.get('placed_trains_in_zone')
    end

    if placed_trains_in_zone.placed >= placed_trains_in_zone.limit then
        return
    end

    local surface = data.surface
    local tiles = data.hidden_tiles
    local entities = data.entities
    local top_x = data.top_x
    local top_y = data.top_y
    local position = {x = top_x + random(4, 12) * 2, y = top_y + random(4, 12) * 2}
    local wagon_mineable = {
        callback = Functions.disable_minable_and_ICW_callback
    }

    local rail_mineable = {
        callback = Functions.disable_destructible_callback
    }

    local radius = 300
    local area = {
        left_top = {x = position.x - radius, y = position.y - radius},
        right_bottom = {x = position.x + radius, y = position.y + radius}
    }

    if is_position_near(area, placed_trains_in_zone.positions) then
        return
    end

    local location
    local direction
    local r1 = random(2, 4) * 2
    local r2 = random(2, 4) * 2

    if random(1, 2) == 1 then
        location = surface.find_tiles_filtered({area = {{position.x, position.y - r1}, {position.x + 2, position.y + r2}}})
        direction = 0
    else
        location = surface.find_tiles_filtered({area = {{position.x - r1, position.y}, {position.x + r2, position.y + 2}}})
        direction = 2
    end

    for k, tile in pairs(location) do
        tiles[#tiles + 1] = {name = 'nuclear-ground', position = tile.position}
        if tile.position.y % 1 == 0 and tile.position.x % 1 == 0 then
            entities[#entities + 1] = {
                name = 'straight-rail',
                position = tile.position,
                force = 'player',
                direction = direction,
                callback = rail_mineable
            }
        end
    end
    entities[#entities + 1] = {
        name = wagon_raffle[random(1, #wagon_raffle)],
        position = position,
        force = 'player',
        callback = wagon_mineable
    }
    placed_trains_in_zone.placed = placed_trains_in_zone.placed + 1
    placed_trains_in_zone.positions[#placed_trains_in_zone.positions + 1] = position

    return true
end

local function get_oil_amount(p)
    return (abs(p.y) * 200 + 10000) * random(75, 125) * 0.01
end

function Public.increment_value(tbl)
    tbl.yv = tbl.yv + 1

    if tbl.yv == 32 then
        if tbl.xv == 32 then
            tbl.xv = 0
        end
        if tbl.yv == 32 then
            tbl.yv = 0
        end
        tbl.xv = tbl.xv + 1
    end

    return tbl.xv, tbl.yv
end

local function spawn_turret(entities, p, probability)
    entities[#entities + 1] = {
        name = turret_list[probability].name,
        position = p,
        force = 'enemy',
        callback = turret_list[probability].callback,
        direction = 4,
        collision = true
    }
end

local function wall(data)
    local tiles = data.tiles
    local entities = data.entities
    local surface = data.surface
    local treasure = data.treasure
    local stone_wall = {callback = Functions.disable_minable_callback}
    local enable_arties = WPT.get('enable_arties')

    local x, y = Public.increment_value(data)

    local seed = data.seed
    local p = {x = x + data.top_x, y = y + data.top_y}

    local small_caves = get_perlin('small_caves', p, seed + 300000)
    local cave_ponds = get_perlin('cave_rivers', p, seed + 150000)
    if y > 9 + cave_ponds * 6 and y < 23 + small_caves * 6 then
        if small_caves > 0.02 or cave_ponds > 0.02 then
            if small_caves > 0.005 then
                tiles[#tiles + 1] = {name = 'water', position = p}
            else
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 32) == 1 then
                    entities[#entities + 1] = {
                        name = 'land-mine',
                        position = p,
                        force = 'enemy'
                    }
                end
            end
            if random(1, 48) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
        else
            tiles[#tiles + 1] = {name = 'nuclear-ground', position = p}

            if random(1, 5) ~= 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, #rock_raffle)], position = p}
                if random(1, 32) == 1 then
                    entities[#entities + 1] = {
                        name = 'land-mine',
                        position = p,
                        force = 'enemy'
                    }
                end
            end
        end
    else
        tiles[#tiles + 1] = {name = 'nuclear-ground', position = p}

        if
            surface.can_place_entity(
                {
                    name = 'stone-wall',
                    position = p,
                    force = 'enemy'
                }
            )
         then
            if random(1, 512) == 1 and y > 3 and y < 28 then
                if random(1, 2) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                else
                    treasure[#treasure + 1] = {position = p, chest = 'steel-chest'}
                end
            end
            if y < 4 or y > 25 then
                if y <= 23 then
                    if random(1, y + 1) == 1 then
                        entities[#entities + 1] = {
                            name = 'stone-wall',
                            position = p,
                            force = 'player',
                            callback = stone_wall
                        }
                    end
                else
                    if random(1, 32 - y) == 1 then
                        entities[#entities + 1] = {
                            name = 'stone-wall',
                            position = p,
                            force = 'player',
                            callback = stone_wall
                        }
                    end
                end
            end
        end

        get_tiberium_trees(entities, p)

        if random(1, 40) == 1 then
            if
                surface.can_place_entity(
                    {
                        name = 'medium-worm-turret',
                        position = p,
                        force = 'enemy'
                    }
                )
             then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy'
                }
            end
        end

        if random(1, 25) == 1 then
            if abs(p.y) < Public.level_depth * 1.5 then
                if random(1, 16) == 1 then
                    spawn_turret(entities, p, 1)
                else
                    spawn_turret(entities, p, 2)
                end
            elseif abs(p.y) < Public.level_depth * 2.5 then
                if random(1, 8) == 1 then
                    spawn_turret(entities, p, 3)
                end
            elseif abs(p.y) < Public.level_depth * 3.5 then
                if random(1, 4) == 1 then
                    spawn_turret(entities, p, 4)
                else
                    spawn_turret(entities, p, 3)
                end
            elseif abs(p.y) < Public.level_depth * 4.5 then
                if random(1, 4) == 1 then
                    spawn_turret(entities, p, 4)
                else
                    spawn_turret(entities, p, 5)
                end
            elseif abs(p.y) < Public.level_depth * 5.5 then
                if random(1, 4) == 1 then
                    spawn_turret(entities, p, 4)
                elseif random(1, 2) == 1 then
                    spawn_turret(entities, p, 5)
                elseif random(1, 8) == 1 then
                    spawn_turret(entities, p, enable_arties)
                end
            end
        elseif abs(p.y) > Public.level_depth * 5.5 then
            if random(1, 15) == 1 then
                spawn_turret(entities, p, random(3, enable_arties))
            end
        end
    end
end

local function process_level_14_position(x, y, data)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure

    local small_caves = get_perlin('small_caves', p, seed)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 40000)

    --Resource Spots
    if smol_areas < -0.71 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    if small_caves > -0.21 and small_caves < 0.21 then
        tiles[#tiles + 1] = {name = 'grass-3', position = p}
        if random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
        end
        return
    end

    if small_caves < -0.34 or small_caves > 0.34 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        return
    end

    if small_caves > -0.41 and small_caves < 0.41 then
        if noise_cave_ponds > 0.35 then
            local success = place_wagon(data)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.23 then
            tiles[#tiles + 1] = {name = 'grass-4', position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
    end

    tiles[#tiles + 1] = {name = 'water-shallow', position = p}
end

local function process_level_13_position(x, y, data)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure

    local small_caves = get_perlin('small_caves', p, seed)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 70000)

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    if small_caves > -0.22 and small_caves < 0.22 then
        tiles[#tiles + 1] = {name = 'dirt-3', position = p}
        if random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    if small_caves < -0.35 or small_caves > 0.35 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        return
    end

    if small_caves > -0.40 and small_caves < 0.40 then
        if noise_cave_ponds > 0.35 then
            local success = place_wagon(data)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'dirt-' .. random(1, 4), position = p}
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
    end

    tiles[#tiles + 1] = {name = 'water-shallow', position = p}
end

local function process_level_12_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local noise_1 = get_perlin('small_caves', p, seed)
    local noise_2 = get_perlin('no_rocks_2', p, seed + 20000)
    local smol_areas = get_perlin('smol_areas', p, seed + 60000)

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    if noise_1 > 0.65 then
        if random(1, 100) > 88 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        else
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
        end
        if random(1, 48) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if noise_1 < -0.72 then
        local success = place_wagon(data)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = void_or_lab, position = p}
        if random(1, 100) > 88 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        return
    end

    if noise_1 > -0.30 and noise_1 < 0.30 then
        if noise_1 > -0.14 and noise_1 < 0.14 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        else
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        end
        return
    end

    if random(1, 64) == 1 and noise_2 > 0.65 then
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'stone', position = p, amount = abs(p.y) + 1}
        elseif random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'iron-ore', position = p, amount = abs(p.y) + 1}
        elseif random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'copper-ore', position = p, amount = abs(p.y) + 1}
        elseif random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'coal', position = p, amount = abs(p.y) + 1}
        end
    end
    if random(1, 8192) == 1 then
        markets[#markets + 1] = p
    end
    if random(1, 1024) == 1 then
        entities[#entities + 1] = {
            name = 'crash-site-chest-' .. random(1, 2),
            position = p,
            force = 'neutral'
        }
    end

    tiles[#tiles + 1] = {name = 'tutorial-grid', position = p}
end

local function process_level_11_position(x, y, data)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local noise_1 = get_perlin('small_caves', p, seed)
    local noise_2 = get_perlin('no_rocks_2', p, seed + 10000)
    local smol_areas = get_perlin('smol_areas', p, seed + 50000)

    if noise_1 > 0.7 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 48) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    if noise_1 < -0.72 then
        tiles[#tiles + 1] = {name = 'lab-dark-1', position = p}
        entities[#entities + 1] = {name = 'uranium-ore', position = p, amount = abs(p.y) + 1 * 3}
        return
    end

    if noise_1 > -0.30 and noise_1 < 0.30 then
        if noise_1 > -0.14 and noise_1 < 0.14 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
        else
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        end
        return
    end

    if random(1, 64) == 1 and noise_2 > 0.65 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end
    if random(1, 8192) == 1 then
        markets[#markets + 1] = p
    end
    if random(1, 1024) == 1 then
        entities[#entities + 1] = {
            name = 'crash-site-chest-' .. random(1, 2),
            position = p,
            force = 'neutral'
        }
    end

    local success = place_wagon(data)
    if success then
        return
    end

    local noise_forest_location = get_perlin('forest_location', p, seed)
    if noise_forest_location > 0.095 then
        if noise_forest_location > 0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'red-refined-concrete', position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'green-refined-concrete', position = p}
            end
        end
        return
    end

    if noise_forest_location < -0.095 then
        if noise_forest_location < -0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'blue-refined-concrete', position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'red-refined-concrete', position = p}
            end
        end
        return
    end
end

local function process_level_10_position(x, y, data)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure

    local scrapyard = get_perlin('scrapyard', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 45000)

    if scrapyard < -0.70 or scrapyard > 0.70 then
        tiles[#tiles + 1] = {name = 'grass-3', position = p}
        if random(1, 40) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if scrapyard < -0.65 or scrapyard > 0.65 then
        tiles[#tiles + 1] = {name = 'water-green', position = p}
        return
    end
    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    if abs(scrapyard) > 0.40 and abs(scrapyard) < 0.65 then
        if random(1, 64) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        tiles[#tiles + 1] = {name = 'water-mud', position = p}
        return
    end
    if abs(scrapyard) > 0.25 and abs(scrapyard) < 0.40 then
        local success = place_wagon(data)
        if success then
            return
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        tiles[#tiles + 1] = {name = 'water-shallow', position = p}
        return
    end
    local noise_forest_location = get_perlin('forest_location', p, seed)
    if scrapyard > -0.15 and scrapyard < 0.15 then
        if noise_forest_location > 0.095 then
            if random(1, 256) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy'
                }
            end
            if noise_forest_location > 0.6 then
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'tree-03', position = p}
                end
            else
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'tree-01', position = p}
                end
            end
            return
        end

        if noise_forest_location < -0.095 then
            if random(1, 256) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy'
                }
            end
            if noise_forest_location < -0.6 then
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'dry-tree', position = p}
                end
            else
                if random(1, 100) > 42 then
                    entities[#entities + 1] = {name = 'tree-02-red', position = p}
                end
            end
            return
        end
        tiles[#tiles + 1] = {name = 'dirt-6', position = p}
        return
    end
    tiles[#tiles + 1] = {name = 'grass-2', position = p}
end

local function process_level_9_position(x, y, data)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local maze_p = {x = floor(p.x - p.x % 10), y = floor(p.y - p.y % 10)}
    local maze_noise = get_perlin('no_rocks_2', maze_p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 40000)

    if maze_noise > -0.35 and maze_noise < 0.35 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        local no_rocks_2 = get_perlin('no_rocks_2', p, seed)
        if random(1, 2) == 1 and no_rocks_2 > -0.5 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        if random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        return
    end

    if maze_noise > 0 and maze_noise < 0.45 then
        local success = place_wagon(data)
        if success then
            return
        end
        if random(1, 512) == 1 then
            markets[#markets + 1] = p
        end
        if random(1, 256) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    if maze_noise < -0.5 or maze_noise > 0.5 then
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 96) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = 'water', position = p}
    if random(1, 96) == 1 then
        entities[#entities + 1] = {name = 'fish', position = p}
    end
end

--SCRAPYARD
local function process_scrap_zone_1(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings

    local scrapyard = get_perlin('scrapyard', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 35000)

    --Chasms
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local small_caves = get_perlin('small_caves', p, seed)
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.35 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.35 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if scrapyard < -0.25 or scrapyard > 0.25 then
        if random(1, 256) == 1 then
            if random(1, 8) == 1 then
                spawn_turret(entities, p, 3)
            else
                spawn_turret(entities, p, 4)
            end
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if scrapyard < -0.55 or scrapyard > 0.55 then
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
        if scrapyard < -0.28 or scrapyard > 0.28 then
            local success = place_wagon(data)
            if success then
                return
            end
            if random(1, 128) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
            end
            if random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities[random(1, scrap_entities_index)],
                    position = p,
                    force = 'enemy'
                }
            end
            if random(1, 96) == 1 then
                entities[#entities + 1] = {
                    name = scrap_entities_friendly[random(1, scrap_entities_friendly_index)],
                    position = p,
                    force = 'player'
                }
            end

            local scrap_mineable_entities, scrap_mineable_entities_index = get_scrap_mineable_entities()

            if random(1, 5) > 1 then
                entities[#entities + 1] = {name = scrap_mineable_entities[random(1, scrap_mineable_entities_index)], position = p, force = 'neutral'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
            end
            return
        end
        return
    end

    local cave_ponds = get_perlin('cave_ponds', p, seed)
    if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
        get_imersite_ores(entities, p)
    end

    local large_caves = get_perlin('large_caves', p, seed)
    if scrapyard > -0.15 and scrapyard < 0.15 then
        if floor(large_caves * 10) % 4 < 3 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
            return
        end
    end

    if random(1, 64) == 1 and cave_ponds > 0.6 then
        entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
    end

    tiles[#tiles + 1] = {name = 'stone-path', position = p}
    if random(1, 256) == 1 then
        entities[#entities + 1] = {name = 'land-mine', position = p, force = 'enemy'}
    end
end

local function process_level_7_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local cave_rivers_3 = get_perlin('cave_rivers_3', p, seed)
    local cave_rivers_4 = get_perlin('cave_rivers_4', p, seed + 50000)
    local no_rocks_2 = get_perlin('no_rocks_2', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 30000)

    if cave_rivers_3 > -0.025 and cave_rivers_3 < 0.025 and no_rocks_2 > -0.6 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    if cave_rivers_4 > -0.025 and cave_rivers_4 < 0.025 and no_rocks_2 > -0.6 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    local noise_ores = get_perlin('no_rocks_2', p, seed + 25000)

    if cave_rivers_3 > -0.20 and cave_rivers_3 < 0.20 then
        tiles[#tiles + 1] = {name = 'grass-' .. floor(cave_rivers_3 * 32) % 3 + 1, position = p}
        if cave_rivers_3 > -0.10 and cave_rivers_3 < 0.10 then
            if random(1, 8) == 1 and no_rocks_2 > -0.25 then
                entities[#entities + 1] = {name = 'tree-01', position = p}
            end
            if random(1, 2048) == 1 then
                markets[#markets + 1] = p
            end
            if noise_ores < -0.5 and no_rocks_2 > -0.6 then
                if cave_rivers_3 > 0 and cave_rivers_3 < 0.07 then
                    entities[#entities + 1] = {name = 'iron-ore', position = p, amount = abs(p.y) + 1}
                end
            end
        end
        if random(1, 64) == 1 and no_rocks_2 > 0.7 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        get_imersite_ores(entities, p)
        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    if cave_rivers_4 > -0.20 and cave_rivers_4 < 0.20 then
        tiles[#tiles + 1] = {name = 'grass-' .. floor(cave_rivers_4 * 32) % 3 + 1, position = p}
        if cave_rivers_4 > -0.10 and cave_rivers_4 < 0.10 then
            local success = place_wagon(data)
            if success then
                return
            end
            if random(1, 8) == 1 and no_rocks_2 > -0.25 then
                entities[#entities + 1] = {name = 'tree-02', position = p}
            end
            if random(1, 2048) == 1 then
                markets[#markets + 1] = p
            end
            if noise_ores < -0.5 and no_rocks_2 > -0.6 then
                if cave_rivers_4 > 0 and cave_rivers_4 < 0.07 then
                    entities[#entities + 1] = {name = 'copper-ore', position = p, amount = abs(p.y) + 1}
                end
            end
        end
        if random(1, 64) == 1 and no_rocks_2 > 0.7 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Chasms
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local small_caves = get_perlin('small_caves', p, seed)
    if noise_cave_ponds < 0.25 and noise_cave_ponds > -0.25 then
        if small_caves > 0.55 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.55 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}

            return
        end
    end

    --Resource Spots
    if smol_areas < -0.72 then
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        get_tiberium_trees(entities, p)
    end

    tiles[#tiles + 1] = {name = 'dirt-7', position = p}
    if random(1, 100) > 15 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
    end
    if random(1, 256) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
    end
end

local function process_forest_zone_2(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local large_caves = get_perlin('large_caves', p, seed)
    local cave_rivers = get_perlin('cave_rivers', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 25000)

    --Chasms
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local small_caves = get_perlin('small_caves', p, seed)
    if noise_cave_ponds < 0.45 and noise_cave_ponds > -0.45 then
        if small_caves > 0.45 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.45 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if large_caves > -0.03 and large_caves < 0.03 and cave_rivers < 0.25 then
        tiles[#tiles + 1] = {name = 'water-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        get_imersite_ores(entities, p)
        return
    end
    local noise_forest_location = get_perlin('forest_location', p, seed)
    if cave_rivers > -0.1 and cave_rivers < 0.1 then
        local success = place_wagon(data)
        if success then
            return
        end
        if random(1, 36) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
    else
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 100) > 15 then
            if noise_forest_location > 0.095 then
                if random(1, 256) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                if noise_forest_location > 0.6 then
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-08-brown', position = p}
                    end
                else
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-01', position = p}
                    end
                end
                return
            end

            if noise_forest_location < -0.095 then
                if random(1, 256) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                if noise_forest_location < -0.6 then
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-04', position = p}
                    end
                else
                    if random(1, 100) > 42 then
                        entities[#entities + 1] = {name = 'tree-02-red', position = p}
                    end
                end
                get_tiberium_trees(entities, p)
                return
            end
        end
        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 4096) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 8096) == 1 then
            markets[#markets + 1] = p
        end
    end
end

local function process_level_5_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local treasure = data.treasure

    local small_caves = get_perlin('small_caves', p, seed)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 20000)

    if small_caves > -0.24 and small_caves < 0.24 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 768) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    if small_caves < -0.50 or small_caves > 0.50 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 128) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        if random(1, 256) == 1 then
            spawn_turret(entities, p, 4)
        end
        return
    end

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        get_imersite_ores(entities, p)
        return
    end

    if small_caves > -0.40 and small_caves < 0.40 then
        if noise_cave_ponds > 0.35 then
            local success = place_wagon(data)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'dirt-' .. random(1, 4), position = p}
            if random(1, 256) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            if random(1, 256) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            return
        end
        if noise_cave_ponds > 0.25 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            get_tiberium_trees(entities, p)
            if random(1, 2) == 1 then
                entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
            end
        end
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function process_level_4_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local noise_large_caves = get_perlin('large_caves', p, seed)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local small_caves = get_perlin('dungeons', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 15000)

    if abs(noise_large_caves) > 0.7 then
        tiles[#tiles + 1] = {name = 'water', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end
    if abs(noise_large_caves) > 0.6 then
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'tree-02', position = p}
        end
        if random(1, 32) == 1 then
            markets[#markets + 1] = p
        end
    end
    if abs(noise_large_caves) > 0.5 then
        tiles[#tiles + 1] = {name = 'grass-2', position = p}
        if random(1, 620) == 1 then
            entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
        end
        if random(1, 384) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {name = Biters.wave_defense_roll_worm_name(), position = p, force = 'enemy'}
        end
        local success = place_wagon(data)
        if success then
            return
        end
        if random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end
    if abs(noise_large_caves) > 0.475 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
        if small_caves > 0.75 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end

        if small_caves < -0.75 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    if small_caves > -0.15 and small_caves < 0.15 then
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 2) == 1 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        if random(1, 1024) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        return
    end

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        get_imersite_ores(entities, p)
        return
    end

    if noise_large_caves > -0.2 and noise_large_caves < 0.2 then
        --Main Rock Terrain
        local no_rocks_2 = get_perlin('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            return
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        get_tiberium_trees(entities, p)
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 100) > 30 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function process_level_3_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local entities = data.entities
    local buildings = data.buildings
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_perlin('dungeons', p, seed + 50000)
    local small_caves_2 = get_perlin('small_caves_2', p, seed + 70000)
    local noise_large_caves = get_perlin('large_caves', p, seed + 60000)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 60000)

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        return
    end

    --Market Spots
    if noise_cave_ponds < -0.77 then
        if noise_cave_ponds > -0.79 then
            tiles[#tiles + 1] = {name = 'dirt-7', position = p}
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        else
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
            end
        end
        return
    end

    if noise_large_caves > -0.15 and noise_large_caves < 0.15 or small_caves_2 > 0 then
        --Green Water Ponds
        if noise_cave_ponds > 0.80 then
            tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end

        --Chasms
        if noise_cave_ponds < 0.12 and noise_cave_ponds > -0.12 then
            if small_caves > 0.85 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}

                return
            end

            if small_caves < -0.85 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}

                return
            end
        end

        --Rivers
        local cave_rivers = get_perlin('cave_rivers', p, seed + 100000)
        if cave_rivers < 0.024 and cave_rivers > -0.024 then
            if noise_cave_ponds > 0.2 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end
        local cave_rivers_2 = get_perlin('cave_rivers_2', p, seed)
        if cave_rivers_2 < 0.024 and cave_rivers_2 > -0.024 then
            if noise_cave_ponds < 0.4 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.725 then
            tiles[#tiles + 1] = {name = 'dirt-' .. random(4, 6), position = p}
            return
        end

        local no_rocks = get_perlin('no_rocks', p, seed + 25000)
        --Worm oil Zones
        if no_rocks < 0.20 and no_rocks > -0.20 then
            if small_caves > 0.35 then
                tiles[#tiles + 1] = {name = 'dirt-' .. floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if random(1, 320) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 50) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                get_imersite_ores(entities, p)
                if random(1, 256) == 1 then
                    spawn_turret(entities, p, 3)
                end
                if random(1, 512) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end

        --Main Rock Terrain
        local no_rocks_2 = get_perlin('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            local success = place_wagon(data)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            get_tiberium_trees(entities, p)
            return
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        tiles[#tiles + 1] = {name = 'dirt-7', position = p}
        if random(1, 100) > 30 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function process_level_2_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local tiles = data.tiles
    local buildings = data.buildings
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_perlin('dungeons', p, seed)
    local noise_large_caves = get_perlin('large_caves', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 15000)

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        return
    end

    if noise_large_caves > -0.75 and noise_large_caves < 0.75 then
        local noise_cave_ponds = get_perlin('cave_ponds', p, seed)

        --Chasms
        if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
            if small_caves > 0.32 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}

                return
            end
            if small_caves < -0.32 then
                tiles[#tiles + 1] = {name = void_or_lab, position = p}
                return
            end
        end

        --Green Water Ponds
        if noise_cave_ponds > 0.80 then
            tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end

        --Rivers
        local cave_rivers = get_perlin('cave_rivers', p, seed + 100000)
        if cave_rivers < 0.037 and cave_rivers > -0.037 then
            if noise_cave_ponds < 0.1 then
                tiles[#tiles + 1] = {name = 'water-shallow', position = p}
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'fish', position = p}
                end
                return
            end
        end

        if noise_cave_ponds > 0.66 then
            tiles[#tiles + 1] = {name = 'dirt-' .. random(4, 6), position = p}
            return
        end

        --Market Spots
        if noise_cave_ponds < -0.80 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 32) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 16) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
            end
            return
        end

        local no_rocks = get_perlin('no_rocks', p, seed + 25000)
        --Worm oil Zones
        if no_rocks < 0.20 and no_rocks > -0.20 then
            if small_caves > 0.30 then
                tiles[#tiles + 1] = {name = 'dirt-' .. floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 64) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end
                get_imersite_ores(entities, p)
                if random(1, 256) == 1 then
                    spawn_turret(entities, p, 2)
                end
                if random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'dead-tree-desert', position = p}
                end
                return
            end
        end

        --Main Rock Terrain
        local no_rocks_2 = get_perlin('no_rocks_2', p, seed + 75000)
        if no_rocks_2 > 0.80 or no_rocks_2 < -0.80 then
            local success = place_wagon(data)
            if success then
                return
            end
            tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
            if random(1, 512) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
            end
            get_tiberium_trees(entities, p)
            return
        end

        if random(1, 2048) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'wooden-chest'}
        end
        tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
        if random(1, 100) > 25 then
            entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        end
        return
    end

    tiles[#tiles + 1] = {name = void_or_lab, position = p}
end

local function process_forest_zone_1(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local buildings = data.buildings
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_perlin('dungeons', p, seed + 33322)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed + 33333)

    --Resource Spots
    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.101 and noise_cave_ponds > -0.102 then
        if small_caves > 0.52 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
        if small_caves < -0.52 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    --Water Ponds
    if noise_cave_ponds > 0.670 then
        if noise_cave_ponds > 0.750 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 4) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 4) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Rivers
    local cave_rivers = get_perlin('cave_rivers', p, seed + 200000)
    if cave_rivers < 0.041 and cave_rivers > -0.042 then
        if noise_cave_ponds > 0 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.74 then
        tiles[#tiles + 1] = {name = 'grass-' .. random(1, 4), position = p}
        tiles[#tiles + 1] = {name = 'grass-1', position = p}
        if cave_rivers < -0.502 then
            tiles[#tiles + 1] = {name = 'refined-hazard-concrete-right', position = p}
        end
        if random(1, 64) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
        end
        return
    end

    local no_rocks = get_perlin('no_rocks', p, seed + 30000)
    --Worm oil Zones
    if p.y < -64 + noise_cave_ponds * 10 then
        if no_rocks < 0.11 and no_rocks > -0.11 then
            if small_caves > 0.31 then
                tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
                if random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 96) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end

                get_imersite_ores(entities, p)

                if random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
                end
                return
            end
        end
    end

    --Main Rock Terrain
    local no_rocks_2 = get_perlin('no_rocks_2', p, seed + 5000)
    if no_rocks_2 > 0.64 or no_rocks_2 < -0.64 then
        local success = place_wagon(data)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        get_tiberium_trees(entities, p)
        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
        end
        return
    end

    if random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
    end
    tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
    local noise_forest_location = get_perlin('forest_location', p, seed)
    if noise_forest_location > 0.095 then
        if random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        if noise_forest_location > 0.6 then
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-08-brown', position = p}
            end
        else
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-01', position = p}
            end
        end
        return
    end

    if noise_forest_location < -0.095 then
        if random(1, 256) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        if noise_forest_location < -0.6 then
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-04', position = p}
            end
        else
            if random(1, 100) > 42 then
                entities[#entities + 1] = {name = 'tree-02-red', position = p}
            end
        end
        return
    end
end

local function process_level_1_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local buildings = data.buildings
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_perlin('dungeons', p, seed)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed)

    if smol_areas < 0.055 and smol_areas > -0.025 then
        tiles[#tiles + 1] = {name = 'deepwater-green', position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 32) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.111 and noise_cave_ponds > -0.112 then
        if small_caves > 0.53 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
        if small_caves < -0.53 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    --Water Ponds
    if noise_cave_ponds > 0.670 then
        if noise_cave_ponds > 0.750 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 4) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 4) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Rivers
    local cave_rivers = get_perlin('cave_rivers', p, seed + 300000)
    if cave_rivers < 0.042 and cave_rivers > -0.042 then
        if noise_cave_ponds > 0 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.74 then
        tiles[#tiles + 1] = {name = 'dirt-' .. random(4, 6), position = p}
        tiles[#tiles + 1] = {name = 'grass-1', position = p}
        if cave_rivers < -0.502 then
            tiles[#tiles + 1] = {name = 'refined-hazard-concrete-right', position = p}
        end
        if random(1, 64) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        return
    end

    local no_rocks = get_perlin('no_rocks', p, seed + 50000)
    --Worm oil Zones
    if p.y < -64 + noise_cave_ponds * 10 then
        if no_rocks < 0.12 and no_rocks > -0.12 then
            if small_caves > 0.30 then
                tiles[#tiles + 1] = {name = 'dirt-' .. floor(noise_cave_ponds * 32) % 7 + 1, position = p}
                if random(1, 450) == 1 then
                    entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
                end
                if random(1, 96) == 1 then
                    Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                    entities[#entities + 1] = {
                        name = Biters.wave_defense_roll_worm_name(),
                        position = p,
                        force = 'enemy'
                    }
                end

                get_imersite_ores(entities, p)

                if random(1, 1024) == 1 then
                    treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
                end
                if random(1, 64) == 1 then
                    entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
                end
                return
            end
        end
    end

    --Main Rock Terrain
    local no_rocks_2 = get_perlin('no_rocks_2', p, seed + 75000)
    if no_rocks_2 > 0.66 or no_rocks_2 < -0.66 then
        local success = place_wagon(data)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end
        get_tiberium_trees(entities, p)
        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
        end
        return
    end

    if random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
    end
    local random_tiles = get_perlin('forest_location', p, seed)
    if random_tiles > 0.095 then
        if random_tiles > 0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'sand-1', position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'sand-2', position = p}
            end
        end
    end

    if random_tiles < -0.095 then
        if random_tiles < -0.6 then
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'sand-1', position = p}
            end
        else
            if random(1, 100) > 42 then
                tiles[#tiles + 1] = {name = 'lab-dark-1', position = p}
            end
        end
    end
    if random(1, 100) > 25 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
    end
end

local function process_level_0_position(x, y, data, void_or_lab)
    local p = {x = x, y = y}
    local seed = data.seed
    local buildings = data.buildings
    local tiles = data.tiles
    local entities = data.entities
    local markets = data.markets
    local treasure = data.treasure

    local small_caves = get_perlin('dungeons', p, seed)
    local noise_cave_ponds = get_perlin('cave_ponds', p, seed)
    local smol_areas = get_perlin('smol_areas', p, seed)
    local no_rocks_2 = get_perlin('no_rocks_2', p, seed)
    local cave_rivers = get_perlin('cave_rivers', p, seed)
    local no_rocks = get_perlin('no_rocks', p, seed)

    if smol_areas < 0.055 and smol_areas > -0.025 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
        if random(1, 32) == 1 then
            Generate_resources(buildings, p, Public.level_depth)
        end
        if random(1, 128) == 1 then
            Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
            entities[#entities + 1] = {
                name = Biters.wave_defense_roll_worm_name(),
                position = p,
                force = 'enemy'
            }
        end
        return
    end

    --Chasms
    if noise_cave_ponds < 0.111 and noise_cave_ponds > -0.112 then
        if small_caves > 0.53 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
        if small_caves < -0.53 then
            tiles[#tiles + 1] = {name = void_or_lab, position = p}
            return
        end
    end

    --Water Ponds
    if noise_cave_ponds > 0.670 then
        if noise_cave_ponds > 0.750 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 4) == 1 then
                markets[#markets + 1] = p
            end
            if random(1, 4) == 1 then
                entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
            end
            return
        end
        tiles[#tiles + 1] = {name = 'deepwater', position = p}
        if random(1, 16) == 1 then
            entities[#entities + 1] = {name = 'fish', position = p}
        end
        return
    end

    --Rivers
    if cave_rivers < 0.044 and cave_rivers > -0.062 then
        if noise_cave_ponds > 0.1 then
            tiles[#tiles + 1] = {name = 'water-shallow', position = p}
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'fish', position = p}
            end
            return
        end
    end

    if noise_cave_ponds > 0.632 then
        if noise_cave_ponds > 0.542 then
            if cave_rivers > -0.302 then
                tiles[#tiles + 1] = {name = 'refined-hazard-concrete-right', position = p}
            end
        end
        if random(1, 64) == 1 then
            entities[#entities + 1] = {name = tree_raffle[random(1, size_of_tree_raffle)], position = p}
        end
        return
    end

    --Worm oil Zones
    if no_rocks < 0.031 and no_rocks > -0.141 then
        if small_caves > 0.081 then
            tiles[#tiles + 1] = {name = 'grass-' .. floor(noise_cave_ponds * 32) % 3 + 1, position = p}
            if random(1, 250) == 1 then
                entities[#entities + 1] = {name = 'crude-oil', position = p, amount = get_oil_amount(p)}
            end
            if random(1, 96) == 1 then
                Biters.wave_defense_set_worm_raffle(abs(p.y) * worm_level_modifier)
                entities[#entities + 1] = {
                    name = Biters.wave_defense_roll_worm_name(),
                    position = p,
                    force = 'enemy'
                }
            end

            if random(1, 1024) == 1 then
                treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
            end
            if random(1, 64) == 1 then
                entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
            end
            return
        end
    end

    --Main Rock Terrain
    if no_rocks_2 > 0.334 and no_rocks_2 < 0.544 then
        local success = place_wagon(data)
        if success then
            return
        end
        tiles[#tiles + 1] = {name = 'dirt-' .. floor(no_rocks_2 * 8) % 2 + 5, position = p}
        if random(1, 32) == 1 then
            entities[#entities + 1] = {name = 'tree-0' .. random(1, 9), position = p}
        end

        get_tiberium_trees(entities, p)

        if random(1, 512) == 1 then
            treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
        end
        return
    end

    if random(1, 2048) == 1 then
        treasure[#treasure + 1] = {position = p, chest = 'iron-chest'}
    end
    tiles[#tiles + 1] = {name = 'dirt-7', position = p}
    if random(1, 100) > 25 then
        entities[#entities + 1] = {name = rock_raffle[random(1, size_of_rock_raffle)], position = p}
    end
end

Public.levels = {
    process_level_0_position,
    process_level_1_position,
    process_forest_zone_1, -- zone 3
    process_level_3_position,
    process_level_5_position,
    process_scrap_zone_1, -- zone 6
    process_level_9_position,
    process_level_4_position,
    process_level_2_position,
    process_level_3_position,
    process_forest_zone_2, -- zone 11
    process_level_4_position,
    process_level_5_position,
    process_forest_zone_2, -- zone 14
    process_level_7_position,
    process_scrap_zone_1, -- zone 16
    process_level_9_position,
    process_level_10_position,
    process_level_11_position,
    process_level_12_position,
    process_level_13_position,
    process_level_14_position
}

local function is_out_of_map(p)
    if p.x < 480 and p.x >= -480 then
        return
    end
    return true
end

local function process_bits(x, y, data)
    local levels = Public.levels
    local left_top_y = data.area.left_top.y
    local index = floor((abs(left_top_y / Public.level_depth)) % 22) + 1
    local process_level = levels[index]
    if not process_level then
        process_level = levels[#levels]
    end

    local void_or_tile = WPT.get('void_or_tile')

    process_level(x, y, data, void_or_tile)
end

local function border_chunk(data)
    local entities = data.entities
    local decoratives = data.decoratives

    local x, y = Public.increment_value(data)

    local pos = {x = x + data.top_x, y = y + data.top_y}

    if random(1, ceil(pos.y + pos.y) + 64) == 1 then
        entities[#entities + 1] = {name = trees[random(1, #trees)], position = pos}
    end
    local scrap_mineable_entities, scrap_mineable_entities_index = get_scrap_mineable_entities()

    if not is_out_of_map(pos) then
        if random(1, ceil(pos.y + pos.y) + 32) == 1 then
            entities[#entities + 1] = {name = scrap_mineable_entities[random(1, scrap_mineable_entities_index)], position = pos, force = 'neutral'}
        end
        if random(1, pos.y + 2) == 1 then
            decoratives[#decoratives + 1] = {
                name = 'rock-small',
                position = pos,
                amount = random(1, 1 + ceil(20 - y / 2))
            }
        end
        if random(1, pos.y + 2) == 1 then
            decoratives[#decoratives + 1] = {
                name = 'rock-tiny',
                position = pos,
                amount = random(1, 1 + ceil(20 - y / 2))
            }
        end
    end
end

local function biter_chunk(data)
    local surface = data.surface
    local entities = data.entities
    local tile_positions = {}
    local x, y = Public.increment_value(data)

    local p = {x = x + data.top_x, y = y + data.top_y}
    tile_positions[#tile_positions + 1] = p

    local disable_spawners = {
        callback = Functions.deactivate_callback
    }
    local disable_worms = {
        callback = Functions.active_not_destructible_callback
    }

    if random(1, 128) == 1 then
        local position = surface.find_non_colliding_position('biter-spawner', tile_positions[random(1, #tile_positions)], 16, 2)
        if position then
            entities[#entities + 1] = {
                name = spawner_raffle[random(1, #spawner_raffle)],
                position = position,
                force = 'enemy',
                callback = disable_spawners
            }
        end
    end

    if random(1, 128) == 1 then
        local position = surface.find_non_colliding_position('big-worm-turret', tile_positions[random(1, #tile_positions)], 16, 2)
        if position then
            entities[#entities + 1] = {
                name = 'big-worm-turret',
                position = position,
                force = 'enemy',
                callback = disable_worms
            }
        end
    end
end

local function out_of_map(x, y, data)
    local tiles = data.tiles

    local p = {x = x, y = y}

    tiles[#tiles + 1] = {name = 'out-of-map', position = p}
end

function Public.heavy_functions(x, y, data)
    local top_y = data.top_y
    local surface = data.surface
    local p = {x = data.x, y = data.y}
    local get_tile = surface.get_tile(p)

    local map_name = 'mountain_fortress_v3'

    if string.sub(surface.name, 0, #map_name) ~= map_name then
        return
    end

    if not data.seed then
        data.seed = surface.map_gen_settings.seed
    end

    if get_tile.valid and get_tile.name == 'out-of-map' then
        return
    end

    if top_y % Public.level_depth == 0 and top_y < 0 then
        WPT.set().left_top = data.left_top
        wall(data)
        return
    end

    if top_y < 0 then
        process_bits(x, y, data)
        return
    end

    if top_y > 120 then
        out_of_map(x, y, data)
        return
    end

    if top_y > 75 then
        biter_chunk(data)
        return
    end

    if top_y >= 0 then
        border_chunk(data)
        return
    end
end

Event.add(
    defines.events.on_chunk_generated,
    function(e)
        local surface = e.surface
        local map_name = 'mountain_fortress_v3'

        if string.sub(surface.name, 0, #map_name) ~= map_name then
            return
        end

        local area = e.area
        local left_top = area.left_top
        if not surface then
            return
        end
        if not surface.valid then
            return
        end

        local winter_mode = WPT.get('winter_mode')
        if winter_mode then
            rendering.draw_sprite(
                {sprite = 'tile/lab-white', x_scale = 32, y_scale = 32, target = left_top, surface = surface, tint = {r = 0.6, g = 0.6, b = 0.6, a = 0.6}, render_layer = 'ground'}
            )
        end

        if left_top.y == -128 and left_top.x == -128 then
            local locomotive = WPT.get('locomotive')
            if locomotive and locomotive.valid then
                local position = locomotive.position
                for _, entity in pairs(surface.find_entities_filtered({area = {{position.x - 5, position.y - 6}, {position.x + 5, position.y + 10}}, type = 'simple-entity'})) do
                    entity.destroy()
                end
            end
        end

        if left_top.y > 32 then
            game.forces.player.chart(surface, {{left_top.x, left_top.y}, {left_top.x + 31, left_top.y + 31}})
        end
    end
)

return Public
