require 'player_modifiers'

local Global = require 'utils.global'
local Event = require 'utils.event'
local Alert = require 'utils.alert'
local Tabs = require 'comfy_panel.main'
local P = require 'player_modifiers'
local WD = require 'modules.wave_defense.table'

local points_per_level = 5

local nth_tick = 18001
local visuals_delay = 1800
local level_up_floating_text_color = {0, 205, 0}
local xp_floating_text_color = {157, 157, 157}
local experience_levels = {0}
for a = 1, 9999, 1 do
    experience_levels[#experience_levels + 1] = experience_levels[#experience_levels] + a * 8
end
local gain_info_tooltip = 'XP gain from mining, moving, crafting, repairing and combat.'
local reset_tooltip = 'ONE-TIME reset if you picked the wrong path (this will keep your points)'
local reset_not_available =
    'ONE-TIME reset if you picked the wrong path (this will keep your points)\nAvailable after level 50.'

local teller_global_pool = '[color=blue]Global Pool Reward:[/color] \n'
local teller_level_limit = '[color=blue]Level Limit:[/color] \n'

local rpg_t = {}
local rpg_extra = {
    debug = false,
    breached_walls = 1,
    reward_new_players = 0,
    level_limit_enabled = false,
    global_pool = 0,
    leftover_pool = 0,
    turret_kills_to_global_pool = true,
    difficulty = false
}
local rpg_frame_icons = {
    'entity/small-worm-turret',
    'entity/medium-worm-turret',
    'entity/big-worm-turret',
    'entity/behemoth-worm-turret',
    'entity/small-biter',
    'entity/small-biter',
    'entity/small-spitter',
    'entity/medium-biter',
    'entity/medium-biter',
    'entity/medium-spitter',
    'entity/big-biter',
    'entity/big-biter',
    'entity/big-spitter',
    'entity/behemoth-biter',
    'entity/behemoth-biter',
    'entity/behemoth-spitter'
}

local rpg_xp_yield = {
    ['behemoth-biter'] = 16,
    ['behemoth-spitter'] = 16,
    ['behemoth-worm-turret'] = 64,
    ['big-biter'] = 8,
    ['big-spitter'] = 8,
    ['big-worm-turret'] = 48,
    ['biter-spawner'] = 64,
    ['character'] = 16,
    ['gun-turret'] = 8,
    ['laser-turret'] = 16,
    ['medium-biter'] = 4,
    ['medium-spitter'] = 4,
    ['medium-worm-turret'] = 32,
    ['small-biter'] = 1,
    ['small-spitter'] = 1,
    ['small-worm-turret'] = 16,
    ['spitter-spawner'] = 64
}

Global.register(
    {rpg_t = rpg_t, rpg_frame_icons = rpg_frame_icons, rpg_extra = rpg_extra, rpg_xp_yield = rpg_xp_yield},
    function(tbl)
        rpg_t = tbl.rpg_t
        rpg_frame_icons = tbl.rpg_frame_icons
        rpg_extra = tbl.rpg_extra
        rpg_xp_yield = tbl.rpg_xp_yield
    end
)

local Public = {}

local classes = {
    ['engineer'] = 'ENGINEER',
    ['strength'] = 'MINER',
    ['magicka'] = 'SCIENTIST',
    ['dexterity'] = 'BEASTMASTER',
    ['vitality'] = 'SOLDIER'
}

local enemy_types = {
    ['unit'] = true,
    ['unit-spawner'] = true,
    ['turret'] = true
}

local die_cause = {
    ['ammo-turret'] = true,
    ['electric-turret'] = true,
    ['fluid-turret'] = true
}

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.index] then
        return false
    end
    return true
end

local function level_limit_exceeded(player, value)
    if not rpg_extra.level_limit_enabled then
        return false
    end

    local limits = {
        [1] = 30,
        [2] = 50,
        [3] = 70,
        [4] = 90,
        [5] = 110,
        [6] = 130,
        [7] = 150,
        [8] = 170,
        [9] = 190,
        [10] = 210
    }

    local level = rpg_t[player.index].level
    local zone = rpg_extra.breached_walls
    if zone >= 11 then
        zone = 10
    end
    if value then
        return limits[zone]
    end

    if level >= limits[zone] then
        return true
    end
    return false
end

local function level_up_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity(
        {name = 'flying-text', position = position, text = '+LVL ', color = level_up_floating_text_color}
    )
    local b = 0.75
    for a = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity(
            {name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}}
        )
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

local function xp_effects(player)
    local position = {x = player.position.x - 0.75, y = player.position.y - 1}
    player.surface.create_entity(
        {name = 'flying-text', position = position, text = '+XP', color = level_up_floating_text_color}
    )
    local b = 0.75
    for a = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }
        player.surface.create_entity(
            {name = 'flying-text', position = p, text = '✚', color = {255, math.random(0, 100), 0}}
        )
    end
    player.play_sound {path = 'utility/achievement_unlocked', volume_modifier = 0.40}
end

local function get_melee_modifier(player)
    return (rpg_t[player.index].strength - 10) * 0.10
end

local function get_heal_modifier(player)
    return (rpg_t[player.index].vitality - 10) * 0.02
end

local function get_life_on_hit(player)
    return (rpg_t[player.index].vitality - 10) * 0.4
end

local function get_one_punch_chance(player)
    if rpg_t[player.index].strength < 100 then
        return 0
    end
    local chance = math.round(rpg_t[player.index].strength * 0.01, 1)
    if chance > 100 then
        chance = 100
    end
    return chance
end

local function draw_gui_char_button(player)
    if player.gui.top.rpg then
        return
    end
    local b = player.gui.top.add({type = 'sprite-button', name = 'rpg', caption = 'CHAR'})
    b.style.font_color = {165, 165, 165}
    b.style.font = 'heading-1'
    b.style.minimal_height = 38
    b.style.minimal_width = 60
    b.style.padding = 0
    b.style.margin = 0
end

local function update_char_button(player)
    if not player.gui.top.rpg then
        draw_gui_char_button(player)
    end
    if rpg_t[player.index].points_to_distribute > 0 then
        player.gui.top.rpg.style.font_color = {245, 0, 0}
    else
        player.gui.top.rpg.style.font_color = {175, 175, 175}
    end
end

local function update_player_stats(player)
    local player_modifiers = P.get_table()
    local strength = rpg_t[player.index].strength - 10
    player_modifiers[player.index].character_inventory_slots_bonus['rpg'] = math.round(strength * 0.2, 3)
    player_modifiers[player.index].character_mining_speed_modifier['rpg'] = math.round(strength * 0.007, 3)
    player_modifiers[player.index].character_maximum_following_robot_count_bonus['rpg'] = math.round(strength * 0.07, 1)

    local magic = rpg_t[player.index].magicka - 10
    local v = magic * 0.22
    player_modifiers[player.index].character_build_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_item_drop_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_reach_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_loot_pickup_distance_bonus['rpg'] = math.round(v * 0.22, 3)
    player_modifiers[player.index].character_item_pickup_distance_bonus['rpg'] = math.round(v * 0.25, 3)
    player_modifiers[player.index].character_resource_reach_distance_bonus['rpg'] = math.round(v * 0.15, 3)

    local dexterity = rpg_t[player.index].dexterity - 10
    player_modifiers[player.index].character_running_speed_modifier['rpg'] = math.round(dexterity * 0.0015, 3)
    player_modifiers[player.index].character_crafting_speed_modifier['rpg'] = math.round(dexterity * 0.015, 3)

    player_modifiers[player.index].character_health_bonus['rpg'] =
        math.round((rpg_t[player.index].vitality - 10) * 6, 3)

    P.update_player_modifiers(player)
end

local function get_class(player)
    local average =
        (rpg_t[player.index].strength + rpg_t[player.index].magicka + rpg_t[player.index].dexterity +
        rpg_t[player.index].vitality) /
        4
    local high_attribute = 0
    local high_attribute_name = ''
    for _, attribute in pairs({'strength', 'magicka', 'dexterity', 'vitality'}) do
        if rpg_t[player.index][attribute] > high_attribute then
            high_attribute = rpg_t[player.index][attribute]
            high_attribute_name = attribute
        end
    end
    if high_attribute < average + average * 0.25 then
        high_attribute_name = 'engineer'
    end
    return classes[high_attribute_name]
end

local function add_gui_description(element, value, width)
    local e = element.add({type = 'label', caption = value})
    e.style.single_line = false
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = 40
    e.style.minimal_height = 38
    e.style.font = 'default-bold'
    e.style.font_color = {175, 175, 200}
    e.style.horizontal_align = 'right'
    e.style.vertical_align = 'center'
    return e
end

local function add_gui_stat(element, value, width)
    local e = element.add({type = 'sprite-button', caption = value})
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.font = 'default-bold'
    e.style.font_color = {222, 222, 222}
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    return e
end

local function add_gui_increase_stat(element, name, player)
    local sprite = 'virtual-signal/signal-red'
    local symbol = '✚'
    if rpg_t[player.index].points_to_distribute <= 0 then
        sprite = 'virtual-signal/signal-black'
    end
    local e = element.add({type = 'sprite-button', name = name, caption = symbol, sprite = sprite})
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.maximal_width = 38
    e.style.minimal_width = 38
    e.style.font = 'default-large-semibold'
    e.style.font_color = {0, 0, 0}
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    e.style.padding = 0
    e.style.margin = 0
    e.tooltip =
        'Right-click to allocate ' .. tostring(points_per_level) .. ' points.\nShift + click to allocate all points.'

    return e
end

local function add_separator(element, width)
    local e = element.add({type = 'line'})
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.minimal_height = 12
    return e
end

local function draw_gui(player, forced)
    if not forced then
        if rpg_t[player.index].gui_refresh_delay > game.tick then
            return
        end
    end

    Tabs.comfy_panel_clear_left_gui(player)

    if player.gui.left.rpg then
        player.gui.left.rpg.destroy()
    end
    if not player.character then
        return
    end

    local value
    local e

    local frame =
        player.gui.left.add({type = 'frame', name = 'rpg', direction = 'vertical', style = 'changelog_subheader_frame'})
    frame.style.maximal_height = 800
    frame.style.maximal_width = 440
    frame.style.minimal_width = 440
    frame.style.use_header_filler = false
    frame.style.top_padding = 4
    frame.style.bottom_padding = 4
    frame.style.left_padding = 4
    frame.style.right_padding = 10

    local scroll_pane =
        frame.add {
        type = 'scroll-pane',
        direction = 'vertical',
        vertical_scroll_policy = 'always',
        horizontal_scroll_policy = 'never'
    }
    scroll_pane.style.minimal_width = 400
    scroll_pane.style.maximal_width = 450
    scroll_pane.style.minimal_height = 600
    scroll_pane.style.horizontally_squashable = false
    scroll_pane.style.vertically_squashable = false

    local t = scroll_pane.add({type = 'table', column_count = 2})
    e = add_gui_stat(t, player.name, 200)
    e.style.font_color = player.chat_color
    e.style.font = 'default-large-bold'
    e = add_gui_stat(t, get_class(player), 200)
    e.style.font = 'default-large-bold'

    add_separator(scroll_pane, 400)

    t = scroll_pane.add({type = 'table', column_count = 4})
    t.style.cell_padding = 1

    add_gui_description(t, 'LEVEL', 80)
    e = add_gui_stat(t, rpg_t[player.index].level, 80)
    if rpg_extra.level_limit_enabled then
        local level_tooltip =
            'Current max level limit for this zone is: ' ..
            level_limit_exceeded(player, true) .. '\nIncreases by breaching walls/zones.'
        e.tooltip = level_tooltip
    else
        e.tooltip = gain_info_tooltip
    end

    add_gui_description(t, 'EXPERIENCE', 100)
    e = add_gui_stat(t, math.floor(rpg_t[player.index].xp), 125)
    e.tooltip = gain_info_tooltip

    if not rpg_t[player.index].reset then
        add_gui_description(t, 'RESET', 80)
        e = add_gui_stat(t, rpg_t[player.index].reset, 80)
        if rpg_t[player.index].level <= 19 then
            e.tooltip = reset_not_available
        else
            e.tooltip = reset_tooltip
        end
    else
        add_gui_description(t, ' ', 75)
        add_gui_description(t, ' ', 75)
    end

    add_gui_description(t, 'NEXT LEVEL', 100)
    e = add_gui_stat(t, experience_levels[rpg_t[player.index].level + 1], 125)
    e.tooltip = gain_info_tooltip

    add_separator(scroll_pane, 400)

    local t = scroll_pane.add({type = 'table', column_count = 2})
    local tt = t.add({type = 'table', column_count = 3})
    tt.style.cell_padding = 1
    local w1 = 85
    local w2 = 63

    local tip = 'Increases inventory slots, mining speed.\nIncreases melee damage and amount of robot followers.'
    e = add_gui_description(tt, 'STRENGTH', w1)
    e.tooltip = tip
    e = add_gui_stat(tt, rpg_t[player.index].strength, w2)
    e.tooltip = tip
    add_gui_increase_stat(tt, 'strength', player)

    local tip = 'Increases reach distance.\nIncreases repair speed.'
    e = add_gui_description(tt, 'MAGIC', w1)
    e.tooltip = tip
    e = add_gui_stat(tt, rpg_t[player.index].magicka, w2)
    e.tooltip = tip
    add_gui_increase_stat(tt, 'magicka', player)

    local tip = 'Increases running and crafting speed.'
    e = add_gui_description(tt, 'DEXTERITY', w1)
    e.tooltip = tip
    e = add_gui_stat(tt, rpg_t[player.index].dexterity, w2)
    e.tooltip = tip
    add_gui_increase_stat(tt, 'dexterity', player)

    local tip = 'Increases health.\nIncreases melee life on-hit.'
    e = add_gui_description(tt, 'VITALITY', w1)
    e.tooltip = tip
    e = add_gui_stat(tt, rpg_t[player.index].vitality, w2)
    e.tooltip = tip
    add_gui_increase_stat(tt, 'vitality', player)

    add_gui_description(tt, 'POINTS TO\nDISTRIBUTE', w1)
    e = add_gui_stat(tt, rpg_t[player.index].points_to_distribute, w2)
    e.style.font_color = {200, 0, 0}
    add_gui_description(tt, ' ', w2)

    add_gui_description(tt, ' ', w1)
    add_gui_description(tt, ' ', w2)
    add_gui_description(tt, ' ', w2)

    add_gui_description(tt, 'LIFE', w1)
    add_gui_stat(tt, math.floor(player.character.health), w2)
    add_gui_stat(
        tt,
        math.floor(
            player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus
        ),
        w2
    )

    local shield = 0
    local shield_max = 0
    local i = player.character.get_inventory(defines.inventory.character_armor)
    if not i.is_empty() then
        if i[1].grid then
            shield = math.floor(i[1].grid.shield)
            shield_max = math.floor(i[1].grid.max_shield)
        end
    end
    add_gui_description(tt, 'SHIELD', w1)
    add_gui_stat(tt, shield, w2)
    add_gui_stat(tt, shield_max, w2)

    local tt = t.add({type = 'table', column_count = 3})
    tt.style.cell_padding = 1
    local w0 = 2
    local w1 = 80
    local w2 = 80

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'MINING\nSPEED', w1)
    value =
        math.round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100) ..
        '%'
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'SLOT\nBONUS', w1)
    value = '+ ' .. math.round(player.force.character_inventory_slots_bonus + player.character_inventory_slots_bonus)
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'MELEE\nDAMAGE', w1)
    value = math.round(100 * (1 + get_melee_modifier(player))) .. '%'
    e = add_gui_stat(tt, value, w2)
    e.tooltip =
        'Life on-hit: ' .. get_life_on_hit(player) .. '\nOne punch chance: ' .. get_one_punch_chance(player) .. '%'

    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10

    value = '+ ' .. (player.force.character_reach_distance_bonus + player.character_reach_distance_bonus)
    local tooltip = ''
    tooltip = tooltip .. 'Reach distance bonus: ' .. player.character_reach_distance_bonus
    tooltip = tooltip .. '\nBuild distance bonus: ' .. player.character_build_distance_bonus
    tooltip = tooltip .. '\nItem drop distance bonus: ' .. player.character_item_drop_distance_bonus
    tooltip = tooltip .. '\nLoot pickup distance bonus: ' .. player.character_loot_pickup_distance_bonus
    tooltip = tooltip .. '\nItem pickup distance bonus: ' .. player.character_item_pickup_distance_bonus
    tooltip = tooltip .. '\nResource reach distance bonus: ' .. player.character_resource_reach_distance_bonus
    tooltip = tooltip .. '\nRepair speed: ' .. Public.get_magicka(player)
    add_gui_description(tt, ' ', w0)
    e = add_gui_description(tt, 'REACH\nDISTANCE', w1)
    e.tooltip = tooltip
    e = add_gui_stat(tt, value, w2)
    e.tooltip = tooltip

    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'CRAFTING\nSPEED', w1)
    value =
        math.round((player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier + 1) * 100) ..
        '%'
    add_gui_stat(tt, value, w2)

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'RUNNING\nSPEED', w1)
    value =
        math.round((player.force.character_running_speed_modifier + player.character_running_speed_modifier + 1) * 100) ..
        '%'
    add_gui_stat(tt, value, w2)

    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10
    e = add_gui_description(tt, '', w0)
    e.style.maximal_height = 10

    add_gui_description(tt, ' ', w0)
    add_gui_description(tt, 'HEALTH\nBONUS', w1)
    value = '+ ' .. math.round((player.force.character_health_bonus + player.character_health_bonus))
    e = add_gui_stat(tt, value, w2)
    e.tooltip = 'Health regen bonus: ' .. get_heal_modifier(player)

    add_separator(scroll_pane, 400)
    local t = scroll_pane.add({type = 'table', column_count = 14})
    for i = 1, 14, 1 do
        e = t.add({type = 'sprite', sprite = rpg_frame_icons[i]})
        e.style.maximal_width = 24
        e.style.maximal_height = 24
        e.style.padding = 0
    end
    add_separator(scroll_pane, 400)

    rpg_t[player.index].gui_refresh_delay = game.tick + 60
    update_char_button(player)
end

local function draw_level_text(player)
    if not player.character then
        return
    end

    if rpg_t[player.index].text then
        rendering.destroy(rpg_t[player.index].text)
        rpg_t[player.index].text = nil
    end

    local players = {}
    for _, p in pairs(game.players) do
        if p.index ~= player.index then
            players[#players + 1] = p.index
        end
    end
    if #players == 0 then
        return
    end

    rpg_t[player.index].text =
        rendering.draw_text {
        text = 'lvl ' .. rpg_t[player.index].level,
        surface = player.surface,
        target = player.character,
        target_offset = {0, -3.25},
        color = {
            r = player.color.r * 0.6 + 0.25,
            g = player.color.g * 0.6 + 0.25,
            b = player.color.b * 0.6 + 0.25,
            a = 1
        },
        players = players,
        scale = 1.00,
        font = 'default-large-semibold',
        alignment = 'center',
        scale_with_zoom = false
    }
end

local function level_up(player)
    local distribute_points_gain = 0
    for i = rpg_t[player.index].level + 1, #experience_levels, 1 do
        if rpg_t[player.index].xp > experience_levels[i] then
            rpg_t[player.index].level = i
            distribute_points_gain = distribute_points_gain + points_per_level
        else
            break
        end
    end
    if distribute_points_gain == 0 then
        return
    end
    draw_level_text(player)
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute + distribute_points_gain
    update_char_button(player)
    table.shuffle_table(rpg_frame_icons)
    if player.gui.left.rpg then
        draw_gui(player, true)
    end
    level_up_effects(player)
end

local function add_to_global_pool(amount)
    if not rpg_extra.global_pool then
        return
    end

    local fee = amount * 0.3

    rpg_extra.global_pool = rpg_extra.global_pool + fee
    return fee
end

local function global_pool(players, count)
    if not rpg_extra.global_pool then
        return
    end

    local pool = math.floor(rpg_extra.global_pool)

    local random_amount = math.random(5000, 10000)

    if pool <= random_amount then
        return
    end

    if pool >= 20000 then
        pool = 20000
    end

    local share = pool / count

    Public.debug_log('RPG - Share per player:' .. share)

    for i = 1, #players do
        local p = players[i]
        if p.afk_time < 5000 then
            if not level_limit_exceeded(p) then
                Public.gain_xp(p, share, false, true)
                xp_effects(p)
            else
                share = share / 10
                rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
                Public.debug_log('RPG - player capped: ' .. p.name .. '. Amount to pool:' .. share)
            end
        else
            local message = teller_global_pool .. p.name .. ' received nothing. Reason: AFK'
            Alert.alert_player_warning(p, 10, message)
            share = share / 10
            rpg_extra.leftover_pool = rpg_extra.leftover_pool + share
            Public.debug_log('RPG - player AFK: ' .. p.name .. '. Amount to pool:' .. share)
        end
    end

    rpg_extra.global_pool = rpg_extra.leftover_pool or 0

    return
end

local function on_gui_click(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    local element = event.element
    local player = game.players[event.player_index]

    if element.type ~= 'sprite-button' then
        return
    end

    local shift = event.shift

    if element.caption == 'CHAR' then
        if element.name == 'rpg' then
            if player.gui.left.rpg then
                player.gui.left.rpg.destroy()
                return
            end
            draw_gui(player, true)
        end
    end

    if element.caption == 'false' then
        if rpg_t[player.index].level <= 49 then
            return
        end
        rpg_t[player.index].reset = true
        Public.rpg_reset_player(player, true)
        return
    end

    if element.caption ~= '✚' then
        return
    end
    if element.sprite ~= 'virtual-signal/signal-red' then
        return
    end

    local index = element.name
    if not rpg_t[player.index][index] then
        return
    end
    if not player.character then
        return
    end

    if shift then
        local count = rpg_t[player.index].points_to_distribute
        if not count then
            return
        end
        rpg_t[player.index].points_to_distribute = 0
        rpg_t[player.index][index] = rpg_t[player.index][index] + count
        if not rpg_t[player.index].reset then
            rpg_t[player.index].total = rpg_t[player.index].total + count
        end
        update_player_stats(player)
        draw_gui(player, true)
    elseif event.button == defines.mouse_button_type.right then
        for _ = 1, points_per_level, 1 do
            if rpg_t[player.index].points_to_distribute <= 0 then
                draw_gui(player, true)
                return
            end
            rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute - 1
            rpg_t[player.index][index] = rpg_t[player.index][index] + 1
            if not rpg_t[player.index].reset then
                rpg_t[player.index].total = rpg_t[player.index].total + 1
            end
            update_player_stats(player)
        end
        draw_gui(player, true)
        return
    end

    if rpg_t[player.index].points_to_distribute <= 0 then
        draw_gui(player, true)
        return
    end
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute - 1
    rpg_t[player.index][index] = rpg_t[player.index][index] + 1
    if not rpg_t[player.index].reset then
        rpg_t[player.index].total = rpg_t[player.index].total + 1
    end
    update_player_stats(player)
    draw_gui(player, true)
end

local function train_type_cause(cause)
    local players = {}
    if cause.train.passengers then
        for _, player in pairs(cause.train.passengers) do
            players[#players + 1] = player
        end
    end
    return players
end

local get_cause_player = {
    ['character'] = function(cause)
        if not cause.player then
            return
        end
        return {cause.player}
    end,
    ['combat-robot'] = function(cause)
        if not cause.last_user then
            return
        end
        if not game.players[cause.last_user.index] then
            return
        end
        return {game.players[cause.last_user.index]}
    end,
    ['car'] = function(cause)
        local players = {}
        local driver = cause.get_driver()
        if driver then
            if driver.player then
                players[#players + 1] = driver.player
            end
        end
        local passenger = cause.get_passenger()
        if passenger then
            if passenger.player then
                players[#players + 1] = passenger.player
            end
        end
        return players
    end,
    ['locomotive'] = train_type_cause,
    ['cargo-wagon'] = train_type_cause,
    ['artillery-wagon'] = train_type_cause,
    ['fluid-wagon'] = train_type_cause
}

local function on_entity_died(event)
    if not event.entity.valid then
        return
    end

    --Grant XP for hand placed land mines
    if event.entity.last_user then
        if event.entity.type == 'land-mine' then
            if event.cause then
                if event.cause.valid then
                    if event.cause.force.index == event.entity.force.index then
                        return
                    end
                end
            end
            Public.gain_xp(event.entity.last_user, 1)
            return
        end
    end

    if rpg_xp_yield['big-biter'] <= 16 then
        local wave_number = WD.get_wave()
        if wave_number >= 1000 then
            rpg_xp_yield['big-biter'] = 16
            rpg_xp_yield['behemoth-biter'] = 64
        end
    end

    if not event.cause then
        return
    end

    if not event.cause.valid then
        return
    end

    local type = event.cause.type
    if not type then
        goto continue
    end

    if event.cause.force.index == 1 then
        if die_cause[type] then
            if rpg_xp_yield[event.entity.name] then
                local amount = rpg_xp_yield[event.entity.name]
                amount = amount / 5
                if rpg_extra.turret_kills_to_global_pool then
                    add_to_global_pool(amount)
                end
            else
                add_to_global_pool(0.5)
            end
            return
        end
    end

    ::continue::

    if event.cause.force.index == event.entity.force.index then
        return
    end

    if not get_cause_player[event.cause.type] then
        return
    end

    local players = get_cause_player[event.cause.type](event.cause)
    if not players then
        return
    end
    if not players[1] then
        return
    end

    --Grant modified XP for health boosted units
    if global.biter_health_boost then
        if enemy_types[event.entity.type] then
            for _, player in pairs(players) do
                if rpg_xp_yield[event.entity.name] then
                    local amount = rpg_xp_yield[event.entity.name] * global.biter_health_boost
                    if rpg_extra.turret_kills_to_global_pool then
                        local inserted = add_to_global_pool(amount)
                        Public.gain_xp(player, inserted, true)
                    else
                        Public.gain_xp(player, amount)
                    end
                else
                    Public.gain_xp(player, 0.5 * global.biter_health_boost)
                end
            end
            return
        end
    end

    --Grant normal XP
    for _, player in pairs(players) do
        if rpg_xp_yield[event.entity.name] then
            local amount = rpg_xp_yield[event.entity.name]
            if rpg_extra.turret_kills_to_global_pool then
                local inserted = add_to_global_pool(amount)
                Public.gain_xp(player, inserted, true)
            else
                Public.gain_xp(player, amount)
            end
        else
            Public.gain_xp(player, 0.5)
        end
    end
end

local function on_healed_player(players)
    for i = 1, #players do
        local player = players[i]
        local heal_per_tick = get_heal_modifier(player)
        if heal_per_tick <= 0 then
            return
        end
        if player and player.valid then
            if player.character and player.character.valid then
                player.character.health = player.character.health + heal_per_tick
            end
        end
    end
end

--Melee damage modifier
local function one_punch(character, target, damage)
    local base_vector = {target.position.x - character.position.x, target.position.y - character.position.y}

    local vector = {base_vector[1], base_vector[2]}
    vector[1] = vector[1] * 1000
    vector[2] = vector[2] * 1000

    character.surface.create_entity(
        {
            name = 'flying-text',
            position = {character.position.x + base_vector[1] * 0.5, character.position.y + base_vector[2] * 0.5},
            text = 'ONE PUNCH',
            color = {255, 0, 0}
        }
    )
    character.surface.create_entity({name = 'blood-explosion-huge', position = target.position})
    character.surface.create_entity(
        {
            name = 'big-artillery-explosion',
            position = {target.position.x + vector[1] * 0.5, target.position.y + vector[2] * 0.5}
        }
    )

    if math.abs(vector[1]) > math.abs(vector[2]) then
        local d = math.abs(vector[1])
        if math.abs(vector[1]) > 0 then
            vector[1] = vector[1] / d
        end
        if math.abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
    else
        local d = math.abs(vector[2])
        if math.abs(vector[2]) > 0 then
            vector[2] = vector[2] / d
        end
        if math.abs(vector[1]) > 0 and d > 0 then
            vector[1] = vector[1] / d
        end
    end

    vector[1] = vector[1] * 1.5
    vector[2] = vector[2] * 1.5

    local a = 0.25

    for i = 1, 16, 1 do
        for x = i * -1 * a, i * a, 1 do
            for y = i * -1 * a, i * a, 1 do
                local p = {character.position.x + x + vector[1] * i, character.position.y + y + vector[2] * i}
                character.surface.create_trivial_smoke({name = 'train-smoke', position = p})
                for _, e in pairs(character.surface.find_entities({{p[1] - a, p[2] - a}, {p[1] + a, p[2] + a}})) do
                    if e.valid then
                        if e.health then
                            if e.destructible and e.minable and e.force.index ~= 3 then
                                if e.force.index ~= character.force.index then
                                    e.health = e.health - damage * 0.05
                                    if e.health <= 0 then
                                        e.die(e.force.name, character)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function on_entity_damaged(event)
    if not event.cause then
        return
    end
    if not event.cause.valid then
        return
    end
    if event.cause.force.index == 2 then
        return
    end
    if event.cause.name ~= 'character' then
        return
    end
    if event.damage_type.name ~= 'physical' then
        return
    end
    if not event.entity.valid then
        return
    end
    if
        event.cause.get_inventory(defines.inventory.character_ammo)[event.cause.selected_gun_index].valid_for_read and
            event.cause.get_inventory(defines.inventory.character_guns)[event.cause.selected_gun_index].valid_for_read
     then
        return
    end
    if not event.cause.player then
        return
    end

    --Grant the player life-on-hit.
    event.cause.health = event.cause.health + get_life_on_hit(event.cause.player)

    --Calculate modified damage.
    local damage = event.original_damage_amount + event.original_damage_amount * get_melee_modifier(event.cause.player)
    if event.entity.prototype.resistances then
        if event.entity.prototype.resistances.physical then
            damage = damage - event.entity.prototype.resistances.physical.decrease
            damage = damage - damage * event.entity.prototype.resistances.physical.percent
        end
    end
    damage = math.round(damage, 3)
    if damage < 1 then
        damage = 1
    end

    --Cause a one punch.
    if math.random(0, 999) < get_one_punch_chance(event.cause.player) * 10 then
        one_punch(event.cause, event.entity, damage)
        if event.entity.valid then
            event.entity.die(event.entity.force.name, event.cause)
        end
        return
    end

    --Floating messages and particle effects.
    if math.random(1, 7) == 1 then
        damage = damage * math.random(250, 350) * 0.01
        event.cause.surface.create_entity(
            {
                name = 'flying-text',
                position = event.entity.position,
                text = '‼' .. math.floor(damage),
                color = {255, 0, 0}
            }
        )
        event.cause.surface.create_entity({name = 'blood-explosion-huge', position = event.entity.position})
    else
        damage = damage * math.random(100, 125) * 0.01
        event.cause.player.create_local_flying_text(
            {
                text = math.floor(damage),
                position = event.entity.position,
                color = {150, 150, 150},
                time_to_live = 90,
                speed = 2
            }
        )
    end

    --Handle the custom health pool of the biter health booster, if it is used in the map.
    if global.biter_health_boost then
        local health_pool = global.biter_health_boost_units[event.entity.unit_number]
        if health_pool then
            health_pool[1] = health_pool[1] + event.final_damage_amount
            health_pool[1] = health_pool[1] - damage

            --Set entity health relative to health pool
            event.entity.health = health_pool[1] * health_pool[2]

            if health_pool[1] <= 0 then
                global.biter_health_boost_units[event.entity.unit_number] = nil
                event.entity.die(event.entity.force.name, event.cause)
            end
            return
        end
    end

    --Handle vanilla damage.
    event.entity.health = event.entity.health + event.final_damage_amount
    event.entity.health = event.entity.health - damage
    if event.entity.health <= 0 then
        event.entity.die(event.entity.force.name, event.cause)
    end
end

local function on_player_repaired_entity(event)
    if math.random(1, 4) ~= 1 then
        return
    end

    local entity = event.entity

    if not entity then
        return
    end

    if not entity.valid then
        return
    end

    if not entity.health then
        return
    end

    local player = game.players[event.player_index]

    if not player.character then
        return
    end
    Public.gain_xp(player, 0.05)

    local repair_speed = Public.get_magicka(player)
    if repair_speed <= 0 then
        return
    end
    entity.health = entity.health + repair_speed
end

local function on_player_rotated_entity(event)
    local player = game.players[event.player_index]
    if not player.character then
        return
    end
    if rpg_t[player.index].rotated_entity_delay > game.tick then
        return
    end
    rpg_t[player.index].rotated_entity_delay = game.tick + 20
    Public.gain_xp(player, 0.20)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    local map_name = 'mountain_fortress_v3'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    if math.random(1, 64) ~= 1 then
        return
    end
    if not player.character then
        return
    end
    if player.character.driving then
        return
    end
    Public.gain_xp(player, 1.0)
end

local building_and_mining_blacklist = {
    ['tile-ghost'] = true,
    ['entity-ghost'] = true,
    ['item-entity'] = true
}

local function on_pre_player_mined_item(event)
    local entity = event.entity
    if not entity.valid then
        return
    end
    if building_and_mining_blacklist[entity.type] then
        return
    end
    if entity.force.index ~= 3 then
        return
    end
    local player = game.players[event.player_index]

    if
        rpg_t[player.index].last_mined_entity_position.x == event.entity.position.x and
            rpg_t[player.index].last_mined_entity_position.y == event.entity.position.y
     then
        return
    end
    rpg_t[player.index].last_mined_entity_position.x = entity.position.x
    rpg_t[player.index].last_mined_entity_position.y = entity.position.y

    local distance_multiplier = math.floor(math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2)) * 0.0005 + 1

    local xp_amount
    if entity.type == 'resource' then
        xp_amount = 0.5 * distance_multiplier
    else
        xp_amount = (1.5 + event.entity.prototype.max_health * 0.0035) * distance_multiplier
    end

    Public.gain_xp(player, xp_amount)
end

local function on_player_crafted_item(event)
    if not event.recipe.energy then
        return
    end
    local player = game.players[event.player_index]
    if not player.valid then
        return
    end

    if player.cheat_mode then
        return
    end

    local amount = 0.30 * math.random(1, 2)

    Public.gain_xp(player, event.recipe.energy * amount)
end

local function on_player_respawned(event)
    local player = game.players[event.player_index]
    if not rpg_t[player.index] then
        Public.rpg_reset_player(player)
        return
    end
    update_player_stats(player)
    draw_level_text(player)
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
    if not rpg_t[player.index] then
        Public.rpg_reset_player(player)
        if rpg_extra.reward_new_players > 10 then
            Public.gain_xp(player, rpg_extra.reward_new_players)
        end
    end
    for _, p in pairs(game.connected_players) do
        draw_level_text(p)
    end
    draw_gui_char_button(player)
    if not player.character then
        return
    end
    update_player_stats(player)
end

local function tick()
    local ticker = game.tick
    local count = #game.connected_players
    local players = game.connected_players

    if ticker % nth_tick == 0 then
        global_pool(players, count)
    end

    if ticker % 15 == 0 then
        on_healed_player(players)
    end
end

--- Gives connected player some bonus xp if the map was preemptively shut down.
-- amount (integer) -- 10 levels
-- local Public = require 'maps.mountain_fortress_v3.rpg' Public.give_xp(512)
function Public.give_xp(amount)
    for _, player in pairs(game.connected_players) do
        if not validate_player(player) then
            return
        end
        Public.gain_xp(player, amount)
    end
end

function Public.rpg_reset_player(player, one_time_reset)
    if player.gui.left.rpg then
        player.gui.left.rpg.destroy()
    end
    if not player.character then
        player.set_controller({type = defines.controllers.god})
        player.create_character()
    end
    if one_time_reset then
        local total = rpg_t[player.index].total
        if not total then
            total = 0
        end
        local old_level = rpg_t[player.index].level
        local old_points_to_distribute = rpg_t[player.index].points_to_distribute
        local old_xp = rpg_t[player.index].xp
        rpg_t[player.index] = {
            level = 1,
            xp = 0,
            strength = 10,
            magicka = 10,
            dexterity = 10,
            vitality = 10,
            points_to_distribute = 0,
            last_floaty_text = visuals_delay,
            xp_since_last_floaty_text = 0,
            reset = true,
            capped = false,
            bonus = rpg_extra.breached_walls or 1,
            rotated_entity_delay = 0,
            gui_refresh_delay = 0,
            last_mined_entity_position = {x = 0, y = 0}
        }
        rpg_t[player.index].points_to_distribute = old_points_to_distribute + total
        rpg_t[player.index].xp = old_xp
        rpg_t[player.index].level = old_level
    else
        rpg_t[player.index] = {
            level = 1,
            xp = 0,
            strength = 10,
            magicka = 10,
            dexterity = 10,
            vitality = 10,
            points_to_distribute = 0,
            last_floaty_text = visuals_delay,
            xp_since_last_floaty_text = 0,
            reset = false,
            capped = false,
            total = 0,
            bonus = 1,
            rotated_entity_delay = 0,
            gui_refresh_delay = 0,
            last_mined_entity_position = {x = 0, y = 0}
        }
    end
    draw_gui_char_button(player)
    draw_level_text(player)
    update_char_button(player)
    update_player_stats(player)
end

function Public.rpg_reset_all_players()
    for k, _ in pairs(rpg_t) do
        rpg_t[k] = nil
    end
    for _, p in pairs(game.connected_players) do
        Public.rpg_reset_player(p)
    end
    rpg_extra.breached_walls = 1
    rpg_extra.reward_new_players = 0
    rpg_extra.global_pool = 0
end

function Public.get_magicka(player)
    return (rpg_t[player.index].magicka - 10) * 0.10
end

function Public.gain_xp(player, amount, added_to_pool, text)
    if level_limit_exceeded(player) then
        add_to_global_pool(amount)
        if not rpg_t[player.index].capped then
            rpg_t[player.index].capped = true
            local message = teller_level_limit .. 'You have hit the max level for the current zone.'
            Alert.alert_player_warning(player, 10, message)
        end
        return
    end

    local text_to_draw

    if rpg_t[player.index].capped then
        rpg_t[player.index].capped = false
    end

    if not added_to_pool then
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
        local fee = add_to_global_pool(amount)
        Public.debug_log('RPG - ' .. player.name .. ' got fee: ' .. fee)
        amount = math.round(amount, 3) - fee
        if rpg_extra.difficulty then
            amount = amount + rpg_extra.difficulty
        end
        Public.debug_log('RPG - ' .. player.name .. ' got after fee: ' .. amount)
    else
        Public.debug_log('RPG - ' .. player.name .. ' got org xp: ' .. amount)
    end

    rpg_t[player.index].xp = rpg_t[player.index].xp + amount
    rpg_t[player.index].xp_since_last_floaty_text = rpg_t[player.index].xp_since_last_floaty_text + amount

    if player.gui.left.rpg then
        draw_gui(player, false)
    end

    if not experience_levels[rpg_t[player.index].level + 1] then
        return
    end

    if rpg_t[player.index].xp >= experience_levels[rpg_t[player.index].level + 1] then
        level_up(player)
    end

    if rpg_t[player.index].last_floaty_text > game.tick then
        if not text then
            return
        end
    end

    if text then
        text_to_draw = '+' .. math.floor(amount) .. ' xp'
    else
        text_to_draw = '+' .. math.floor(rpg_t[player.index].xp_since_last_floaty_text) .. ' xp'
    end

    player.create_local_flying_text {
        text = text_to_draw,
        position = player.position,
        color = xp_floating_text_color,
        time_to_live = 340,
        speed = 2
    }

    rpg_t[player.index].xp_since_last_floaty_text = 0
    rpg_t[player.index].last_floaty_text = game.tick + visuals_delay
end

function Public.get_table(key)
    if key then
        return rpg_t[key]
    else
        return rpg_t
    end
end

function Public.get_extra_table(key)
    if key then
        return rpg_extra[key]
    else
        return rpg_extra
    end
end

function Public.toggle_debug()
    if rpg_extra.debug then
        rpg_extra.debug = false
    else
        rpg_extra.debug = true
    end
end

function Public.distribute_pool()
    local count = #game.connected_players
    local players = game.connected_players
    global_pool(players, count)
    print('Distributed the global XP pool')
end

function Public.debug_log(str)
    if not rpg_extra.debug then
        return
    end
    print(str)
end

Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_crafted_item, on_player_crafted_item)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
Event.add(defines.events.on_pre_player_mined_item, on_pre_player_mined_item)
Event.on_nth_tick(10, tick)

return Public
