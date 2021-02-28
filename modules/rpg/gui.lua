local ComfyGui = require 'comfy_panel.main'
local P = require 'player_modifiers'
local Gui = require 'utils.gui'

--RPG Modules
local Functions = require 'modules.rpg.functions'
local RPG = require 'modules.rpg.table'
local Settings = require 'modules.rpg.settings'

local Public = {}

local classes = RPG.classes

--RPG Settings
local experience_levels = RPG.experience_levels

--RPG Frames
local main_frame_name = RPG.main_frame_name
local draw_main_frame_name = RPG.draw_main_frame_name
local settings_button_name = RPG.settings_button_name
local settings_frame_name = RPG.settings_frame_name
local discard_button_name = RPG.discard_button_name
local save_button_name = RPG.save_button_name
local spell_gui_button_name = RPG.spell_gui_button_name
local spell_gui_frame_name = RPG.spell_gui_frame_name
local spell1_button_name = RPG.spell1_button_name
local spell2_button_name = RPG.spell2_button_name
local spell3_button_name = RPG.spell3_button_name

local sub = string.sub

function Public.draw_gui_char_button(player)
    if player.gui.top[draw_main_frame_name] then
        return
    end
    local b = player.gui.top.add({type = 'sprite-button', name = draw_main_frame_name, caption = '[RPG]', tooltip = 'RPG'})
    b.style.font_color = {165, 165, 165}
    b.style.font = 'heading-3'
    b.style.minimal_height = 38
    b.style.maximal_height = 38
    b.style.minimal_width = 50
    b.style.padding = 0
    b.style.margin = 0
end

function Public.update_char_button(player)
    local rpg_t = RPG.get('rpg_t')
    if not player.gui.top[draw_main_frame_name] then
        Public.draw_gui_char_button(player)
    end
    if rpg_t[player.index].points_to_distribute > 0 then
        player.gui.top[draw_main_frame_name].style.font_color = {245, 0, 0}
    else
        player.gui.top[draw_main_frame_name].style.font_color = {175, 175, 175}
    end
end

local function get_class(player)
    local rpg_t = RPG.get('rpg_t')
    local average = (rpg_t[player.index].strength + rpg_t[player.index].magicka + rpg_t[player.index].dexterity + rpg_t[player.index].vitality) / 4
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

local function add_gui_description(element, value, width, tooltip, min_height, max_height)
    local e = element.add({type = 'label', caption = value})
    e.tooltip = tooltip or ''
    e.style.single_line = false
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = max_height or 40
    e.style.minimal_height = min_height or 38
    e.style.font = 'default-bold'
    e.style.font_color = {175, 175, 200}
    e.style.horizontal_align = 'right'
    e.style.vertical_align = 'center'
    return e
end

local function add_gui_stat(element, value, width, tooltip, name, color)
    local e = element.add({type = 'sprite-button', name = name or nil, caption = value})
    e.tooltip = tooltip or ''
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = 38
    e.style.minimal_height = 38
    e.style.font = 'default-bold'
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    e.style.font_color = color or {222, 222, 222}
    return e
end

local function add_elem_stat(element, value, width, height, font, tooltip, name, color)
    local e = element.add({type = 'sprite-button', name = name or nil, caption = value})
    e.tooltip = tooltip or ''
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.maximal_height = height
    e.style.minimal_height = height
    e.style.font = font or 'default-bold'
    e.style.horizontal_align = 'center'
    e.style.vertical_align = 'center'
    e.style.font_color = color or {222, 222, 222}
    return e
end

local function add_gui_increase_stat(element, name, player)
    local rpg_t = RPG.get('rpg_t')
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
    e.tooltip = ({'rpg_gui.allocate_info', tostring(RPG.points_per_level)})

    return e
end

local function add_separator(element, width)
    local e = element.add({type = 'line'})
    e.style.maximal_width = width
    e.style.minimal_width = width
    e.style.minimal_height = 12
    return e
end

local function remove_settings_frame(settings_frame)
    Gui.remove_data_recursively(settings_frame)
    settings_frame.destroy()
end

local function remove_main_frame(main_frame, screen)
    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()

    local settings_frame = screen[settings_frame_name]
    if settings_frame and settings_frame.valid then
        remove_settings_frame(settings_frame)
    end
end

local function draw_main_frame(player, location)
    if not player.character then
        return
    end

    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = main_frame_name,
            caption = 'RPG',
            direction = 'vertical'
        }
    )
    if location then
        main_frame.location = location
    else
        main_frame.location = {x = 1, y = 40}
    end

    local data = {}
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')

    local inside_frame =
        main_frame.add {
        type = 'frame',
        style = 'deep_frame_in_shallow_frame'
    }
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    inside_frame_style.maximal_height = 800

    local inside_table =
        inside_frame.add {
        type = 'table',
        column_count = 1
    }

    local scroll_pane =
        inside_table.add {
        type = 'scroll-pane',
        vertical_scroll_policy = 'never',
        horizontal_scroll_policy = 'never'
    }
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.bottom_padding = 2
    scroll_style.left_padding = 2
    scroll_style.right_padding = 2
    scroll_style.top_padding = 2

    --!top table
    local main_table = scroll_pane.add({type = 'table', column_count = 2})
    local player_name = add_gui_stat(main_table, player.name, 200, ({'rpg_gui.player_name', player.name}))
    player_name.style.font_color = player.chat_color
    player_name.style.font = 'default-large-bold'
    local rank = add_gui_stat(main_table, get_class(player), 200, ({'rpg_gui.class_info', get_class(player)}))
    rank.style.font = 'default-large-bold'

    add_elem_stat(main_table, ({'rpg_gui.settings_name'}), 200, 35, nil, ({'rpg_gui.settings_frame'}), settings_button_name)

    add_separator(scroll_pane, 400)

    --!sub top table
    local scroll_table = scroll_pane.add({type = 'table', column_count = 4})
    scroll_table.style.cell_padding = 1

    add_gui_description(scroll_table, ({'rpg_gui.level_name'}), 80)
    if rpg_extra.level_limit_enabled then
        local level_tooltip = ({'rpg_gui.level_limit', Functions.level_limit_exceeded(player, true)})
        add_gui_stat(scroll_table, rpg_t[player.index].level, 80, level_tooltip)
    else
        add_gui_stat(scroll_table, rpg_t[player.index].level, 80)
    end

    add_gui_description(scroll_table, ({'rpg_gui.experience_name'}), 100)
    local exp_gui = add_gui_stat(scroll_table, math.floor(rpg_t[player.index].xp), 125, ({'rpg_gui.gain_info_tooltip'}))
    data.exp_gui = exp_gui

    add_gui_description(scroll_table, ' ', 75)
    add_gui_description(scroll_table, ' ', 75)

    add_gui_description(scroll_table, ({'rpg_gui.next_level_name'}), 100)
    add_gui_stat(scroll_table, experience_levels[rpg_t[player.index].level + 1], 125, ({'rpg_gui.gain_info_tooltip'}))

    add_separator(scroll_pane, 400)

    --!bottom table
    local bottom_table = scroll_pane.add({type = 'table', column_count = 2})
    local left_bottom_table = bottom_table.add({type = 'table', column_count = 3})
    left_bottom_table.style.cell_padding = 1
    local w0 = 2
    local w1 = 85
    local w2 = 63

    add_gui_description(left_bottom_table, ({'rpg_gui.strength_name'}), w1, ({'rpg_gui.strength_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t[player.index].strength, w2, ({'rpg_gui.strength_tooltip'}))
    add_gui_increase_stat(left_bottom_table, 'strength', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.magic_name'}), w1, ({'rpg_gui.magic_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t[player.index].magicka, w2, ({'rpg_gui.magic_tooltip'}))
    add_gui_increase_stat(left_bottom_table, 'magicka', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.dexterity_name'}), w1, ({'rpg_gui.dexterity_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t[player.index].dexterity, w2, ({'rpg_gui.dexterity_tooltip'}))

    add_gui_increase_stat(left_bottom_table, 'dexterity', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.vitality_name'}), w1, ({'rpg_gui.vitality_tooltip'}))
    add_gui_stat(left_bottom_table, rpg_t[player.index].vitality, w2, ({'rpg_gui.vitality_tooltip'}))
    add_gui_increase_stat(left_bottom_table, 'vitality', player)

    add_gui_description(left_bottom_table, ({'rpg_gui.points_to_dist'}), w1)
    add_gui_stat(left_bottom_table, rpg_t[player.index].points_to_distribute, w2, nil, nil, {200, 0, 0})
    add_gui_description(left_bottom_table, ' ', w2)

    add_gui_description(left_bottom_table, ' ', 40)
    add_gui_description(left_bottom_table, ' ', 40)
    add_gui_description(left_bottom_table, ' ', 40)

    add_gui_description(left_bottom_table, ({'rpg_gui.life_name'}), w1, ({'rpg_gui.life_tooltip'}))
    local health_gui = add_gui_stat(left_bottom_table, math.floor(player.character.health), w2, ({'rpg_gui.life_increase'}))
    data.health = health_gui
    add_gui_stat(
        left_bottom_table,
        math.floor(player.character.prototype.max_health + player.character_health_bonus + player.force.character_health_bonus),
        w2,
        ({'rpg_gui.life_maximum'})
    )

    local shield = 0
    local shield_max = 0
    local shield_desc_tip = ({'rpg_gui.shield_no_shield'})
    local shield_tip = ({'rpg_gui.shield_no_armor'})
    local shield_max_tip = shield_tip

    local i = player.character.get_inventory(defines.inventory.character_armor)
    if not i.is_empty() then
        if i[1].grid then
            shield = math.floor(i[1].grid.shield)
            shield_max = math.floor(i[1].grid.max_shield)
            shield_desc_tip = ({'rpg_gui.shield_tooltip'})
            shield_tip = ({'rpg_gui.shield_current'})
            shield_max_tip = ({'rpg_gui.shield_max'})
            add_gui_description(left_bottom_table, ({'rpg_gui.shield_name'}), w1, shield_desc_tip)
            local shield_gui = add_gui_stat(left_bottom_table, shield, w2, shield_tip)
            local shield_max_gui = add_gui_stat(left_bottom_table, shield_max, w2, shield_max_tip)

            data.shield = shield_gui
            data.shield_max = shield_max_gui
        end
    else
        add_gui_description(left_bottom_table, ({'rpg_gui.shield_name'}), w1, shield_desc_tip)
        add_gui_stat(left_bottom_table, shield, w2, shield_tip)
        add_gui_stat(left_bottom_table, shield_max, w2, shield_max_tip)
    end

    if rpg_extra.enable_mana then
        local mana = rpg_t[player.index].mana
        local mana_max = rpg_t[player.index].mana_max

        local mana_tip = ({'rpg_gui.mana_tooltip'})
        add_gui_description(left_bottom_table, ({'rpg_gui.mana_name'}), w1, mana_tip)
        local mana_regen_tip = ({'rpg_gui.mana_regen_current'})
        local mana_max_regen_tip
        if rpg_t[player.index].mana_max >= rpg_extra.mana_limit then
            mana_max_regen_tip = ({'rpg_gui.mana_max_limit'})
        else
            mana_max_regen_tip = ({'rpg_gui.mana_max'})
        end
        local mana_gui = add_gui_stat(left_bottom_table, mana, w2, mana_regen_tip)
        local mana_max_gui = add_gui_stat(left_bottom_table, mana_max, w2, mana_max_regen_tip)
        data.mana = mana_gui
        data.mana_max = mana_max_gui
    end

    local right_bottom_table = bottom_table.add({type = 'table', column_count = 3})
    right_bottom_table.style.cell_padding = 1

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.mining_name'}), w1)
    local mining_speed_value = math.round((player.force.manual_mining_speed_modifier + player.character_mining_speed_modifier + 1) * 100) .. '%'
    add_gui_stat(right_bottom_table, mining_speed_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.slot_name'}), w1)
    local slot_bonus_value = '+ ' .. math.round(player.force.character_inventory_slots_bonus + player.character_inventory_slots_bonus)
    add_gui_stat(right_bottom_table, slot_bonus_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.melee_name'}), w1)
    local melee_damage_value = math.round(100 * (1 + Functions.get_melee_modifier(player))) .. '%'
    local melee_damage_tooltip
    if rpg_extra.enable_one_punch then
        melee_damage_tooltip = ({
            'rpg_gui.one_punch_chance',
            Functions.get_life_on_hit(player),
            Functions.get_one_punch_chance(player),
            Functions.get_extra_following_robots(player)
        })
    else
        melee_damage_tooltip = ({'rpg_gui.one_punch_disabled'})
    end
    add_gui_stat(right_bottom_table, melee_damage_value, w2, melee_damage_tooltip)

    add_gui_description(right_bottom_table, '', w0, '', nil, 5)
    add_gui_description(right_bottom_table, '', w0, '', nil, 5)
    add_gui_description(right_bottom_table, '', w0, '', nil, 5)

    local reach_distance_value = '+ ' .. (player.force.character_reach_distance_bonus + player.character_reach_distance_bonus)
    local reach_bonus_tooltip = ({
        'rpg_gui.bonus_tooltip',
        player.character_reach_distance_bonus,
        player.character_build_distance_bonus,
        player.character_item_drop_distance_bonus,
        player.character_loot_pickup_distance_bonus,
        player.character_item_pickup_distance_bonus,
        player.character_resource_reach_distance_bonus,
        Functions.get_magicka(player)
    })

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.reach_distance'}), w1)
    add_gui_stat(right_bottom_table, reach_distance_value, w2, reach_bonus_tooltip)

    add_gui_description(right_bottom_table, '', w0, '', nil, 10)
    add_gui_description(right_bottom_table, '', w0, '', nil, 10)
    add_gui_description(right_bottom_table, '', w0, '', nil, 10)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.crafting_speed'}), w1)
    local crafting_speed_value = math.round((player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier + 1) * 100) .. '%'
    add_gui_stat(right_bottom_table, crafting_speed_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.running_speed'}), w1)
    local running_speed_value = math.round((player.force.character_running_speed_modifier + player.character_running_speed_modifier + 1) * 100) .. '%'
    add_gui_stat(right_bottom_table, running_speed_value, w2)

    add_gui_description(right_bottom_table, ' ', w0)
    add_gui_description(right_bottom_table, ({'rpg_gui.health_bonus_name'}), w1)
    local health_bonus_value = '+ ' .. math.round((player.force.character_health_bonus + player.character_health_bonus))
    local health_tooltip = ({'rpg_gui.health_tooltip', Functions.get_heal_modifier(player)})
    add_gui_stat(right_bottom_table, health_bonus_value, w2, health_tooltip)

    add_gui_description(right_bottom_table, ' ', w0)

    if rpg_extra.enable_mana then
        add_gui_description(right_bottom_table, ({'rpg_gui.mana_bonus'}), w1)
        local mana_bonus_value = '+ ' .. (math.floor(Functions.get_mana_modifier(player) * 10) / 10)
        local mana_bonus_tooltip = ({
            'rpg_gui.mana_regen_bonus',
            (math.floor(Functions.get_mana_modifier(player) * 10) / 10)
        })
        add_gui_stat(right_bottom_table, mana_bonus_value, w2, mana_bonus_tooltip)
    end

    add_separator(scroll_pane, 400)

    Public.update_char_button(player)
    data.frame = main_frame

    Gui.set_data(main_frame, data)
end

function Public.draw_level_text(player)
    if not player.character then
        return
    end

    local rpg_t = RPG.get('rpg_t')

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

function Public.update_player_stats(player)
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')
    local player_modifiers = P.get_table()
    local strength = rpg_t[player.index].strength - 10
    player_modifiers[player.index].character_inventory_slots_bonus['rpg'] = math.round(strength * 0.2, 3)
    player_modifiers[player.index].character_mining_speed_modifier['rpg'] = math.round(strength * 0.007, 3)
    player_modifiers[player.index].character_maximum_following_robot_count_bonus['rpg'] = math.round(strength / 2 * 0.03, 3)

    local magic = rpg_t[player.index].magicka - 10
    local v = magic * 0.22
    player_modifiers[player.index].character_build_distance_bonus['rpg'] = math.min(60, math.round(v * 0.25, 3))
    player_modifiers[player.index].character_item_drop_distance_bonus['rpg'] = math.min(60, math.round(v * 0.25, 3))
    player_modifiers[player.index].character_reach_distance_bonus['rpg'] = math.min(60, math.round(v * 0.25, 3))
    player_modifiers[player.index].character_loot_pickup_distance_bonus['rpg'] = math.min(20, math.round(v * 0.22, 3))
    player_modifiers[player.index].character_item_pickup_distance_bonus['rpg'] = math.min(20, math.round(v * 0.25, 3))
    player_modifiers[player.index].character_resource_reach_distance_bonus['rpg'] = math.min(20, math.round(v * 0.15, 3))
    if rpg_t[player.index].mana_max >= rpg_extra.mana_limit then
        rpg_t[player.index].mana_max = rpg_extra.mana_limit
    else
        rpg_t[player.index].mana_max = math.round((magic) * 2, 3)
    end

    local dexterity = rpg_t[player.index].dexterity - 10
    player_modifiers[player.index].character_running_speed_modifier['rpg'] = math.round(dexterity * 0.0015, 3)
    player_modifiers[player.index].character_crafting_speed_modifier['rpg'] = math.round(dexterity * 0.015, 3)

    player_modifiers[player.index].character_health_bonus['rpg'] = math.round((rpg_t[player.index].vitality - 10) * 6, 3)

    P.update_player_modifiers(player)
end

function Public.toggle(player, recreate)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if recreate and main_frame then
        local location = main_frame.location
        remove_main_frame(main_frame, screen)
        draw_main_frame(player, location)
        return
    end
    if main_frame then
        remove_main_frame(main_frame, screen)
        ComfyGui.comfy_panel_restore_left_gui(player)
    else
        ComfyGui.comfy_panel_clear_left_gui(player)
        draw_main_frame(player)
    end
end

function Public.remove_frame(player)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if main_frame then
        remove_main_frame(main_frame, screen)
        ComfyGui.comfy_panel_restore_left_gui(player)
    end
end

local toggle = Public.toggle
Public.remove_main_frame = remove_main_frame

Gui.on_click(
    draw_main_frame_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        toggle(player)
    end
)

Gui.on_click(
    save_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        local player_modifiers = P.get_table()
        local data = Gui.get_data(event.element)
        local health_bar_gui_input = data.health_bar_gui_input
        local reset_gui_input = data.reset_gui_input
        local conjure_gui_input = data.conjure_gui_input
        local spell_gui_input1 = data.spell_gui_input1
        local spell_gui_input2 = data.spell_gui_input2
        local spell_gui_input3 = data.spell_gui_input3
        local magic_pickup_gui_input = data.magic_pickup_gui_input
        local movement_speed_gui_input = data.movement_speed_gui_input
        local flame_boots_gui_input = data.flame_boots_gui_input
        local explosive_bullets_gui_input = data.explosive_bullets_gui_input
        local enable_entity_gui_input = data.enable_entity_gui_input
        local stone_path_gui_input = data.stone_path_gui_input
        local one_punch_gui_input = data.one_punch_gui_input
        local auto_allocate_gui_input = data.auto_allocate_gui_input

        local rpg_t = RPG.get('rpg_t')

        if frame and frame.valid then
            if auto_allocate_gui_input and auto_allocate_gui_input.valid and auto_allocate_gui_input.selected_index then
                rpg_t[player.index].allocate_index = auto_allocate_gui_input.selected_index
            end

            if one_punch_gui_input and one_punch_gui_input.valid then
                if not one_punch_gui_input.state then
                    rpg_t[player.index].one_punch = false
                elseif one_punch_gui_input.state then
                    rpg_t[player.index].one_punch = true
                end
            end

            if stone_path_gui_input and stone_path_gui_input.valid then
                if not stone_path_gui_input.state then
                    rpg_t[player.index].stone_path = false
                elseif stone_path_gui_input.state then
                    rpg_t[player.index].stone_path = true
                end
            end

            if enable_entity_gui_input and enable_entity_gui_input.valid then
                if not enable_entity_gui_input.state then
                    rpg_t[player.index].enable_entity_spawn = false
                elseif enable_entity_gui_input.state then
                    rpg_t[player.index].enable_entity_spawn = true
                end
            end

            if flame_boots_gui_input and flame_boots_gui_input.valid then
                if not flame_boots_gui_input.state then
                    rpg_t[player.index].flame_boots = false
                elseif flame_boots_gui_input.state then
                    rpg_t[player.index].flame_boots = true
                end
            end

            if explosive_bullets_gui_input and explosive_bullets_gui_input.valid then
                if not explosive_bullets_gui_input.state then
                    rpg_t[player.index].explosive_bullets = false
                elseif explosive_bullets_gui_input.state then
                    rpg_t[player.index].explosive_bullets = true
                end
            end

            if movement_speed_gui_input and movement_speed_gui_input.valid then
                if not player_modifiers.disabled_modifier[player.index] then
                    player_modifiers.disabled_modifier[player.index] = {}
                end
                if not movement_speed_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_running_speed_modifier = true
                    P.update_player_modifiers(player)
                elseif movement_speed_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_running_speed_modifier = false
                    P.update_player_modifiers(player)
                end
            end

            if magic_pickup_gui_input and magic_pickup_gui_input.valid then
                if not player_modifiers.disabled_modifier[player.index] then
                    player_modifiers.disabled_modifier[player.index] = {}
                end
                if not magic_pickup_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus = true
                    player_modifiers.disabled_modifier[player.index].character_build_distance_bonus = true
                    player_modifiers.disabled_modifier[player.index].character_item_drop_distance_bonus = true
                    player_modifiers.disabled_modifier[player.index].character_reach_distance_bonus = true
                    player_modifiers.disabled_modifier[player.index].character_loot_pickup_distance_bonus = true
                    player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus = true
                    player_modifiers.disabled_modifier[player.index].character_resource_reach_distance_bonus = true
                    P.update_player_modifiers(player)
                elseif magic_pickup_gui_input.state then
                    player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus = false
                    player_modifiers.disabled_modifier[player.index].character_build_distance_bonus = false
                    player_modifiers.disabled_modifier[player.index].character_item_drop_distance_bonus = false
                    player_modifiers.disabled_modifier[player.index].character_reach_distance_bonus = false
                    player_modifiers.disabled_modifier[player.index].character_loot_pickup_distance_bonus = false
                    player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus = false
                    player_modifiers.disabled_modifier[player.index].character_resource_reach_distance_bonus = false
                    P.update_player_modifiers(player)
                end
            end
            if conjure_gui_input and conjure_gui_input.valid and conjure_gui_input.selected_index then
                rpg_t[player.index].dropdown_select_index = conjure_gui_input.selected_index
            end
            if spell_gui_input1 and spell_gui_input1.valid and spell_gui_input1.selected_index then
                rpg_t[player.index].dropdown_select_index1 = spell_gui_input1.selected_index
            end
            if spell_gui_input2 and spell_gui_input2.valid and spell_gui_input2.selected_index then
                rpg_t[player.index].dropdown_select_index2 = spell_gui_input2.selected_index
            end
            if spell_gui_input3 and spell_gui_input3.valid and spell_gui_input3.selected_index then
                rpg_t[player.index].dropdown_select_index3 = spell_gui_input3.selected_index
            end
            if player.gui.screen[spell_gui_frame_name] then
                Settings.update_spell_gui(player, nil)
            end

            if reset_gui_input and reset_gui_input.valid and reset_gui_input.state then
                if not rpg_t[player.index].reset then
                    rpg_t[player.index].allocate_index = 1
                    rpg_t[player.index].reset = true
                    Functions.rpg_reset_player(player, true)
                end
            end
            if health_bar_gui_input and health_bar_gui_input.valid then
                if not health_bar_gui_input.state then
                    rpg_t[player.index].show_bars = false
                    Functions.update_health(player)
                    Functions.update_mana(player)
                elseif health_bar_gui_input.state then
                    rpg_t[player.index].show_bars = true
                    Functions.update_health(player)
                    Functions.update_mana(player)
                end
            end

            remove_settings_frame(event.element)

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    discard_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        if not player or not player.valid or not player.character then
            return
        end
        if frame and frame.valid then
            frame.destroy()
        end
    end
)

Gui.on_click(
    settings_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[settings_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        local surface_name = RPG.get('rpg_extra').surface_name
        if sub(player.surface.name, 0, #surface_name) ~= surface_name then
            return
        end

        if frame and frame.valid then
            frame.destroy()
        else
            Settings.extra_settings(player)
        end
    end
)

Gui.on_click(
    spell_gui_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        local surface_name = RPG.get('rpg_extra').surface_name
        if sub(player.surface.name, 0, #surface_name) ~= surface_name then
            return
        end

        if frame and frame.valid then
            frame.destroy()
        else
            Settings.spell_gui_settings(player)
        end
    end
)

Gui.on_click(
    spell1_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        local surface_name = RPG.get('rpg_extra').surface_name
        if sub(player.surface.name, 0, #surface_name) ~= surface_name then
            return
        end

        if frame and frame.valid then
            Settings.update_spell_gui(player, 1)
        end
    end
)

Gui.on_click(
    spell2_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        local surface_name = RPG.get('rpg_extra').surface_name
        if sub(player.surface.name, 0, #surface_name) ~= surface_name then
            return
        end

        if frame and frame.valid then
            Settings.update_spell_gui(player, 2)
        end
    end
)

Gui.on_click(
    spell3_button_name,
    function(event)
        local player = event.player
        local screen = player.gui.screen
        local frame = screen[spell_gui_frame_name]
        if not player or not player.valid or not player.character then
            return
        end

        local surface_name = RPG.get('rpg_extra').surface_name
        if sub(player.surface.name, 0, #surface_name) ~= surface_name then
            return
        end

        if frame and frame.valid then
            Settings.update_spell_gui(player, 3)
        end
    end
)

ComfyGui.screen_to_bypass(spell_gui_frame_name)

return Public
