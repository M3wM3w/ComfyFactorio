--antigrief things made by mewmew

local Event = require 'utils.event'
local Jailed = require 'utils.jail_data'
local Tabs = require 'comfy_panel.main'
local AntiGrief = require 'antigrief'

local lower = string.lower

local function jail(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    Jailed.try_ul_data(player.name, true, source_player.name)
end

local function free(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    Jailed.try_ul_data(player.name, false, source_player.name)
end

local bring_player_messages = {
    'Come here my friend!',
    'Papers, please.',
    'What are you up to?'
}

local function bring_player(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if player.driving == true then
        source_player.print('Target player is in a vehicle, teleport not available.', {r = 0.88, g = 0.88, b = 0.88})
        return
    end
    local pos = source_player.surface.find_non_colliding_position('character', source_player.position, 50, 1)
    if pos then
        player.teleport(pos, source_player.surface)
        game.print(
            player.name ..
                ' has been teleported to ' ..
                    source_player.name .. '. ' .. bring_player_messages[math.random(1, #bring_player_messages)],
            {r = 0.98, g = 0.66, b = 0.22}
        )
    end
end

local go_to_player_messages = {
    'Papers, please.',
    'What are you up to?'
}
local function go_to_player(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    local pos = player.surface.find_non_colliding_position('character', player.position, 50, 1)
    if pos then
        source_player.teleport(pos, player.surface)
        game.print(
            source_player.name ..
                ' is visiting ' .. player.name .. '. ' .. go_to_player_messages[math.random(1, #go_to_player_messages)],
            {r = 0.98, g = 0.66, b = 0.22}
        )
    end
end

local function spank(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if player.character then
        if player.character.health > 1 then
            player.character.damage(1, 'player')
        end
        player.character.health = player.character.health - 5
        player.surface.create_entity({name = 'water-splash', position = player.position})
        game.print(source_player.name .. ' spanked ' .. player.name, {r = 0.98, g = 0.66, b = 0.22})
    end
end

local damage_messages = {
    ' recieved a love letter from ',
    ' recieved a strange package from '
}
local function damage(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if player.character then
        if player.character.health > 1 then
            player.character.damage(1, 'player')
        end
        player.character.health = player.character.health - 125
        player.surface.create_entity({name = 'big-explosion', position = player.position})
        game.print(
            player.name .. damage_messages[math.random(1, #damage_messages)] .. source_player.name,
            {r = 0.98, g = 0.66, b = 0.22}
        )
    end
end

local kill_messages = {
    ' did not obey the law.',
    ' should not have triggered the admins.',
    ' did not respect authority.',
    ' had a strange accident.',
    ' was struck by lightning.'
}
local function kill(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if player.character then
        player.character.die('player')
        game.print(player.name .. kill_messages[math.random(1, #kill_messages)], {r = 0.98, g = 0.66, b = 0.22})
        admin_only_message(source_player.name .. ' killed ' .. player.name)
    end
end

local enemy_messages = {
    'Shoot on sight!',
    'Wanted dead or alive!'
}
local function enemy(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    if not game.forces.enemy_players then
        game.create_force('enemy_players')
    end
    player.force = game.forces.enemy_players
    game.print(
        player.name .. ' is now an enemy! ' .. enemy_messages[math.random(1, #enemy_messages)],
        {r = 0.95, g = 0.15, b = 0.15}
    )
    admin_only_message(source_player.name .. ' has turned ' .. player.name .. ' into an enemy')
end

local function ally(player, source_player)
    if player.name == source_player.name then
        return player.print("You can't select yourself!", {r = 1, g = 0.5, b = 0.1})
    end
    player.force = game.forces.player
    game.print(player.name .. ' is our ally again!', {r = 0.98, g = 0.66, b = 0.22})
    admin_only_message(source_player.name .. ' made ' .. player.name .. ' our ally')
end

local function turn_off_global_speakers(player)
    local counter = 0
    for _, surface in pairs(game.surfaces) do
        local speakers = surface.find_entities_filtered({name = 'programmable-speaker'})
        for i, speaker in pairs(speakers) do
            if speaker.parameters.playback_globally == true then
                speaker.surface.create_entity({name = 'massive-explosion', position = speaker.position})
                speaker.die('player')
                counter = counter + 1
            end
        end
    end
    if counter == 0 then
        return
    end
    if counter == 1 then
        game.print(player.name .. ' has nuked ' .. counter .. ' global speaker.', {r = 0.98, g = 0.66, b = 0.22})
    else
        game.print(player.name .. ' has nuked ' .. counter .. ' global speakers.', {r = 0.98, g = 0.66, b = 0.22})
    end
end

local function delete_all_blueprints(player)
    local counter = 0
    for _, surface in pairs(game.surfaces) do
        for _, ghost in pairs(surface.find_entities_filtered({type = {'entity-ghost', 'tile-ghost'}})) do
            ghost.destroy()
            counter = counter + 1
        end
    end
    if counter == 0 then
        return
    end
    if counter == 1 then
        game.print(counter .. ' blueprint has been cleared!', {r = 0.98, g = 0.66, b = 0.22})
    else
        game.print(counter .. ' blueprints have been cleared!', {r = 0.98, g = 0.66, b = 0.22})
    end
    admin_only_message(player.name .. ' has cleared all blueprints.')
end

local function create_mini_camera_gui(player, caption, position, surface)
    if player.gui.center['mini_camera'] then
        player.gui.center['mini_camera'].destroy()
    end
    local frame = player.gui.center.add({type = 'frame', name = 'mini_camera', caption = caption})
    surface = tonumber(surface)
    local camera =
        frame.add(
        {
            type = 'camera',
            name = 'mini_cam_element',
            position = position,
            zoom = 0.6,
            surface_index = game.surfaces[surface].index
        }
    )
    camera.style.minimal_width = 640
    camera.style.minimal_height = 480
end

local function filter_brackets(str)
    return (string.find(str, '%[') ~= nil)
end

local function match_test(value, pattern)
    return lower(value:gsub('-', ' ')):find(pattern)
end

local function contains_text(key, value, search_text)
    if filter_brackets(search_text) then
        return false
    end
    if value then
        if not match_test(key[value], search_text) then
            return false
        end
    else
        if not match_test(key, search_text) then
            return false
        end
    end
    return true
end

local function draw_events(data)
    local frame = data.frame
    local antigrief = data.antigrief
    local search_text = data.search_text or nil
    local history = frame['admin_history_select'].items[frame['admin_history_select'].selected_index]

    local history_index = {
        ['Capsule History'] = antigrief.capsule_history,
        ['Friendly Fire History'] = antigrief.friendly_fire_history,
        ['Mining History'] = antigrief.mining_history,
        ['Landfill History'] = antigrief.landfill_history,
        ['Corpse Looting History'] = antigrief.corpse_history,
        ['Cancel Crafting History'] = antigrief.cancel_crafting_history
    }

    local scroll_pane
    if frame.datalog then
        frame.datalog.clear()
    else
        scroll_pane =
            frame.add(
            {
                type = 'scroll-pane',
                name = 'datalog',
                direction = 'vertical',
                horizontal_scroll_policy = 'never',
                vertical_scroll_policy = 'auto'
            }
        )
        scroll_pane.style.maximal_height = 200
    end

    local target_player_name = frame['admin_player_select'].items[frame['admin_player_select'].selected_index]
    if game.players[target_player_name] then
        local target_player = game.players[target_player_name].index

        for _, value in pairs(history_index[history][target_player]) do
            if search_text then
                local success = contains_text(value, nil, search_text)
                if not success then
                    goto continue
                end
            end

            frame.datalog.add(
                {
                    type = 'label',
                    caption = value,
                    tooltip = 'Click to open mini camera.'
                }
            )
            ::continue::
        end
    else
        for key, value in pairs(history_index[history]) do
            for t = 1, #value do
                if search_text then
                    local success = contains_text(value, t, search_text)
                    if not success then
                        goto continue
                    end
                end

                frame.datalog.add(
                    {
                        type = 'label',
                        caption = history_index[history][key][t],
                        tooltip = 'Click to open mini camera.'
                    }
                )
                ::continue::
            end
        end
    end
end

local function text_changed(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end

    local antigrief = AntiGrief.get()
    local player = game.players[event.player_index]

    local frame = Tabs.comfy_panel_get_active_frame(player)
    if not frame then
        return
    end
    if frame.name ~= 'Admin' then
        return
    end

    local data = {
        frame = frame,
        antigrief = antigrief,
        search_text = element.text
    }

    draw_events(data)
end

local create_admin_panel = (function(player, frame)
    local antigrief = AntiGrief.get()
    frame.clear()

    local player_names = {}
    for _, p in pairs(game.connected_players) do
        table.insert(player_names, tostring(p.name))
    end
    table.insert(player_names, 'Select Player')

    local selected_index = #player_names
    if global.admin_panel_selected_player_index then
        if global.admin_panel_selected_player_index[player.name] then
            if player_names[global.admin_panel_selected_player_index[player.name]] then
                selected_index = global.admin_panel_selected_player_index[player.name]
            end
        end
    end

    local drop_down =
        frame.add(
        {type = 'drop-down', name = 'admin_player_select', items = player_names, selected_index = selected_index}
    )
    drop_down.style.minimal_width = 326
    drop_down.style.right_padding = 12
    drop_down.style.left_padding = 12

    local t = frame.add({type = 'table', column_count = 3})
    local buttons = {
        t.add(
            {
                type = 'button',
                caption = 'Jail',
                name = 'jail',
                tooltip = 'Jails the player, they will no longer be able to perform any actions except writing in chat.'
            }
        ),
        t.add({type = 'button', caption = 'Free', name = 'free', tooltip = 'Frees the player from jail.'}),
        t.add(
            {
                type = 'button',
                caption = 'Bring Player',
                name = 'bring_player',
                tooltip = 'Teleports the selected player to your position.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Make Enemy',
                name = 'enemy',
                tooltip = 'Sets the selected players force to enemy_players.          DO NOT USE IN PVP MAPS!!'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Make Ally',
                name = 'ally',
                tooltip = 'Sets the selected players force back to the default player force.           DO NOT USE IN PVP MAPS!!'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Go to Player',
                name = 'go_to_player',
                tooltip = 'Teleport yourself to the selected player.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Spank',
                name = 'spank',
                tooltip = 'Hurts the selected player with minor damage. Can not kill the player.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Damage',
                name = 'damage',
                tooltip = 'Damages the selected player with greater damage. Can not kill the player.'
            }
        ),
        t.add({type = 'button', caption = 'Kill', name = 'kill', tooltip = 'Kills the selected player instantly.'})
    }
    for _, button in pairs(buttons) do
        button.style.font = 'default-bold'
        --button.style.font_color = { r=0.99, g=0.11, b=0.11}
        button.style.font_color = {r = 0.99, g = 0.99, b = 0.99}
        button.style.minimal_width = 106
    end

    local line = frame.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    local l = frame.add({type = 'label', caption = 'Global Actions:'})
    local t = frame.add({type = 'table', column_count = 2})
    local buttons = {
        t.add(
            {
                type = 'button',
                caption = 'Destroy global speakers',
                name = 'turn_off_global_speakers',
                tooltip = 'Destroys all speakers that are set to play sounds globally.'
            }
        ),
        t.add(
            {
                type = 'button',
                caption = 'Delete blueprints',
                name = 'delete_all_blueprints',
                tooltip = 'Deletes all placed blueprints on the map.'
            }
        )
        ---	t.add({type = "button", caption = "Cancel all deconstruction orders", name = "remove_all_deconstruction_orders"})
    }
    for _, button in pairs(buttons) do
        button.style.font = 'default-bold'
        button.style.font_color = {r = 0.98, g = 0.66, b = 0.22}
        button.style.minimal_width = 80
    end

    local line = frame.add {type = 'line'}
    line.style.top_margin = 8
    line.style.bottom_margin = 8

    local histories = {}
    if antigrief.capsule_history then
        table.insert(histories, 'Capsule History')
    end
    if antigrief.friendly_fire_history then
        table.insert(histories, 'Friendly Fire History')
    end
    if antigrief.mining_history then
        table.insert(histories, 'Mining History')
    end
    if antigrief.landfill_history then
        table.insert(histories, 'Landfill History')
    end
    if antigrief.corpse_history then
        table.insert(histories, 'Corpse Looting History')
    end
    if antigrief.cancel_crafting_history then
        table.insert(histories, 'Cancel Crafting History')
    end

    if #histories == 0 then
        return
    end

    local search_table = frame.add({type = 'table', column_count = 2})
    search_table.add({type = 'label', caption = 'Search: '})
    local search_text = search_table.add({type = 'textfield'})
    search_text.style.width = 140

    local l = frame.add({type = 'label', caption = '----------------------------------------------'})
    l.style.font = 'default-listbox'
    l.style.font_color = {r = 0.98, g = 0.66, b = 0.22}

    local selected_index_2 = 1
    if global.admin_panel_selected_history_index then
        if global.admin_panel_selected_history_index[player.name] then
            selected_index_2 = global.admin_panel_selected_history_index[player.name]
        end
    end

    local drop_down_2 =
        frame.add(
        {type = 'drop-down', name = 'admin_history_select', items = histories, selected_index = selected_index_2}
    )
    drop_down_2.style.right_padding = 12
    drop_down_2.style.left_padding = 12

    local data = {
        frame = frame,
        antigrief = antigrief
    }

    draw_events(data)
end)

local admin_functions = {
    ['jail'] = jail,
    ['free'] = free,
    ['bring_player'] = bring_player,
    ['spank'] = spank,
    ['damage'] = damage,
    ['kill'] = kill,
    ['enemy'] = enemy,
    ['ally'] = ally,
    ['go_to_player'] = go_to_player
}

local admin_global_functions = {
    ['turn_off_global_speakers'] = turn_off_global_speakers,
    ['delete_all_blueprints'] = delete_all_blueprints
}

local function get_surface_from_string(str)
    if not str then
        return
    end
    if str == '' then
        return
    end
    str = string.lower(str)
    local start = string.find(str, 'surface:')
    local sname = string.len(str)
    local surface = string.sub(str, start + 8, sname)
    if not surface then
        return false
    end

    return surface
end

local function get_position_from_string(str)
    if not str then
        return
    end
    if str == '' then
        return
    end
    str = string.lower(str)
    local x_pos = string.find(str, 'x:')
    local y_pos = string.find(str, 'y:')
    if not x_pos then
        return false
    end
    if not y_pos then
        return false
    end
    x_pos = x_pos + 2
    y_pos = y_pos + 2

    local a = 1
    for i = 1, string.len(str), 1 do
        local s = string.sub(str, x_pos + i, x_pos + i)
        if not s then
            break
        end
        if string.byte(s) == 32 then
            break
        end
        a = a + 1
    end
    local x = string.sub(str, x_pos, x_pos + a)

    local a = 1
    for i = 1, string.len(str), 1 do
        local s = string.sub(str, y_pos + i, y_pos + i)
        if not s then
            break
        end
        if string.byte(s) == 32 then
            break
        end
        a = a + 1
    end

    local y = string.sub(str, y_pos, y_pos + a)
    x = tonumber(x)
    y = tonumber(y)
    local position = {x = x, y = y}
    return position
end

local function on_gui_click(event)
    local player = game.players[event.player_index]
    local frame = Tabs.comfy_panel_get_active_frame(player)
    if not frame then
        return
    end

    if not event.element.valid then
        return
    end

    local name = event.element.name

    if name == 'mini_camera' or name == 'mini_cam_element' then
        player.gui.center['mini_camera'].destroy()
        return
    end

    if frame.name ~= 'Admin' then
        return
    end

    if admin_functions[name] then
        local target_player_name = frame['admin_player_select'].items[frame['admin_player_select'].selected_index]
        if not target_player_name then
            return
        end
        if target_player_name == 'Select Player' then
            player.print('No target player selected.', {r = 0.88, g = 0.88, b = 0.88})
            return
        end
        local target_player = game.players[target_player_name]
        if target_player.connected == true then
            admin_functions[name](target_player, player)
        end
        return
    end

    if admin_global_functions[name] then
        admin_global_functions[name](player)
        return
    end

    if not frame then
        return
    end
    if not event.element.caption then
        return
    end
    local position = get_position_from_string(event.element.caption)
    if not position then
        return
    end

    local surface = get_surface_from_string(event.element.caption)
    if not surface then
        return
    end

    if player.gui.center['mini_camera'] then
        if player.gui.center['mini_camera'].caption == event.element.caption then
            player.gui.center['mini_camera'].destroy()
            return
        end
    end

    create_mini_camera_gui(player, event.element.caption, position, surface)
end

local function on_gui_selection_state_changed(event)
    local player = game.players[event.player_index]
    local name = event.element.name

    if name == 'admin_history_select' then
        if not global.admin_panel_selected_history_index then
            global.admin_panel_selected_history_index = {}
        end
        global.admin_panel_selected_history_index[player.name] = event.element.selected_index

        local frame = Tabs.comfy_panel_get_active_frame(player)
        if not frame then
            return
        end
        if frame.name ~= 'Admin' then
            return
        end

        create_admin_panel(player, frame)
    end
    if name == 'admin_player_select' then
        if not global.admin_panel_selected_player_index then
            global.admin_panel_selected_player_index = {}
        end
        global.admin_panel_selected_player_index[player.name] = event.element.selected_index

        local frame = Tabs.comfy_panel_get_active_frame(player)
        if not frame then
            return
        end
        if frame.name ~= 'Admin' then
            return
        end

        create_admin_panel(player, frame)
    end
end

comfy_panel_tabs['Admin'] = {gui = create_admin_panel, admin = true}

Event.add(defines.events.on_gui_text_changed, text_changed)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)
