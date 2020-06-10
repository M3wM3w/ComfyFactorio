local math_random = math.random

local death_animation_ticks = 120
local decay_ticks = 2

local worms = {
    ["small-worm-turret"] = { corpse="small-worm-corpse", patch_size = { min=30000, max=90000} },
    ["medium-worm-turret"] = { corpse="medium-worm-corpse", patch_size = { min=60000, max=120000 } },
    ["big-worm-turret"] = { corpse="big-worm-corpse", patch_size = { min=90000, max=300000 } }
}

local function destroy_worm(name, position, surface)
    local entity = surface.find_entity(name, position)
    if entity ~= nil and entity.valid then entity.destroy() end
    local corpse = worms[name].corpse
    local remains = surface.find_entity(corpse, position)
    if remains ~= nil and remains.valid then
        -- show an animation
        if math_random(1,40) == 1 then surface.create_entity({name = "explosion", position = {x = position.x + (3 - (math_random(1,60) * 0.1)), y = position.y + (3 - (math_random(1,60) * 0.1))}}) end
        if math_random(1,32) == 1 then surface.create_entity({name = "blood-explosion-huge", position = position}) end
        if math_random(1,16) == 1 then surface.create_entity({name = "blood-explosion-big", position = position}) end
        if math_random(1,8) == 1 then surface.create_entity({name = "blood-explosion-small", position = position}) end
    end
end

local function remove_corpse(name, position, surface)
    local corpse = worms[name].corpse
    local remains = surface.find_entity(corpse, position)
    if remains ~= nil and remains.valid then remains.destroy() end
end

-- place an oil patch at the worm location
local function create_oil_patch(name, position, surface)
    local min = worms[name].patch_size.min
    local max = worms[name].patch_size.max
    surface.create_entity({name="crude-oil", position=position, amount=math_random(min,max)})
end

-- worms create oil patches when killed
local function process_worm(entity)
    local name = entity.name
    local position = entity.position
    local surface = entity.surface

    local tick1 = game.tick + death_animation_ticks
    if not global.on_tick_schedule[tick1] then global.on_tick_schedule[tick1] = {} end
    global.on_tick_schedule[tick1][#global.on_tick_schedule[tick1]+1] = {
        func = destroy_worm,
        args = {name, position, surface}
    }

    local tick2 = game.tick + death_animation_ticks + decay_ticks
    if not global.on_tick_schedule[tick2] then global.on_tick_schedule[tick2] = {} end
    global.on_tick_schedule[tick2][#global.on_tick_schedule[tick2]+1] = {
        func = remove_corpse,
        args = {name, position, surface}
    }

    local tick3 = game.tick + death_animation_ticks + decay_ticks + 1
    if not global.on_tick_schedule[tick3] then global.on_tick_schedule[tick3] = {} end
    global.on_tick_schedule[tick3][#global.on_tick_schedule[tick3]+1] = {
        func = create_oil_patch,
        args = {name, position, surface}
    }

end

local function on_entity_died(event)
    local entity = event.entity
    local test = {
        ["small-worm-turret"] = true,
        ["medium-worm-turret"] = true,
        ["big-worm-turret"] = true
    }
    if test[entity.name] ~= nil then
        process_worm(entity)
    end
end

local Event = require 'utils.event'
Event.add(defines.events.on_entity_died, on_entity_died)