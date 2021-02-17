local Collapse = require 'modules.collapse'
local Terrain = require 'maps.mountain_fortress_v3.terrain'
local Balance = require 'maps.mountain_fortress_v3.balance'
local RPG_Settings = require 'modules.rpg.table'
local Functions = require 'modules.rpg.functions'
local WPT = require 'maps.mountain_fortress_v3.table'
local Alert = require 'utils.alert'
local Event = require 'utils.event'
local Task = require 'utils.task'
local Token = require 'utils.token'
-- local BM = require 'maps.mountain_fortress_v3.blood_moon'

local raise_event = script.raise_event
local floor = math.floor
local abs = math.abs
local random = math.random
local sqrt = math.sqrt
local level_depth = WPT.level_depth

local forest = {
    [2] = true,
    [10] = true,
    [13] = true,
    [17] = true,
    [19] = true,
    [21] = true
}

local scrap = {
    [5] = true,
    [15] = true
}

local collapse_message =
    Token.register(
    function(data)
        local pos = data.position
        local message = ({'breached_wall.collapse_start'})
        local collapse_position = {
            position = pos
        }
        Alert.alert_all_players_location(collapse_position, message)
    end
)

local spidertron_unlocked =
    Token.register(
    function()
        local message = ({'breached_wall.spidertron_unlocked'})
        Alert.alert_all_players(30, message, nil, 'achievement/tech-maniac', 0.1)
    end
)
--[[
local calculate_hp = function(zone)
    return 2 + 0.2 * zone - 1 * floor(zone / 20)
end ]]
local first_player_to_zone =
    Token.register(
    function(data)
        local player = data.player
        if not player or not player.valid then
            return
        end
        local breached_wall = data.breached_wall
        local message = ({'breached_wall.first_to_reach', player.name, breached_wall})
        Alert.alert_all_players(10, message)
    end
)

local artillery_warning =
    Token.register(
    function()
        local message = ({'breached_wall.artillery_warning'})
        Alert.alert_all_players(10, message)
    end
)

local spidertron_too_far =
    Token.register(
    function(data)
        local player = data.player
        local message = ({'breached_wall.cheating_through', player.name})
        Alert.alert_all_players(30, message)
    end
)

local compare_player_pos = function(player)
    local p = player.position
    local index = player.index
    local zone = floor((abs(p.y / level_depth)) % 22)
    if scrap[zone] then
        RPG_Settings.set_value_to_player(index, 'scrap_zone', true)
    else
        local has_scrap = RPG_Settings.get_value_from_player(index, 'scrap_zone')
        if has_scrap then
            RPG_Settings.set_value_to_player(index, 'scrap_zone', false)
        end
    end

    if forest[zone] then
        RPG_Settings.set_value_to_player(index, 'forest_zone', true)
    else
        local is_in_forest = RPG_Settings.get_value_from_player(index, 'forest_zone')
        if is_in_forest then
            RPG_Settings.set_value_to_player(index, 'forest_zone', false)
        end
    end
end

local compare_player_and_train = function(player, entity)
    if not player.driving then
        return
    end

    if not (entity and entity.valid) then
        return
    end

    local position = player.position
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local gap_between_zones = WPT.get('gap_between_zones')
    gap_between_zones.highest_pos = locomotive.position
    gap_between_zones = WPT.get('gap_between_zones')

    local c_y = position.y
    local t_y = gap_between_zones.highest_pos.y

    if c_y - t_y <= gap_between_zones.neg_gap then
        if entity.health then
            entity.health = entity.health - 500
            if entity.health <= 0 then
                entity.die('enemy')
                Task.set_timeout_in_ticks(30, spidertron_too_far, {player = player})
                return
            end
        end
    end
end

local function distance(player)
    local index = player.index
    local bonus = RPG_Settings.get_value_from_player(index, 'bonus')
    local rpg_extra = RPG_Settings.get('rpg_extra')
    local breached_wall = WPT.get('breached_wall')
    local bonus_xp_on_join = WPT.get('bonus_xp_on_join')
    local enable_arties = WPT.get('enable_arties')

    local p = player.position

    local s = WPT.get('validate_spider')
    if s[index] then
        local e = s[index]
        if not (e and e.valid) then
            s[index] = nil
        end
        compare_player_and_train(player, s[index])
    end

    compare_player_pos(player)

    local distance_to_center = floor(sqrt(p.x ^ 2 + p.y ^ 2))
    local location = distance_to_center
    if location < Terrain.level_depth * bonus - 10 then
        return
    end

    local max = Terrain.level_depth * bonus
    local breach_max = Terrain.level_depth * breached_wall
    local breach_max_times = location >= breach_max
    local max_times = location >= max
    if max_times then
        if breach_max_times then
            rpg_extra.breached_walls = rpg_extra.breached_walls + 1
            rpg_extra.reward_new_players = bonus_xp_on_join * rpg_extra.breached_walls
            WPT.set().breached_wall = breached_wall + 1
            WPT.set().placed_trains_in_zone.placed = 0
            WPT.set().biters.amount = 0
            WPT.set('blood_moon', false)
            WPT.set().placed_trains_in_zone.randomized = false
            WPT.set().placed_trains_in_zone.positions = {}
            raise_event(Balance.events.breached_wall, {})
            if WPT.get('breached_wall') == WPT.get('spidertron_unlocked_at_zone') then
                local main_market_items = WPT.get('main_market_items')
                if not main_market_items['spidertron'] then
                    local rng = random(70000, 120000)
                    main_market_items['spidertron'] = {
                        stack = 1,
                        value = 'coin',
                        price = rng,
                        tooltip = 'Chonk Spidertron',
                        upgrade = false,
                        static = true
                    }
                    Task.set_timeout_in_ticks(150, spidertron_unlocked)
                end
            end

            --[[ if breached_wall % 2 == 0 then
                local blood_moon = WPT.get('blood_moon')
                local t = game.tick
                local surface = player.surface
                if not blood_moon then
                    BM.set_daytime(surface, t, true)
                    WPT.set('blood_moon', true)
                end
            else
                local surface = player.surface
                surface.brightness_visual_weights = {
                    a = 1,
                    b = 0,
                    g = 0,
                    r = 0
                }
                surface.daytime = 0.7
                surface.freeze_daytime = false
            end ]]
            local data = {
                player = player,
                breached_wall = breached_wall
            }
            Task.set_timeout_in_ticks(360, first_player_to_zone, data)
            if breached_wall == 5 then
                if enable_arties == 6 then
                    Task.set_timeout_in_ticks(360, artillery_warning)
                end
            end
        end

        if not Collapse.start_now() then
            Collapse.start_now(true)
            local data = {
                position = Collapse.get_position()
            }
            Task.set_timeout_in_ticks(550, collapse_message, data)
        end

        RPG_Settings.set_value_to_player(index, 'bonus', bonus + 1)

        Functions.gain_xp(player, bonus_xp_on_join * bonus)
        local message = ({'breached_wall.wall_breached', bonus})
        Alert.alert_player_warning(player, 10, message)
        return
    end
end

local function on_player_changed_position(event)
    local player = game.get_player(event.player_index)
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    distance(player)
end

local function on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end
    local entity = event.entity
    if not (entity and entity.valid) then
        return
    end
    local s = WPT.get('validate_spider')
    if entity.name == 'spidertron' then
        if not s[player.index] then
            s[player.index] = entity
        end
    else
        if s[player.index] then
            s[player.index] = nil
        end
    end
end

Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
