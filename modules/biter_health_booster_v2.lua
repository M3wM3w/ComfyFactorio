-- Biters, Spawners and Worms gain additional health / resistance -- mewmew
-- modified by Gerkiz
-- Use this.biter_health_boost or this.biter_health_boost_forces to modify their health.
-- 1 = vanilla health, 2 = 200% vanilla health
-- do not use values below 1
local Event = require 'utils.event'
local Global = require 'utils.global'

local floor = math.floor
local insert = table.insert
local round = math.round
local Public = {}

local this = {
    biter_health_boost = 1,
    biter_health_boost_forces = {},
    biter_health_boost_units = {},
    biter_health_boost_count = 0,
    active_surface = 'nauvis'
}

Global.register(
    this,
    function(t)
        this = t
    end
)

function Public.reset_table()
    this.biter_health_boost = 1
    this.biter_health_boost_forces = {}
    this.biter_health_boost_units = {}
    this.biter_health_boost_count = 0
    this.active_surface = 'nauvis'
    this.check_on_entity_died = false
end

local entity_types = {
    ['unit'] = true,
    ['turret'] = true,
    ['unit-spawner'] = true
}

if is_loaded('maps.biter_hatchery.terrain') then
    entity_types['unit-spawner'] = nil
end

local function clean_table()
    --Perform a table cleanup every 500 boosts
    this.biter_health_boost_count = this.biter_health_boost_count + 1
    if this.biter_health_boost_count % 500 ~= 0 then
        return
    end

    local units_to_delete = {}

    --Mark all health boost entries for deletion
    for key, _ in pairs(this.biter_health_boost_units) do
        units_to_delete[key] = true
    end

    --Remove valid health boost entries from deletion
    local validTypes = {}
    for k, v in pairs(entity_types) do
        if v then
            insert(validTypes, k)
        end
    end

    local surface = game.surfaces[this.active_surface]

    for _, unit in pairs(surface.find_entities_filtered({type = validTypes})) do
        units_to_delete[unit.unit_number] = nil
    end

    --Remove abandoned health boost entries
    for key, _ in pairs(units_to_delete) do
        this.biter_health_boost_units[key] = nil
    end
end

local function create_boss_healthbar(entity, size)
    return rendering.draw_sprite(
        {
            sprite = 'virtual-signal/signal-white',
            tint = {0, 200, 0},
            x_scale = size * 15,
            y_scale = size,
            render_layer = 'light-effect',
            target = entity,
            target_offset = {0, -2.5},
            surface = entity.surface
        }
    )
end

local function set_boss_healthbar(health, max_health, healthbar_id)
    local m = health / max_health
    local x_scale = rendering.get_y_scale(healthbar_id) * 15
    rendering.set_x_scale(healthbar_id, x_scale * m)
    rendering.set_color(healthbar_id, {floor(255 - 255 * m), floor(200 * m), 0})
end

function Public.add_unit(unit, health_multiplier)
    if not health_multiplier then
        health_multiplier = this.biter_health_boost
    end
    this.biter_health_boost_units[unit.unit_number] = {
        floor(unit.prototype.max_health * health_multiplier),
        round(1 / health_multiplier, 5)
    }
end

function Public.add_boss_unit(unit, health_multiplier, health_bar_size)
    if not health_multiplier then
        health_multiplier = this.biter_health_boost
    end
    if not health_bar_size then
        health_bar_size = 0.5
    end
    local health = floor(unit.prototype.max_health * health_multiplier)
    this.biter_health_boost_units[unit.unit_number] = {
        health,
        round(1 / health_multiplier, 5),
        {max_health = health, healthbar_id = create_boss_healthbar(unit, health_bar_size), last_update = game.tick}
    }
end

local function on_entity_damaged(event)
    local biter = event.entity
    if not (biter and biter.valid) then
        return
    end
    if not entity_types[biter.type] then
        return
    end

    local biter_health_boost_units = this.biter_health_boost_units

    local unit_number = biter.unit_number

    --Create new health pool
    local health_pool = biter_health_boost_units[unit_number]
    if not health_pool then
        if this.biter_health_boost_forces[biter.force.index] then
            Public.add_unit(biter, this.biter_health_boost_forces[biter.force.index])
        else
            Public.add_unit(biter, this.biter_health_boost)
        end
        health_pool = this.biter_health_boost_units[unit_number]
    end

    --Process boss unit health bars
    local boss = health_pool[3]
    if boss then
        if boss.last_update + 10 < game.tick then
            set_boss_healthbar(health_pool[1], boss.max_health, boss.healthbar_id)
            boss.last_update = game.tick
        end
    end

    --Reduce health pool
    health_pool[1] = health_pool[1] - event.final_damage_amount

    --Set entity health relative to health pool
    biter.health = health_pool[1] * health_pool[2]

    --Proceed to kill entity if health is 0
    if biter.health > 0 then
        return
    end

    if event.cause then
        if event.cause.valid then
            event.entity.die(event.cause.force, event.cause)
            return
        end
    end
    biter.die(biter.force)
end

local function on_entity_died(event)
    if not this.check_on_entity_died then
        return
    end

    local biter = event.entity
    if not (biter and biter.valid) then
        return
    end
    if not entity_types[biter.type] then
        return
    end

    local biter_health_boost_units = this.biter_health_boost_units

    local unit_number = biter.unit_number

    local health_pool = biter_health_boost_units[unit_number]
    if health_pool then
        biter_health_boost_units[unit_number] = nil
    end
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.set_active_surface(str)
    if str and type(str) == 'string' then
        this.active_surface = str
    end
    return this.active_surface
end

function Public.check_on_entity_died(boolean)
    this.check_on_entity_died = boolean or false

    return this.check_on_entity_died
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.on_nth_tick(7200, clean_table)
Event.add(defines.events.on_entity_died, on_entity_died)

return Public
