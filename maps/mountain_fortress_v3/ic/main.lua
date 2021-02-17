require 'modules.check_fullness'

local Event = require 'utils.event'
local Functions = require 'maps.mountain_fortress_v3.ic.functions'
local IC = require 'maps.mountain_fortress_v3.ic.table'
local Minimap = require 'maps.mountain_fortress_v3.ic.minimap'
local Public = {}

Public.reset = IC.reset
Public.get_table = IC.get

local function on_entity_died(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local valid_types = IC.get_types()

    if (valid_types[entity.type] or valid_types[entity.name]) then
        local ic = IC.get()
        Functions.kill_car(ic, entity)
    end
end

local function on_player_mined_entity(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local valid_types = IC.get_types()

    if (valid_types[entity.type] or valid_types[entity.name]) then
        local ic = IC.get()
        Minimap.kill_minimap(game.players[event.player_index])
        Functions.save_car(ic, event)
    end
end

local function on_robot_mined_entity(event)
    local entity = event.entity

    if not entity and not entity.valid then
        return
    end

    local valid_types = IC.get_types()

    if (valid_types[entity.type] or valid_types[entity.name]) then
        local ic = IC.get()
        Functions.kill_car(ic, entity)
    end
end

local function on_built_entity(event)
    local ce = event.created_entity

    if not ce or not ce.valid then
        return
    end

    local valid_types = IC.get_types()

    if (valid_types[ce.type] or valid_types[ce.name]) ~= true then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    local ic = IC.get()
    Functions.create_car(ic, event)
end

local function on_player_driving_changed_state(event)
    local ic = IC.get()
    local player = game.players[event.player_index]

    Functions.use_door_with_entity(ic, player, event.entity)
    Functions.validate_owner(ic, player, event.entity)
end

local function on_tick()
    local ic = IC.get()
    local tick = game.tick

    if tick % 10 == 1 then
        Functions.item_transfer(ic)
    end

    if tick % 240 == 0 then
        Minimap.update_minimap()
    end

    if tick % 400 == 0 then
        Functions.remove_invalid_cars(ic)
    end
end

local function on_gui_closed(event)
    local entity = event.entity
    if not entity then
        return
    end
    if not entity.valid then
        return
    end
    if not entity.unit_number then
        return
    end
    local ic = IC.get()
    if not ic.cars[entity.unit_number] then
        return
    end

    Minimap.kill_minimap(game.players[event.player_index])
end

local function on_gui_opened(event)
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if not entity.unit_number then
        return
    end
    local ic = IC.get()
    local car = ic.cars[entity.unit_number]
    if not car then
        return
    end

    Minimap.minimap(
        game.players[event.player_index],
        car.surface,
        {
            car.area.left_top.x + (car.area.right_bottom.x - car.area.left_top.x) * 0.5,
            car.area.left_top.y + (car.area.right_bottom.y - car.area.left_top.y) * 0.5
        }
    )
end

local function on_gui_click(event)
    local element = event.element
    if not element or not element.valid then
        return
    end

    local player = game.get_player(event.player_index)
    if not player or not player.valid then
        return
    end

    if event.element.name == 'minimap_button' then
        Minimap.minimap(player, false)
    elseif event.element.name == 'minimap_frame' or event.element.name == 'minimap_toggle_frame' then
        Minimap.toggle_minimap(event)
    elseif event.element.name == 'switch_auto_map' then
        Minimap.toggle_auto(player)
    end
end

local function trigger_on_player_kicked_from_surface(data)
    local player = data.player
    local target = data.target
    local this = data.this
    Functions.kick_player_from_surface(this, player, target)
end

local function on_init()
    Public.reset()
end

local function on_gui_switch_state_changed(event)
    local element = event.element
    local player = game.players[event.player_index]
    if not (player and player.valid) then
        return
    end

    if not element.valid then
        return
    end

    if element.name == 'ic_auto_switch' then
        Minimap.toggle_auto(player)
    end
end

local changed_surface = Minimap.changed_surface

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_surface, changed_surface)
Event.add(IC.events.on_player_kicked_from_surface, trigger_on_player_kicked_from_surface)
Event.add(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)

return Public
