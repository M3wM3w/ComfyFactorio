local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'

local tick_tacks = {'*tick*', '*tick*', '*tack*', '*tak*', '*tik*', '*tok*'}

local kaboom_weights = {
    {name = 'grenade', chance = 7},
    {name = 'cluster-grenade', chance = 1},
    {name = 'destroyer-capsule', chance = 1},
    {name = 'defender-capsule', chance = 4},
    {name = 'distractor-capsule', chance = 2},
    {name = 'poison-capsule', chance = 2},
    {name = 'explosive-uranium-cannon-projectile', chance = 3},
    {name = 'explosive-cannon-projectile', chance = 5}
}

local kabooms = {}
for _, t in pairs(kaboom_weights) do
    for _ = 1, t.chance, 1 do
        kabooms[#kabooms + 1] = t.name
    end
end

local function create_flying_text(surface, position, text)
    if not surface.valid then
        return
    end
    surface.create_entity(
        {
            name = 'flying-text',
            position = position,
            text = text,
            color = {r = 0.75, g = 0.75, b = 0.75}
        }
    )

    surface.play_sound({path = 'utility/armor_insert', position = position, volume_modifier = 0.75})
end

local function create_kaboom(surface, position, name)
    if not surface.valid then
        return
    end

    local target = position
    local speed = 0.5
    if name == 'defender-capsule' or name == 'destroyer-capsule' or name == 'distractor-capsule' then
        surface.create_entity(
            {
                name = 'flying-text',
                position = position,
                text = '(((Sentries Engaging Target)))',
                color = {r = 0.8, g = 0.0, b = 0.0}
            }
        )
        local nearest_player_unit =
            surface.find_nearest_enemy({position = position, max_distance = 128, force = 'enemy'})
        if nearest_player_unit then
            target = nearest_player_unit.position
        end
        speed = 0.001
    end
    surface.create_entity(
        {
            name = name,
            position = position,
            force = 'enemy',
            target = target,
            speed = speed
        }
    )
end

local function tick_tack_trap(surface, position)
    if not surface then
        return
    end
    if not surface.valid then
        return
    end
    if not position then
        return
    end
    if not position.x then
        return
    end
    if not position.y then
        return
    end
    local traps = WPT.get('traps')
    local tick_tack_count = math.random(5, 9)
    for t = 60, tick_tack_count * 60, 60 do
        if not traps[game.tick + t] then
            traps[game.tick + t] = {}
        end

        if t < tick_tack_count * 60 then
            traps[game.tick + t][#traps[game.tick + t] + 1] = {
                callback = 'create_flying_text',
                params = {surface, {x = position.x, y = position.y}, tick_tacks[math.random(1, #tick_tacks)]}
            }
        else
            if math.random(1, 10) == 1 then
                traps[game.tick + t][#traps[game.tick + t] + 1] = {
                    callback = 'create_flying_text',
                    params = {surface, {x = position.x, y = position.y}, '( ͡° ͜ʖ ͡°)'}
                }
            else
                traps[game.tick + t][#traps[game.tick + t] + 1] = {
                    callback = 'create_kaboom',
                    params = {surface, {x = position.x, y = position.y}, kabooms[math.random(1, #kabooms)]}
                }
            end
        end
    end
end

local function on_tick()
    local traps = WPT.get('traps')
    if not traps[game.tick] then
        return
    end
    for _, token in pairs(traps[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'create_kaboom' then
            create_kaboom(params[1], params[2], params[3])
        elseif callback == 'create_flying_text' then
            create_flying_text(params[1], params[2], params[3])
        end
    end
    traps[game.tick] = nil
end

Event.add(defines.events.on_tick, on_tick)

return tick_tack_trap
