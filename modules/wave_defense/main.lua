local Event = require 'utils.event'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local BiterRolls = require 'modules.wave_defense.biter_rolls'
local SideTargets = require 'modules.wave_defense.side_targets'
local ThreatEvent = require 'modules.wave_defense.threat_events'
local update_gui = require 'modules.wave_defense.gui'
local threat_values = require 'modules.wave_defense.threat_values'
local WD = require 'modules.wave_defense.table'
local Alert = require 'utils.alert'

local Public = {}
local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local math_sqrt = math.sqrt
local math_round = math.round

local group_size_modifier_raffle = {}
local group_size_chances = {
    {4, 0.4},
    {5, 0.5},
    {6, 0.6},
    {7, 0.7},
    {8, 0.8},
    {9, 0.9},
    {10, 1},
    {9, 1.1},
    {8, 1.2},
    {7, 1.3},
    {6, 1.4},
    {5, 1.5},
    {4, 1.6},
    {3, 1.7},
    {2, 1.8}
}

for _, v in pairs(group_size_chances) do
    for _ = 1, v[1], 1 do
        table_insert(group_size_modifier_raffle, v[2])
    end
end
local group_size_modifier_raffle_size = #group_size_modifier_raffle

local function debug_print(msg)
    local debug = WD.get('debug')
    if not debug then
        return
    end
    print('WaveDefense: ' .. msg)
end

local function valid(userdata)
    if not (userdata and userdata.valid) then
        return false
    end
    return true
end

local function find_initial_spot(surface, position)
    local spot = WD.get('spot')
    if not spot then
        local pos = surface.find_non_colliding_position('rocket-silo', position, 128, 1)
        if not pos then
            pos = surface.find_non_colliding_position('rocket-silo', position, 148, 1)
        end
        if not pos then
            pos = surface.find_non_colliding_position('rocket-silo', position, 164, 1)
        end
        if not pos then
            pos = position
        end

        WD.set('spot', pos)
        return pos
    else
        spot = WD.get('spot')
        return spot
    end
end

local function is_closer(pos1, pos2, pos)
    return ((pos1.x - pos.x) ^ 2 + (pos1.y - pos.y) ^ 2) < ((pos2.x - pos.x) ^ 2 + (pos2.y - pos.y) ^ 2)
end

local function shuffle_distance(tbl, position)
    local size = #tbl
    for i = size, 1, -1 do
        local rand = math_random(size)
        if is_closer(tbl[i].position, tbl[rand].position, position) and i > rand then
            tbl[i], tbl[rand] = tbl[rand], tbl[i]
        end
    end
    return tbl
end

local function is_position_near(pos_to_check, check_against)
    local function inside(pos)
        return pos.x >= pos_to_check.x and pos.y >= pos_to_check.y and pos.x <= pos_to_check.x and pos.y <= pos_to_check.y
    end

    if inside(check_against) then
        return true
    end

    return false
end

local function remove_trees(entity)
    if not valid(entity) then
        return
    end
    local surface = entity.surface
    local radius = 10
    local pos = entity.position
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local trees = surface.find_entities_filtered {area = area, type = 'tree'}
    if #trees > 0 then
        for i, tree in pairs(trees) do
            if tree and tree.valid then
                tree.destroy()
            end
        end
    end
end

local function remove_rocks(entity)
    if not valid(entity) then
        return
    end
    local surface = entity.surface
    local radius = 10
    local pos = entity.position
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local rocks = surface.find_entities_filtered {area = area, type = 'simple-entity'}
    if #rocks > 0 then
        for i, rock in pairs(rocks) do
            if rock and rock.valid then
                rock.destroy()
            end
        end
    end
end

local function fill_tiles(entity, size)
    if not valid(entity) then
        return
    end
    local surface = entity.surface
    local radius = size or 10
    local pos = entity.position
    local t = {
        'water',
        'water-green',
        'water-mud',
        'water-shallow',
        'deepwater',
        'deepwater-green'
    }
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local tiles = surface.find_tiles_filtered {area = area, name = t}
    if #tiles > 0 then
        for _, tile in pairs(tiles) do
            surface.set_tiles({{name = 'sand-1', position = tile.position}}, true)
        end
    end
    debug_print('fill_tiles - filled tiles cause we found non-placable tiles.')
end

local function get_spawn_pos()
    local surface_index = WD.get('surface_index')
    local surface = game.surfaces[surface_index]
    if not surface then
        return debug_print('get_spawn_pos - surface was not valid?')
    end

    local c = 0

    ::retry::

    local position = WD.get('spawn_position')

    position = find_initial_spot(surface, position)
    position = surface.find_non_colliding_position('behemoth-biter', position, 32, 1)
    -- local x = position.x
    -- local y = position.y
    -- game.print('[gps=' .. x .. ',' .. y .. ',' .. surface.name .. ']')
    if not position then
        local remove_entities = WD.get('remove_entities')
        if remove_entities then
            c = c + 1
            position = WD.get('spawn_position')
            remove_trees({surface = surface, position = position, valid = true})
            remove_rocks({surface = surface, position = position, valid = true})
            fill_tiles({surface = surface, position = position, valid = true})
            WD.set('spot', 'nil')
            if c == 5 then
                return debug_print('get_spawn_pos - we could not find a spawning pos?')
            end
            goto retry
        else
            return debug_print('get_spawn_pos - we could not find a spawning pos?')
        end
    end

    return position
end

local function is_unit_valid(biter)
    local max_biter_age = WD.get('max_biter_age')
    if not biter.entity then
        debug_print('is_unit_valid - unit destroyed - does no longer exist')
        return false
    end
    if not biter.entity.valid then
        debug_print('is_unit_valid - unit destroyed - invalid')
        return false
    end
    if not biter.entity.unit_group then
        debug_print('is_unit_valid - unit destroyed - no unitgroup')
        return false
    end
    if biter.spawn_tick + max_biter_age < game.tick then
        debug_print('is_unit_valid - unit destroyed - timed out')
        return false
    end
    return true
end

local function refresh_active_unit_threat()
    local active_biter_threat = WD.get('active_biter_threat')
    local active_biters = WD.get('active_biters')
    debug_print('refresh_active_unit_threat - current value ' .. active_biter_threat)
    local biter_threat = 0
    for k, biter in pairs(active_biters) do
        if valid(biter.entity) then
            biter_threat = biter_threat + threat_values[biter.entity.name]
        else
            active_biters[k] = nil
        end
    end
    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')
    WD.set('active_biter_threat', math_round(biter_threat * biter_health_boost, 2))
    debug_print('refresh_active_unit_threat - new value ' .. active_biter_threat)
end

local function time_out_biters()
    local active_biters = WD.get('active_biters')
    local active_biter_count = WD.get('active_biter_count')
    local active_biter_threat = WD.get('active_biter_threat')

    if active_biter_count >= 100 and #active_biters <= 10 then
        WD.set('active_biter_count', 50)
    end

    local biter_health_boost = BiterHealthBooster.get('biter_health_boost')

    for k, biter in pairs(active_biters) do
        if not is_unit_valid(biter) then
            WD.set('active_biter_count', active_biter_count - 1)
            if biter.entity then
                if biter.entity.valid then
                    WD.set('active_biter_threat', active_biter_threat - math_round(threat_values[biter.entity.name] * biter_health_boost, 2))
                    if biter.entity.force.index == 2 then
                        biter.entity.destroy()
                    end
                    debug_print('time_out_biters: ' .. k .. ' got deleted.')
                end
            end
            active_biters[k] = nil
        end
    end
end

local function get_random_close_spawner()
    local nests = WD.get('nests')
    local target = WD.get('target')
    local get_random_close_spawner_attempts = WD.get('get_random_close_spawner_attempts')
    local center = target.position
    local spawner
    local retries = 0
    for i = 1, get_random_close_spawner_attempts, 1 do
        ::retry::
        if #nests < 1 then
            return false
        end
        local k = math_random(1, #nests)
        local spawner_2 = nests[k]
        if not spawner_2 or not spawner_2.valid then
            nests[k] = nil
            retries = retries + 1
            if retries == 5 then
                break
            end
            goto retry
        end
        if not spawner or (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then
            spawner = spawner_2
        end
    end
    debug_print('get_random_close_spawner - Found at x' .. spawner.position.x .. ' y' .. spawner.position.y)
    return spawner
end

local function get_random_character()
    local characters = {}
    local surface_index = WD.get('surface_index')
    local p = game.connected_players
    for _, player in pairs(p) do
        if player.character then
            if player.character.valid then
                if player.character.surface.index == surface_index then
                    characters[#characters + 1] = player.character
                end
            end
        end
    end
    if not characters[1] then
        return
    end
    return characters[math_random(1, #characters)]
end

local function set_main_target()
    local target = WD.get('target')
    if target then
        if target.valid then
            return
        end
    end

    local sec_target = SideTargets.get_side_target()
    if not sec_target then
        sec_target = get_random_character()
    end
    if not sec_target then
        return
    end

    WD.set('target', sec_target)
    debug_print('set_main_target -- New main target ' .. sec_target.name .. ' at position x' .. sec_target.position.x .. ' y' .. sec_target.position.y .. ' selected.')
end

local function set_group_spawn_position(surface)
    local spawner = get_random_close_spawner()
    if not spawner then
        return
    end
    local position = surface.find_non_colliding_position('behemoth-biter', spawner.position, 128, 1)
    if not position then
        return
    end
    WD.set('spawn_position', {x = position.x, y = position.y})
    local spawn_position = get_spawn_pos()
    debug_print('set_group_spawn_position -- Changed position to x' .. spawn_position.x .. ' y' .. spawn_position.y .. '.')
end

local function set_enemy_evolution()
    local wave_number = WD.get('wave_number')
    local biter_health_boost = WD.get('biter_health_boost')
    local threat = WD.get('threat')
    local evolution_factor = wave_number * 0.001
    local biter_h_boost = 1
    --local damage_increase = 0

    if evolution_factor > 1 then
        evolution_factor = 1
    end

    if biter_health_boost then
        biter_h_boost = math_round(biter_health_boost + (threat - 5000) * 0.000044, 3)
    else
        biter_h_boost = math_round(biter_h_boost + (threat - 5000) * 0.000044, 3)
    end
    if biter_h_boost <= 1 then
        biter_h_boost = 1
    end
    --damage_increase = math_round(damage_increase + threat * 0.0000025, 3)

    BiterHealthBooster.set('biter_health_boost', biter_h_boost)
    --game.forces.enemy.set_ammo_damage_modifier("melee", damage_increase)
    --game.forces.enemy.set_ammo_damage_modifier("biological", damage_increase)
    game.forces.enemy.evolution_factor = evolution_factor
end

local function can_units_spawn()
    local threat = WD.get('threat')

    if threat <= 0 then
        debug_print('can_units_spawn - threat too low')
        time_out_biters()
        return false
    end

    local active_biter_count = WD.get('active_biter_count')
    local max_active_biters = WD.get('max_active_biters')
    if active_biter_count >= max_active_biters then
        debug_print('can_units_spawn - active biter count too high')
        time_out_biters()
        return false
    end

    local active_biter_threat = WD.get('active_biter_threat')
    if active_biter_threat >= threat then
        debug_print('can_units_spawn - active biter threat too high (' .. active_biter_threat .. ')')
        time_out_biters()
        return false
    end
    return true
end

local function get_active_unit_groups_count()
    local unit_groups = WD.get('unit_groups')
    local count = 0

    for k, g in pairs(unit_groups) do
        if g.valid then
            if #g.members > 0 then
                count = count + 1
            else
                g.destroy()
            end
        else
            unit_groups[k] = nil
            local unit_group_last_command = WD.get('unit_group_last_command')
            if unit_group_last_command[k] then
                unit_group_last_command[k] = nil
            end
            local unit_group_pos = WD.get('unit_group_pos')
            local positions = unit_group_pos.positions
            if positions[k] then
                positions[k] = nil
            end
        end
    end
    debug_print('Active unit group count: ' .. count)
    return count
end

local function spawn_biter(surface, is_boss_biter)
    if not is_boss_biter then
        if not can_units_spawn() then
            return
        end
    end

    local boosted_health = BiterHealthBooster.get('biter_health_boost')

    local name
    if math_random(1, 100) > 73 then
        name = BiterRolls.wave_defense_roll_spitter_name()
    else
        name = BiterRolls.wave_defense_roll_biter_name()
    end
    local position = get_spawn_pos()

    local biter = surface.create_entity({name = name, position = position, force = 'enemy'})
    biter.ai_settings.allow_destroy_when_commands_fail = true
    biter.ai_settings.allow_try_return_to_spawner = true
    biter.ai_settings.do_separation = true

    local increase_health_per_wave = WD.get('increase_health_per_wave')

    if increase_health_per_wave and not is_boss_biter then
        local modified_unit_health = WD.get('modified_unit_health')
        BiterHealthBooster.add_unit(biter, modified_unit_health.current_value)
    end

    if is_boss_biter then
        local increase_boss_health_per_wave = WD.get('increase_boss_health_per_wave')
        if increase_boss_health_per_wave then
            local modified_boss_unit_health = WD.get('modified_boss_unit_health')
            BiterHealthBooster.add_boss_unit(biter, modified_boss_unit_health, 0.55)
        else
            local sum = boosted_health * 5
            debug_print('Boss Health Boosted: ' .. sum)
            BiterHealthBooster.add_boss_unit(biter, sum, 0.55)
        end
    end

    WD.set('active_biters')[biter.unit_number] = {entity = biter, spawn_tick = game.tick}
    local active_biter_count = WD.get('active_biter_count')
    WD.set('active_biter_count', active_biter_count + 1)
    local active_biter_threat = WD.get('active_biter_threat')
    WD.set('active_biter_threat', active_biter_threat + math_round(threat_values[name] * boosted_health, 2))
    return biter
end

local function increase_biter_damage()
    local increase_damage_per_wave = WD.get('increase_damage_per_wave')
    if not increase_damage_per_wave then
        return
    end

    local Difficulty
    if is_loaded('modules.difficulty_vote_by_amount') then
        Difficulty = is_loaded('modules.difficulty_vote_by_amount')
    elseif is_loaded('modules.difficulty_vote') then
        Difficulty = is_loaded('modules.difficulty_vote')
    end

    if not Difficulty then
        return
    end

    local e = game.forces.enemy
    local new = Difficulty.get().difficulty_vote_value * 0.04
    local melee = new
    local bio = new - 0.02
    local e_old_melee = e.get_ammo_damage_modifier('melee')
    local e_old_biological = e.get_ammo_damage_modifier('biological')

    debug_print('Melee: ' .. melee + e_old_melee)
    debug_print('Biological: ' .. bio + e_old_biological)

    e.set_ammo_damage_modifier('melee', melee + e_old_melee)
    e.set_ammo_damage_modifier('biological', bio + e_old_biological)
end

local function increase_biters_health()
    local increase_health_per_wave = WD.get('increase_health_per_wave')
    if not increase_health_per_wave then
        return
    end

    local boosted_health = BiterHealthBooster.get('biter_health_boost')
    local wave_number = WD.get('wave_number')

    -- this sets normal units health
    local modified_unit_health = WD.get('modified_unit_health')
    if modified_unit_health.current_value > modified_unit_health.limit_value then
        modified_unit_health.current_value = modified_unit_health.limit_value
    end
    debug_print('[HEALTHBOOSTER] > Normal Units Health Boosted: ' .. modified_unit_health.current_value)
    WD.set('modified_unit_health').current_value = modified_unit_health.current_value + modified_unit_health.health_increase_per_boss_wave

    -- this sets boss units health
    if boosted_health == 1 then
        boosted_health = 1.20
    end
    boosted_health = boosted_health * (wave_number * 0.03)
    local sum = boosted_health * 4
    debug_print('[HEALTHBOOSTER] > Boss Health Boosted: ' .. sum)
    if sum >= 100 then
        sum = 100
    end

    WD.set('modified_boss_unit_health', sum)
end

local function set_next_wave()
    local wave_number = WD.get('wave_number')
    WD.set('wave_number', wave_number + 1)
    wave_number = WD.get('wave_number')

    local threat_gain_multiplier = WD.get('threat_gain_multiplier')
    local threat_gain = wave_number * threat_gain_multiplier
    if wave_number > 1000 then
        threat_gain = threat_gain * (wave_number * 0.001)
    end
    if wave_number % 25 == 0 then
        increase_biter_damage()
        increase_biters_health()
        WD.set('boss_wave', true)
        WD.set('boss_wave_warning', true)
        local alert_boss_wave = WD.get('alert_boss_wave')
        local spawn_position = get_spawn_pos()
        if alert_boss_wave then
            local msg = 'Boss Wave: ' .. wave_number
            local pos = {
                position = spawn_position
            }
            Alert.alert_all_players_location(pos, msg, {r = 0.8, g = 0.1, b = 0.1})
        end
        threat_gain = threat_gain * 2
    else
        local boss_wave_warning = WD.get('boss_wave_warning')
        if boss_wave_warning then
            WD.set('boss_wave_warning', false)
        end
    end

    local threat = WD.get('threat')
    WD.set('threat', threat + math_floor(threat_gain))

    local wave_enforced = WD.get('wave_enforced')
    local next_wave = WD.get('next_wave')
    local wave_interval = WD.get('wave_interval')
    if not wave_enforced then
        WD.set('last_wave', next_wave)
        WD.set('next_wave', game.tick + wave_interval)
    end

    local clear_corpses = WD.get('clear_corpses')
    if clear_corpses then
        local surface_index = WD.get('surface_index')
        local surface = game.surfaces[surface_index]
        for _, entity in pairs(surface.find_entities_filtered {type = 'corpse'}) do
            if math_random(1, 2) == 1 then
                entity.destroy()
            end
        end
    end
end

local function reform_group(group)
    local unit_group_command_step_length = WD.get('unit_group_command_step_length')
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = unit_group_command_step_length
    local position = group.surface.find_non_colliding_position('biter-spawner', group_position, step_length, 4)
    if position then
        local new_group = group.surface.create_unit_group {position = position, force = group.force}
        for key, biter in pairs(group.members) do
            new_group.add_member(biter)
        end
        debug_print('Creating new unit group, because old one was stuck.')
        local unit_groups = WD.get('unit_groups')
        unit_groups[new_group.group_number] = new_group

        return new_group
    else
        debug_print('Destroying stuck group.')
        local unit_groups = WD.get('unit_groups')
        if unit_groups[group.group_number] then
            local unit_group_last_command = WD.get('unit_group_last_command')
            if unit_group_last_command[group.group_number] then
                unit_group_last_command[group.group_number] = nil
            end
            local unit_group_pos = WD.get('unit_group_pos')
            local positions = unit_group_pos.positions
            if positions[group.group_number] then
                positions[group.group_number] = nil
            end
            table.remove(unit_groups, group.group_number)
        end
        group.destroy()
    end
    return nil
end

local function get_side_targets(group)
    local unit_group_command_step_length = WD.get('unit_group_command_step_length')

    local commands = {}
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = unit_group_command_step_length

    local side_target = SideTargets.get_side_target()
    local target_position = side_target.position
    local distance_to_target = math_floor(math_sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
    local steps = math_floor(distance_to_target / step_length) + 1

    for i = 1, steps, 1 do
        local old_position = group_position
        local obstacles =
            group.surface.find_entities_filtered {
            position = old_position,
            radius = step_length * 2,
            type = {'simple-entity', 'tree'},
            limit = 100
        }
        if obstacles then
            for v = 1, #obstacles, 1 do
                if obstacles[v].valid then
                    commands[#commands + 1] = {
                        type = defines.command.attack,
                        destination = obstacles[v].position,
                        distraction = defines.distraction.by_anything
                    }
                end
            end
        end

        commands[#commands + 1] = {
            type = defines.command.attack,
            target = side_target,
            distraction = defines.distraction.by_anything
        }
    end

    return commands
end

local function get_main_command(group)
    local unit_group_command_step_length = WD.get('unit_group_command_step_length')
    local commands = {}
    local group_position = {x = group.position.x, y = group.position.y}
    local step_length = unit_group_command_step_length

    local target = WD.get('target')
    if not valid(target) then
        return
    end

    debug_print('get_main_command - starting')

    local target_position = target.position
    local distance_to_target = math_floor(math_sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
    local steps = math_floor(distance_to_target / step_length) + 1
    local vector = {
        math_round((target_position.x - group_position.x) / steps, 3),
        math_round((target_position.y - group_position.y) / steps, 3)
    }

    debug_print('get_commmands - to main target x' .. target_position.x .. ' y' .. target_position.y)
    debug_print('get_commmands - distance_to_target:' .. distance_to_target .. ' steps:' .. steps)
    debug_print('get_commmands - vector ' .. vector[1] .. '_' .. vector[2])

    for i = 1, steps, 1 do
        local old_position = group_position
        group_position.x = group_position.x + vector[1]
        group_position.y = group_position.y + vector[2]
        local obstacles =
            group.surface.find_entities_filtered {
            position = old_position,
            radius = step_length / 2,
            type = {'simple-entity', 'tree'},
            limit = 50
        }
        if obstacles then
            shuffle_distance(obstacles, old_position)
            for i = 1, #obstacles, 1 do
                if obstacles[i].valid then
                    commands[#commands + 1] = {
                        type = defines.command.attack,
                        target = obstacles[i],
                        distraction = defines.distraction.by_anything
                    }
                end
            end
        end
        local position = group.surface.find_non_colliding_position('behemoth-biter', group_position, step_length, 1)
        if position then
            commands[#commands + 1] = {
                type = defines.command.attack_area,
                destination = {x = position.x, y = position.y},
                radius = 16,
                distraction = defines.distraction.by_anything
            }
        end
    end

    commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = {x = target_position.x, y = target_position.y},
        radius = 8,
        distraction = defines.distraction.by_anything
    }

    commands[#commands + 1] = {
        type = defines.command.attack,
        target = target,
        distraction = defines.distraction.by_anything
    }

    return commands
end

local function command_to_main_target(group, bypass)
    if not valid(group) then
        return
    end
    local unit_group_last_command = WD.get('unit_group_last_command')
    local unit_group_command_delay = WD.get('unit_group_command_delay')
    if not bypass then
        if not unit_group_last_command[group.group_number] then
            unit_group_last_command[group.group_number] = game.tick - (unit_group_command_delay + 1)
        end

        if unit_group_last_command[group.group_number] then
            if unit_group_last_command[group.group_number] + unit_group_command_delay > game.tick then
                return
            end
        end
    end

    local fill_tiles_so_biter_can_path = WD.get('fill_tiles_so_biter_can_path')
    if fill_tiles_so_biter_can_path then
        fill_tiles(group, 10)
    end

    local tile = group.surface.get_tile(group.position)
    if tile.valid and tile.collides_with('player-layer') then
        group = reform_group(group)
    end
    if not valid(group) then
        return
    end

    local commands = get_main_command(group)

    debug_print('get_main_command - got commands')

    group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )
    debug_print('get_main_command - sent commands')
    if valid(group) then
        unit_group_last_command[group.group_number] = game.tick
    end
end

local function command_to_side_target(group)
    local unit_group_last_command = WD.get('unit_group_last_command')
    local unit_group_command_delay = WD.get('unit_group_command_delay')
    if not unit_group_last_command[group.group_number] then
        unit_group_last_command[group.group_number] = game.tick - (unit_group_command_delay + 1)
    end

    if unit_group_last_command[group.group_number] then
        if unit_group_last_command[group.group_number] + unit_group_command_delay > game.tick then
            return
        end
    end

    local tile = group.surface.get_tile(group.position)
    if tile.valid and tile.collides_with('player-layer') then
        group = reform_group(group)
    end

    local commands = get_side_targets(group)

    group.set_command(
        {
            type = defines.command.compound,
            structure_type = defines.compound_command.return_last,
            commands = commands
        }
    )

    unit_group_last_command[group.group_number] = game.tick
end

local function give_side_commands_to_group()
    local enable_side_target = WD.get('enable_side_target')
    if not enable_side_target then
        return
    end

    local target = WD.get('target')
    if not valid(target) then
        return
    end

    local unit_groups = WD.get('unit_groups')
    for k, group in pairs(unit_groups) do
        if type(group) ~= 'number' then
            if group.valid then
                command_to_side_target(group)
            else
                get_active_unit_groups_count()
            end
        end
    end
end

local function give_main_command_to_group()
    local target = WD.get('target')
    if not valid(target) then
        return
    end

    local unit_groups = WD.get('unit_groups')
    for k, group in pairs(unit_groups) do
        if type(group) ~= 'number' then
            if group.valid then
                if group.surface.index == target.surface.index then
                    command_to_main_target(group)
                end
            else
                get_active_unit_groups_count()
            end
        end
    end
end

local function spawn_unit_group()
    if not can_units_spawn() then
        debug_print('spawn_unit_group - Cant spawn units?')
        return
    end
    local target = WD.get('target')
    if not valid(target) then
        debug_print('spawn_unit_group - Target was not valid?')
        return
    end

    local max_active_unit_groups = WD.get('max_active_unit_groups')
    if get_active_unit_groups_count() >= max_active_unit_groups then
        debug_print('spawn_unit_group - unit_groups at max')
        return
    end
    local surface_index = WD.get('surface_index')
    local remove_entities = WD.get('remove_entities')

    local surface = game.surfaces[surface_index]
    set_group_spawn_position(surface)

    local spawn_position = get_spawn_pos()
    if not spawn_position then
        return
    end

    local radius = 10
    local area = {
        left_top = {spawn_position.x - radius, spawn_position.y - radius},
        right_bottom = {spawn_position.x + radius, spawn_position.y + radius}
    }
    for k, v in pairs(surface.find_entities_filtered {area = area, name = 'land-mine'}) do
        if v and v.valid then
            debug_print('spawn_unit_group - found land-mines')
            v.die()
        end
    end

    if remove_entities then
        remove_trees({surface = surface, position = spawn_position, valid = true})
        remove_rocks({surface = surface, position = spawn_position, valid = true})
        fill_tiles({surface = surface, position = spawn_position, valid = true})
    end

    local wave_number = WD.get('wave_number')
    BiterRolls.wave_defense_set_unit_raffle(wave_number)

    debug_print('Spawning unit group at x' .. spawn_position.x .. ' y' .. spawn_position.y)
    local position = spawn_position

    local unit_group_pos = WD.get('unit_group_pos')
    local unit_group = surface.create_unit_group({position = position, force = 'enemy'})
    unit_group_pos.positions[unit_group.group_number] = {position = unit_group.position, index = 0}
    local average_unit_group_size = WD.get('average_unit_group_size')
    local group_size = math_floor(average_unit_group_size * group_size_modifier_raffle[math_random(1, group_size_modifier_raffle_size)])
    for _ = 1, group_size, 1 do
        local biter = spawn_biter(surface)
        if not biter then
            debug_print('spawn_unit_group - No biters were found?')
            break
        end
        unit_group.add_member(biter)

        -- command_to_side_target(unit_group)
    end

    local boss_wave = WD.get('boss_wave')
    if boss_wave then
        local count = math_random(1, math_floor(wave_number * 0.01) + 2)
        if count > 16 then
            count = 16
        end
        if count <= 1 then
            count = 4
        end
        for _ = 1, count, 1 do
            local biter = spawn_biter(surface, true)
            if not biter then
                debug_print('spawn_unit_group - No biters were found?')
                break
            end
            unit_group.add_member(biter)
        end
        WD.set('boss_wave', false)
    end

    local unit_groups = WD.get('unit_groups')
    unit_groups[unit_group.group_number] = unit_group
    if math_random(1, 2) == 1 then
        WD.set('random_group', unit_group.group_number)
    end
    WD.set('spot', 'nil')
    return true
end

local function check_group_positions()
    local unit_groups = WD.get('unit_groups')
    local unit_group_pos = WD.get('unit_group_pos')
    local target = WD.get('target')
    if not valid(target) then
        return
    end

    for k, group in pairs(unit_groups) do
        if group.valid then
            local ugp = unit_group_pos.positions
            if group.state == defines.group_state.finished then
                return command_to_main_target(group, true)
            end
            if ugp[group.group_number] then
                local success = is_position_near(group.position, ugp[group.group_number].position)
                if success then
                    ugp[group.group_number].index = ugp[group.group_number].index + 1
                    if ugp[group.group_number].index >= 2 then
                        command_to_main_target(group, true)
                        fill_tiles(group, 30)
                        remove_rocks(group)
                        remove_trees(group)
                        if ugp[group.group_number].index >= 4 then
                            unit_group_pos.positions[group.group_number] = nil
                            reform_group(group)
                        end
                    end
                end
            end
        end
    end
end

local function log_threat()
    local threat_log_index = WD.get('threat_log_index')
    WD.set('threat_log_index', threat_log_index + 1)
    local threat_log = WD.get('threat_log')
    local threat = WD.get('threat')
    threat_log_index = WD.get('threat_log_index')
    threat_log[threat_log_index] = threat
    if threat_log_index > 900 then
        threat_log[threat_log_index - 901] = nil
    end
end

local tick_tasks = {
    [30] = set_main_target,
    [60] = set_enemy_evolution,
    [90] = spawn_unit_group,
    [120] = give_main_command_to_group,
    [150] = ThreatEvent.build_nest,
    [180] = ThreatEvent.build_worm,
    [1200] = give_side_commands_to_group,
    [3600] = time_out_biters,
    [7200] = refresh_active_unit_threat
}

local function on_tick()
    local tick = game.tick
    local game_lost = WD.get('game_lost')
    if game_lost then
        return
    end

    local next_wave = WD.get('next_wave')
    if tick > next_wave then
        set_next_wave()
    end

    local t = tick % 300
    local t2 = tick % 18000

    if tick_tasks[t] then
        tick_tasks[t]()
    end
    if tick_tasks[t2] then
        tick_tasks[t2]()
    end

    local resolve_pathing = WD.get('resolve_pathing')
    if resolve_pathing then
        if tick % 60 == 0 then
            check_group_positions()
        end
    end

    local enable_threat_log = WD.get('enable_threat_log')
    if enable_threat_log then
        if tick % 60 == 0 then
            log_threat()
        end
    end
    local players = game.connected_players
    for _, player in pairs(players) do
        update_gui(player)
    end
end

Event.on_nth_tick(30, on_tick)

return Public
