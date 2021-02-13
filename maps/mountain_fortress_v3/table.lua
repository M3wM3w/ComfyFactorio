-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    players = {},
    traps = {}
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

Public.level_depth = 704
Public.level_width = 512

Public.pickaxe_upgrades = {
    'Wood',
    'Plastic',
    'Bone',
    'Alabaster',
    'Lead',
    'Zinc',
    'Tin',
    'Salt',
    'Bauxite',
    'Borax',
    'Bismuth',
    'Amber',
    'Galena',
    'Calcite',
    'Aluminium',
    'Silver',
    'Gold',
    'Copper',
    'Marble',
    'Brass',
    'Flourite',
    'Platinum',
    'Nickel',
    'Iron',
    'Manganese',
    'Apatite',
    'Uraninite',
    'Turquoise',
    'Hematite',
    'Glass',
    'Magnetite',
    'Concrete',
    'Pyrite',
    'Steel',
    'Zircon',
    'Titanium',
    'Silicon',
    'Quartz',
    'Garnet',
    'Flint',
    'Tourmaline',
    'Beryl',
    'Topaz',
    'Chrysoberyl',
    'Chromium',
    'Tungsten',
    'Corundum',
    'Tungsten',
    'Diamond',
    'Penumbrite',
    'Meteorite',
    'Crimtane',
    'Obsidian',
    'Demonite',
    'Mythril',
    'Adamantite',
    'Chlorophyte',
    'Densinium',
    'Luminite'
}

function Public.reset_table()
    -- @start
    -- these 3 are in case of stop/start/reloading the instance.
    this.soft_reset = true
    this.restart = false
    this.shutdown = false
    this.announced_message = false
    this.game_saved = false
    -- @end
    this.icw_locomotive = nil
    this.debug = false
    this.game_lost = false
    this.fullness_enabled = true
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.gap_between_zones = {
        set = false,
        gap = 900,
        neg_gap = -500,
        highest_pos = 0
    }
    this.force_chunk = false
    this.train_upgrades = 0
    this.biter_pets = {}
    this.flamethrower_damage = {}
    this.mined_scrap = 0
    this.biters_killed = 0
    this.cleared_nauvis = false
    this.locomotive_xp_aura = 40
    this.locomotive_pos = {tbl = {}}
    this.trusted_only_car_tanks = true
    this.xp_points = 0
    this.xp_points_upgrade = 0
    --!grief prevention
    this.enable_arties = 6 -- default to callback 6
    --!snip
    this.poison_deployed = false
    this.robotics_deployed = false
    this.upgrades = {
        showed_text = false,
        landmine = {
            limit = 25,
            bought = 0,
            built = 0
        },
        flame_turret = {
            limit = 6,
            bought = 0,
            built = 0
        },
        unit_number = {
            landmine = {},
            flame_turret = {}
        }
    }
    this.aura_upgrades = 0
    this.pickaxe_tier = 1
    this.pickaxe_speed_per_purchase = 0.10
    this.health_upgrades = 0
    this.breached_wall = 1
    this.left_top = {
        x = 0,
        y = 0
    }
    this.biters = {
        amount = 0,
        limit = 512
    }
    this.traps = {}
    this.munch_time = true
    this.coin_amount = 1
    this.difficulty_set = false
    this.bonus_xp_on_join = 250
    this.main_market_items = {}
    this.spill_items_to_surface = false
    this.outside_chests = {}
    this.chests_linked_to = {}
    this.chest_limit_outside_upgrades = 1
    this.placed_trains_in_zone = {
        placed = 0,
        positions = {},
        limit = 2,
        randomized = false
    }
    this.marked_fixed_prices = {
        chest_limit_cost = 3000,
        health_cost = 7000,
        pickaxe_cost = 3000,
        aura_cost = 4000,
        xp_point_boost_cost = 5000,
        explosive_bullets_cost = 10000,
        flamethrower_turrets_cost = 3000,
        land_mine_cost = 2
    }
    this.collapse_grace = true
    this.explosive_bullets = false
    this.locomotive_biter = nil
    this.disconnect_wagon = false
    this.offline_players_enabled = true
    this.offline_players = {}
    this.collapse_amount = false
    this.collapse_speed = false
    this.spawn_near_collapse = {
        active = true,
        total_pos = 35,
        compare = -150,
        compare_next = 200,
        distance_from = 2
    }
    this.spidertron_unlocked_at_wave = 11
    -- this.void_or_tile = 'lab-dark-2'
    this.void_or_tile = 'out-of-map'
    this.validate_spider = {}
    this.check_afk_players = true
    this.winter_mode = false
    this.sent_to_discord = false
    this.difficulty = {
        multiply = 0.25,
        highest = 10
    }
    this.market_announce = game.tick + 1200
    this.check_heavy_damage = true

    --!reset player tables
    for _, player in pairs(this.players) do
        player.died = false
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

local on_init = function()
    Public.reset_table()
end

Event.on_init(on_init)

return Public
