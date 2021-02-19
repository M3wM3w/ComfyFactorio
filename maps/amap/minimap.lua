local Public = {}

local ICT = require 'maps.amap.ic.table'
local Functions = require 'maps.amap.ic.functions'
local Gui = require 'maps.amap.ic.gui'

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
    if not game.players[player.name] then
        return false
    end
    return true
end

local function create_button(player)
    local button =
        player.gui.top.add(
        {
            type = 'sprite-button',
            name = 'minimap_button',
            sprite = 'utility/map',
            tooltip = 'Open or close minimap.'
        }
    )
    button.visible = false
end

function Public.toggle_button(player)
    if not player.gui.top['minimap_button'] then
        create_button(player)
    end
    local ic = ICT.get()
    local button = player.gui.top['minimap_button']
    if Functions.get_player_surface(ic, player) then
        button.visible = true
    else
        button.visible = false
    end
end

local function get_player_data(player)
    local ic = ICT.get()
    local player_data = ic.minimap[player.index]
    if ic.minimap[player.index] then
        return player_data
    end

    ic.minimap[player.index] = {
        surface = ic.allowed_surface,
        zoom = 0.30,
        map_size = 360,
        auto_map = true
    }
    return ic.minimap[player.index]
end

function Public.toggle_auto(player)
    local ic = ICT.get()
    local switch = player.gui.left.minimap_toggle_frame['switch_auto_map']
    if not switch or not switch.valid then
        return
    end

    if switch.switch_state == 'left' then
        ic.minimap[player.index].auto_map = true
    elseif switch.switch_state == 'right' then
        ic.minimap[player.index].auto_map = false
    end
end

local function kill_minimap(player)
    local frame = player.gui.left.minimap_toggle_frame
    if not frame or not frame.valid then
        return
    end
    if frame.visible then
        frame.destroy()
    end
end



local function kill_frame(player)
    if player.gui.left.minimap_toggle_frame then
        local element = player.gui.left.minimap_toggle_frame.minimap_frame
        if not element or not element.valid then
            return
        end
        element.destroy()
    end
end

local function draw_minimap(player, surface, position)
    local ic = ICT.get()
    surface = surface or game.surfaces[ic.allowed_surface]
    if not surface or not surface.valid then
        return
    end
    local cars = ic.cars

    local entity = Functions.get_entity_from_player_surface(cars, player)
    if not position then
        if not entity or not entity.valid then
            kill_minimap(player)
            kill_frame(player)
            return
        end
    end

    position = position or entity.position
    local player_data = get_player_data(player)
    local frame = player.gui.left.minimap_toggle_frame
    if not frame then
        frame =
            player.gui.left.add(
            {type = 'frame', direction = 'vertical', name = 'minimap_toggle_frame', caption = 'Minimap'}
        )
    end
    frame.visible = true
    local element = frame['minimap_frame']
    if not element then
        element =
            player.gui.left.minimap_toggle_frame.add(
            {
                type = 'camera',
                name = 'minimap_frame',
                position = position,
                surface_index = surface.index,
                zoom = player_data.zoom,
                tooltip = 'LMB: Increase zoom level.\nRMB: Decrease zoom level.\nMMB: Toggle camera size.'
            }
        )
        element.style.margin = 1
        element.style.minimal_height = player_data.map_size
        element.style.minimal_width = player_data.map_size
        return
    end
    element.position = position
end

function Public.minimap(player, surface, position)
    local frame = player.gui.left['minimap_toggle_frame']
    local ic = ICT.get()
    if frame and frame.visible then
        kill_minimap(player)
    else
        if Functions.get_player_surface(ic, player) and not surface and not position then
            draw_minimap(player)
        else
            draw_minimap(player, surface, position)
        end
    end
end

function Public.update_minimap()
    local ic = ICT.get()
    for k, player in pairs(game.connected_players) do
        if Functions.get_player_surface(ic, player) and player.gui.left.minimap_toggle_frame then
            kill_frame(player)
            draw_minimap(player)
          else
          kill_minimap(player)
        end
    end
end

function Public.toggle_minimap(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end
    if element.name ~= 'minimap_frame' then
        return
    end
    local player = game.players[event.player_index]
    local player_data = get_player_data(player)
    if event.button == defines.mouse_button_type.right then
        player_data.zoom = player_data.zoom - 0.07
        if player_data.zoom < 0.07 then
            player_data.zoom = 0.07
        end
        element.zoom = player_data.zoom
        return
    end
    if event.button == defines.mouse_button_type.left then
        player_data.zoom = player_data.zoom + 0.07
        if player_data.zoom > 2 then
            player_data.zoom = 2
        end
        element.zoom = player_data.zoom
        return
    end
    if event.button == defines.mouse_button_type.middle then
        player_data.map_size = player_data.map_size + 50
        if player_data.map_size > 650 then
            player_data.map_size = 250
        end
        element.style.minimal_height = player_data.map_size
        element.style.minimal_width = player_data.map_size
        element.style.maximal_height = player_data.map_size
        element.style.maximal_width = player_data.map_size
        return
    end
end

function Public.changed_surface(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end

    local ic = ICT.get()
    local surface = game.surfaces[ic.allowed_surface]
    if not surface or not surface.valid then
        return
    end
    local wd = player.gui.top['wave_defense']
    local diff = player.gui.top['difficulty_gui']

    if Functions.get_player_surface(ic, player) then
        Public.toggle_button(player)
        Public.minimap(player, surface)
        if wd and wd.visible then
            wd.visible = false
        end
        if diff and diff.visible then
            diff.visible = false
        end
    elseif player.surface.index == surface.index then
        Gui.remove_toolbar(player)
        Public.toggle_button(player)
        kill_minimap(player)
        if wd and not wd.visible then
            wd.visible = true
        end
        if diff and not diff.visible then
            diff.visible = true
        end
    end
end

Public.kill_minimap = kill_minimap

return Public
