local RPG = require 'modules.rpg.table'
local Gui = require 'utils.gui'
local P = require 'player_modifiers'
local Session = require 'utils.datastore.session_data'

local Public = {}

local settings_frame_name = RPG.settings_frame_name
local save_button_name = RPG.save_button_name
local discard_button_name = RPG.discard_button_name
local spell_gui_button_name = RPG.spell_gui_button_name
local spell_gui_frame_name = RPG.spell_gui_frame_name
local spell1_button_name = RPG.spell1_button_name
local spell2_button_name = RPG.spell2_button_name
local spell3_button_name = RPG.spell3_button_name

local function create_input_element(frame, type, value, items, index)
    if type == 'slider' then
        return frame.add({type = 'slider', value = value, minimum_value = 0, maximum_value = 1})
    end
    if type == 'boolean' then
        return frame.add({type = 'checkbox', state = value})
    end
    if type == 'dropdown' then
        return frame.add({type = 'drop-down', items = items, selected_index = index})
    end
    return frame.add({type = 'text-box', text = value})
end

function Public.update_spell_gui(player, spell_index)
    local rpg_t = RPG.get('rpg_t')
    local spells, names = RPG.rebuild_spells()
    local main_frame = player.gui.screen[spell_gui_frame_name]
    if not main_frame then
        return
    end
    local spell_table = main_frame['spell_table']
    if spell_index then
        if spell_index == 1 then
            rpg_t[player.index].dropdown_select_index = rpg_t[player.index].dropdown_select_index1
        elseif spell_index == 2 then
            rpg_t[player.index].dropdown_select_index = rpg_t[player.index].dropdown_select_index2
        elseif spell_index == 3 then
            rpg_t[player.index].dropdown_select_index = rpg_t[player.index].dropdown_select_index3
        end
    end
    spell_table[spell1_button_name].tooltip = names[rpg_t[player.index].dropdown_select_index1] or '---'
    spell_table[spell1_button_name].sprite = spells[rpg_t[player.index].dropdown_select_index1].sprite
    spell_table[spell2_button_name].tooltip = names[rpg_t[player.index].dropdown_select_index2] or '---'
    spell_table[spell2_button_name].sprite = spells[rpg_t[player.index].dropdown_select_index2].sprite
    spell_table[spell3_button_name].tooltip = names[rpg_t[player.index].dropdown_select_index3] or '---'
    spell_table[spell3_button_name].sprite = spells[rpg_t[player.index].dropdown_select_index3].sprite
    if rpg_t[player.index].dropdown_select_index1 == rpg_t[player.index].dropdown_select_index then
        spell_table[spell1_button_name].enabled = false
        spell_table[spell1_button_name].number = 1
    else
        spell_table[spell1_button_name].enabled = true
        spell_table[spell1_button_name].number = nil
    end
    if rpg_t[player.index].dropdown_select_index2 == rpg_t[player.index].dropdown_select_index then
        spell_table[spell2_button_name].enabled = false
        spell_table[spell2_button_name].number = 1
    else
        spell_table[spell2_button_name].enabled = true
        spell_table[spell2_button_name].number = nil
    end
    if rpg_t[player.index].dropdown_select_index3 == rpg_t[player.index].dropdown_select_index then
        spell_table[spell3_button_name].enabled = false
        spell_table[spell3_button_name].number = 1
    else
        spell_table[spell3_button_name].enabled = true
        spell_table[spell3_button_name].number = nil
    end
    spell_table['mana-cost'].caption = spells[rpg_t[player.index].dropdown_select_index].mana_cost
    spell_table['mana'].caption = math.floor(rpg_t[player.index].mana)
    spell_table['maxmana'].caption = math.floor(rpg_t[player.index].mana_max)
end

function Public.spell_gui_settings(player)
    local rpg_t = RPG.get('rpg_t')
    local spells, names = RPG.rebuild_spells()
    local main_frame = player.gui.screen[spell_gui_frame_name]
    if not main_frame or not main_frame.valid then
        main_frame =
            player.gui.screen.add(
            {
                type = 'frame',
                name = spell_gui_frame_name,
                caption = ({'rpg_settings.spell_name'}),
                direction = 'vertical'
            }
        )
        main_frame.auto_center = true
        local table = main_frame.add({type = 'table', column_count = 3, name = 'spell_table'})
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t[player.index].dropdown_select_index1].sprite,
                name = spell1_button_name,
                tooltip = names[rpg_t[player.index].dropdown_select_index1] or '---'
            }
        )
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t[player.index].dropdown_select_index2].sprite,
                name = spell2_button_name,
                tooltip = names[rpg_t[player.index].dropdown_select_index2] or '---'
            }
        )
        table.add(
            {
                type = 'sprite-button',
                sprite = spells[rpg_t[player.index].dropdown_select_index3].sprite,
                name = spell3_button_name,
                tooltip = names[rpg_t[player.index].dropdown_select_index3] or '---'
            }
        )
        local b1 = table.add({type = 'sprite-button', name = 'mana-cost', tooltip = {'rpg_settings.mana_cost'}, caption = 0})
        local b2 = table.add({type = 'sprite-button', name = 'mana', tooltip = {'rpg_settings.mana'}, caption = 0})
        local b3 = table.add({type = 'sprite-button', name = 'maxmana', tooltip = {'rpg_settings.mana_max'}, caption = 0})
        b1.style.font_color = {r = 0.98, g = 0.98, b = 0.98}
        b2.style.font_color = {r = 0.98, g = 0.98, b = 0.98}
        b3.style.font_color = {r = 0.98, g = 0.98, b = 0.98}
        Public.update_spell_gui(player, nil)
    else
        main_frame.destroy()
    end
end

function Public.extra_settings(player)
    local player_modifiers = P.get_table()
    local rpg_extra = RPG.get('rpg_extra')
    local rpg_t = RPG.get('rpg_t')
    local trusted = Session.get_trusted_table()
    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = settings_frame_name,
            caption = ({'rpg_settings.name'}),
            direction = 'vertical'
        }
    )
    main_frame.auto_center = true
    local main_frame_style = main_frame.style
    main_frame_style.width = 500

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 0

    inside_table.add({type = 'line'})

    local info_text = inside_table.add({type = 'label', caption = ({'rpg_settings.info_text_label'})})
    local info_text_style = info_text.style
    info_text_style.font = 'default-bold'
    info_text_style.padding = 0
    info_text_style.left_padding = 10
    info_text_style.horizontal_align = 'left'
    info_text_style.vertical_align = 'bottom'
    info_text_style.font_color = {0.55, 0.55, 0.99}

    inside_table.add({type = 'line'})

    local scroll_pane = inside_table.add({type = 'scroll-pane'})
    local scroll_style = scroll_pane.style
    scroll_style.vertically_squashable = true
    scroll_style.maximal_height = 800
    scroll_style.bottom_padding = 5
    scroll_style.left_padding = 5
    scroll_style.right_padding = 5
    scroll_style.top_padding = 5

    local setting_grid = scroll_pane.add({type = 'table', column_count = 2})

    local health_bar_gui_input
    if rpg_extra.enable_health_and_mana_bars then
        local health_bar_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.health_text_label'})
            }
        )

        local style = health_bar_label.style
        style.horizontally_stretchable = true
        style.height = 35
        style.vertical_align = 'center'

        local health_bar_input = setting_grid.add({type = 'flow'})
        local input_style = health_bar_input.style
        input_style.height = 35
        input_style.vertical_align = 'center'
        health_bar_gui_input = create_input_element(health_bar_input, 'boolean', rpg_t[player.index].show_bars)
        health_bar_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
        if not rpg_extra.enable_mana then
            health_bar_label.caption = ({'rpg_settings.health_only_text_label'})
        end
    end

    local reset_label =
        setting_grid.add(
        {
            type = 'label',
            caption = ({'rpg_settings.reset_text_label'}),
            tooltip = ''
        }
    )

    local reset_label_style = reset_label.style
    reset_label_style.horizontally_stretchable = true
    reset_label_style.height = 35
    reset_label_style.vertical_align = 'center'

    local reset_input = setting_grid.add({type = 'flow'})
    local reset_input_style = reset_input.style
    reset_input_style.height = 35
    reset_input_style.vertical_align = 'center'
    local reset_gui_input = create_input_element(reset_input, 'boolean', false)

    if not rpg_t[player.index].reset then
        if not trusted[player.name] then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = ({'rpg_settings.not_trusted'})
            goto continue
        end
        if rpg_t[player.index].level < 50 then
            reset_gui_input.enabled = false
            reset_gui_input.tooltip = ({'rpg_settings.low_level', 50})
            reset_label.tooltip = ({'rpg_settings.low_level', 50})
        else
            reset_gui_input.enabled = true
            reset_gui_input.tooltip = ({'rpg_settings.reset_tooltip'})
            reset_label.tooltip = ({'rpg_settings.reset_tooltip'})
        end
    else
        reset_gui_input.enabled = false
        reset_gui_input.tooltip = ({'rpg_settings.used_up'})
    end

    ::continue::
    local magic_pickup_label =
        setting_grid.add(
        {
            type = 'label',
            caption = ({'rpg_settings.reach_text_label'}),
            tooltip = ({'rpg_settings.reach_text_tooltip'})
        }
    )

    local magic_pickup_label_style = magic_pickup_label.style
    magic_pickup_label_style.horizontally_stretchable = true
    magic_pickup_label_style.height = 35
    magic_pickup_label_style.vertical_align = 'center'

    local magic_pickup_input = setting_grid.add({type = 'flow'})
    local magic_pickup_input_style = magic_pickup_input.style
    magic_pickup_input_style.height = 35
    magic_pickup_input_style.vertical_align = 'center'
    local reach_mod
    if player_modifiers.disabled_modifier[player.index] and player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus then
        reach_mod = not player_modifiers.disabled_modifier[player.index].character_item_pickup_distance_bonus
    else
        reach_mod = true
    end
    local magic_pickup_gui_input = create_input_element(magic_pickup_input, 'boolean', reach_mod)
    magic_pickup_gui_input.tooltip = ({'rpg_settings.tooltip_check'})

    local movement_speed_label =
        setting_grid.add(
        {
            type = 'label',
            caption = ({'rpg_settings.movement_text_label'}),
            tooltip = ({'rpg_settings.movement_text_tooltip'})
        }
    )

    local movement_speed_label_style = movement_speed_label.style
    movement_speed_label_style.horizontally_stretchable = true
    movement_speed_label_style.height = 35
    movement_speed_label_style.vertical_align = 'center'

    local movement_speed_input = setting_grid.add({type = 'flow'})
    local movement_speed_input_style = movement_speed_input.style
    movement_speed_input_style.height = 35
    movement_speed_input_style.vertical_align = 'center'
    local speed_mod
    if player_modifiers.disabled_modifier[player.index] and player_modifiers.disabled_modifier[player.index].character_running_speed_modifier then
        speed_mod = not player_modifiers.disabled_modifier[player.index].character_running_speed_modifier
    else
        speed_mod = true
    end
    local movement_speed_gui_input = create_input_element(movement_speed_input, 'boolean', speed_mod)
    movement_speed_gui_input.tooltip = ({'rpg_settings.tooltip_check'})

    local enable_entity_gui_input
    local conjure_gui_input
    local spell_gui_input1
    local spell_gui_input2
    local spell_gui_input3
    local flame_boots_gui_input
    local explosive_bullets_gui_input
    local stone_path_gui_input
    local one_punch_gui_input
    local auto_allocate_gui_input

    if rpg_extra.enable_stone_path then
        local stone_path_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.stone_path_label'}),
                tooltip = ({'rpg_settings.stone_path_tooltip'})
            }
        )

        local stone_path_label_style = stone_path_label.style
        stone_path_label_style.horizontally_stretchable = true
        stone_path_label_style.height = 35
        stone_path_label_style.vertical_align = 'center'

        local stone_path_input = setting_grid.add({type = 'flow'})
        local stone_path_input_style = stone_path_input.style
        stone_path_input_style.height = 35
        stone_path_input_style.vertical_align = 'center'
        local stone_path
        if rpg_t[player.index].stone_path then
            stone_path = rpg_t[player.index].stone_path
        else
            stone_path = false
        end
        stone_path_gui_input = create_input_element(stone_path_input, 'boolean', stone_path)

        if rpg_t[player.index].level < 20 then
            stone_path_gui_input.enabled = false
            stone_path_gui_input.tooltip = ({'rpg_settings.low_level', 20})
            stone_path_label.tooltip = ({'rpg_settings.low_level', 20})
        else
            stone_path_gui_input.enabled = true
            stone_path_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
        end
    end

    if rpg_extra.enable_one_punch then
        local one_punch_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.one_punch_label'}),
                tooltip = ({'rpg_settings.one_punch_tooltip'})
            }
        )

        local one_punch_label_style = one_punch_label.style
        one_punch_label_style.horizontally_stretchable = true
        one_punch_label_style.height = 35
        one_punch_label_style.vertical_align = 'center'

        local one_punch_input = setting_grid.add({type = 'flow'})
        local one_punch_input_style = one_punch_input.style
        one_punch_input_style.height = 35
        one_punch_input_style.vertical_align = 'center'
        local one_punch
        if rpg_t[player.index].one_punch then
            one_punch = rpg_t[player.index].one_punch
        else
            one_punch = false
        end
        one_punch_gui_input = create_input_element(one_punch_input, 'boolean', one_punch)

        if rpg_extra.enable_one_punch_globally then
            one_punch_gui_input.state = true
            one_punch_gui_input.enabled = false
            one_punch_gui_input.tooltip = ({'rpg_settings.one_punch_globally'})
        else
            if rpg_t[player.index].level < 30 then
                one_punch_gui_input.enabled = false
                one_punch_gui_input.tooltip = ({'rpg_settings.low_level', 30})
            else
                one_punch_gui_input.enabled = true
                one_punch_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
            end
        end
    end

    if rpg_extra.enable_flame_boots then
        local flame_boots_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.flameboots_label'}),
                tooltip = ({'rpg_settings.flameboots_tooltip'})
            }
        )

        local flame_boots_label_style = flame_boots_label.style
        flame_boots_label_style.horizontally_stretchable = true
        flame_boots_label_style.height = 35
        flame_boots_label_style.vertical_align = 'center'

        local flame_boots_input = setting_grid.add({type = 'flow'})
        local flame_boots_input_style = flame_boots_input.style
        flame_boots_input_style.height = 35
        flame_boots_input_style.vertical_align = 'center'
        local flame_mod
        if rpg_t[player.index].flame_boots then
            flame_mod = rpg_t[player.index].flame_boots
        else
            flame_mod = false
        end
        flame_boots_gui_input = create_input_element(flame_boots_input, 'boolean', flame_mod)

        if rpg_t[player.index].mana > 50 then
            if rpg_t[player.index].level < 100 then
                flame_boots_gui_input.enabled = false
                flame_boots_gui_input.tooltip = ({'rpg_settings.low_level', 100})
                flame_boots_label.tooltip = ({'rpg_settings.low_level', 100})
            else
                flame_boots_gui_input.enabled = true
                flame_boots_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
            end
        else
            flame_boots_gui_input.enabled = false
            flame_boots_gui_input.tooltip = ({'rpg_settings.no_mana'})
        end
    end

    if rpg_extra.enable_explosive_bullets_globally then
        local explosive_bullets_label =
            setting_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.explosive_bullets_label'}),
                tooltip = ({'rpg_settings.explosive_bullets_tooltip'})
            }
        )

        local explosive_bullets_label_style = explosive_bullets_label.style
        explosive_bullets_label_style.horizontally_stretchable = true
        explosive_bullets_label_style.height = 35
        explosive_bullets_label_style.vertical_align = 'center'

        local explosive_bullet_input = setting_grid.add({type = 'flow'})
        local explosive_bullet_input_style = explosive_bullet_input.style
        explosive_bullet_input_style.height = 35
        explosive_bullet_input_style.vertical_align = 'center'
        local explosive_bullets
        if rpg_t[player.index].explosive_bullets then
            explosive_bullets = rpg_t[player.index].explosive_bullets
        else
            explosive_bullets = false
        end
        explosive_bullets_gui_input = create_input_element(explosive_bullet_input, 'boolean', explosive_bullets)

        if rpg_t[player.index].level < 50 then
            explosive_bullets_gui_input.enabled = false
            explosive_bullets_gui_input.tooltip = ({'rpg_settings.low_level', 50})
            explosive_bullets_label.tooltip = ({'rpg_settings.low_level', 50})
        else
            explosive_bullets_gui_input.enabled = true
            explosive_bullets_gui_input.tooltip = ({'rpg_settings.explosive_bullets_tooltip'})
        end
    end

    if rpg_extra.enable_mana then
        local mana_frame = inside_table.add({type = 'scroll-pane'})
        local mana_style = mana_frame.style
        mana_style.vertically_squashable = true
        mana_style.bottom_padding = 5
        mana_style.left_padding = 5
        mana_style.right_padding = 5
        mana_style.top_padding = 5

        mana_frame.add({type = 'line'})

        local label = mana_frame.add({type = 'label', caption = ({'rpg_settings.mana_label'})})
        label.style.font = 'default-bold'
        label.style.padding = 0
        label.style.left_padding = 10
        label.style.horizontal_align = 'left'
        label.style.vertical_align = 'bottom'
        label.style.font_color = {0.55, 0.55, 0.99}

        mana_frame.add({type = 'line'})

        local setting_grid_2 = mana_frame.add({type = 'table', column_count = 2})

        local mana_grid = mana_frame.add({type = 'table', column_count = 2})

        local enable_entity =
            setting_grid_2.add(
            {
                type = 'label',
                caption = ({'rpg_settings.magic_label'}),
                tooltip = ({'rpg_settings.magic_tooltip'})
            }
        )

        local enable_entity_style = enable_entity.style
        enable_entity_style.horizontally_stretchable = true
        enable_entity_style.height = 35
        enable_entity_style.vertical_align = 'center'

        local entity_input = setting_grid_2.add({type = 'flow'})
        local entity_input_style = entity_input.style
        entity_input_style.height = 35
        entity_input_style.vertical_align = 'center'
        entity_input_style.horizontal_align = 'right'
        local entity_mod
        if rpg_t[player.index].enable_entity_spawn then
            entity_mod = rpg_t[player.index].enable_entity_spawn
        else
            entity_mod = false
        end
        enable_entity_gui_input = create_input_element(entity_input, 'boolean', entity_mod)

        if not trusted[player.name] then
            enable_entity_gui_input.enabled = false
            enable_entity_gui_input.tooltip = ({'rpg_settings.not_trusted'})
        else
            enable_entity_gui_input.enabled = true
            enable_entity_gui_input.tooltip = ({'rpg_settings.tooltip_check'})
        end

        local conjure_label =
            mana_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.magic_spell'}),
                tooltip = ''
            }
        )

        local spells, names = RPG.rebuild_spells()

        local conjure_label_style = conjure_label.style
        conjure_label_style.horizontally_stretchable = true
        conjure_label_style.height = 35
        conjure_label_style.vertical_align = 'center'

        local conjure_input = mana_grid.add({type = 'flow'})
        local conjure_input_style = conjure_input.style
        conjure_input_style.height = 35
        conjure_input_style.vertical_align = 'center'
        conjure_gui_input = create_input_element(conjure_input, 'dropdown', false, names, rpg_t[player.index].dropdown_select_index)

        for _, entity in pairs(spells) do
            if entity.type == 'item' then
                conjure_label.tooltip = ({
                    'rpg_settings.magic_item_requirement',
                    conjure_label.tooltip,
                    entity.obj_to_create,
                    entity.mana_cost,
                    entity.level
                })
            elseif entity.type == 'entity' then
                conjure_label.tooltip = ({
                    'rpg_settings.magic_entity_requirement',
                    conjure_label.tooltip,
                    entity.obj_to_create,
                    entity.mana_cost,
                    entity.level
                })
            elseif entity.type == 'special' then
                conjure_label.tooltip = ({
                    'rpg_settings.magic_special_requirement',
                    conjure_label.tooltip,
                    entity.name,
                    entity.mana_cost,
                    entity.level
                })
            end
        end
        if not spells[rpg_t[player.index].dropdown_select_index1] then
            rpg_t[player.index].dropdown_select_index1 = 1
        end
        if not spells[rpg_t[player.index].dropdown_select_index2] then
            rpg_t[player.index].dropdown_select_index2 = 1
        end
        if not spells[rpg_t[player.index].dropdown_select_index3] then
            rpg_t[player.index].dropdown_select_index3 = 1
        end

        mana_frame.add({type = 'label', caption = {'rpg_settings.spell_gui_setup'}, tooltip = {'rpg_settings.spell_gui_tooltip'}})
        local spell_grid = mana_frame.add({type = 'table', column_count = 4, name = 'spell_grid_table'})
        spell_gui_input1 = create_input_element(spell_grid, 'dropdown', false, names, rpg_t[player.index].dropdown_select_index1)
        spell_gui_input1.style.maximal_width = 135
        spell_gui_input2 = create_input_element(spell_grid, 'dropdown', false, names, rpg_t[player.index].dropdown_select_index2)
        spell_gui_input2.style.maximal_width = 135
        spell_gui_input3 = create_input_element(spell_grid, 'dropdown', false, names, rpg_t[player.index].dropdown_select_index3)
        spell_gui_input3.style.maximal_width = 135
        spell_grid.add({type = 'sprite-button', name = spell_gui_button_name, sprite = 'item/raw-fish'})
    end

    if rpg_extra.enable_auto_allocate then
        local allocate_frame = inside_table.add({type = 'scroll-pane'})
        local allocate_style = allocate_frame.style
        allocate_style.vertically_squashable = true
        allocate_style.bottom_padding = 5
        allocate_style.left_padding = 5
        allocate_style.right_padding = 5
        allocate_style.top_padding = 5

        allocate_frame.add({type = 'line'})

        local a_label = allocate_frame.add({type = 'label', caption = ({'rpg_settings.allocation_settings_label'})})
        a_label.style.font = 'default-bold'
        a_label.style.padding = 0
        a_label.style.left_padding = 10
        a_label.style.horizontal_align = 'left'
        a_label.style.vertical_align = 'bottom'
        a_label.style.font_color = {0.55, 0.55, 0.99}

        allocate_frame.add({type = 'line'})

        local allocate_grid = allocate_frame.add({type = 'table', column_count = 2})

        local allocate_label =
            allocate_grid.add(
            {
                type = 'label',
                caption = ({'rpg_settings.allocation_label'}),
                tooltip = ''
            }
        )
        allocate_label.tooltip = ({'rpg_settings.allocation_tooltip'})

        local names = RPG.auto_allocate_nodes

        local allocate_label_style = allocate_label.style
        allocate_label_style.horizontally_stretchable = true
        allocate_label_style.height = 35
        allocate_label_style.vertical_align = 'center'

        local name_input = allocate_grid.add({type = 'flow'})
        local name_input_style = name_input.style
        name_input_style.height = 35
        name_input_style.vertical_align = 'center'
        auto_allocate_gui_input = create_input_element(name_input, 'dropdown', false, names, rpg_t[player.index].allocate_index)
    end

    local data = {
        reset_gui_input = reset_gui_input,
        magic_pickup_gui_input = magic_pickup_gui_input,
        movement_speed_gui_input = movement_speed_gui_input
    }

    if rpg_extra.enable_health_and_mana_bars then
        data.health_bar_gui_input = health_bar_gui_input
    end

    if rpg_extra.enable_mana then
        data.conjure_gui_input = conjure_gui_input
        data.spell_gui_input1 = spell_gui_input1
        data.spell_gui_input2 = spell_gui_input2
        data.spell_gui_input3 = spell_gui_input3
        data.enable_entity_gui_input = enable_entity_gui_input
    end

    if rpg_extra.enable_flame_boots then
        data.flame_boots_gui_input = flame_boots_gui_input
    end

    if rpg_extra.enable_explosive_bullets_globally then
        data.explosive_bullets_gui_input = explosive_bullets_gui_input
    end

    if rpg_extra.enable_stone_path then
        data.stone_path_gui_input = stone_path_gui_input
    end

    if rpg_extra.enable_one_punch then
        data.one_punch_gui_input = one_punch_gui_input
    end

    if rpg_extra.enable_auto_allocate then
        data.auto_allocate_gui_input = auto_allocate_gui_input
    end

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_button_name, caption = ({'rpg_settings.discard_changes'})})
    close_button.style = 'back_button'

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_button_name, caption = ({'rpg_settings.save_changes'})})
    save_button.style = 'confirm_button'

    Gui.set_data(save_button, data)

    player.opened = main_frame
end

return Public
