-- fish defender -- by mewmew --

--require "modules.rpg"

require 'maps.fish_defender_v2.terrain'
require 'maps.fish_defender_v2.market'
require 'maps.fish_defender_v2.commands'
require 'maps.fish_defender_v2.shotgun_buff'
require 'maps.fish_defender_v2.on_entity_damaged'
require 'modules.rocket_launch_always_yields_science'
require 'modules.launch_fish_to_win'
require 'modules.biters_yield_coins'
require 'modules.custom_death_messages'

local Unit_health_booster = require 'modules.biter_health_booster'
local Difficulty = require 'modules.difficulty_vote'
local Map = require 'modules.map_info'
local Event = require 'utils.event'
local Reset = require 'functions.soft_reset'
local Server = require 'utils.server'
local Poll = require 'comfy_panel.poll'
local boss_biter = require 'maps.fish_defender_v2.boss_biters'
local FDT = require 'maps.fish_defender_v2.table'
local Score = require 'comfy_panel.score'
local AntiGrief = require 'antigrief'
local math_random = math.random
local insert = table.insert
local enable_start_grace_period = true

local Public = {}

local starting_items = {
    ['pistol'] = 1,
    ['firearm-magazine'] = 16,
    ['raw-fish'] = 3,
    ['iron-plate'] = 32,
    ['stone'] = 12
}

local function shuffle(tbl)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
    return tbl
end

local biter_count_limit = 1024 --maximum biters on the east side of the map, next wave will be delayed if the maximum has been reached

local function create_wave_gui(player)
    if player.gui.top['fish_defense_waves'] then
        player.gui.top['fish_defense_waves'].destroy()
    end
    local frame = player.gui.top.add({type = 'frame', name = 'fish_defense_waves'})
    frame.style.maximal_height = 38

    local wave_count = 0
    local wave_count_fdt = FDT.get('wave_count')
    local wave_grace_period = FDT.get('wave_grace_period')
    local wave_interval = FDT.get('wave_interval')

    if wave_count_fdt then
        wave_count = wave_count_fdt
    end

    if not wave_grace_period then
        local label = frame.add({type = 'label', caption = 'Wave: ' .. wave_count})
        label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
        label.style.font = 'default-listbox'
        label.style.left_padding = 4
        label.style.right_padding = 4
        label.style.minimal_width = 68
        label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        local next_level_progress = game.tick % wave_interval / wave_interval

        local progressbar = frame.add({type = 'progressbar', value = next_level_progress})
        progressbar.style.minimal_width = 120
        progressbar.style.maximal_width = 120
        progressbar.style.top_padding = 10
    else
        local time_remaining = math.floor(((wave_grace_period - (game.tick % wave_grace_period)) / 60) / 60)
        if time_remaining <= 0 then
            FDT.set('wave_grace_period', nil)
            return
        end

        local label = frame.add({type = 'label', caption = 'Waves will start in ' .. time_remaining .. ' minutes.'})
        label.style.font_color = {r = 0.88, g = 0.88, b = 0.88}
        label.style.font = 'default-listbox'
        label.style.left_padding = 4
        label.style.right_padding = 4
        label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

        if not enable_start_grace_period then
            FDT.set('wave_grace_period', nil)
            return
        end
    end
end

local function show_fd_stats(player)
    local gui_id = 'fd-stats'
    local table_id = gui_id .. 'table'

    if player.gui.left[gui_id] then
        player.gui.left[gui_id].destroy()
    end

    local frame =
        player.gui.left.add {
        type = 'frame',
        name = gui_id
    }
    local table =
        frame.add {
        type = 'table',
        name = table_id,
        column_count = 2
    }

    local entity_limits = FDT.get('entity_limits')

    local table_header = {'Building', 'Placed' .. '/' .. 'Limit'}
    for k, v in pairs(table_header) do
        local h = table.add {type = 'label', caption = v}
        h.style.font = 'heading-2'
    end

    for k, v in pairs(entity_limits) do
        local name = v.str
        local placed = v.placed
        local limit = v.limit
        local entry = {name, placed .. '/' .. limit}
        for _, value_entry in pairs(entry) do
            table.add {
                type = 'label',
                caption = value_entry
            }
        end
    end
end

local function update_fd_stats()
    for _, player in pairs(game.connected_players) do
        if player.gui.left['fd-stats'] then
            show_fd_stats(player)
        end
    end
end

local function add_fd_stats_button(player)
    local button_id = 'fd-stats-button'
    if player.gui.top[button_id] then
        player.gui.top[button_id].destroy()
    end

    player.gui.top.add {
        type = 'sprite-button',
        name = button_id,
        sprite = 'item/submachine-gun'
    }
end

local function on_gui_click(event)
    if not event.element.valid then
        return
    end
    if event.element.name ~= 'fd-stats-button' then
        return
    end
    local player = game.players[event.player_index]
    local frame = player.gui.left['fd-stats']
    if frame == nil then
        show_fd_stats(player)
    else
        frame.destroy()
    end
end

local function on_market_item_purchased()
    update_fd_stats()
end

local threat_values = {
    ['small_biter'] = 1,
    ['medium_biter'] = 3,
    ['big_biter'] = 5,
    ['behemoth_biter'] = 10,
    ['small_spitter'] = 1,
    ['medium_spitter'] = 3,
    ['big_spitter'] = 5,
    ['behemoth_spitter'] = 10
}

local function get_biter_initial_pool()
    local wave_count = FDT.get('wave_count')
    local biter_pool
    if wave_count > 1750 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if wave_count > 1500 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 1},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if wave_count > 1250 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 2},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if wave_count > 1000 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 3},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.1 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 3},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.2 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 10},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 2},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 5},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.3 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 18},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 6},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 8},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 3},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.4 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 8},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 2},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 4},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.5 then
        biter_pool = {
            {name = 'small-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 4},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 8},
            {name = 'small-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 4}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.6 then
        biter_pool = {
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 4},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 8},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 4}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.7 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 12},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 20},
            {name = 'behemoth-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 6},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 10}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor < 0.8 then
        biter_pool = {
            {name = 'behemoth-biter', threat = threat_values.small_biter, weight = 2},
            {name = 'medium-biter', threat = threat_values.medium_biter, weight = 4},
            {name = 'big-biter', threat = threat_values.big_biter, weight = 10},
            {name = 'behemoth-spitter', threat = threat_values.small_spitter, weight = 1},
            {name = 'medium-spitter', threat = threat_values.medium_spitter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 5}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor <= 0.9 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 12},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 6},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
    if game.forces.enemy.evolution_factor <= 1 then
        biter_pool = {
            {name = 'big-biter', threat = threat_values.big_biter, weight = 4},
            {name = 'behemoth-biter', threat = threat_values.behemoth_biter, weight = 2},
            {name = 'big-spitter', threat = threat_values.big_spitter, weight = 2},
            {name = 'behemoth-spitter', threat = threat_values.behemoth_spitter, weight = 1}
        }
        return biter_pool
    end
end

local function fish_eye(surface, position)
    for x = -48, 48, 1 do
        for y = -48, 48, 1 do
            local p = {x = position.x + x, y = position.y + y}
            local distance = ((position.x - p.x) ^ 2) + ((position.y - p.y) ^ 2)
            if distance < 1936 then
                if distance < 484 then
                    surface.set_tiles({{name = 'out-of-map', position = p}}, true)
                else
                    surface.set_tiles({{name = 'water-green', position = p}}, true)
                end
            end
        end
    end
    print('Fish Eye created.')
    FDT.set('fish_eye', true)
end

local function get_biter_pool()
    local biter_pool = get_biter_initial_pool()
    local biter_raffle = {}
    for _, biter_type in pairs(biter_pool) do
        for _ = 1, biter_type.weight, 1 do
            insert(biter_raffle, {name = biter_type.name, threat = biter_type.threat})
        end
    end
    return biter_raffle
end

local function spawn_biter(pos, biter_pool)
    local attack_wave_threat = FDT.get('attack_wave_threat')
    if attack_wave_threat < 1 then
        return false
    end
    local active_surface_index = FDT.get('active_surface_index')

    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    biter_pool = shuffle(biter_pool)
    FDT.set('attack_wave_threat', attack_wave_threat - biter_pool[1].threat)
    local valid_pos = surface.find_non_colliding_position(biter_pool[1].name, pos, 100, 2)
    local biter = surface.create_entity({name = biter_pool[1].name, position = valid_pos})
    biter.ai_settings.allow_destroy_when_commands_fail = false
    biter.ai_settings.allow_try_return_to_spawner = false
    return biter
end

local function get_y_coord_raffle_table()
    local t = {}
    for y = -109, 168, 8 do
        t[#t + 1] = y
    end
    table.shuffle_table(t)
    return t
end

local attack_group_count_thresholds = {
    {0, 1},
    {50, 2},
    {100, 3},
    {150, 4},
    {200, 5},
    {1000, 6},
    {2000, 7},
    {3000, 8}
}

local function get_number_of_attack_groups()
    local n = 1
    local wave_count = FDT.get('wave_count')
    for _, entry in pairs(attack_group_count_thresholds) do
        if wave_count >= entry[1] then
            n = entry[2]
        end
    end
    return n
end

local function clear_corpses(surface)
    local wave_count = FDT.get('wave_count')

    if not wave_count then
        return
    end
    local chance = 4
    if wave_count > 250 then
        chance = 3
    end
    if wave_count > 500 then
        chance = 2
    end

    local area = {{-137, -256}, {160, 256}}
    for _, entity in pairs(surface.find_entities_filtered {area = area, type = 'corpse'}) do
        if math_random(1, chance) == 1 then
            entity.destroy()
        end
    end
end

local function send_unit_group(unit_group)
    local commands = {}
    local market = FDT.get('market')
    if not (market and market.valid) then
        return
    end
    for x = unit_group.position.x, market.position.x, -48 do
        local destination = unit_group.surface.find_non_colliding_position('stone-wall', {x = x, y = unit_group.position.y}, 32, 4)
        if destination then
            commands[#commands + 1] = {
                type = defines.command.attack_area,
                destination = destination,
                radius = 16,
                distraction = defines.distraction.by_enemy
            }
        end
    end
    commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = {x = market.position.x, y = unit_group.position.y},
        radius = 16,
        distraction = defines.distraction.by_enemy
    }
    commands[#commands + 1] = {
        type = defines.command.attack,
        target = market,
        distraction = defines.distraction.by_enemy
    }

    unit_group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.logical_and,
            commands = commands
        }
    )
end

local function spawn_boss_units(surface)
    local wave_count = FDT.get('wave_count')
    if wave_count <= 2000 then
        game.print({'fish_defender_v2.boss_message', wave_count, {'fish_defender_v2.' .. wave_count}}, {r = 0.8, g = 0.1, b = 0.1})
    else
        game.print({'fish_defender_v2.boss_message', wave_count}, {r = 0.8, g = 0.1, b = 0.1})
    end

    local boss_waves = FDT.get('boss_waves')

    if not boss_waves[wave_count] then
        local amount = wave_count
        if amount > 1000 then
            amount = 1000
        end
        boss_waves[wave_count] = {
            {name = 'behemoth-biter', count = math.floor(amount / 20)},
            {name = 'behemoth-spitter', count = math.floor(amount / 40)}
        }
    end

    local health_factor = FDT.get_current_difficulty_boss_modifier()
    if wave_count == 100 then
        health_factor = health_factor * 2
    end

    local biter_health_boost = FDT.get('biter_health_boost')
    local boss_biters = FDT.get('boss_biters')

    local position = {x = 216, y = 0}
    local biter_group = surface.create_unit_group({position = position})
    for _, entry in pairs(boss_waves[wave_count]) do
        for _ = 1, entry.count, 1 do
            local pos = surface.find_non_colliding_position(entry.name, position, 64, 3)
            if pos then
                local biter = surface.create_entity({name = entry.name, position = pos})
                biter.ai_settings.allow_destroy_when_commands_fail = false
                biter.ai_settings.allow_try_return_to_spawner = false
                boss_biters[biter.unit_number] = biter
                Unit_health_booster.add_boss_unit(biter, biter_health_boost * health_factor, 0.55)
                biter_group.add_member(biter)
            end
        end
    end

    send_unit_group(biter_group)
end

local function wake_up_the_biters(surface)
    local market = FDT.get('market')
    if not (market and market.valid) then
        return
    end

    local units = surface.find_entities_filtered({type = 'unit'})
    units = shuffle(units)
    local unit_groups = {}
    local y_raffle = get_y_coord_raffle_table()
    for i = 1, 2, 1 do
        if not units[i] then
            break
        end
        if not units[i].valid then
            break
        end
        local x = units[i].position.x
        if x > 300 then
            x = 300
        end
        local y = units[i].position.y
        if y > 168 or y < -109 then
            y = y_raffle[i]
        end

        unit_groups[i] = surface.create_unit_group({position = {x = x, y = y}})
        local biters = surface.find_enemy_units(units[i].position, 24, 'player')
        for _, biter in pairs(biters) do
            unit_groups[i].add_member(biter)
        end
    end

    for i = 1, #unit_groups, 1 do
        if unit_groups[i].valid then
            if #unit_groups[i].members > 0 then
                send_unit_group(unit_groups[i])
            else
                unit_groups[i].destroy()
            end
        end
    end

    surface.set_multi_command(
        {
            command = {
                type = defines.command.attack,
                target = market,
                distraction = defines.distraction.none
            },
            unit_count = 16,
            force = 'enemy',
            unit_search_distance = 24
        }
    )
end

local function biter_attack_wave()
    local Diff = Difficulty.get()
    local market = FDT.get('market')

    if not market or not market.valid then
        return
    end
    local wave_grace_period = FDT.get('wave_grace_period')
    if wave_grace_period then
        return
    end
    local active_surface_index = FDT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    clear_corpses(surface)
    wake_up_the_biters(surface)

    if surface.count_entities_filtered({type = 'unit'}) > biter_count_limit then
        --game.print("Biter limit reached, wave delayed.", {r = 0.7, g = 0.1, b = 0.1})
        return
    end
    local wave_count = FDT.get('wave_count')
    if not wave_count then
        FDT.set('wave_count', 1)
    else
        FDT.set('wave_count', wave_count + 1)
    end

    wave_count = FDT.get('wave_count')

    local m = 0.0015
    if Diff.difficulty_vote_index then
        m = m * FDT.get_current_difficulty_strength_modifier()
    end
    game.forces.enemy.set_ammo_damage_modifier('melee', wave_count * m)
    game.forces.enemy.set_ammo_damage_modifier('biological', wave_count * m)
    FDT.set('biter_health_boost', 1 + (wave_count * (m * 2)))

    m = 4
    if Diff.difficulty_vote_index then
        m = m * FDT.get_current_difficulty_amount_modifier()
    end

    if wave_count % 50 == 0 then
        local attack_wave_threat = FDT.set('attack_wave_threat', math.floor(wave_count * (m * 1.5)))
        spawn_boss_units(surface)
        if attack_wave_threat > 10000 then
            FDT.set('attack_wave_threat', 10000)
        end
    else
        local attack_wave_threat = FDT.set('attack_wave_threat', math.floor(wave_count * m))
        FDT.set('attack_wave_threat', math.floor(wave_count * m))
        if attack_wave_threat > 10000 then
            FDT.set('attack_wave_threat', 10000)
        end
    end

    local evolution = wave_count * 0.00125
    if evolution > 1 then
        evolution = 1
    end
    game.forces.enemy.evolution_factor = evolution

    local y_raffle = get_y_coord_raffle_table()

    local unit_groups = {}
    if wave_count > 50 and math_random(1, 8) == 1 then
        for i = 1, 10, 1 do
            unit_groups[i] = surface.create_unit_group({position = {x = 300, y = y_raffle[i]}})
        end
    else
        for i = 1, get_number_of_attack_groups(), 1 do
            unit_groups[i] = surface.create_unit_group({position = {x = 300, y = y_raffle[i]}})
        end
    end

    local biter_pool = get_biter_pool()

    while FDT.get('attack_wave_threat') > 0 do
        for i = 1, #unit_groups, 1 do
            local biter = spawn_biter(unit_groups[i].position, biter_pool)
            if biter then
                unit_groups[i].add_member(biter)
            else
                break
            end
        end
    end

    for i = 1, #unit_groups, 1 do
        send_unit_group(unit_groups[i])
    end
end

local function get_sorted_list(column_name, score_list)
    for _ = 1, #score_list, 1 do
        for y = 1, #score_list, 1 do
            if not score_list[y + 1] then
                break
            end
            if score_list[y][column_name] < score_list[y + 1][column_name] then
                local key = score_list[y]
                score_list[y] = score_list[y + 1]
                score_list[y + 1] = key
            end
        end
    end
    return score_list
end

local function get_mvps()
    local get_score = Score.get_table().score_table
    if not get_score['player'] then
        return false
    end
    local score = get_score['player']
    local score_list = {}
    for _, p in pairs(game.players) do
        local killscore = 0
        if score.players[p.name].killscore then
            killscore = score.players[p.name].killscore
        end
        local deaths = 0
        if score.players[p.name].deaths then
            deaths = score.players[p.name].deaths
        end
        local built_entities = 0
        if score.players[p.name].built_entities then
            built_entities = score.players[p.name].built_entities
        end
        local mined_entities = 0
        if score.players[p.name].mined_entities then
            mined_entities = score.players[p.name].mined_entities
        end
        table.insert(
            score_list,
            {
                name = p.name,
                killscore = killscore,
                deaths = deaths,
                built_entities = built_entities,
                mined_entities = mined_entities
            }
        )
    end
    local mvp = {}
    score_list = get_sorted_list('killscore', score_list)
    mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
    score_list = get_sorted_list('deaths', score_list)
    mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
    score_list = get_sorted_list('built_entities', score_list)
    mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
    return mvp
end

local function is_game_lost()
    local game_has_ended = FDT.get('game_has_ended')
    if not game_has_ended then
        return
    end

    for _, player in pairs(game.connected_players) do
        if player.gui.left['fish_defense_game_lost'] then
            return
        end
        local f =
            player.gui.left.add(
            {
                type = 'frame',
                name = 'fish_defense_game_lost',
                caption = 'The fish market was overrun! The biters are having a feast :3',
                direction = 'vertical'
            }
        )
        f.style.font_color = {r = 0.65, g = 0.1, b = 0.99}

        local t = f.add({type = 'table', column_count = 2})

        local survival_time_label = t.add({type = 'label', caption = 'Survival Time >> '})
        survival_time_label.style.font = 'default-listbox'
        survival_time_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

        local market_age_label

        local market_age = FDT.get('market_age')
        if not market_age then
            return
        end

        if market_age then
            if market_age >= 216000 then
                market_age_label =
                    t.add(
                    {
                        type = 'label',
                        caption = math.floor(((market_age / 60) / 60) / 60) ..
                            ' hours ' .. math.ceil((market_age % 216000 / 60) / 60) .. ' minutes'
                    }
                )
                market_age_label.style.font = 'default-bold'
                market_age_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
            else
                market_age_label = t.add({type = 'label', caption = math.ceil((market_age % 216000 / 60) / 60) .. ' minutes'})
                market_age_label.style.font = 'default-bold'
                market_age_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}
            end
        end

        local mvp = get_mvps()
        if mvp then
            local mvp_defender_label = t.add({type = 'label', caption = 'MVP Defender >> '})
            mvp_defender_label.style.font = 'default-listbox'
            mvp_defender_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

            local mvp_killscore_label = t.add({type = 'label', caption = mvp.killscore.name .. ' with a score of ' .. mvp.killscore.score})
            mvp_killscore_label.style.font = 'default-bold'
            mvp_killscore_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local mvp_builder_label = t.add({type = 'label', caption = 'MVP Builder >> '})
            mvp_builder_label.style.font = 'default-listbox'
            mvp_builder_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

            local mvp_built_ent_label =
                t.add(
                {
                    type = 'label',
                    caption = mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things'
                }
            )
            mvp_built_ent_label.style.font = 'default-bold'
            mvp_built_ent_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local mvp_deaths_label = t.add({type = 'label', caption = 'MVP Deaths >> '})
            mvp_deaths_label.style.font = 'default-listbox'
            mvp_deaths_label.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

            local mvp_deaths_name_label = t.add({type = 'label', caption = mvp.deaths.name .. ' died ' .. mvp.deaths.score .. ' times'})
            mvp_deaths_name_label.style.font = 'default-bold'
            mvp_deaths_name_label.style.font_color = {r = 0.33, g = 0.66, b = 0.9}

            local results_sent = FDT.get('results_sent')
            if not results_sent then
                local result = {}
                insert(result, 'MVP Defender: \\n')
                insert(result, mvp.killscore.name .. ' with a score of ' .. mvp.killscore.score .. '\\n')
                insert(result, '\\n')
                insert(result, 'MVP Builder: \\n')
                insert(result, mvp.built_entities.name .. ' built ' .. mvp.built_entities.score .. ' things\\n')
                insert(result, '\\n')
                insert(result, 'MVP Deaths: \\n')
                insert(result, mvp.deaths.name .. ' died ' .. mvp.deaths.score .. ' times')
                local message = table.concat(result)
                Server.to_discord_embed(message)
                FDT.set('results_sent', true)
            end
        end

        player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
    end

    game.map_settings.enemy_expansion.enabled = true
    game.map_settings.enemy_expansion.max_expansion_distance = 15
    game.map_settings.enemy_expansion.settler_group_min_size = 15
    game.map_settings.enemy_expansion.settler_group_max_size = 30
    game.map_settings.enemy_expansion.min_expansion_cooldown = 600
    game.map_settings.enemy_expansion.max_expansion_cooldown = 600
end

local function damage_entities_in_radius(surface, position, radius, damage)
    local entities_to_damage =
        surface.find_entities_filtered({area = {{position.x - radius, position.y - radius}, {position.x + radius, position.y + radius}}})
    for _, entity in pairs(entities_to_damage) do
        if entity.valid then
            if entity.health and entity.name ~= 'land-mine' then
                if entity.force.name ~= 'enemy' then
                    if entity.name == 'character' then
                        entity.damage(damage, 'enemy')
                    else
                        entity.health = entity.health - damage
                        if entity.health <= 0 then
                            entity.die('enemy')
                        end
                    end
                end
            end
        end
    end
end

local function market_kill_visuals()
    local active_surface_index = FDT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local market = FDT.get('market')
    if not (market and market.valid) then
        return
    end

    local m = 32
    local m2 = m * 0.005
    for i = 1, 1024, 1 do
        surface.create_particle(
            {
                name = 'branch-particle',
                position = market.position,
                frame_speed = 0.1,
                vertical_speed = 0.1,
                height = 0.1,
                movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
            }
        )
    end

    for x = -5, 5, 0.5 do
        for y = -5, 5, 0.5 do
            if math_random(1, 2) == 1 then
                surface.create_trivial_smoke(
                    {
                        name = 'smoke-fast',
                        position = {market.position.x + (x * 0.35), market.position.y + (y * 0.35)}
                    }
                )
            end
            if math_random(1, 3) == 1 then
                surface.create_trivial_smoke(
                    {
                        name = 'train-smoke',
                        position = {market.position.x + (x * 0.35), market.position.y + (y * 0.35)}
                    }
                )
            end
        end
    end
    surface.spill_item_stack(market.position, {name = 'raw-fish', count = 1024}, true)
end

local biter_splash_damage = {
    ['medium-biter'] = {
        visuals = {'blood-explosion-big', 'big-explosion'},
        radius = 1.5,
        damage_min = 50,
        damage_max = 100,
        chance = 32
    },
    ['big-biter'] = {
        visuals = {'blood-explosion-huge', 'ground-explosion'},
        radius = 2,
        damage_min = 75,
        damage_max = 150,
        chance = 48
    },
    ['behemoth-biter'] = {
        visuals = {'blood-explosion-huge', 'big-artillery-explosion'},
        radius = 2.5,
        damage_min = 100,
        damage_max = 200,
        chance = 64
    }
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end

    local boss_biters = FDT.get('boss_biters')

    if event.entity.force.name == 'enemy' then
        local surface = event.entity.surface

        if boss_biters[event.entity.unit_number] then
            boss_biter.died(event)
        end

        local splash = biter_splash_damage[event.entity.name]
        if splash then
            if math_random(1, splash.chance) == 1 then
                for _, visual in pairs(splash.visuals) do
                    surface.create_entity({name = visual, position = event.entity.position})
                end
                damage_entities_in_radius(surface, event.entity.position, splash.radius, math_random(splash.damage_min, splash.damage_max))
                return
            end
        end

        if event.entity.name == 'behemoth-biter' then
            if math_random(1, 16) == 1 then
                local p = surface.find_non_colliding_position('big-biter', event.entity.position, 3, 0.5)
                if p then
                    surface.create_entity {name = 'big-biter', position = p}
                end
            end
            for i = 1, math_random(1, 2), 1 do
                local p = surface.find_non_colliding_position('medium-biter', event.entity.position, 3, 0.5)
                if p then
                    surface.create_entity {name = 'medium-biter', position = p}
                end
            end
        end
        return
    end

    local market = FDT.get('market')
    local last_reset = FDT.get('last_reset')

    if event.entity == market then
        market_kill_visuals()
        market.die()
        FDT.set('market', nil)
        FDT.set('market_age', game.tick - last_reset)
        FDT.set('game_has_ended', true)
        is_game_lost()
        return
    end

    local entity_limits = FDT.get('entity_limits')

    if entity_limits[event.entity.name] then
        entity_limits[event.entity.name].placed = entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    local active_surface_index = FDT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    if player.online_time == 0 then
        for item, amount in pairs(starting_items) do
            player.insert({name = item, count = amount})
        end

        if global.show_floating_killscore then
            global.show_floating_killscore[player.name] = false
        end
    end

    local spawn = player.force.get_spawn_position(surface)
    local pos = surface.find_non_colliding_position('character', spawn, 3, 0.5)

    if not pos and player.online_time < 2 then
        player.teleport(spawn, surface)
    elseif player.online_time < 2 or player.surface.index ~= active_surface_index then
        player.teleport(pos, surface)
    end

    create_wave_gui(player)
    add_fd_stats_button(player)

    if game.tick > 900 then
        is_game_lost()
    end
end

local function on_built_entity(event)
    local get_score = Score.get_table().score_table
    local entity = event.created_entity
    if not entity.valid then
        return
    end
    local entity_limits = FDT.get('entity_limits')
    if entity_limits[entity.name] then
        local surface = entity.surface

        if entity_limits[entity.name].placed < entity_limits[entity.name].limit then
            entity_limits[entity.name].placed = entity_limits[entity.name].placed + 1
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = entity_limits[entity.name].placed ..
                        ' / ' .. entity_limits[entity.name].limit .. ' ' .. entity_limits[entity.name].str .. 's',
                    color = {r = 0.98, g = 0.66, b = 0.22}
                }
            )
            update_fd_stats()
        else
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = entity_limits[entity.name].str .. ' limit reached.',
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
            local player = game.players[event.player_index]
            player.insert({name = entity.name, count = 1})
            if get_score then
                if get_score[player.force.name] then
                    if get_score[player.force.name].players[player.name] then
                        get_score[player.force.name].players[player.name].built_entities =
                            get_score[player.force.name].players[player.name].built_entities - 1
                    end
                end
            end
            entity.destroy()
        end
    end
end

local function on_robot_built_entity(event)
    local entity = event.created_entity

    local entity_limits = FDT.get('entity_limits')

    if entity_limits[entity.name] then
        local surface = entity.surface
        if entity_limits[entity.name].placed < entity_limits[entity.name].limit then
            entity_limits[entity.name].placed = entity_limits[entity.name].placed + 1
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = entity_limits[entity.name].placed ..
                        ' / ' .. entity_limits[entity.name].limit .. ' ' .. entity_limits[entity.name].str .. 's',
                    color = {r = 0.98, g = 0.66, b = 0.22}
                }
            )
            update_fd_stats()
        else
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = entity.position,
                    text = entity_limits[entity.name].str .. ' limit reached.',
                    color = {r = 0.82, g = 0.11, b = 0.11}
                }
            )
            local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
            inventory.insert({name = entity.name, count = 1})
            entity.destroy()
        end
    end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local active_surface_index = FDT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    if player.position.x >= 254 then
        player.teleport({player.position.x - 1, 0}, surface)

        if player.character then
            player.character.health = player.character.health - 25
            player.character.surface.create_entity({name = 'water-splash', position = player.position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local function on_player_mined_entity(event)
    local entity_limits = FDT.get('entity_limits')

    if entity_limits[event.entity.name] then
        entity_limits[event.entity.name].placed = entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local function on_robot_mined_entity(event)
    local entity_limits = FDT.get('entity_limits')

    if entity_limits[event.entity.name] then
        entity_limits[event.entity.name].placed = entity_limits[event.entity.name].placed - 1
        update_fd_stats()
    end
end

local function on_research_finished(event)
    local research = event.research.name
    if research ~= 'tank' then
        return
    end
    game.forces['player'].technologies['artillery'].researched = true
    game.forces.player.recipes['artillery-wagon'].enabled = false
end

local function on_player_respawned(event)
    local market_age = FDT.get('market_age')
    if not market_age then
        return
    end
    local player = game.players[event.player_index]
    player.character.destructible = false
end

local function has_the_game_ended()
    local market_age = FDT.get('market_age')
    if market_age then
        local game_restart_timer = FDT.get('game_restart_timer')
        if not game_restart_timer then
            FDT.set('game_restart_timer', 5400)
        else
            if game_restart_timer < 0 then
                return
            end
            FDT.set('game_restart_timer', game_restart_timer - 30)
        end
        game_restart_timer = FDT.get('game_restart_timer')
        local cause_msg
        local restart = FDT.get('restart')
        local shutdown = FDT.get('shutdown')
        local soft_reset = FDT.get('soft_reset')
        if restart then
            cause_msg = 'restart'
        elseif shutdown then
            cause_msg = 'shutdown'
        elseif soft_reset then
            cause_msg = 'soft-reset'
        end

        if game_restart_timer % 1800 == 0 then
            if game_restart_timer > 0 then
                FDT.set('game_reset', true)
                game.print('Game will ' .. cause_msg .. ' in ' .. game_restart_timer / 60 .. ' seconds!', {r = 0.22, g = 0.88, b = 0.22})
            end
            if soft_reset and game_restart_timer == 0 then
                FDT.set('game_reset_tick', nil)
                Server.start_scenario('Fish_Defender')
                return
            end
            local announced_message = FDT.get('announced_message')
            if restart and game_restart_timer == 0 then
                if not announced_message then
                    game.print('Soft-reset is disabled. Server will restart!', {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled. Server will restart!'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.start_scenario('Fish_Defender')
                    FDT.set('announced_message', true)
                    return
                end
            end
            if shutdown and game_restart_timer == 0 then
                if not announced_message then
                    game.print('Soft-reset is disabled. Server is shutting down!', {r = 0.22, g = 0.88, b = 0.22})
                    local message = 'Soft-reset is disabled. Server is shutting down!'
                    Server.to_discord_bold(table.concat {'*** ', message, ' ***'})
                    Server.stop_scenario()
                    FDT.set('announced_message', true)
                    return
                end
            end
        end
    end
end

function Public.reset_game()
    FDT.reset_table()
    local get_score = Score.get_table()
    Poll.reset()

    Difficulty.reset_difficulty_poll()

    AntiGrief.reset_tables()

    FDT.set('fish_eye_location', {x = -1667, y = -50})

    global.fish_in_space = 0
    get_score.score_table = {}

    local wave_grace_period = FDT.get('wave_grace_period')
    if not wave_grace_period then
        wave_grace_period = game.tick + 72000
    end
    Difficulty.reset_difficulty_poll({difficulty_poll_closing_timeout = wave_grace_period})

    local difficulties = {
        [1] = {
            name = 'Easy',
            value = 0.75,
            color = {r = 0.00, g = 0.25, b = 0.00},
            print_color = {r = 0.00, g = 0.4, b = 0.00},
            enabled = true
        },
        [2] = {
            name = 'Normal',
            value = 1,
            color = {r = 0.00, g = 0.00, b = 0.25},
            print_color = {r = 0.0, g = 0.0, b = 0.5}
        },
        [3] = {
            name = 'Hard',
            value = 1.5,
            color = {r = 0.25, g = 0.00, b = 0.00},
            print_color = {r = 0.4, g = 0.0, b = 0.00}
        },
        [4] = {
            name = 'Nightmare',
            value = 3,
            color = {r = 0.35, g = 0.00, b = 0.00},
            print_color = {r = 0.6, g = 0.0, b = 0.00}
        },
        [5] = {
            name = 'Impossible',
            value = 5,
            color = {r = 0.45, g = 0.00, b = 0.00},
            print_color = {r = 0.8, g = 0.0, b = 0.00}
        }
    }
    Difficulty.set_difficulties(difficulties)

    local players = game.connected_players
    for i = 1, #players do
        local player = players[i]
        Score.init_player_table(player)
        if player.gui.left['fish_defense_game_lost'] then
            player.gui.left['fish_defense_game_lost'].destroy()
        end
        if player.gui.left['fish_in_space'] then
            player.gui.left['fish_in_space'].destroy()
        end
    end

    local map_gen_settings = {}
    map_gen_settings.seed = math_random(10000, 99999)
    map_gen_settings.width = 4000
    map_gen_settings.height = 1800
    map_gen_settings.water = 0.10
    map_gen_settings.terrain_segmentation = 3
    map_gen_settings.cliff_settings = {cliff_elevation_interval = 32, cliff_elevation_0 = 32}
    map_gen_settings.autoplace_controls = {
        ['coal'] = {frequency = 4, size = 1.5, richness = 2},
        ['stone'] = {frequency = 4, size = 1.5, richness = 2},
        ['copper-ore'] = {frequency = 4, size = 1.5, richness = 2},
        ['iron-ore'] = {frequency = 4, size = 1.5, richness = 2},
        ['uranium-ore'] = {frequency = 0, size = 0, richness = 0},
        ['crude-oil'] = {frequency = 5, size = 1.25, richness = 2},
        ['trees'] = {frequency = 2, size = 1, richness = 1},
        ['enemy-base'] = {frequency = 'none', size = 'none', richness = 'none'}
    }

    local active_surface_index = FDT.get('active_surface_index')

    if not active_surface_index then
        FDT.set('active_surface_index', game.create_surface('fish_defender', map_gen_settings).index)
        active_surface_index = FDT.get('active_surface_index')
    else
        FDT.set('active_surface_index', Reset.soft_reset_map(game.surfaces[active_surface_index], map_gen_settings, starting_items).index)
        active_surface_index = FDT.get('active_surface_index')
    end

    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end

    surface.peaceful_mode = false

    game.map_settings.enemy_expansion.enabled = false
    game.map_settings.enemy_evolution.destroy_factor = 0
    game.map_settings.enemy_evolution.time_factor = 0
    game.map_settings.enemy_evolution.pollution_factor = 0
    game.map_settings.pollution.enabled = false

    game.forces['player'].technologies['atomic-bomb'].enabled = false
    --game.forces["player"].technologies["landfill"].enabled = false

    if not game.forces.decoratives then
        game.create_force('decoratives')
    end

    game.forces['decoratives'].set_cease_fire('enemy', true)
    game.forces['enemy'].set_cease_fire('decoratives', true)
    game.forces['player'].set_cease_fire('decoratives', true)
    game.remove_offline_players()

    game.map_settings.enemy_expansion.enabled = false
    game.forces.player.technologies['artillery'].researched = false
    game.forces.player.technologies['spidertron'].enabled = false
    game.forces.player.technologies['spidertron'].researched = false
    game.reset_time_played()

    if not global.catplanet_goals then
        global.catplanet_goals = {
            {goal = 0, rank = false, achieved = true},
            {
                goal = 100,
                rank = 'Copper',
                color = {r = 201, g = 133, b = 6},
                msg = 'You have saved the first container of fish!',
                msg2 = 'However, this is only the beginning.',
                achieved = false
            },
            {
                goal = 1000,
                rank = 'Bronze',
                color = {r = 186, g = 115, b = 39},
                msg = 'Thankful for the fish, they sent back a toy mouse made of solid bronze!',
                msg2 = 'They are demanding more.',
                achieved = false
            },
            {
                goal = 10000,
                rank = 'Silver',
                color = {r = 186, g = 178, b = 171},
                msg = 'In gratitude for the fish, they left you a silver furball!',
                msg2 = 'They are still longing for more.',
                achieved = false
            },
            {
                goal = 25000,
                rank = 'Gold',
                color = {r = 255, g = 214, b = 33},
                msg = 'Pleased about the delivery, they sent back a golden audiotape with cat purrs.',
                msg2 = 'They still demand more.',
                achieved = false
            },
            {
                goal = 50000,
                rank = 'Platinum',
                color = {r = 224, g = 223, b = 215},
                msg = 'To express their infinite love, they sent back a yarnball made of shiny material.',
                msg2 = 'Defying all logic, they still demand more fish.',
                achieved = false
            },
            {
                goal = 100000,
                rank = 'Diamond',
                color = {r = 237, g = 236, b = 232},
                msg = 'A box arrives with a mewing kitten, it a has a diamond collar.',
                msg2 = 'More fish? Why? What..',
                achieved = false
            },
            {
                goal = 250000,
                rank = 'Anti-matter',
                color = {r = 100, g = 100, b = 245},
                msg = 'The obese cat colapses and forms a black hole!',
                msg2 = ':obese:',
                achieved = false
            },
            {
                goal = 500000,
                rank = 'Black Hole',
                color = {r = 100, g = 100, b = 245},
                msg = 'A letter arrives, it reads: Go to bed hooman!',
                msg2 = 'Not yet...',
                achieved = false
            },
            {
                goal = 1000000,
                rank = 'Blue Screen',
                color = {r = 100, g = 100, b = 245},
                msg = 'Cat error #4721',
                msg2 = '....',
                achieved = false
            },
            {goal = 10000000, rank = 'Blue Screen', color = {r = 100, g = 100, b = 245}, msg = '....', msg2 = '....', achieved = false}
        }
    end
end

function Public.on_init()
    Public.reset_game()

    local T = Map.Pop_info()
    T.localised_category = 'fish_defender'
    T.main_caption_color = {r = 0.11, g = 0.8, b = 0.44}
    T.sub_caption_color = {r = 0.33, g = 0.66, b = 0.9}
end

local function on_tick()
    local active_surface_index = FDT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not surface or not surface.valid then
        return
    end
    local tick = game.tick
    if tick % 30 == 0 then
        has_the_game_ended()
        local market = FDT.get('market')
        if market and market.valid then
            for _, player in pairs(game.connected_players) do
                if surface.peaceful_mode == false then
                    create_wave_gui(player)
                end
            end
        end
        if tick % 180 == 0 then
            if surface then
                game.forces.player.chart(surface, {{-160, -130}, {160, 179}})
                FDT.set('wave_interval', FDT.get_current_difficulty_wave_interval())
            end
        end

        local wave_count = FDT.get('wave_count')
        local wave_limit = FDT.get('wave_limit')

        if wave_count >= wave_limit then
            if market and market.valid then
                market.die()
                game.print('Game wave limit reached! Game will soft-reset shortly.', {r = 0.22, g = 0.88, b = 0.22})
            end
        end

        local spawn_area_generated = FDT.get('spawn_area_generated')
        local fish = FDT.get('fish_eye')
        if spawn_area_generated and not fish then
            fish_eye(surface, {x = -1667, y = -50})
        end
    end

    local wave_interval = FDT.get('wave_interval')

    if tick % wave_interval == wave_interval - 1 then
        if surface.peaceful_mode == true then
            return
        end
        biter_attack_wave()
    end
end

local on_init = Public.on_init

Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_tick, on_tick)
Event.on_init(on_init)

return Public
