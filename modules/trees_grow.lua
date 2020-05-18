-- trees multiply --  mewmew

local event = require 'utils.event'
local math_random = math.random

local vectors = {}
local r = 8
for x = r * -1, r, 0.25 do
    for y = r * -1, r, 0.25 do
        if math.sqrt(x ^ 2 + y ^ 2) <= r then
            vectors[#vectors + 1] = {x, y}
        end
    end
end

local resistant_tiles = {
    ['concrete'] = 8,
    ['hazard-concrete-left'] = 8,
    ['hazard-concrete-right'] = 8,
    ['refined-concrete'] = 24,
    ['refined-hazard-concrete-left'] = 24,
    ['refined-hazard-concrete-right'] = 24,
    ['stone-path'] = 4
}

local blacklist = {
    ['dead-grey-trunk'] = true
}

local function coord_string(x, y)
    str = tostring(x) .. '_'
    str = str .. tostring(y)
    return str
end

local function get_chunk(surface)
    local Diff = Difficulty.get()
    if #global.trees_grow_chunk_raffle == 0 then
        return false
    end
    local p =
        global.trees_grow_chunk_position[global.trees_grow_chunk_raffle[math_random(1, #global.trees_grow_chunk_raffle)]]
    local str = coord_string(p.x, p.y)
    if not global.trees_grow_chunk_next_visit[str] then
        return p
    end
    if global.trees_grow_chunk_next_visit[str] < game.tick then
        return p
    end
    return false
end

local function get_trees(surface)
    local p = get_chunk(surface)
    if not p then
        return false
    end
    local trees =
        surface.find_entities_filtered({type = 'tree', area = {{p.x * 32, p.y * 32}, {p.x * 32 + 32, p.y * 32 + 32}}})

    local a = 750
    if Diff.difficulty_vote_value then
        a = a / Diff.difficulty_vote_value
    end
    global.trees_grow_chunk_next_visit[coord_string(p.x, p.y)] = math.floor(game.tick + math.floor(a + (#trees * 5)))

    if not trees[1] then
        return false
    end
    return trees
end

local function grow_trees(surface)
    local Diff = Difficulty.get()
    local trees = get_trees(surface)
    if not trees then
        return false
    end
    local m = 2
    if Diff.difficulty_vote_index then
        m = Diff.difficulty_vote_index
    end
    for a = 1, math_random(m, math.ceil(m * 1.5)), 1 do
        local tree = trees[math_random(1, #trees)]
        if not blacklist[tree.name] then
            local vector = vectors[math_random(1, #vectors)]

            local p =
                surface.find_non_colliding_position(
                'car',
                {tree.position.x + vector[1], tree.position.y + vector[2]},
                8,
                4
            )
            if p then
                local tile = surface.get_tile(p)
                if resistant_tiles[tile.name] then
                    if math_random(1, resistant_tiles[tile.name]) == 1 then
                        surface.set_tiles({{name = tile.hidden_tile, position = p}})
                        surface.create_entity({name = tree.name, position = p, force = tree.force.name})
                    end
                else
                    surface.create_entity({name = tree.name, position = p, force = tree.force.name})
                end
            end
        end
    end

    return true
end

local function on_chunk_charted(event)
    local position = event.position
    local str = coord_string(position.x, position.y)
    if global.trees_grow_chunks_charted[str] then
        return
    end
    global.trees_grow_chunks_charted[str] = true
    global.trees_grow_chunks_charted_counter = global.trees_grow_chunks_charted_counter + 1

    global.trees_grow_chunk_raffle[#global.trees_grow_chunk_raffle + 1] = str
    global.trees_grow_chunk_position[str] = {x = position.x, y = position.y}
end

local function tick(event)
    if not game.connected_players[1] then
        return
    end
    local surface = game.connected_players[1].surface

    for a = 1, 32, 1 do
        if grow_trees(surface) then
            break
        end
    end
end

local function on_init(event)
    global.trees_grow_chunk_next_visit = {}
    global.trees_grow_chunk_raffle = {}
    global.trees_grow_chunk_position = {}

    global.trees_grow_chunks_charted = {}
    global.trees_grow_chunks_charted_counter = 0
end

event.on_init(on_init)
event.on_nth_tick(1, tick)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
