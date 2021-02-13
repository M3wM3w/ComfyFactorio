local math_random = math.random

local Global = require 'utils.global'
local tick_schedule = {}
Global.register(
        tick_schedule,
        function(t)
            tick_schedule = t
        end
)

local death_animation_ticks = 120
local decay_ticks = 2

local worms = {
    ["small-worm-turret"] = { corpse="small-worm-corpse", patch_size = { min=30000, max=90000} },
    ["medium-worm-turret"] = { corpse="medium-worm-corpse", patch_size = { min=60000, max=120000 } },
    ["big-worm-turret"] = { corpse="big-worm-corpse", patch_size = { min=90000, max=300000 } },
    ["behemoth-worm-turret"] = { corpse="behemoth-worm-corpse", patch_size = { min=120000, max=600000 } }
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
    if not tick_schedule[tick1] then tick_schedule[tick1] = {} end
    tick_schedule[tick1][#tick_schedule[tick1] + 1] = {
        callback = 'destroy_worm',
        params = {name, position, surface}
    }
    local tick2 = game.tick + death_animation_ticks + decay_ticks
    if not tick_schedule[tick2] then tick_schedule[tick2] = {} end
    tick_schedule[tick2][#tick_schedule[tick2] + 1] = {
        callback = 'remove_corpse',
        params = {name, position, surface}
    }
    if math_random(1,4) == 1 then
        local tick3 = game.tick + death_animation_ticks + decay_ticks + 1
        if not tick_schedule[tick3] then tick_schedule[tick3] = {} end
        tick_schedule[tick3][#tick_schedule[tick3] + 1] = {
            callback = 'create_oil_patch',
            params = {name, position, surface}
        }
    end
end

local function on_entity_died(event)
    local entity = event.entity
    local test = {
        ["small-worm-turret"] = true,
        ["medium-worm-turret"] = true,
        ["big-worm-turret"] = true,
        ["behemoth-worm-turret"] = true
    }
    if test[entity.name] ~= nil then
        process_worm(entity)
    end
end

local function on_tick()
    if not tick_schedule[game.tick] then return end
    for _, token in pairs(tick_schedule[game.tick]) do
        local callback = token.callback
        local params = token.params
        if callback == 'destroy_worm' then destroy_worm(params[1], params[2], params[3]) end
        if callback == 'remove_corpse' then remove_corpse(params[1], params[2], params[3]) end
        if callback == 'create_oil_patch' then create_oil_patch(params[1], params[2], params[3]) end
    end
    tick_schedule[game.tick] = nil
end

local Event = require 'utils.event'
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_entity_died, on_entity_died)