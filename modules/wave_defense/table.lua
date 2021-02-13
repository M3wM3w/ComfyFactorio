local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

function Public.debug_module()
    this.next_wave = 1000
    this.wave_interval = 500
    this.wave_enforced = true
    this.debug = true
end

function Public.reset_wave_defense()
    this.boss_wave = false
    this.boss_wave_warning = false
    this.side_target_count = 0
    this.active_biters = {}
    this.active_biter_count = 0
    this.active_biter_threat = 0
    this.average_unit_group_size = 24
    this.biter_raffle = {}
    this.debug = false
    this.game_lost = false
    this.get_random_close_spawner_attempts = 5
    this.group_size = 2
    this.last_wave = game.tick
    this.max_active_biters = 1280
    this.max_active_unit_groups = 32
    this.max_biter_age = 3600 * 60
    this.nests = {}
    this.nest_building_density = 48
    this.next_wave = game.tick + 3600 * 15
    this.side_targets = {}
    this.simple_entity_shredding_cost_modifier = 0.009
    this.spawn_position = {x = 0, y = 64}
    this.spitter_raffle = {}
    this.surface_index = 1
    this.target = nil
    this.threat = 0
    this.threat_gain_multiplier = 2
    this.threat_log = {}
    this.threat_log_index = 0
    this.unit_groups = {}
    this.unit_group_pos = {
        positions = {}
    }
    this.index = 0
    this.random_group = nil
    this.unit_group_command_delay = 3600 * 20
    this.unit_group_command_step_length = 15
    this.unit_group_last_command = {}
    this.wave_interval = 3600
    this.wave_enforced = false
    this.wave_number = 0
    this.worm_building_chance = 3
    this.worm_building_density = 16
    this.worm_raffle = {}
    this.clear_corpses = false
    this.biter_health_boost = 1
    this.alert_boss_wave = false
    this.remove_entities = false
    this.enable_side_target = false
    this.enable_threat_log = true
    this.disable_threat_below_zero = false
    this.check_collapse_position = true
    this.resolve_pathing = true
    this.increase_damage_per_wave = false
    this.increase_boss_health_per_wave = true
    this.increase_health_per_wave = false
    this.fill_tiles_so_biter_can_path = true
    this.modified_unit_health = 1.02
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false or value == 'nil') then
        if value == 'nil' then
            this[key] = nil
        else
            this[key] = value
        end
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Public.get_table = Public.get

function Public.clear_corpses(value)
    if (value or value == false) then
        this.clear_corpses = value
    end
    return this.clear_corpses
end

function Public.get_wave()
    return this.wave_number
end

function Public.get_disable_threat_below_zero()
    return this.disable_threat_below_zero
end

function Public.set_disable_threat_below_zero(boolean)
    if (boolean or boolean == false) then
        this.disable_threat_below_zero = boolean
    end
    return this.disable_threat_below_zero
end

function Public.get_alert_boss_wave()
    return this.get_alert_boss_wave
end

function Public.alert_boss_wave(boolean)
    if (boolean or boolean == false) then
        this.alert_boss_wave = boolean
    end
    return this.alert_boss_wave
end

function Public.set_spawn_position(tbl)
    if type(tbl) == 'table' then
        this.spawn_position = tbl
    else
        error('Tbl must be of type table.')
    end
    return this.spawn_position
end

function Public.remove_entities(boolean)
    if (boolean or boolean == false) then
        this.remove_entities = boolean
    end
    return this.remove_entities
end

function Public.increase_health_per_wave(boolean)
    if (boolean or boolean == false) then
        this.increase_health_per_wave = boolean
    end
    return this.increase_health_per_wave
end

function Public.enable_threat_log(boolean)
    if (boolean or boolean == false) then
        this.enable_threat_log = boolean
    end
    return this.enable_threat_log
end

function Public.check_collapse_position(boolean)
    if (boolean or boolean == false) then
        this.check_collapse_position = boolean
    end
    return this.check_collapse_position
end

function Public.enable_side_target(boolean)
    if (boolean or boolean == false) then
        this.enable_side_target = boolean
    end
    return this.enable_side_target
end

function Public.increase_boss_health_per_wave(boolean)
    if (boolean or boolean == false) then
        this.increase_boss_health_per_wave = boolean
    end
    return this.increase_boss_health_per_wave
end

function Public.resolve_pathing(boolean)
    if (boolean or boolean == false) then
        this.resolve_pathing = boolean
    end
    return this.resolve_pathing
end

function Public.fill_tiles_so_biter_can_path(boolean)
    if (boolean or boolean == false) then
        this.fill_tiles_so_biter_can_path = boolean
    end
    return this.fill_tiles_so_biter_can_path
end

function Public.increase_damage_per_wave(boolean)
    if (boolean or boolean == false) then
        this.increase_damage_per_wave = boolean
    end
    return this.increase_damage_per_wave
end

function Public.set_biter_health_boost(number)
    if number and type(number) == 'number' then
        this.biter_health_boost = number
    else
        this.biter_health_boost = 1
    end
    return this.biter_health_boost
end

local on_init = function()
    Public.reset_wave_defense()
end

-- Event.on_nth_tick(30, Public.debug_module)

Event.on_init(on_init)

return Public
