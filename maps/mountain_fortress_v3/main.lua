require 'modules.rpg.main'

local Functions = require 'maps.mountain_fortress_v3.functions'
local BuriedEnemies = require 'maps.mountain_fortress_v3.buried_enemies'

local HS = require 'maps.mountain_fortress_v3.highscore'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local ICMinimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Autostash = require 'modules.autostash'
local Group = require 'comfy_panel.group'
local PL = require 'comfy_panel.player_list'
local CS = require 'maps.mountain_fortress_v3.surface'
local Server = require 'utils.server'
local Explosives = require 'modules.explosives'
local Balance = require 'maps.mountain_fortress_v3.balance'
local Entities = require 'maps.mountain_fortress_v3.entities'
local Gui_mf = require 'maps.mountain_fortress_v3.gui'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local WD = require 'modules.wave_defense.table'
local Map = require 'modules.map_info'
local RPG_Settings = require 'modules.rpg.table'
local RPG_Func = require 'modules.rpg.functions'
local Event = require 'utils.event'
local WPT = require 'maps.mountain_fortress_v3.table'
local Locomotive = require 'maps.mountain_fortress_v3.locomotive'
local Score = require 'comfy_panel.score'
local Poll = require 'comfy_panel.poll'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local AntiGrief = require 'antigrief'
local Commands = require 'commands.misc'
local Modifiers = require 'player_modifiers'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

require 'maps.mountain_fortress_v3.rocks_yield_ore_veins'

require 'maps.mountain_fortress_v3.generate'
require 'maps.mountain_fortress_v3.commands'
require 'maps.mountain_fortress_v3.breached_wall'
require 'maps.mountain_fortress_v3.ic.main'
require 'maps.mountain_fortress_v3.biters_yield_coins'

require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.spawners_contain_biters'
require 'modules.wave_defense.main'
require 'modules.charging_station'

local Public = {}
local raise_event = script.raise_event
local floor = math.floor
local remove = table.remove

local collapse_kill = {
    entities = {
        ['laser-turret'] = true,
        ['flamethrower-turret'] = true,
        ['gun-turret'] = true,
        ['artillery-turret'] = true,
        ['landmine'] = true,
        ['locomotive'] = true,
        ['cargo-wagon'] = true,
        ['character'] = true,
        ['car'] = true,
        ['tank'] = true,
        ['assembling-machine'] = true,
        ['furnace'] = true,
        ['steel-chest'] = true
    },
    enabled = true
}

local init_new_force = function()
    local new_force = game.forces.protectors
    local enemy = game.forces.enemy
    if not new_force then
        new_force = game.create_force('protectors')
    end
    new_force.set_friend('enemy', true)
    enemy.set_friend('protectors', true)
end

local is_position_near_tbl = function(position, tbl)
    local status = false
    local function inside(pos)
        return pos.x >= position.x and pos.y >= position.y and pos.x <= position.x and pos.y <= position.y
    end

    for i = 1, #tbl do
        if inside(tbl[i]) then
            status = true
        end
    end

    return status
end

function Public.reset_map()
    local Diff = Difficulty.get()
    local this = WPT.get()
    local wave_defense_table = WD.get_table()

    this.active_surface_index = CS.create_surface()

    Autostash.insert_into_furnace(true)
    Autostash.insert_into_wagon(true)
    Autostash.bottom_button(true)
    BuriedEnemies.reset()
    Commands.reset()
    Commands.activate_custom_buttons(true)
    Commands.bottom_right(true)

    Poll.reset()
    ICW.reset()
    IC.reset()
    IC.allowed_surface(game.surfaces[this.active_surface_index].name)
    Functions.reset_table()
    game.reset_time_played()
    WPT.reset_table()

    RPG_Func.rpg_reset_all_players()
    RPG_Settings.set_surface_name(game.surfaces[this.active_surface_index].name)
    RPG_Settings.enable_health_and_mana_bars(true)
    RPG_Settings.enable_wave_defense(true)
    RPG_Settings.enable_mana(true)
    RPG_Settings.enable_flame_boots(true)
    RPG_Settings.personal_tax_rate(0.3)
    RPG_Settings.enable_stone_path(true)
    RPG_Settings.enable_one_punch(true)
    RPG_Settings.enable_one_punch_globally(false)
    RPG_Settings.enable_auto_allocate(true)
    RPG_Settings.disable_cooldowns_on_spells()

    Group.reset_groups()
    Group.alphanumeric_only(false)

    Functions.disable_tech()
    init_new_force()

    local surface = game.surfaces[this.active_surface_index]

    if this.winter_mode then
        surface.daytime = 0.45
    end

    Explosives.set_surface_whitelist({[surface.name] = true})

    game.forces.player.set_spawn_position({-27, 25}, surface)
    game.forces.player.manual_mining_speed_modifier = 0

    BiterHealthBooster.set_active_surface(tostring(surface.name))
    BiterHealthBooster.acid_nova(true)
    BiterHealthBooster.check_on_entity_died(true)
    BiterHealthBooster.boss_spawns_projectiles(true)
    BiterHealthBooster.enable_boss_loot(false)

    Balance.init_enemy_weapon_damage()

    AntiGrief.log_tree_harvest(true)
    AntiGrief.whitelist_types('tree', true)
    AntiGrief.enable_capsule_warning(false)
    AntiGrief.enable_capsule_cursor_warning(false)
    AntiGrief.enable_jail(true)
    AntiGrief.damage_entity_threshold(20)
    AntiGrief.explosive_threshold(32)

    PL.show_roles_in_list(true)

    Score.reset_tbl()

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Score.init_player_table(player, true)
        Commands.insert_all_items(player)
        Modifiers.reset_player_modifiers(player)
        if player.gui.left['mvps'] then
            player.gui.left['mvps'].destroy()
        end
        ICMinimap.kill_minimap(player)
        raise_event(Gui_mf.events.reset_map, {player_index = player.index})
    end

    Difficulty.reset_difficulty_poll({difficulty_poll_closing_timeout = game.tick + 36000})
    Diff.gui_width = 20

    Collapse.set_kill_entities(false)
    Collapse.set_kill_specific_entities(collapse_kill)
    Collapse.set_speed(8)
    Collapse.set_amount(1)
    Collapse.set_max_line_size(WPT.level_width)
    Collapse.set_surface(surface)
    Collapse.set_position({0, 130})
    Collapse.set_direction('north')
    Collapse.start_now(false)

    this.locomotive_health = 10000
    this.locomotive_max_health = 10000

    Locomotive.locomotive_spawn(surface, {x = -18, y = 25})
    Locomotive.render_train_hp()
    Functions.render_direction(surface)

    WD.reset_wave_defense()
    wave_defense_table.surface_index = this.active_surface_index
    wave_defense_table.target = this.locomotive
    wave_defense_table.nest_building_density = 32
    wave_defense_table.game_lost = false
    wave_defense_table.spawn_position = {x = 0, y = 100}
    WD.alert_boss_wave(true)
    WD.clear_corpses(false)
    WD.remove_entities(true)
    WD.enable_threat_log(true)
    WD.check_collapse_position(true)
    WD.set_disable_threat_below_zero(true)
    WD.increase_boss_health_per_wave(true)
    WD.increase_damage_per_wave(true)
    WD.increase_health_per_wave(true)

    Functions.set_difficulty()
    Functions.disable_creative()

    if not surface.is_chunk_generated({-20, 22}) then
        surface.request_to_generate_chunks({-20, 22}, 0.1)
        surface.force_generate_chunk_requests()
    end

    game.forces.player.set_spawn_position({-27, 25}, surface)

    Task.start_queue()
    Task.set_queue_speed(16)

    HS.get_scores()

    if is_game_modded() then
        game.difficulty_settings.technology_price_multiplier = 0.5
    end

    this.chunk_load_tick = game.tick + 1200
    this.market_announce = game.tick + 1200
    this.game_lost = false
end

local is_locomotive_valid = function()
    local locomotive = WPT.get('locomotive')
    if not locomotive.valid then
        Entities.loco_died()
    end
end

local is_player_valid = function()
    local players = game.connected_players
    for _, player in pairs(players) do
        if player.connected and not player.character or not player.character.valid then
            if not player.admin then
                local player_data = Functions.get_player_data(player)
                if player_data.died then
                    return
                end
                player.set_controller {type = defines.controllers.god}
                player.create_character()
            end
        end
    end
end

local has_the_game_ended = function()
    local game_reset_tick = WPT.get('game_reset_tick')
    if game_reset_tick then
        if game_reset_tick < 0 then
            return
        end

        local this = WPT.get()

        this.game_reset_tick = this.game_reset_tick - 30
        if this.game_reset_tick % 1800 == 0 then
            if this.game_reset_tick > 0 then
                local cause_msg
                if this.restart then
                    cause_msg = 'restart'
                elseif this.shutdown then
                    cause_msg = 'shutdown'
                elseif this.soft_reset then
                    cause_msg = 'soft-reset'
                end

                game.print(({'main.reset_in', cause_msg, this.game_reset_tick / 60}), {r = 0.22, g = 0.88, b = 0.22})
            end

            local diff_name = Difficulty.get('name')

            if this.soft_reset and this.game_reset_tick == 0 then
                this.game_reset_tick = nil
                HS.set_scores(diff_name)
                Public.reset_map()
                return
            end

            if this.restart and this.game_reset_tick == 0 then
                if not this.announced_message then
                    HS.set_scores(diff_name)
                    game.print(({'entity.notify_restart'}), {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled! Server will restart from scenario to load new changes.'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.start_scenario('Mountain_Fortress_v3')
                    this.announced_message = true
                    return
                end
            end
            if this.shutdown and this.game_reset_tick == 0 then
                if not this.announced_message then
                    HS.set_scores(diff_name)
                    game.print(({'entity.notify_shutdown'}), {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled! Server will shutdown. Most likely because of updates.'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.stop_scenario()
                    this.announced_message = true
                    return
                end
            end
        end
    end
end

local chunk_load = function()
    local chunk_load_tick = WPT.get('chunk_load_tick')
    if chunk_load_tick then
        if chunk_load_tick < game.tick then
            WPT.get().chunk_load_tick = nil
            Task.set_queue_speed(3)
        end
    end
end

local collapse_message =
    Token.register(
    function(data)
        local pos = data.position
        local message = data.message
        local collapse_position = {
            position = pos
        }
        Alert.alert_all_players_location(collapse_position, message)
    end
)

local lock_locomotive_positions = function()
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local locomotive_positions = WPT.get('locomotive_pos')
    local success = is_position_near_tbl(locomotive.position, locomotive_positions.tbl)
    local p = locomotive.position
    if not success then
        locomotive_positions.tbl[#locomotive_positions.tbl + 1] = {x = floor(p.x), y = floor(p.y)}
    end

    local total_pos = #locomotive_positions.tbl
    if total_pos > 50 then
        remove(locomotive_positions.tbl, total_pos - total_pos + 1)
    end
end

local compare_collapse_and_train = function()
    local collapse_pos = Collapse.get_position()
    local locomotive = WPT.get('locomotive')
    local carriages = WPT.get('carriages')
    if not (locomotive and locomotive.valid) then
        return
    end

    if not carriages then
        WPT.set().carriages = locomotive.train.carriages
    end

    local c_y = collapse_pos.y
    local t_y = locomotive.position.y

    local gap_between_zones = WPT.get('gap_between_zones')

    if c_y - t_y <= gap_between_zones.gap then
        Functions.set_difficulty()
    else
        Collapse.set_speed(1)
        Collapse.set_amount(4)
    end
end

local collapse_after_wave_100 = function()
    local collapse_grace = WPT.get('collapse_grace')
    if not collapse_grace then
        return
    end
    if Collapse.start_now() then
        return
    end

    local wave_number = WD.get_wave()

    if wave_number >= 100 then
        Collapse.start_now(true)
        local data = {
            position = Collapse.get_position()
        }
        data.message = ({'breached_wall.collapse_start'})
        Task.set_timeout_in_ticks(550, collapse_message, data)
    end
end

local on_tick = function()
    local update_gui = Gui_mf.update_gui
    local tick = game.tick

    if tick % 40 == 0 then
        for _, player in pairs(game.connected_players) do
            update_gui(player)
        end
        lock_locomotive_positions()
        is_player_valid()
        is_locomotive_valid()
        has_the_game_ended()
        chunk_load()
    end

    if tick % 250 == 0 then
        compare_collapse_and_train()
        Functions.set_spawn_position()
        Functions.boost_difficulty()
    end

    if tick % 1000 == 0 then
        collapse_after_wave_100()
        Functions.remove_offline_players()
        Functions.set_difficulty()
        Functions.is_creativity_mode_on()
    end
end

local on_init = function()
    local this = WPT.get()
    Public.reset_map()

    game.map_settings.path_finder.general_entity_collision_penalty = 1 -- Recommended value
    game.map_settings.path_finder.general_entity_subsequent_collision_penalty = 1 -- Recommended value

    local tooltip
    if is_game_modded() then
        tooltip = {
            [1] = ({'main.diff_tooltip', '0', '0.5', '0.15', '0.15', '1', '12', '50', '20000', '100%', '15', '10'}),
            [2] = ({'main.diff_tooltip', '0', '0.25', '0.1', '0.1', '2', '10', '50', '12000', '75%', '8', '8'}),
            [3] = ({'main.diff_tooltip', '0', '0', '0', '0', '4', '3', '10', '8000', '50%', '5', '6'})
        }
    else
        tooltip = {
            [1] = ({'main.diff_tooltip', '0', '0.5', '0.15', '0.15', '1', '12', '50', '10000', '100%', '15', '10'}),
            [2] = ({'main.diff_tooltip', '0', '0.25', '0.1', '0.1', '2', '10', '50', '7000', '75%', '8', '8'}),
            [3] = ({'main.diff_tooltip', '0', '0', '0', '0', '4', '3', '10', '5000', '50%', '5', '6'})
        }
    end

    Difficulty.set_tooltip(tooltip)

    this.rocks_yield_ore_maximum_amount = 500
    this.type_modifier = 1
    this.rocks_yield_ore_base_amount = 40
    this.rocks_yield_ore_distance_modifier = 0.020

    local T = Map.Pop_info()
    T.localised_category = 'mountain_fortress_v3'
    T.main_caption_color = {r = 150, g = 150, b = 0}
    T.sub_caption_color = {r = 0, g = 150, b = 0}

    Explosives.set_destructible_tile('out-of-map', 1500)
    Explosives.set_destructible_tile('water', 1000)
    Explosives.set_destructible_tile('water-green', 1000)
    Explosives.set_destructible_tile('deepwater-green', 1000)
    Explosives.set_destructible_tile('deepwater', 1000)
    Explosives.set_destructible_tile('water-shallow', 1000)
    Explosives.set_destructible_tile('water-mud', 1000)
    Explosives.set_destructible_tile('lab-dark-2', 1000)
    Explosives.set_whitelist_entity('straight-rail')
    Explosives.set_whitelist_entity('curved-rail')
    Explosives.set_whitelist_entity('character')
    Explosives.set_whitelist_entity('spidertron')
    Explosives.set_whitelist_entity('car')
    Explosives.set_whitelist_entity('tank')
end

Event.on_nth_tick(10, on_tick)
Event.on_init(on_init)

return Public
