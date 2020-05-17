local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {
    gui = {},
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

local function build_prototype_data(item_name)
    local localised_name
    for name, prototype in pairs(game.item_prototypes) do
        if item_name == name then
            localised_name = prototype.localised_name
        end
    end

    return localised_name
end

local function adjustSpace(guiIn)
    addStyle(guiIn.add {type = 'line', direction = 'horizontal'}, space)
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
    local element = player.gui.center
    local data = this.data[player.index]
    if not data then
        return
    end

    if element and element.valid then
        element = element['inventory_gui']
        if element and element.valid then
            element.destroy()
        end
        if data.frame and data.frame.valid then
            data.frame.destroy()
        end
        Public.reset_table(player)
    end
end

local function redraw_inventory(gui, source, target, caption, panel_type)
    gui.clear()

    local items_table = gui.add({type = 'table', column_count = 11})
    local prototype

    local mod_gui = this.gui[source.index].inventory_gui
    mod_gui.caption = 'Inventory of ' .. target.name

    for name, opts in pairs(panel_type) do
        local flow = items_table.add({type = 'flow'})
        flow.style.vertical_align = 'bottom'

        prototype = build_prototype_data(name)

        local button =
            flow.add(
            {
                type = 'sprite-button',
                sprite = 'item/' .. name,
                number = opts,
                name = name,
                tooltip = prototype,
                style = 'slot_button'
            }
        )
        button.enabled = false

        if caption == 'Armor' then
            if not target.get_inventory(5)[1].grid then
                return
            end
            local p_armor = target.get_inventory(5)[1].grid.get_contents()
            for k, v in pairs(p_armor) do
                prototype = build_prototype_data(k)
                local armor_gui =
                    flow.add(
                    {
                        type = 'sprite-button',
                        sprite = 'item/' .. k,
                        number = v,
                        name = k,
                        tooltip = prototype,
                        style = 'slot_button'
                    }
                )
                armor_gui.enabled = false
            end
        end

        ::continue::
    end
end

local function add_inventory(panel, source, target, caption, panel_type)
    local data = this.data[source.index]
    data.item_frame = data.item_frame or {}
    data.panel_type = data.panel_type or {}
    local pane_name = panel.add({type = 'tab', caption = caption})
    local scroll_pane =
        panel.add {
        type = 'scroll-pane',
        direction = 'vertical',
        vertical_scroll_policy = 'always',
        horizontal_scroll_policy = 'never'
    }
    scroll_pane.style.maximal_height = 200
    scroll_pane.style.horizontally_stretchable = true
    scroll_pane.style.minimal_height = 200
    scroll_pane.style.right_padding = 0
    panel.add_tab(pane_name, scroll_pane)

    data.item_frame[caption] = scroll_pane
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

    local mod_gui = this.gui[source.index]
    local menu_frame = mod_gui.inventory_gui
    if menu_frame then
        menu_frame.destroy()
    end

    local frame =
        mod_gui.add(
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

    local panel = frame.add({type = 'tabbed-pane'})

    this.data[source.index].frame = frame
    this.data[source.index].player_opened = target

    local types = {
        ['Main'] = target.get_main_inventory().get_contents(),
        ['Armor'] = target.get_inventory(defines.inventory.character_armor).get_contents(),
        ['Guns'] = target.get_inventory(defines.inventory.character_guns).get_contents(),
        ['Ammo'] = target.get_inventory(defines.inventory.character_ammo).get_contents(),
        ['Trash'] = target.get_inventory(defines.inventory.character_trash).get_contents()
    }

    for k, v in pairs(types) do
        add_inventory(panel, source, target, k, v)
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

    if not this.gui[player.index] then
        this.gui[player.index] = player.gui.screen
    end
    if not this.data[player.index] then
        this.data[player.index] = {}
    end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    Public.reset_table(player)
end

local function update_gui()
    for _, source in pairs(game.connected_players) do
        local target = this.data[source.index].player_opened
        if target then
            open_inventory(source, target)
        end
    end
end

commands.add_command(
    'inventory',
    'Opens a players inventory!',
    function(cmd)
        local player = game.player

        if player and player ~= nil then
            if cmd.parameter == nil then
                return
            end
            local target_player = game.players[cmd.parameter]
            if target_player then
                open_inventory(player, target_player)
            end
        else
            return
        end
    end
)

function Public.get_table()
    return this
end

function Public.reset_table(player)
    if player then
        local data = this.data[player.index]
        for k, _ in pairs(data) do
            this.data[player.index][k] = nil
        end
    end
end

Event.add(defines.events.on_player_main_inventory_changed, update_gui)
Event.add(defines.events.on_gui_closed, gui_closed)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)

return Public
