local Global = require 'utils.global'
local Event = require 'utils.event'
local Functions = require "maps.scrapyard.icw.functions"
local Constants = require "maps.scrapyard.icw.constants"
local Public = {}

local math_round = math.round

local icw = {}
Global.register(
    icw,
    function(tbl)
        icw = tbl
    end
)

function Public.reset()
	if icw.surfaces then
		for k, surface in pairs(icw.surfaces) do
			if surface and surface.valid then
				game.delete_surface(surface)
			end
		end
	end
	for k, v in pairs(icw) do icw[k] = nil end
	icw.doors = {}
	icw.wagons = {}
	icw.trains = {}
	icw.players = {}
	icw.surfaces = {}
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity and not entity.valid then return end
	if not Constants.wagon_types[entity.type] then return end
	Functions.subtract_wagon_entity_count(icw, entity)
	Functions.kill_wagon(icw, entity)
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity and not entity.valid then return end
	Functions.subtract_wagon_entity_count(icw, entity)
	Functions.kill_wagon(icw, entity)
end

local function on_robot_mined_entity(event)
	local entity = event.entity
	if not entity and not entity.valid then return end
	Functions.subtract_wagon_entity_count(icw, entity)
	Functions.kill_wagon(icw, entity)
end

local function on_built_entity(event)
	local created_entity = event.created_entity
	Functions.create_wagon(icw, created_entity)
	Functions.add_wagon_entity_count(icw, created_entity)
end

local function on_robot_built_entity(event)
	local created_entity = event.created_entity
	Functions.create_wagon(icw, created_entity)
	Functions.add_wagon_entity_count(icw, created_entity)		
end

local function on_player_driving_changed_state(event)
	local player = game.players[event.player_index]
	Functions.use_cargo_wagon_door(icw, player, event.entity)
end
--[[
local function on_player_created(event)
	local player = game.players[event.player_index]
	player.insert({name = "cargo-wagon", count = 5})
	player.insert({name = "artillery-wagon", count = 5})
	player.insert({name = "fluid-wagon", count = 5})
	player.insert({name = "locomotive", count = 5})
	player.insert({name = "rail", count = 100})
end
]]
local function on_gui_closed(event)
	local entity = event.entity 
	if not entity then return end
	if not entity.valid then return end
	if not entity.unit_number then return end
	if not icw.wagons[entity.unit_number] then return end
	Functions.kill_minimap(game.players[event.player_index])
end

local function on_gui_opened(event)
	local entity = event.entity 
	if not entity then return end
	if not entity.valid then return end
	if not entity.unit_number then return end
	local wagon = icw.wagons[entity.unit_number]
	if not wagon then return end
	Functions.draw_minimap(icw, game.players[event.player_index], wagon.surface, {wagon.area.left_top.x + (wagon.area.right_bottom.x - wagon.area.left_top.x) * 0.5, wagon.area.left_top.y + (wagon.area.right_bottom.y - wagon.area.left_top.y) * 0.5})
end

local function on_player_died(event)
	Functions.kill_minimap(game.players[event.player_index])
end

local function on_train_created(event)
	Functions.request_reconstruction(icw)
end

local function on_gui_click(event)
	Functions.toggle_minimap(icw, event)	
end

local function on_tick()
	local tick = game.tick
	if tick % 60 == 0 then Functions.item_transfer(icw) end
	if tick % 240 == 0 then Functions.update_minimap(icw) end
	
	if not icw.rebuild_tick then return end
	if icw.rebuild_tick ~= tick then return end
	Functions.reconstruct_all_trains(icw)
	icw.rebuild_tick = nil
end

local function on_init()
	Public.reset()
end

function Public.get_table()
	return icw
end

function Public.register_wagon(wagon_entity)
	return Functions.create_wagon(icw, wagon_entity)
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_train_created, on_train_created)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_player_died, on_player_died)
--Event.add(defines.events.on_player_created, on_player_created)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_closed, on_gui_closed)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)

return Public