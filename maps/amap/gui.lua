local ICT = require 'maps.amap.ic.table'
local Color = require 'utils.color_presets'
local Gui = require 'utils.gui'
local Tabs = require 'comfy_panel.main'
local Event = require 'utils.event'
local rpgtable = require 'modules.rpg.table'
local Loot = require'maps.amap.loot'
local Public = {}
local Alert = require 'utils.alert'
--! Gui Frames
local save_add_player_button_name = Gui.uid_name()
local save_transfer_car_button_name = Gui.uid_name()
local discard_add_player_button_name = Gui.uid_name()
local discard_transfer_car_button_name = Gui.uid_name()
local main_frame_name = Gui.uid_name()
local draw_add_player_frame_name = Gui.uid_name()
local draw_transfer_car_frame_name = Gui.uid_name()
local main_toolbar_name = Gui.uid_name()
local cool = Gui.uid_name()
local gambel = Gui.uid_name()
local buyxp = Gui.uid_name()
local add_player_name = Gui.uid_name()
local transfer_car_name = Gui.uid_name()
local kick_player_name = Gui.uid_name()

local raise_event = script.raise_event
local add_toolbar
local remove_toolbar

local function increment(t, k)
    t[k] = true
end

local function decrement(t, k)
    t[k] = nil
end

local function create_player_table(player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        trust_system[player.index] = {
            [player.name] = true
        }
    end
    return trust_system[player.index]
end

local function does_player_table_exist(player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        return false
    else
        return true
    end
end

local function transfer_player_table(player, new_player)
    local trust_system = ICT.get('trust_system')
    if not trust_system[player.index] then
        return false
    end

    if player.index == new_player.index then
        return false
    end

    if not trust_system[new_player.index] then
        local Functions = require 'maps.amap.ic.functions'

        trust_system[new_player.index] = trust_system[player.index]
        local name = new_player.name

        if not trust_system[new_player.index][name] then
            increment(trust_system[new_player.index], name)
        end

        local cars = ICT.get('cars')
        local renders = ICT.get('renders')
        local c = Functions.get_owner_car_object(cars, player)
        local car = cars[c]
        car.owner = new_player.index

        Functions.render_owner_text(renders, player, car.entity, new_player)

        remove_toolbar(player)
        add_toolbar(new_player)

        trust_system[player.index] = nil
    else
        return false
    end

    return trust_system[new_player.index]
end

local function remove_main_frame(main_frame)
    Gui.remove_data_recursively(main_frame)
    main_frame.destroy()
end

local function draw_add_player(frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_add_player_frame_name,
            caption = 'Add Player',
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local add_player_frame = main_frame.add({type = 'textfield', text = 'Name of the player.'})
    add_player_frame.style.width = 140

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_add_player_button_name, caption = 'Discard'})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_add_player_button_name, caption = 'Save'})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, add_player_frame)
end

local function draw_transfer_car(frame)
    local main_frame =
        frame.add(
        {
            type = 'frame',
            name = draw_transfer_car_frame_name,
            caption = 'Transfer Car',
            direction = 'vertical'
        }
    )
    local main_frame_style = main_frame.style
    main_frame_style.width = 370
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0
    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 325

    local transfer_car_alert_frame = main_frame.add({type = 'label', caption = "Warning, this action can't be undone!"})
    transfer_car_alert_frame.style.font_color = {r = 255, g = 0, b = 0}
    local transfer_car_frame = main_frame.add({type = 'textfield', text = 'Name of the player.'})
    transfer_car_frame.style.width = 140

    local bottom_flow = main_frame.add({type = 'flow', direction = 'horizontal'})

    local left_flow = bottom_flow.add({type = 'flow'})
    left_flow.style.horizontal_align = 'left'
    left_flow.style.horizontally_stretchable = true

    local close_button = left_flow.add({type = 'button', name = discard_transfer_car_button_name, caption = 'Discard'})
    close_button.style = 'back_button'
    close_button.style.maximal_width = 100

    local right_flow = bottom_flow.add({type = 'flow'})
    right_flow.style.horizontal_align = 'right'

    local save_button = right_flow.add({type = 'button', name = save_transfer_car_button_name, caption = 'Save'})
    save_button.style = 'confirm_button'
    save_button.style.maximal_width = 100

    Gui.set_data(save_button, transfer_car_frame)
end

local function draw_players(data)
    local player_table = data.player_table
    local add_player_frame = data.add_player_frame
    local player = data.player
    local player_list = create_player_table(player)

    for p, _ in pairs(player_list) do
        Gui.set_data(add_player_frame, p)
        local t_label =
            player_table.add(
            {
                type = 'label',
                caption = p
            }
        )
        t_label.style.minimal_width = 75
        t_label.style.horizontal_align = 'center'

        local a_label =
            player_table.add(
            {
                type = 'label',
                caption = '✔️'
            }
        )
        a_label.style.minimal_width = 75
        a_label.style.horizontal_align = 'center'
        a_label.style.font = 'default-large-bold'

        local kick_flow = player_table.add {type = 'flow'}
        local kick_player_button =
            kick_flow.add(
            {
                type = 'button',
                caption = 'Kick ' .. p,
                name = kick_player_name
            }
        )
        if player.name == t_label.caption then
            kick_player_button.enabled = false
        end
        kick_player_button.style.minimal_width = 75
        Gui.set_data(kick_player_button, p)
    end
end

local function draw_main_frame(player)
    local main_frame =
        player.gui.screen.add(
        {
            type = 'frame',
            name = main_frame_name,
            caption = 'Car Settings',
            direction = 'vertical',
            style = 'inner_frame_in_outer_frame'
        }
    )

    main_frame.auto_center = true
    local main_frame_style = main_frame.style
    main_frame_style.width = 400
    main_frame_style.use_header_filler = true

    local inside_frame = main_frame.add {type = 'frame', style = 'inside_shallow_frame'}
    local inside_frame_style = inside_frame.style
    inside_frame_style.padding = 0

    local inside_table = inside_frame.add {type = 'table', column_count = 1}
    local inside_table_style = inside_table.style
    inside_table_style.vertical_spacing = 5
    inside_table_style.top_padding = 10
    inside_table_style.left_padding = 10
    inside_table_style.right_padding = 0
    inside_table_style.bottom_padding = 10
    inside_table_style.width = 350

    local add_player_frame = inside_table.add({type = 'button', caption = 'Add Player', name = add_player_name})
    local transfer_car_frame = inside_table.add({type = 'button', caption = 'Transfer Car', name = transfer_car_name})

    local player_table =
        inside_table.add {
        type = 'table',
        column_count = 3,
        draw_horizontal_lines = true,
        draw_vertical_lines = true,
        vertical_centering = true
    }
    local player_table_style = player_table.style
    player_table_style.vertical_spacing = 10
    player_table_style.width = 350
    player_table_style.horizontal_spacing = 30

    local name_label =
        player_table.add(
        {
            type = 'label',
            caption = 'Name',
            tooltip = ''
        }
    )
    name_label.style.minimal_width = 75
    name_label.style.horizontal_align = 'center'

    local trusted_label =
        player_table.add(
        {
            type = 'label',
            caption = 'Allowed',
            tooltip = ''
        }
    )
    trusted_label.style.minimal_width = 75
    trusted_label.style.horizontal_align = 'center'

    local operations_label =
        player_table.add(
        {
            type = 'label',
            caption = 'Operations',
            tooltip = ''
        }
    )
    operations_label.style.minimal_width = 75
    operations_label.style.horizontal_align = 'center'

    local data = {
        player_table = player_table,
        add_player_frame = add_player_frame,
        transfer_car_frame = transfer_car_frame,
        player = player
    }
    draw_players(data)

    player.opened = main_frame
end

local function toggle(player, recreate)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if recreate and main_frame then
        local location = main_frame.location
        remove_main_frame(main_frame)
        draw_main_frame(player, location)
        return
    end
    if main_frame then
        remove_main_frame(main_frame)
        Tabs.comfy_panel_restore_left_gui(player)
    else
        Tabs.comfy_panel_clear_left_gui(player)
        draw_main_frame(player)
    end
end

add_toolbar = function(player, remove)
    if remove then
        if player.gui.top[main_toolbar_name] then
		player.gui.top[cool].destroy()
		player.gui.top[buyxp].destroy()
    player.gui.top[gambel].destroy()
            player.gui.top[main_toolbar_name].destroy()

            return
        end
    end
    if player.gui.top[main_toolbar_name] then
        return
    end

    local tooltip = 'contorl who can enter your car.'
    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/spidertron',
            name = main_toolbar_name,
            tooltip = tooltip
        }
    )

    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/logistic-chest-storage',
            name = cool,
            tooltip = {'amap.openchest'}
        }
    )
    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/coin',
            name = gambel,
            tooltip = {'amap.gambel'}
        }
    )
	    player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/rocket-part',
            name = buyxp,
            tooltip = {'amap.buyxp'}
        }
    )
end

remove_toolbar = function(player)
    local screen = player.gui.screen
    local main_frame = screen[main_frame_name]

    if main_frame and main_frame.valid then
        remove_main_frame(main_frame)
    end

    if player.gui.top[main_toolbar_name] then
        player.gui.top[main_toolbar_name].destroy()
		player.gui.top[cool].destroy()
		player.gui.top[buyxp].destroy()
    player.gui.top[gambel].destroy()
        return
    end
end

Gui.on_click(
    add_player_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_add_player_frame_name]
        if not player_frame or not player_frame.valid then
            draw_add_player(frame)
        else
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    transfer_car_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_transfer_car_frame_name]
        if not player_frame or not player_frame.valid then
            draw_transfer_car(frame)
        else
            player_frame.destroy()
        end
    end
)
Gui.on_click(
    gambel ,
    function(event)
        local player = event.player
        local something = player.get_inventory(defines.inventory.chest)
          for k, v in pairs(something.get_contents()) do
             local t = {name = k, count = v}
      if t.name == 'coin' then
      if v > 999 then
        player.remove_item{name='coin', count = '1000'}
	   local roll = math.random(1,100)
     if roll <= 36 then
       player.insert{name='coin', count = '2500'}
	   player.print({'amap.gambel1'})
	   return
	   else
	   player.print({'amap.gambel2'})
	   return
    end
	else
		player.print({'amap.noenough'})
		return
	end
	end
	end
    end
)

Gui.on_click(
    cool ,
    function(event)
        local player = event.player
		local something = player.get_inventory(defines.inventory.chest)
     for k, v in pairs(something.get_contents()) do
        local t = {name = k, count = v}
 if t.name == 'coin' then
 if v > 2999 then
 player.remove_item{name='coin', count = '3000'}
 local luck = math.floor(math.random(1,130))
 player.print({'amap.lucknb'})
 player.print(luck)
    local magic = luck*5+100
       local msg = {'amap.whatopen'}
	Loot.cool(player.surface, player.surface.find_non_colliding_position("steel-chest", player.position, 20, 1, true) or player.position, 'steel-chest', magic)
		  Alert.alert_player(player, 5, msg)
		  return
		  else
		  player.print({'amap.noenough'})
		  return
 end
 end
   end
    end
)
Gui.on_click(
    buyxp ,
    function(event)
        local player = event.player
		local something = player.get_inventory(defines.inventory.chest)
     for k, v in pairs(something.get_contents()) do
        local t = {name = k, count = v}
 if t.name == 'coin' then
 if v > 4999 then
 player.remove_item{name='coin', count = '5000'}
 local rpg_t = rpgtable.get('rpg_t')

 rpg_t[player.index].xp = rpg_t[player.index].xp +1000
       local msg = {'amap.buyover'}
		  Alert.alert_player(player, 5, msg)
		  return
		  else
		  player.print({'amap.noenough'})
		  return
 end
 end
   end
    end
)
Gui.on_click(
    save_add_player_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local add_player_frame = Gui.get_data(event.element)

        if frame and frame.valid then
            if add_player_frame and add_player_frame.valid and add_player_frame.text then
                local text = add_player_frame.text
                if not text then
                    return
                end
                local player_to_add = game.get_player(text)
                if not player_to_add or not player_to_add.valid then
                    return player.print('Target player was not valid.', Color.warning)
                end

                local name = player_to_add.name

                if not player_list[name] then
                    player.print(name .. ' was added to your vehicle.', Color.info)
                    player_to_add.print(player.name .. ' added you to their vehicle. You may now enter it.', Color.info)
                    increment(player_list, name)
                else
                    return player.print('Target player is already trusted.', Color.warning)
                end

                remove_main_frame(event.element)

                if player.gui.screen[main_frame_name] then
                    toggle(player, true)
                end
            end
        end
    end
)

Gui.on_click(
    save_transfer_car_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local transfer_car_frame = Gui.get_data(event.element)

        if frame and frame.valid then
            if transfer_car_frame and transfer_car_frame.valid and transfer_car_frame.text then
                local text = transfer_car_frame.text
                if not text then
                    return
                end
                local player_to_add = game.get_player(text)
                if not player_to_add or not player_to_add.valid then
                    return player.print('Target player was not valid.', Color.warning)
                end

                local name = player_to_add.name
                local does_player_have_a_car = does_player_table_exist(name)
                if does_player_have_a_car then
                    return player.print(name .. ' already has a vehicle.', Color.warning)
                end

                local to_add = game.get_player(name)
                if not (to_add and to_add.valid) then
                    return player.print(name .. ' does not exist.', Color.warning)
                end

                local success = transfer_player_table(player, to_add)
                if not success then
                    player.print('Please try again.', Color.warning)
                else
                    player.print('You have successfully transferred your car to ' .. name, Color.success)
                    to_add.print('You have become the rightfully owner of ' .. player.name .. "'s car!", Color.success)
                end

                remove_main_frame(event.element)

                if player.gui.screen[main_frame_name] then
                    player.gui.screen[main_frame_name].destroy()
                end
            end
        end
    end
)

Gui.on_click(
    kick_player_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local player_list = create_player_table(player)

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        local player_name = Gui.get_data(event.element)
        local this = ICT.get()

        if frame and frame.valid then
            if not player_name then
                return
            end
            local target = game.get_player(player_name)
            if not target or not target.valid then
                player.print('Target player was not valid.', Color.warning)
                return
            end
            local name = target.name

            if player_list[name] then
                player.print(name .. ' was removed from your vehicle.', Color.info)
                decrement(player_list, name)
                raise_event(
                    ICT.events.on_player_kicked_from_surface,
                    {
                        player = player,
                        target = target,
                        this = this
                    }
                )
            end

            remove_main_frame(event.element)

            if player.gui.screen[main_frame_name] then
                toggle(player, true)
            end
        end
    end
)

Gui.on_click(
    discard_add_player_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_add_player_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    discard_transfer_car_button_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]
        if not frame or not frame.valid then
            return
        end
        local player_frame = frame[draw_transfer_car_frame_name]

        if player_frame and player_frame.valid then
            player_frame.destroy()
        end
    end
)

Gui.on_click(
    main_toolbar_name,
    function(event)
        local player = event.player
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            frame.destroy()
        else
            draw_main_frame(player)
        end
    end
)

Public.draw_main_frame = draw_main_frame
Public.toggle = toggle
Public.add_toolbar = add_toolbar
Public.remove_toolbar = remove_toolbar

Event.add(
    defines.events.on_gui_closed,
    function(event)
        local player = game.get_player(event.player_index)
        if not player or not player.valid or not player.character then
            return
        end

        local screen = player.gui.screen
        local frame = screen[main_frame_name]

        if frame and frame.valid then
            frame.destroy()
        end
    end
)

return Public
