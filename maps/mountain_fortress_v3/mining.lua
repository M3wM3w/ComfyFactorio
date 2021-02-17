local WPT = require 'maps.mountain_fortress_v3.table'
local RPG_Settings = require 'modules.rpg.table'
require 'modules.check_fullness'

local Public = {}
local random = math.random
local floor = math.floor
local sqrt = math.sqrt

local max_spill = 60

local mining_chance_weights = {
    {name = 'iron-plate', chance = 1000},
    {name = 'iron-gear-wheel', chance = 750},
    {name = 'copper-plate', chance = 750},
    {name = 'copper-cable', chance = 500},
    {name = 'electronic-circuit', chance = 300},
    {name = 'steel-plate', chance = 200},
    {name = 'solid-fuel', chance = 150},
    {name = 'pipe', chance = 100},
    {name = 'iron-stick', chance = 50},
    {name = 'battery', chance = 20},
    {name = 'empty-barrel', chance = 10},
    {name = 'crude-oil-barrel', chance = 30},
    {name = 'lubricant-barrel', chance = 20},
    {name = 'petroleum-gas-barrel', chance = 15},
    {name = 'sulfuric-acid-barrel', chance = 15},
    {name = 'heavy-oil-barrel', chance = 15},
    {name = 'light-oil-barrel', chance = 15},
    {name = 'water-barrel', chance = 10},
    {name = 'green-wire', chance = 10},
    {name = 'red-wire', chance = 10},
    {name = 'explosives', chance = 5},
    {name = 'advanced-circuit', chance = 5},
    {name = 'nuclear-fuel', chance = 1},
    {name = 'pipe-to-ground', chance = 10},
    {name = 'plastic-bar', chance = 5},
    {name = 'processing-unit', chance = 2},
    {name = 'used-up-uranium-fuel-cell', chance = 1},
    {name = 'uranium-fuel-cell', chance = 1},
    {name = 'rocket-fuel', chance = 3},
    {name = 'rocket-control-unit', chance = 1},
    {name = 'low-density-structure', chance = 1},
    {name = 'heat-pipe', chance = 1},
    {name = 'engine-unit', chance = 4},
    {name = 'electric-engine-unit', chance = 2},
    {name = 'logistic-robot', chance = 1},
    {name = 'construction-robot', chance = 1},
    {name = 'land-mine', chance = 3},
    {name = 'grenade', chance = 10},
    {name = 'rocket', chance = 3},
    {name = 'explosive-rocket', chance = 3},
    {name = 'cannon-shell', chance = 2},
    {name = 'explosive-cannon-shell', chance = 2},
    {name = 'uranium-cannon-shell', chance = 1},
    {name = 'explosive-uranium-cannon-shell', chance = 1},
    {name = 'artillery-shell', chance = 1},
    {name = 'cluster-grenade', chance = 2},
    {name = 'defender-capsule', chance = 5},
    {name = 'destroyer-capsule', chance = 1},
    {name = 'distractor-capsule', chance = 2}
}

local scrap_yield_amounts = {
    ['iron-plate'] = 16,
    ['iron-gear-wheel'] = 8,
    ['iron-stick'] = 16,
    ['copper-plate'] = 16,
    ['copper-cable'] = 24,
    ['electronic-circuit'] = 8,
    ['steel-plate'] = 4,
    ['pipe'] = 8,
    ['solid-fuel'] = 4,
    ['empty-barrel'] = 3,
    ['crude-oil-barrel'] = 3,
    ['lubricant-barrel'] = 3,
    ['petroleum-gas-barrel'] = 3,
    ['sulfuric-acid-barrel'] = 3,
    ['heavy-oil-barrel'] = 3,
    ['light-oil-barrel'] = 3,
    ['water-barrel'] = 3,
    ['battery'] = 2,
    ['explosives'] = 4,
    ['advanced-circuit'] = 2,
    ['nuclear-fuel'] = 0.1,
    ['pipe-to-ground'] = 1,
    ['plastic-bar'] = 4,
    ['processing-unit'] = 1,
    ['used-up-uranium-fuel-cell'] = 1,
    ['uranium-fuel-cell'] = 0.3,
    ['rocket-fuel'] = 0.3,
    ['rocket-control-unit'] = 0.3,
    ['low-density-structure'] = 0.3,
    ['heat-pipe'] = 1,
    ['green-wire'] = 8,
    ['red-wire'] = 8,
    ['engine-unit'] = 2,
    ['electric-engine-unit'] = 2,
    ['logistic-robot'] = 0.3,
    ['construction-robot'] = 0.3,
    ['land-mine'] = 1,
    ['grenade'] = 2,
    ['rocket'] = 2,
    ['explosive-rocket'] = 2,
    ['cannon-shell'] = 2,
    ['explosive-cannon-shell'] = 2,
    ['uranium-cannon-shell'] = 2,
    ['explosive-uranium-cannon-shell'] = 2,
    ['artillery-shell'] = 0.3,
    ['cluster-grenade'] = 0.3,
    ['defender-capsule'] = 2,
    ['destroyer-capsule'] = 0.3,
    ['distractor-capsule'] = 0.3
}

local valid_rocks = {
    ['sand-rock-big'] = true,
    ['rock-big'] = true,
    ['rock-huge'] = true
}

local valid_trees = {
    ['dead-tree-desert'] = true,
    ['dead-dry-hairy-tree'] = true,
    ['dry-hairy-tree'] = true,
    ['tree-06'] = true,
    ['tree-06-brown'] = true,
    ['dry-tree'] = true,
    ['tree-01'] = true,
    ['tree-02-red'] = true,
    ['tree-03'] = true,
    ['tree-04'] = true,
    ['tree-08-brown'] = true
}

local valid_scrap = {
    ['crash-site-spaceship-wreck-small-1'] = true,
    ['crash-site-spaceship-wreck-small-2'] = true,
    ['crash-site-spaceship-wreck-small-3'] = true,
    ['crash-site-spaceship-wreck-small-4'] = true,
    ['crash-site-spaceship-wreck-small-5'] = true,
    ['crash-site-spaceship-wreck-small-6'] = true,
    ['mineable-wreckages'] = true
}

if is_mod_loaded('MineableWreckage') then
    valid_scrap['mineable-wreckages'] = true
end

local reward_wood = {
    ['dead-tree-desert'] = true,
    ['dead-dry-hairy-tree'] = true,
    ['dry-hairy-tree'] = true,
    ['tree-06'] = true,
    ['tree-06-brown'] = true,
    ['dry-tree'] = true
}

local rock_yield = {
    ['rock-big'] = 1,
    ['rock-huge'] = 2,
    ['sand-rock-big'] = 1
}

local particles = {
    ['iron-ore'] = 'iron-ore-particle',
    ['copper-ore'] = 'copper-ore-particle',
    ['uranium-ore'] = 'coal-particle',
    ['coal'] = 'coal-particle',
    ['stone'] = 'stone-particle'
}

if is_mod_loaded('Factorio-Tiberium') then
    particles['tiberium-ore'] = 'blood-particle'
end

local function create_particles(surface, name, position, amount, cause_position)
    local d1 = (-100 + random(0, 200)) * 0.0004
    local d2 = (-100 + random(0, 200)) * 0.0004

    name = name or 'leaf-particle'

    if cause_position then
        d1 = (cause_position.x - position.x) * 0.025
        d2 = (cause_position.y - position.y) * 0.025
    end

    for i = 1, amount, 1 do
        local m = random(4, 10)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = name,
                position = position,
                frame_speed = 1,
                vertical_speed = 0.130,
                height = 0,
                movement = {
                    (m2 - (random(0, m) * 0.01)) + d1,
                    (m2 - (random(0, m) * 0.01)) + d2
                }
            }
        )
    end
end

local function mining_chances_ores()
    local data = {
        {name = 'iron-ore', chance = 25},
        {name = 'copper-ore', chance = 17},
        {name = 'coal', chance = 15},
        {name = 'stone', chance = 13},
        {name = 'uranium-ore', chance = 2}
    }
    if is_mod_loaded('Factorio-Tiberium') then
        data[#data + 1] = {name = 'tiberium-ore', chance = 5}
    end
    if is_mod_loaded('Krastorio2') then
        data[#data + 1] = {name = 'raw-rare-metals', chance = 5}
    end

    return data
end

local harvest_raffle_ores = {}
for _, t in pairs(mining_chances_ores()) do
    for _ = 1, t.chance, 1 do
        harvest_raffle_ores[#harvest_raffle_ores + 1] = t.name
    end
end

local size_of_ore_raffle = #harvest_raffle_ores

local scrap_raffle = {}
for _, t in pairs(mining_chance_weights) do
    for _ = 1, t.chance, 1 do
        scrap_raffle[#scrap_raffle + 1] = t.name
    end
end

local size_of_scrap_raffle = #scrap_raffle

local function get_amount(data)
    local entity = data.entity
    local t_modifier = WPT.get('type_modifier')
    local rocks_yield_ore_distance_modifier = WPT.get('rocks_yield_ore_distance_modifier')
    local rocks_yield_ore_base_amount = WPT.get('rocks_yield_ore_base_amount')
    local rocks_yield_ore_maximum_amount = WPT.get('rocks_yield_ore_maximum_amount')
    local distance_to_center = floor(sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))
    local type_modifier = 1
    local amount
    local second_amount

    local distance_modifier = 0.25
    local base_amount = 25
    local second_base_amount = 10
    local maximum_amount = 100
    if t_modifier then
        type_modifier = t_modifier
    end
    if rocks_yield_ore_distance_modifier then
        distance_modifier = rocks_yield_ore_distance_modifier
    end

    if rocks_yield_ore_base_amount then
        base_amount = rocks_yield_ore_base_amount
    end
    if rocks_yield_ore_maximum_amount then
        maximum_amount = rocks_yield_ore_maximum_amount
    end

    type_modifier = rock_yield[entity.name] or type_modifier

    if data.size then
        base_amount = data.size
    end

    amount = base_amount + (distance_to_center * distance_modifier)
    second_amount = floor((second_base_amount + (distance_to_center * distance_modifier)) / 3)
    if amount > maximum_amount then
        amount = maximum_amount
    end
    if second_amount > maximum_amount then
        second_amount = maximum_amount
    end

    local m = (70 + random(0, 60)) * 0.01

    amount = floor(amount * type_modifier * m * 0.7)

    return amount, second_amount
end

function Public.entity_died_randomness(data)
    local entity = data.entity
    local surface = data.surface
    local harvest

    harvest = harvest_raffle_ores[random(1, size_of_ore_raffle)]

    local position = {x = entity.position.x, y = entity.position.y}

    surface.spill_item_stack(position, {name = harvest, count = random(1, 5)}, true)
    local particle = particles[harvest]
    create_particles(surface, particle, position, 64, {x = entity.position.x, y = entity.position.y})
end

local function randomness(data)
    local entity = data.entity
    local player = data.player
    local spill_items_to_surface = WPT.get('spill_items_to_surface')
    local harvest
    local harvest_amount

    harvest_amount = get_amount(data)

    local n = entity.name
    if n == 'tree-08-brown' then
        harvest = 'stone'
    elseif n == 'tree-04' then
        harvest = 'coal'
    elseif n == 'tree-02-red' then
        harvest = 'copper-ore'
    elseif n == 'tree-01' then
        harvest = 'iron-ore'
    elseif n == 'tree-03' then
        harvest = 'coal'
    elseif reward_wood[n] then
        harvest = 'wood'
        harvest_amount = random(1, 20)
    else
        harvest = harvest_raffle_ores[random(1, size_of_ore_raffle)]
    end

    local position = {x = entity.position.x, y = entity.position.y}

    player.surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = '+' .. harvest_amount .. '  [img=item/' .. harvest .. ']',
            color = {r = 200, g = 160, b = 30}
        }
    )

    if harvest_amount > max_spill then
        if spill_items_to_surface then
            player.surface.spill_item_stack(position, {name = harvest, count = max_spill}, true)
        else
            player.insert({name = harvest, count = max_spill})
        end
        harvest_amount = harvest_amount - max_spill
        local inserted_count = player.insert({name = harvest, count = harvest_amount})
        harvest_amount = harvest_amount - inserted_count
        if harvest_amount > 0 then
            if spill_items_to_surface then
                player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
            else
                player.insert({name = harvest, count = harvest_amount})
            end
        end
    else
        if spill_items_to_surface then
            player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
        else
            player.insert({name = harvest, count = harvest_amount})
        end
    end
    local particle = particles[harvest]
    create_particles(player.surface, particle, position, 64, {x = player.position.x, y = player.position.y})
end

local function randomness_scrap(data)
    local entity = data.entity
    local player = data.player
    local spill_items_to_surface = WPT.get('spill_items_to_surface')

    local harvest = scrap_raffle[random(1, size_of_scrap_raffle)]
    local amount_bonus = (game.forces.enemy.evolution_factor * 2) + (game.forces.player.mining_drill_productivity_bonus * 2)
    local r1 = math.ceil(scrap_yield_amounts[harvest] * (0.3 + (amount_bonus * 0.3)))
    local r2 = math.ceil(scrap_yield_amounts[harvest] * (1.7 + (amount_bonus * 1.7)))
    local harvest_amount = math.random(r1, r2)

    local position = {x = entity.position.x, y = entity.position.y}

    player.surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = '+' .. harvest_amount .. '  [img=item/' .. harvest .. ']',
            color = {r = 200, g = 160, b = 30}
        }
    )

    if harvest_amount > max_spill then
        if spill_items_to_surface then
            player.surface.spill_item_stack(position, {name = harvest, count = max_spill}, true)
        else
            player.insert({name = harvest, count = max_spill})
        end
        harvest_amount = harvest_amount - max_spill
        local inserted_count = player.insert({name = harvest, count = harvest_amount})
        harvest_amount = harvest_amount - inserted_count
        if harvest_amount > 0 then
            if spill_items_to_surface then
                player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
            else
                player.insert({name = harvest, count = harvest_amount})
            end
        end
    else
        if spill_items_to_surface then
            player.surface.spill_item_stack(position, {name = harvest, count = harvest_amount}, true)
        else
            player.insert({name = harvest, count = harvest_amount})
        end
    end
    local particle = particles[harvest]
    create_particles(player.surface, particle, position, 64, {x = player.position.x, y = player.position.y})
end

function Public.on_player_mined_entity(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    local is_scrap = false

    if valid_scrap[entity.name] then
        is_scrap = true
    end

    if valid_rocks[entity.name] or valid_trees[entity.name] or is_scrap then
        event.buffer.clear()

        local data = {
            entity = entity,
            player = player
        }

        local index = player.index

        local scrap_zone = RPG_Settings.get_value_from_player(index, 'scrap_zone')
        if scrap_zone or is_scrap then
            randomness_scrap(data)
        else
            randomness(data)
        end
    end
end

return Public
