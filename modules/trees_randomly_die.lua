-- trees get randomly hit by lightning strikes --  mewmew

local event = require 'utils.event'
local Difficulty = require 'modules.difficulty_vote'
local math_random = math.random

local difficulties_votes = {
    [1] = 128,
    [2] = 64,
    [3] = 32,
    [4] = 16,
    [5] = 8,
    [6] = 4,
    [7] = 2
}

local function create_particles(surface, name, position, amount)
    local Diff = Difficulty.get()

    local direction_mod = (-100 + math_random(0, 200)) * 0.0005
    local direction_mod_2 = (-100 + math_random(0, 200)) * 0.0005

    for i = 1, amount, 1 do
        local m = math_random(12, 18)
        local m2 = m * 0.005

        surface.create_particle(
            {
                name = name,
                position = position,
                frame_speed = 1,
                vertical_speed = 0.130,
                height = 0,
                movement = {
                    (m2 - (math_random(0, m) * 0.01)) + direction_mod,
                    (m2 - (math_random(0, m) * 0.01)) + direction_mod_2
                }
            }
        )
    end

    surface.create_entity(
        {
            name = 'railgun-beam',
            position = {x = position.x, y = position.y},
            target = {x = (position.x - 6) + math.random(0, 12), y = position.y - math.random(12, 24)}
        }
    )
    surface.create_entity(
        {
            name = 'fire-flame',
            position = {x = position.x, y = position.y}
        }
    )

    local r = 8
    if Diff.difficulty_vote_index then
        r = difficulties_votes[Diff.difficulty_vote_index]
    end

    if math_random(1, r) == 1 then
        surface.create_entity(
            {
                name = 'explosive-cannon-projectile',
                position = position,
                force = 'enemy',
                source = position,
                target = position,
                max_range = 1,
                speed = 1
            }
        )
    end
end

local r = 128
local function get_random_area(surface)
    local p = game.players[math_random(1, #game.players)].position
    if not p then
        return
    end
    local area = {{p.x - r, p.y - r}, {p.x + r, p.y + r}}
    return area
end

local function kill_random_tree(surface)
    local trees = surface.find_entities_filtered({type = 'tree', area = get_random_area(surface)})
    if not trees[1] then
        return false
    end
    local tree = trees[math_random(1, #trees)]
    create_particles(surface, 'wooden-particle', tree.position, 320)
    tree.die()
    return true
end

local function tick()
    local Diff = Difficulty.get()
    local r = 48
    if Diff.difficulty_vote_index then
        r = difficulties_votes[Diff.difficulty_vote_index]
    end
    if math_random(1, r) ~= 1 then
        return
    end
    local surface = game.players[1].surface
    for a = 1, 8, 1 do
        if kill_random_tree(surface) then
            return
        end
    end
end

event.on_nth_tick(60, tick)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
