local Global = require 'utils.global'
local Event = require 'utils.event'

local wave_defense = {}
local Public = {}

Global.register(
    wave_defense,
    function(tbl)
        wave_defense = tbl
    end
)

function Public.reset_wave_defense()
    wave_defense.boss_wave = false
    wave_defense.boss_wave_warning = false
    wave_defense.side_target_count = 0
    wave_defense.active_biters = {}
    wave_defense.active_biter_count = 0
    wave_defense.active_biter_threat = 0
    wave_defense.average_unit_group_size = 168
    wave_defense.biter_raffle = {}
    wave_defense.debug = false
    wave_defense.game_lost = false
    wave_defense.get_random_close_spawner_attempts = 5
    wave_defense.group_size = 2
    wave_defense.last_wave = game.tick
    wave_defense.max_active_biters = 1280
    wave_defense.max_active_unit_groups = 8
    wave_defense.max_biter_age = 3600 * 60
    wave_defense.nest_building_density = 48
    wave_defense.next_wave = game.tick + 3600 * 15
    wave_defense.side_targets = {}
    wave_defense.simple_entity_shredding_cost_modifier = 0.005
    wave_defense.spawn_position = {x = 0, y = 64}
    wave_defense.spitter_raffle = {}
    wave_defense.surface_index = 1
    wave_defense.target = nil
    wave_defense.threat = 0
    wave_defense.threat_gain_multiplier = 2
    wave_defense.threat_log = {}
    wave_defense.threat_log_index = 0
    wave_defense.unit_groups = {}
    wave_defense.unit_group_command_delay = 3600 * 15
    wave_defense.unit_group_command_step_length = 20
    wave_defense.unit_group_last_command = {}
    wave_defense.wave_interval = 3600
    wave_defense.wave_number = 0
    wave_defense.worm_building_chance = 3
    wave_defense.worm_building_density = 16
    wave_defense.worm_raffle = {}
    wave_defense.clear_corpses = false
    wave_defense.alert_boss_wave = false
end

function Public.get_table()
    return wave_defense
end

function Public.clear_corpses(value)
    if value then
        wave_defense.clear_corpses = value
    end
    return wave_defense.clear_corpses
end

function Public.get_wave()
    return wave_defense.wave_number
end

function Public.alert_boss_wave(value)
    if value then
        wave_defense.alert_boss_wave = value
    end
    return wave_defense.alert_boss_wave
end

local on_init = function()
    Public.reset_wave_defense()
end

Event.on_init(on_init)

return Public
