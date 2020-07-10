local Global = require 'utils.global'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'

local this = {
    data = {}
}
local Public = {}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local space = {
    minimal_height = 10,
    top_padding = 0,
    bottom_padding = 0
}

local function addStyle(guiIn, styleIn)
    for k, v in pairs(styleIn) do
        guiIn.style[k] = v
    end
end

local function adjustSpace(guiIn)
    addStyle(guiIn.add {type = 'line', direction = 'horizontal'}, space)
end

local function validate_object(obj)
    if not obj then
        return false
    end
    if not obj.valid then
        return false
    end
    return true
end

local function player_opened(player)
    local data = this.data[player.index]

    if not data then
        return false
    end

    local opened = data.player_opened

    if not validate_object(opened) then
        return false
    end

    return true, opened
end

local function last_tab(player)
    local data = this.data[player.index]

    if not data then
        return false
    end

    local tab = data.last_tab
    if not tab then
        return false
    end

    return true, tab
end

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

local function close_player_inventory(player)
    local data = this.data[player.index]

    if not data then
        return
    end

    local gui = player.gui.screen

    if not validate_object(gui) then
        return
    end

    local element = gui.inventory_gui

    if not validate_object(element) then
        return
    end

    element.destroy()
    Public.reset_table(player)
end

local function redraw_inventory(gui, source, target, caption, panel_type)
    gui.clear()

    local items_table = gui.add({type = 'table', column_count = 11})
    local types = game.item_prototypes

    local screen = source.gui.screen

    if not validate_object(screen) then
        return
    end

    local inventory_gui = screen.inventory_gui

    inventory_gui.caption = 'Inventory of ' .. target.name

    for name, opts in pairs(panel_type) do
        local flow = items_table.add({type = 'flow'})
        flow.style.vertical_align = 'bottom'

        local button =
            flow.add(
            {
                type = 'sprite-button',
                sprite = 'item/' .. name,
                number = opts,
                name = name,
                tooltip = types[name].localised_name,
                style = 'slot_button'
            }
        )
        button.enabled = false

        if caption == 'Armor' then
            if target.get_inventory(5)[1].grid then
                local p_armor = target.get_inventory(5)[1].grid.get_contents()
                for k, v in pairs(p_armor) do
                    local armor_gui =
                        flow.add(
                        {
                            type = 'sprite-button',
                            sprite = 'item/' .. k,
                            number = v,
                            name = k,
                            tooltip = types[name].localised_name,
                            style = 'slot_button'
                        }
                    )
                    armor_gui.enabled = false
                end
            end
        end
    end
end

local function add_inventory(panel, source, target, caption, panel_type)
    local data = this.data[source.index]
    data.panel_type = data.panel_type or {}
    local pane_name = panel.add({type = 'tab', caption = caption, name = caption})
    local scroll_pane =
        panel.add {
        type = 'scroll-pane',
        name = caption .. 'tab',
        direction = 'vertical',
        vertical_scroll_policy = 'always',
        horizontal_scroll_policy = 'never'
    }
    scroll_pane.style.maximal_height = 200
    scroll_pane.style.horizontally_stretchable = true
    scroll_pane.style.minimal_height = 200
    scroll_pane.style.right_padding = 0
    panel.add_tab(pane_name, scroll_pane)

    data.panel_type[caption] = panel_type

    redraw_inventory(scroll_pane, source, target, caption, panel_type)
end

local function open_inventory(source, target)
    if not validate_player(source) then
        return
    end

    if not validate_player(target) then
        return
    end

    local screen = source.gui.screen

    if not validate_object(screen) then
        return
    end

    local inventory_gui = screen.inventory_gui
    if inventory_gui then
        close_player_inventory(source)
    end

    local frame =
        screen.add(
        {
            type = 'frame',
            caption = 'Inventory',
            direction = 'vertical',
            name = 'inventory_gui'
        }
    )

    frame.auto_center = true
    source.opened = frame
    frame.style.minimal_width = 500
    frame.style.minimal_height = 250

    adjustSpace(frame)

    local panel = frame.add({type = 'tabbed-pane', name = 'tabbed_pane'})
    panel.selected_tab_index = 1

    this.data[source.index].player_opened = target
    this.data[source.index].last_tab = 'Main'

    local main = target.get_main_inventory().get_contents()
    local armor = target.get_inventory(defines.inventory.character_armor).get_contents()
    local guns = target.get_inventory(defines.inventory.character_guns).get_contents()
    local ammo = target.get_inventory(defines.inventory.character_ammo).get_contents()
    local trash = target.get_inventory(defines.inventory.character_trash).get_contents()

    local types = {
        ['Main'] = main,
        ['Armor'] = armor,
        ['Guns'] = guns,
        ['Ammo'] = ammo,
        ['Trash'] = trash
    }

    for k, v in pairs(types) do
        if v ~= nil then
            add_inventory(panel, source, target, k, v)
        end
    end
end

local function on_gui_click(event)
    local player = game.players[event.player_index]

    local element = event.element

    if not element or not element.valid then
        return
    end

    local types = {
        ['Main'] = true,
        ['Armor'] = true,
        ['Guns'] = true,
        ['Ammo'] = true,
        ['Trash'] = true
    }

    local name = element.name

    if not types[name] then
        return
    end

    local data = this.data[player.index]
    if not data then
        return
    end

    data.last_tab = name

    local valid, target = player_opened(player)
    if valid then
        local main = target.get_main_inventory().get_contents()
        local armor = target.get_inventory(defines.inventory.character_armor).get_contents()
        local guns = target.get_inventory(defines.inventory.character_guns).get_contents()
        local ammo = target.get_inventory(defines.inventory.character_ammo).get_contents()
        local trash = target.get_inventory(defines.inventory.character_trash).get_contents()

        local target_types = {
            ['Main'] = main,
            ['Armor'] = armor,
            ['Guns'] = guns,
            ['Ammo'] = ammo,
            ['Trash'] = trash
        }
        local frame = Public.get_active_frame(player)
        local panel_type = target_types[name]

        redraw_inventory(frame, player, target, name, panel_type)
    end
end
local function gui_closed(event)
    local player = game.players[event.player_index]

    local type = event.gui_type

    if type == defines.gui_type.custom then
        local data = this.data[player.index]
        if not data then
            return
        end
        close_player_inventory(player)
    end
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]

    if not this.data[player.index] then
        this.data[player.index] = {}
    end
end

local function on_pre_player_left_game(event)
    local player = game.players[event.player_index]
    close_player_inventory(player)
end

local function update_gui()
    for _, player in pairs(game.connected_players) do
        local valid, target = player_opened(player)
        local success, tab = last_tab(player)

        if valid then
            if success then
                local main = target.get_main_inventory().get_contents()
                local armor = target.get_inventory(defines.inventory.character_armor).get_contents()
                local guns = target.get_inventory(defines.inventory.character_guns).get_contents()
                local ammo = target.get_inventory(defines.inventory.character_ammo).get_contents()
                local trash = target.get_inventory(defines.inventory.character_trash).get_contents()

                local types = {
                    ['Main'] = main,
                    ['Armor'] = armor,
                    ['Guns'] = guns,
                    ['Ammo'] = ammo,
                    ['Trash'] = trash
                }

                local frame = Public.get_active_frame(player)
                local panel_type = types[tab]
                if frame then
                    if frame.name == tab .. 'tab' then
                        redraw_inventory(frame, player, target, tab, panel_type)
                    end
                end
            end
        else
            close_player_inventory(player)
        end
    end
end

commands.add_command(
    'inventory',
    'Opens a players inventory!',
    function(cmd)
        local player = game.player

        if validate_player(player) then
            if not cmd.parameter then
                return
            end
            local target_player = game.players[cmd.parameter]

            if target_player == player then
                return player.print('Cannot open self.', Color.warning)
            end

            local valid, opened = player_opened(player)
            if valid then
                if target_player == opened then
                    return player.print('You are already viewing this players inventory.', Color.warning)
                end
            end

            if validate_player(target_player) then
                open_inventory(player, target_player)
            else
                player.print('Please type a name of a player who is connected.', Color.warning)
            end
        else
            return
        end
    end
)

function Public.get_active_frame(player)
    if not player.gui.screen.inventory_gui then
        return false
    end
    return player.gui.screen.inventory_gui.tabbed_pane.tabs[
        player.gui.screen.inventory_gui.tabbed_pane.selected_tab_index
    ].content
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.reset_table(player)
    if validate_player(player) then
        local data = this.data[player.index]
        for k in pairs(data) do
            this.data[player.index][k] = nil
        end
    end
end

Event.add(defines.events.on_player_main_inventory_changed, update_gui)
Event.add(defines.events.on_gui_closed, gui_closed)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)

return Public
