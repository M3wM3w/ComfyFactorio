-- one table to rule them all!
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

function Public.reset_table()
    -- @start
    -- these 3 are in case of stop/start/reloading the instance.
    this.soft_reset = true
    this.restart = false
    this.shutdown = false
    this.announced_message = false
    -- @end
    this.game_has_ended = false
    this.game_reset = false
    this.spawn_area_generated = false
    this.results_sent = false
    this.explosive_bullets_unlocked = false
    this.bouncy_shells_unlocked = false
    this.trapped_capsules_unlocked = false
    this.ultra_mines_unlocked = false
    this.laser_pointer_unlocked = false
    this.railgun_enhancer_unlocked = false
    this.crumbly_walls_unlocked = false
    this.vehicle_nanobots_unlocked = false
    this.game_restart_timer = nil
    this.wave_count = 0
    this.attack_wave_threat = nil
    this.market = nil
    this.market_age = nil
    this.last_reset = game.tick
    this.wave_interval = 3600
    this.wave_grace_period = game.tick + 3600 * 20
    this.boss_biters = {}
    this.acid_lines_delay = {}
    this.entity_limits = {
        ['gun-turret'] = {placed = 1, limit = 1, str = 'gun turret', slot_price = 75},
        ['laser-turret'] = {placed = 0, limit = 1, str = 'laser turret', slot_price = 300},
        ['artillery-turret'] = {placed = 0, limit = 1, str = 'artillery turret', slot_price = 500},
        ['flamethrower-turret'] = {placed = 0, limit = 0, str = 'flamethrower turret', slot_price = 50000},
        ['land-mine'] = {placed = 0, limit = 1, str = 'mine', slot_price = 6}
    }
    this.difficulties_votes = {
        [1] = {wave_interval = 4500, amount_modifier = 0.52, strength_modifier = 0.40, boss_modifier = 3.0},
        [2] = {wave_interval = 4100, amount_modifier = 0.76, strength_modifier = 0.65, boss_modifier = 4.0},
        [3] = {wave_interval = 3800, amount_modifier = 0.92, strength_modifier = 0.85, boss_modifier = 5.0},
        [4] = {wave_interval = 3600, amount_modifier = 1.00, strength_modifier = 1.00, boss_modifier = 6.0},
        [5] = {wave_interval = 3400, amount_modifier = 1.08, strength_modifier = 1.25, boss_modifier = 7.0},
        [6] = {wave_interval = 3100, amount_modifier = 1.24, strength_modifier = 1.75, boss_modifier = 8.0},
        [7] = {wave_interval = 2700, amount_modifier = 1.48, strength_modifier = 2.50, boss_modifier = 9.0}
    }
    this.boss_waves = {
        [50] = {{name = 'big-biter', count = 3}},
        [100] = {{name = 'behemoth-biter', count = 1}},
        [150] = {{name = 'behemoth-spitter', count = 4}, {name = 'big-spitter', count = 16}},
        [200] = {
            {name = 'behemoth-biter', count = 4},
            {name = 'behemoth-spitter', count = 2},
            {name = 'big-biter', count = 32}
        },
        [250] = {
            {name = 'behemoth-biter', count = 8},
            {name = 'behemoth-spitter', count = 4},
            {name = 'big-spitter', count = 32}
        },
        [300] = {{name = 'behemoth-biter', count = 16}, {name = 'behemoth-spitter', count = 8}}
    }
    this.comfylatron_habitat = {
        left_top = {x = -1500, y = -1500},
        right_bottom = {x = -80, y = 1500}
    }
    this.map_height = 96
    this.shotgun_shell_damage_modifier_old = {}
    this.flame_boots = {}
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
