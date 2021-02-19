-- Biters, Spawners and Worms gain additional health / resistance -- mewmew
-- modified by Gerkiz
-- Use this.biter_health_boost or this.biter_health_boost_forces to modify their health.
-- 1 = vanilla health, 2 = 200% vanilla health
-- do not use values below 1

local Event = require 'utils.event'
local LootDrop = require 'modules.mobs_drop_loot'
local WD = require 'modules.wave_defense.table'
local Global = require 'utils.global'

local floor = math.floor
local insert = table.insert
local round = math.round
local random = math.random
local sqrt = math.sqrt
local Public = {}

local this = {
    biter_health_boost = 1,
    biter_health_boost_forces = {},
    biter_health_boost_units = {},
    biter_health_boost_count = 0,
    active_surface = 'nauvis',
    acid_lines_delay = {},
    acid_nova = false,
    boss_spawns_projectiles = false,
    enable_boss_loot = false
}

local radius = 6
local targets = {}
local acid_splashes = {
    ['big-biter'] = 'acid-stream-worm-medium',
    ['behemoth-biter'] = 'acid-stream-worm-big'
}
local acid_lines = {
    ['big-spitter'] = 'acid-stream-spitter-big',
    ['behemoth-spitter'] = 'acid-stream-spitter-big'
}
for x = radius * -1, radius, 1 do
    for y = radius * -1, radius, 1 do
        if sqrt(x ^ 2 + y ^ 2) <= radius then
            targets[#targets + 1] = {x = x, y = y}
        end
    end
end

local projectiles = {
    'slowdown-capsule',
    'defender-capsule',
    'destroyer-capsule',
    'laser',
    'distractor-capsule',
    'rocket',
    'explosive-rocket',
    'grenade',
    'rocket',
    'grenade'
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
    this.acid_lines_delay = {}
    this.acid_nova = false
    this.boss_spawns_projectiles = false
    this.enable_boss_loot = false
end

local entity_types = {
  ['car'] = true,
    ['tank'] = true,
    ['spidertron'] = true,
     ['spider-vehicle'] = true
    --['unit-spawner'] = true
}

if is_loaded('maps.biter_hatchery.terrain') then
    entity_types['unit-spawner'] = nil
end

local function loaded_biters(event)
    local cause = event.cause
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local position = false
    if cause then
        if cause.valid then
            position = cause.position
        end
    end
    if not position then
        position = {entity.position.x + (-20 + random(0, 40)), entity.position.y + (-20 + random(0, 40))}
    end

    entity.surface.create_entity(
        {
            name = projectiles[random(1, 10)],
            position = entity.position,
            force = 'neutral',
            source = entity.position,
            target = position,
            max_range = 16,
            speed = 0.01
        }
    )
end

local function acid_nova(event)
    for _ = 1, random(20, 40) do
        local i = random(1, #targets)
        event.entity.surface.create_entity(
            {
                name = acid_splashes[event.entity.name],
                position = event.entity.position,
                force = event.entity.force.name,
                source = event.entity.position,
                target = {x = event.entity.position.x + targets[i].x, y = event.entity.position.y + targets[i].y},
                max_range = radius,
                speed = 0.001
            }
        )
    end
end
local function acid_line(surface, name, source, target)
    local distance = sqrt((source.x - target.x) ^ 2 + (source.y - target.y) ^ 2)
    local modifier = {(target.x - source.x) / distance, (target.y - source.y) / distance}

    local position = {source.x, source.y}

    for i = 1, distance * 1.5, 1 do
        if random(1, 2) ~= 1 then
            surface.create_entity(
                {
                    name = name,
                    position = source,
                    force = 'enemy',
                    source = source,
                    target = position,
                    max_range = 25,
                    speed = 1
                }
            )
        end
        position = {position[1] + modifier[1], position[2] + modifier[2]}
    end
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
        round(1 / health_multiplier, 5),
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

    local biter_health_boost_units = this.biter_health_boost_units

    local unit_number = biter.unit_number

    --Create new health pool
    local health_pool = biter_health_boost_units[unit_number]

    if not entity_types[biter.type] then
        return
    end

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

    local wave_count = WD.get_wave()

    local health_pool = biter_health_boost_units[unit_number]
    if health_pool and health_pool[3] then
        if this.enable_boss_loot then
            if random(1, 128) == 1 then
                LootDrop.drop_loot(biter, wave_count)
            end
        end
        if this.boss_spawns_projectiles then
            if random(1, 96) == 1 then
                loaded_biters(event)
            end
        end
        biter_health_boost_units[unit_number] = nil
        if this.acid_nova then
            if acid_splashes[biter.name] then
                acid_nova(event)
            end
            if this.acid_lines_delay[biter.unit_number] then
                this.acid_lines_delay[biter.unit_number] = nil
            end
        end
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

function Public.acid_nova(value)
    this.acid_nova = value or false
    return this.acid_nova
end

function Public.check_on_entity_died(boolean)
    this.check_on_entity_died = boolean or false

    return this.check_on_entity_died
end

function Public.boss_spawns_projectiles(boolean)
    this.boss_spawns_projectiles = boolean or false

    return this.boss_spawns_projectiles
end

function Public.enable_boss_loot(boolean)
    this.enable_boss_loot = boolean or false

    return this.enable_boss_loot
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.on_nth_tick(7200, clean_table)
Event.add(defines.events.on_entity_died, on_entity_died)

return Public
