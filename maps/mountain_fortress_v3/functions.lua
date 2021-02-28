local Token = require 'utils.token'
local Task = require 'utils.task'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Alert = require 'utils.alert'
local WPT = require 'maps.mountain_fortress_v3.table'
local WD = require 'modules.wave_defense.table'
local Collapse = require 'modules.collapse'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local math2d = require 'math2d'
local BottomFrame = require 'comfy_panel.bottom_frame'

local this = {
    power_sources = {index = 1},
    refill_turrets = {index = 1},
    magic_crafters = {index = 1},
    magic_fluid_crafters = {index = 1},
    art_table = {index = 1},
    surface_cleared = false
}

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['rail'] = 16, ['wood'] = 16, ['explosives'] = 32}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

local random = math.random
local floor = math.floor
local remove = table.remove
local sqrt = math.sqrt
local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8
local tile_damage = 50

local artillery_target_entities = {
    'character',
    'tank',
    'car',
    'radar',
    'lab',
    'furnace',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon',
    'artillery-turret',
    'laser-turret',
    'gun-turret',
    'flamethrower-turret',
    'silo',
    'spidertron'
}

function Public.get_player_data(player, remove_user_data)
    local players = WPT.get('players')
    if remove_user_data then
        if players[player.index] then
            players[player.index] = nil
        end
    end
    if not players[player.index] then
        players[player.index] = {}
    end
    return players[player.index]
end

local get_player_data = Public.get_player_data

local function debug_str(msg)
    local debug = WPT.get('debug')
    if not debug then
        return
    end
    print('Mtn: ' .. msg)
end

local function show_text(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({name = 'flying-text', position = pos, text = msg})
    else
        surface.create_entity({name = 'flying-text', position = pos, text = msg, color = color})
    end
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local function do_refill_turrets()
    local refill_turrets = this.refill_turrets
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local turret_data = refill_turrets[index]
    local turret = turret_data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)
        return
    end

    refill_turrets.index = index + 1

    local data = turret_data.data
    if data.liquid then
        turret.fluidbox[1] = data
    elseif data then
        turret.insert(data)
    end
end

local function do_turret_energy()
    local power_sources = this.power_sources

    for index = 1, #power_sources do
        local ps_data = power_sources[index]
        if not (ps_data and ps_data.valid) then
            fast_remove(power_sources, index)
            return
        end

        ps_data.energy = 0xfffff
    end
end

local function do_magic_crafters()
    local magic_crafters = this.magic_crafters
    local limit = #magic_crafters
    if limit == 0 then
        return
    end

    local index = magic_crafters.index

    for i = 1, magic_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 1 then
                fcount = 1
            end

            if fcount > 0 then
                entity.get_output_inventory().insert {name = data.item, count = fcount}
                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local magic_fluid_crafters = this.magic_fluid_crafters
    local limit = #magic_fluid_crafters

    if limit == 0 then
        return
    end

    local index = magic_fluid_crafters.index

    for i = 1, magic_fluid_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_fluid_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_fluid_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                local fluidbox_index = data.fluidbox_index
                local fb = entity.fluidbox

                local fb_data = fb[fluidbox_index] or {name = data.item, amount = 0}
                fb_data.amount = fb_data.amount + fcount
                fb[fluidbox_index] = fb_data

                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_fluid_crafters.index = index
end

local artillery_target_callback =
    Token.register(
    function(data)
        local position = data.position
        local entity = data.entity

        if not entity.valid then
            return
        end

        local tx, ty = position.x, position.y

        local pos = entity.position
        local x, y = pos.x, pos.y
        local dx, dy = tx - x, ty - y
        local d = dx * dx + dy * dy
        if d >= 1024 and d <= 441398 then -- 704 in depth~
            if entity.name == 'character' then
                entity.surface.create_entity {
                    name = 'artillery-projectile',
                    position = position,
                    target = entity,
                    force = 'enemy',
                    speed = 1.5
                }
            elseif entity.name ~= 'character' then
                entity.surface.create_entity {
                    name = 'rocket',
                    position = position,
                    target = entity,
                    force = 'enemy',
                    speed = 1.5
                }
            end
        end
    end
)

local function do_artillery_turrets_targets()
    local art_table = this.art_table
    local index = art_table.index

    if index > #art_table then
        art_table.index = 1
        return
    end

    art_table.index = index + 1

    local outpost = art_table[index]

    local now = game.tick
    if now - outpost.last_fire_tick < 480 then
        return
    end

    local turrets = outpost.artillery_turrets
    for i = #turrets, 1, -1 do
        local turret = turrets[i]
        if not turret.valid then
            fast_remove(turrets, i)
        end
    end

    local count = #turrets
    if count == 0 then
        fast_remove(art_table, index)
        return
    end

    outpost.last_fire_tick = now

    local turret = turrets[1]
    local area = outpost.artillery_area
    local surface = turret.surface

    local entities = surface.find_entities_filtered {area = area, name = artillery_target_entities, force = 'player'}

    if #entities == 0 then
        return
    end

    local position = turret.position

    for i = 1, count do
        local entity = entities[random(#entities)]
        if entity and entity.valid then
            local data = {position = position, entity = entity}
            Task.set_timeout_in_ticks(i * 60, artillery_target_callback, data)
        end
    end
end

local function add_magic_crafter_output(entity, output, distance)
    local magic_fluid_crafters = this.magic_fluid_crafters
    local magic_crafters = this.magic_crafters
    local rate = output.min_rate + output.distance_factor * distance

    local fluidbox_index = output.fluidbox_index
    local data = {
        entity = entity,
        last_tick = game.tick,
        base_rate = rate,
        rate = rate,
        item = output.item,
        fluidbox_index = fluidbox_index
    }

    if fluidbox_index then
        magic_fluid_crafters[#magic_fluid_crafters + 1] = data
    else
        magic_crafters[#magic_crafters + 1] = data
    end
end

local function tick()
    do_refill_turrets()
    do_magic_crafters()
    do_magic_fluid_crafters()
    do_artillery_turrets_targets()
end

Public.deactivate_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.neutral_force =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'neutral'
        end
    end
)

Public.enemy_force =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'enemy'
        end
    end
)

Public.active_not_destructible_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = true
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.disable_minable_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
        end
    end
)

Public.disable_minable_and_ICW_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
            ICW.register_wagon(entity, true)
        end
    end
)

Public.disable_destructible_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.destructible = false
            entity.minable = false
        end
    end
)
Public.disable_active_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
        end
    end
)

local disable_active_callback = Public.disable_active_callback

Public.refill_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local callback_data = data.callback_data
        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.refill_artillery_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local art_table = this.art_table
        local index = art_table.index

        turret.active = false
        turret.direction = 3

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = data.callback_data}

        local artillery_data = art_table[index]
        if not artillery_data then
            artillery_data = {}
        end

        local artillery_turrets = artillery_data.artillery_turrets
        if not artillery_turrets then
            artillery_turrets = {}
            artillery_data.artillery_turrets = artillery_turrets

            local pos = turret.position
            local x, y = pos.x, pos.y
            artillery_data.artillery_area = {{x - 112, y}, {x + 112, y + 212}}
            artillery_data.last_fire_tick = 0

            art_table[#art_table + 1] = artillery_data
        end

        artillery_turrets[#artillery_turrets + 1] = turret
    end
)

Public.refill_liquid_turret_callback =
    Token.register(
    function(turret, data)
        local refill_turrets = this.refill_turrets
        local callback_data = data.callback_data
        callback_data.liquid = true

        refill_turrets[#refill_turrets + 1] = {turret = turret, data = callback_data}
    end
)

Public.power_source_callback =
    Token.register(
    function(turret)
        local power_sources = this.power_sources
        power_sources[#power_sources + 1] = turret
    end
)

Public.magic_item_crafting_callback =
    Token.register(
    function(entity, data)
        local callback_data = data.callback_data
        if not (entity and entity.valid) then
            return
        end

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local force = game.forces.player

        local tech = callback_data.tech
        if tech then
            if not force.technologies[tech].researched then
                entity.destroy()
                return
            end
        end

        local recipe = callback_data.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = callback_data.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = callback_data.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for i = 1, #output do
                local o = output[i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

Public.magic_item_crafting_callback_weighted =
    Token.register(
    function(entity, data)
        local callback_data = data.callback_data
        if not (entity and entity.valid) then
            return
        end

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local weights = callback_data.weights
        local loot = callback_data.loot

        local p = entity.position

        local i = random() * weights.total

        local index = table.binary_search(weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local stack = loot[index].stack
        if not stack then
            return
        end

        local force = game.forces.player

        local tech = stack.tech
        if tech then
            if force.technologies[tech] then
                if not force.technologies[tech].researched then
                    entity.destroy()
                    return
                end
            end
        end

        local recipe = stack.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = stack.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = stack.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for o_i = 1, #output do
                local o = output[o_i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

function Public.prepare_weighted_loot(loot)
    local total = 0
    local weights = {}

    for i = 1, #loot do
        local v = loot[i]
        total = total + v.weight
        weights[#weights + 1] = total
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    --entity.destructible = false

    local i = random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.insert {name = stack.name, count = count}
end

function Public.remove_offline_players()
    local offline_players_enabled = WPT.get('offline_players_enabled')
    if not offline_players_enabled then
        return
    end
    local offline_players = WPT.get('offline_players')
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    local player_inv = {}
    local items = {}
    if #offline_players > 0 then
        local later = {}
        for i = 1, #offline_players, 1 do
            if offline_players[i] and game.players[offline_players[i].index] and game.players[offline_players[i].index].connected then
                offline_players[i] = nil
            else
                if offline_players[i] and game.players[offline_players[i].index] and offline_players[i].tick < game.tick - 108000 then
                    local name = offline_players[i].name
                    player_inv[1] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_main)
                    player_inv[2] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_armor)
                    player_inv[3] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_guns)
                    player_inv[4] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_ammo)
                    player_inv[5] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_trash)
                    local pos = game.forces.player.get_spawn_position(surface)
                    local e =
                        surface.create_entity(
                        {
                            name = 'character',
                            position = pos,
                            force = 'neutral'
                        }
                    )
                    local inv = e.get_inventory(defines.inventory.character_main)
                    e.character_inventory_slots_bonus = #player_inv[1]
                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            for iii = 1, #player_inv[ii], 1 do
                                if player_inv[ii][iii].valid then
                                    items[#items + 1] = player_inv[ii][iii]
                                end
                            end
                        end
                    end
                    if #items > 0 then
                        for item = 1, #items, 1 do
                            if items[item].valid then
                                inv.insert(items[item])
                            end
                        end

                        local message = ({'main.cleaner', name})
                        local data = {
                            position = pos
                        }
                        Alert.alert_all_players_location(data, message)

                        e.die('neutral')
                    else
                        e.destroy()
                    end

                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            player_inv[ii].clear()
                        end
                    end
                    offline_players[i] = nil
                else
                    later[#later + 1] = offline_players[i]
                end
            end
        end
        for k, _ in pairs(offline_players) do
            offline_players[k] = nil
        end
        if #later > 0 then
            for i = 1, #later, 1 do
                offline_players[#offline_players + 1] = later[i]
            end
        end
    end
end

local function calc_players()
    local players = game.connected_players
    local check_afk_players = WPT.get('check_afk_players')
    if not check_afk_players then
        return #players
    end
    local total = 0
    for i = 1, #players do
        local player = players[i]
        if player.afk_time < 36000 then
            total = total + 1
        end
    end
    if total <= 0 then
        total = #players
    end
    return total
end

function Public.set_difficulty()
    local game_lost = WPT.get('game_lost')
    if game_lost then
        return
    end
    local Diff = Difficulty.get()
    local wave_defense_table = WD.get_table()
    local collapse_amount = WPT.get('collapse_amount')
    local collapse_speed = WPT.get('collapse_speed')
    local difficulty = WPT.get('difficulty')
    local player_count = calc_players()

    if not Diff.difficulty_vote_value then
        Diff.difficulty_vote_value = 0.1
    end

    wave_defense_table.max_active_biters = 768 + player_count * (90 * Diff.difficulty_vote_value)

    if wave_defense_table.max_active_biters >= 4000 then
        wave_defense_table.max_active_biters = 4000
    end

    -- threat gain / wave
    wave_defense_table.threat_gain_multiplier = 1.2 + player_count * Diff.difficulty_vote_value * 0.1

    -- local amount = player_count * 0.40 + 2 -- too high?
    local amount = player_count * difficulty.multiply + 2
    amount = floor(amount)
    if amount > difficulty.highest then
        amount = difficulty.highest -- lowered from 20 to 15
    end

    wave_defense_table.wave_interval = 3600 - player_count * 60

    if wave_defense_table.wave_interval < 1800 or wave_defense_table.threat <= 0 then
        wave_defense_table.wave_interval = 1800
    end

    if collapse_amount then
        Collapse.set_amount(collapse_amount)
    else
        Collapse.set_amount(amount)
    end
    if collapse_speed then
        Collapse.set_speed(collapse_speed)
    else
        if player_count >= 1 and player_count <= 8 then
            Collapse.set_speed(9)
        elseif player_count > 8 and player_count <= 20 then
            Collapse.set_speed(8)
        elseif player_count > 20 and player_count <= 35 then
            Collapse.set_speed(6)
        elseif player_count > 35 then
            Collapse.set_speed(5)
        end
    end
end

function Public.render_direction(surface)
    local counter = WPT.get('soft_reset_counter')
    local winter_mode = WPT.get('winter_mode')
    local text = 'Welcome to Mountain Fortress v3!'
    if winter_mode then
        text = 'Welcome to Wintery Mountain Fortress v3!'
    end

    local modded = is_game_modded()

    if modded then
        text = 'Welcome to Modded Mountain Fortress v3!'
    end
    if counter then
        rendering.draw_text {
            text = text .. '\nRun: ' .. counter,
            surface = surface,
            target = {-0, 10},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    else
        rendering.draw_text {
            text = text,
            surface = surface,
            target = {-0, 10},
            color = {r = 0.98, g = 0.66, b = 0.22},
            scale = 3,
            font = 'heading-1',
            alignment = 'center',
            scale_with_zoom = false
        }
    end

    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 20},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 30},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 40},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 50},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = '▼',
        surface = surface,
        target = {-0, 60},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }
    rendering.draw_text {
        text = 'Biters will attack this area.',
        surface = surface,
        target = {-0, 70},
        color = {r = 0.98, g = 0.66, b = 0.22},
        scale = 3,
        font = 'heading-1',
        alignment = 'center',
        scale_with_zoom = false
    }

    local x_min = -WPT.level_width / 2
    local x_max = WPT.level_width / 2

    surface.create_entity({name = 'electric-beam', position = {x_min, 74}, source = {x_min, 74}, target = {x_max, 74}})
    surface.create_entity({name = 'electric-beam', position = {x_min, 74}, source = {x_min, 74}, target = {x_max, 74}})
end

function Public.boost_difficulty()
    local difficulty_set = WPT.get('difficulty_set')
    if difficulty_set then
        return
    end

    local breached_wall = WPT.get('breached_wall')

    local difficulty = Difficulty.get()
    local name = difficulty.difficulties[difficulty.difficulty_vote_index].name

    if game.tick < difficulty.difficulty_poll_closing_timeout and breached_wall <= 1 then
        return
    end

    Difficulty.get().name = name
    Difficulty.get().difficulty_poll_closing_timeout = game.tick

    Difficulty.get().button_tooltip = difficulty.tooltip[difficulty.difficulty_vote_index]
    Difficulty.difficulty_gui()

    local message = ({'main.diff_set', name})
    local data = {
        position = WPT.get('locomotive').position
    }
    Alert.alert_all_players_location(data, message)

    local force = game.forces.player

    local unit_modifiers = WD.get('modified_unit_health')

    if name == "I'm too young to die" then
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.5
        force.character_running_speed_modifier = 0.15
        force.manual_crafting_speed_modifier = 0.15
        WPT.set('coin_amount', 1)
        WPT.set('upgrades').flame_turret.limit = 12
        WPT.set('upgrades').landmine.limit = 50
        if is_game_modded() then
            WPT.set('locomotive_health', 20000)
            WPT.set('locomotive_max_health', 20000)
        else
            WPT.set('locomotive_health', 10000)
            WPT.set('locomotive_max_health', 10000)
        end
        WPT.set('bonus_xp_on_join', 500)
        WD.set('next_wave', game.tick + 3600 * 15)
        WPT.set('spidertron_unlocked_at_zone', 10)
        WD.set_biter_health_boost(1.50)
        unit_modifiers.limit_value = 30
        unit_modifiers.health_increase_per_boss_wave = 0.04
        WPT.set('difficulty_set', true)
    elseif name == 'Hurt me plenty' then
        force.manual_mining_speed_modifier = force.manual_mining_speed_modifier + 0.25
        force.character_running_speed_modifier = 0.1
        force.manual_crafting_speed_modifier = 0.1
        WPT.set('coin_amount', 2)
        WPT.set('upgrades').flame_turret.limit = 10
        WPT.set('upgrades').landmine.limit = 50
        if is_game_modded() then
            WPT.set('locomotive_health', 12000)
            WPT.set('locomotive_max_health', 12000)
        else
            WPT.set('locomotive_health', 7000)
            WPT.set('locomotive_max_health', 7000)
        end
        WPT.set('bonus_xp_on_join', 300)
        WD.set('next_wave', game.tick + 3600 * 8)
        WPT.set('spidertron_unlocked_at_zone', 8)
        unit_modifiers.limit_value = 40
        unit_modifiers.health_increase_per_boss_wave = 0.06
        WD.set_biter_health_boost(2)
        WPT.set('difficulty_set', true)
    elseif name == 'Ultra-violence' then
        force.character_running_speed_modifier = 0
        force.manual_crafting_speed_modifier = 0
        WPT.set('coin_amount', 4)
        WPT.set('upgrades').flame_turret.limit = 3
        WPT.set('upgrades').landmine.limit = 10
        if is_game_modded() then
            WPT.set('locomotive_health', 8000)
            WPT.set('locomotive_max_health', 8000)
        else
            WPT.set('locomotive_health', 5000)
            WPT.set('locomotive_max_health', 5000)
        end
        WPT.set('bonus_xp_on_join', 50)
        WD.set('next_wave', game.tick + 3600 * 5)
        WPT.set('spidertron_unlocked_at_zone', 6)
        unit_modifiers.limit_value = 50
        unit_modifiers.health_increase_per_boss_wave = 0.08
        WD.set_biter_health_boost(4)
        WPT.set('difficulty_set', true)
    end
end

function Public.set_spawn_position()
    local collapse_pos = Collapse.get_position()
    local locomotive = WPT.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end
    local l = locomotive.position

    local retries = 0

    local function check_tile(surface, tile, tbl, inc)
        if not (surface and surface.valid) then
            return false
        end
        if not tile then
            return false
        end
        local get_tile = surface.get_tile(tile)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            remove(tbl, inc - inc + 1)
            return true
        else
            return false
        end
    end

    ::retry::

    local locomotive_positions = WPT.get('locomotive_pos')
    local total_pos = #locomotive_positions.tbl

    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    if not (surface and surface.valid) then
        return
    end

    local spawn_near_collapse = WPT.get('spawn_near_collapse')

    if spawn_near_collapse.active then
        local collapse_position = surface.find_non_colliding_position('small-biter', collapse_pos, 32, 2)
        local sizeof = locomotive_positions.tbl[total_pos - total_pos + 1]
        if not sizeof then
            goto continue
        end

        if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
            retries = retries + 1
            if retries == 2 then
                goto continue
            end
            goto retry
        end

        local locomotive_position = surface.find_non_colliding_position('small-biter', sizeof, 128, 1)
        local distance_from = floor(math2d.position.distance(locomotive_position, locomotive.position))
        local l_y = l.y
        local t_y = locomotive_position.y
        local c_y = collapse_pos.y
        if total_pos > spawn_near_collapse.total_pos then
            if l_y - t_y <= spawn_near_collapse.compare then
                if locomotive_position then
                    if check_tile(surface, sizeof, locomotive_positions.tbl, total_pos) then
                        debug_str('total_pos was higher - found oom')
                        retries = retries + 1
                        if retries == 2 then
                            goto continue
                        end
                        goto retry
                    end
                    debug_str('total_pos was higher - spawning at locomotive_position')
                    WD.set_spawn_position(locomotive_position)
                end
            elseif c_y - t_y <= spawn_near_collapse.compare_next then
                if distance_from >= spawn_near_collapse.distance_from then
                    local success = check_tile(surface, locomotive_position, locomotive_positions.tbl, total_pos)
                    if success then
                        debug_str('distance_from was higher - found oom')
                        return
                    end
                    debug_str('distance_from was higher - spawning at locomotive_position')
                    WD.set_spawn_position({x = locomotive_position.x, y = collapse_pos.y - 20})
                else
                    debug_str('distance_from was lower - spawning at locomotive_position')
                    WD.set_spawn_position({x = locomotive_position.x, y = collapse_pos.y - 20})
                end
            else
                if collapse_position then
                    debug_str('total_pos was higher - spawning at collapse_position')
                    WD.set_spawn_position(collapse_position)
                end
            end
        else
            if collapse_position then
                debug_str('total_pos was lower - spawning at collapse_position')
                WD.set_spawn_position(collapse_position)
            end
        end
    end

    ::continue::
end

function Public.on_player_joined_game(event)
    local active_surface_index = WPT.get('active_surface_index')
    local player = game.players[event.player_index]
    local surface = game.surfaces[active_surface_index]

    Public.set_difficulty()

    ICW_Func.is_minimap_valid(player, surface)

    local player_data = get_player_data(player)

    if not player_data.first_join then
        local message = ({'main.greeting', player.name})
        Alert.alert_player(player, 15, message)
        for item, amount in pairs(starting_items) do
            player.insert({name = item, count = amount})
        end
        player_data.first_join = true
    end

    local top = player.gui.top
    if top['mod_gui_top_frame'] then
        top['mod_gui_top_frame'].destroy()
    end

    if player.surface.index ~= active_surface_index then
        player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
    else
        local p = {x = player.position.x, y = player.position.y}
        local get_tile = surface.get_tile(p)
        if get_tile.valid and get_tile.name == 'out-of-map' then
            player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
        end
    end

    local locomotive = WPT.get('locomotive')

    if not locomotive or not locomotive.valid then
        return
    end
    if player.position.y > locomotive.position.y then
        player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 3, 0, 5), surface)
    end
end

function Public.on_player_left_game()
    Public.set_difficulty()
end

function Public.is_creativity_mode_on()
    local creative_enabled = BottomFrame.get('creative_enabled')
    if creative_enabled then
        WD.set('next_wave', 1000)
        Collapse.start_now(true)
        Public.set_difficulty()
    end
end

function Public.disable_creative()
    local creative_enabled = BottomFrame.get('creative_enabled')
    if creative_enabled then
        BottomFrame.set('creative_enabled', false)
    end
end

function Public.on_pre_player_left_game(event)
    local offline_players_enabled = WPT.get('offline_players_enabled')
    if not offline_players_enabled then
        return
    end

    local offline_players = WPT.get('offline_players')
    local player = game.players[event.player_index]
    local ticker = game.tick
    if player.character then
        offline_players[#offline_players + 1] = {
            index = event.player_index,
            name = player.name,
            tick = ticker
        }
    end
end

function Public.on_player_respawned(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local player_data = get_player_data(player)
    if player_data.died then
        player_data.died = nil
    end
end

function Public.on_player_died(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local player_data = get_player_data(player)
    player_data.died = true
end

function Public.on_player_changed_position(event)
    local active_surface_index = WPT.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local player = game.players[event.player_index]
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = player.position
    local surface = game.surfaces[active_surface_index]

    local p = {x = player.position.x, y = player.position.y}
    local get_tile = surface.get_tile(p)
    local config_tile = WPT.get('void_or_tile')
    if config_tile == 'lab-dark-2' then
        if get_tile.valid and get_tile.name == 'lab-dark-2' then
            if random(1, 2) == 1 then
                if random(1, 2) == 1 then
                    show_text('This path is not for players!', p, {r = 0.98, g = 0.66, b = 0.22}, surface)
                end
                player.surface.create_entity({name = 'fire-flame', position = player.position})
                player.character.health = player.character.health - tile_damage
                if player.character.health == 0 then
                    player.character.die()
                    local message = ({'main.death_message_' .. random(1, 7), player.name})
                    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
                end
            end
        end
    end

    if position.y >= 74 then
        player.teleport({position.x, position.y - 1}, surface)
        player.print(({'main.forcefield'}), {r = 0.98, g = 0.66, b = 0.22})
        if player.character then
            player.character.health = player.character.health - 5
            player.character.surface.create_entity({name = 'water-splash', position = position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local disable_recipes = function(force)
    force.recipes['cargo-wagon'].enabled = false
    force.recipes['fluid-wagon'].enabled = false
    force.recipes['car'].enabled = false
    force.recipes['tank'].enabled = false
    force.recipes['artillery-wagon'].enabled = false
    force.recipes['locomotive'].enabled = false
    force.recipes['pistol'].enabled = false
    force.recipes['spidertron-remote'].enabled = false
    if is_mod_loaded('Krastorio2') then
        force.recipes['kr-advanced-tank'].enabled = false
    end
end

function Public.disable_tech()
    local force = game.forces.player
    force.technologies['landfill'].enabled = false
    force.technologies['spidertron'].enabled = false
    force.technologies['spidertron'].researched = false
    force.technologies['atomic-bomb'].enabled = false
    force.technologies['atomic-bomb'].researched = false
    force.technologies['optics'].researched = true
    force.technologies['railway'].researched = true
    force.technologies['land-mine'].enabled = false
    if is_mod_loaded('Krastorio2') then
        force.technologies['kr-nuclear-locomotive'].enabled = false
        force.technologies['kr-nuclear-locomotive'].researched = false
        force.technologies['kr-advanced-tank'].enabled = false
        force.technologies['kr-advanced-tank'].researched = false
    end
    disable_recipes(force)
end

local disable_tech = Public.disable_tech

function Public.on_research_finished(event)
    disable_tech()

    local research = event.research

    research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 50 -- +5 Slots /

    if research.name == 'steel-axe' then
        local msg = 'Steel-axe technology has been researched, 100% has been applied.\nBuy Pickaxe-upgrades in the market to boost it even more!'
        Alert.alert_all_players(30, msg, nil, 'achievement/tech-maniac', 0.6)
    end -- +50% speed for steel-axe research

    local force_name = research.force.name
    if not force_name then
        return
    end
    local flamethrower_damage = WPT.get('flamethrower_damage')
    flamethrower_damage[force_name] = -0.85
    if research.name == 'military' then
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end

    if string.sub(research.name, 0, 18) == 'refined-flammables' then
        flamethrower_damage[force_name] = flamethrower_damage[force_name] + 0.10
        game.forces[force_name].set_turret_attack_modifier('flamethrower-turret', flamethrower_damage[force_name])
        game.forces[force_name].set_ammo_damage_modifier('flamethrower', flamethrower_damage[force_name])
    end
end

-- if is_mod_loaded('Krastorio2') then
-- Public.firearm_magazine_ammo = {name = 'rifle-magazine', count = 200}
-- Public.piercing_rounds_magazine_ammo = {name = 'armor-piercing-rifle-magazine', count = 200}
-- Public.uranium_rounds_magazine_ammo = {name = 'uranium-rifle-magazine', count = 200}
-- else
Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
-- end

Public.light_oil_ammo = {name = 'light-oil', amount = 100}
Public.artillery_shell_ammo = {name = 'artillery-shell', count = 15}
Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}

function Public.reset_table()
    this.power_sources = {index = 1}
    this.refill_turrets = {index = 1}
    this.magic_crafters = {index = 1}
    this.magic_fluid_crafters = {index = 1}
end

local on_player_joined_game = Public.on_player_joined_game
local on_player_left_game = Public.on_player_left_game
local on_player_respawned = Public.on_player_respawned
local on_player_died = Public.on_player_died
local on_research_finished = Public.on_research_finished
local on_player_changed_position = Public.on_player_changed_position
local on_pre_player_left_game = Public.on_pre_player_left_game

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.on_nth_tick(10, tick)
Event.on_nth_tick(5, do_turret_energy)

return Public
