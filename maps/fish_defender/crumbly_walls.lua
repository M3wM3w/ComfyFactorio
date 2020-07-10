local Event = require 'utils.event'
local FDT = require 'maps.fish_defender.table'
local math_random = math.random

local rock_raffle = {'sand-rock-big', 'rock-big', 'rock-big', 'rock-big', 'rock-huge'}

local function on_entity_died(event)
    local crumbly_walls_unlocked = FDT.get('crumbly_walls_unlocked')
    if not crumbly_walls_unlocked then
        return
    end
    local entity = event.entity
    if not entity.valid then
        return
    end
    if entity.name ~= 'stone-wall' then
        return
    end
    if math_random(1, 4) == 1 then
        return
    end
    entity.surface.create_entity(
        {name = rock_raffle[math_random(1, #rock_raffle)], position = entity.position, force = 'player'}
    )
end

Event.add(defines.events.on_entity_died, on_entity_died)
