--[[
Exchange Strings:

for "terrain_layouts.scrap_01"
>>>eNpjYBBiEGQAgwYHBgYHBw6W5PzEHAaGA0Begz2I5krOLyhIL
dLNL0pFFuZMLipNSdXNz0RVnJqXmlupm5RYnAoRgmCOzKL8PHQTW
ItL8vNQRUqKUlOLQazVq1bZgUS5S4sS8zJLc9H1MjCeOHC8uKFFj
gGE/9czKPz/D8JA1gOgX0CYgbEB7ClGoBgMsCbnZKalMTAoODIwF
DiDFTEyVousc39YNcWeEaJGzwHK+AAVOZAEE/GEMfwccEqpwBgmD
oz/weC+PaMxGHxGYkAsLQFaAVXO4YBgQCRbQJKMjL1vty74fuyCH
eOflR8v+SYl2DMauoq8+2C0zg4oyQ7yAhOcmDUTBHbCvMIAM/OBP
VTqpj3j2TMg8MaekQukwwhETKgDEg+WAq0T4AOyFvQACQUZBpjT7
GDGiDgwpoHBN5hPHsMYl+3R/QEMCBuQ4XIg4gSIYGWAGwl0GSOE6
dDvwOggD5OVRCgB6jdiQHZDCsKHJ2HWHkayH80hyBGB6Q80ERUHL
NEADqAUOPGCGe4aYHheYIfxHOY7MDKDGCBVX4BiEB5IBmYUhBZwY
GZAAGDyOnLntR4A3uWt/A==<<<
]]

local Biters = require "modules.towny.biters"
local Combat_balance = require "modules.towny.combat_balance"
local Building = require "modules.towny.building"
local Info = require "modules.towny.info"
local Market = require "modules.towny.market"
local Team = require "modules.towny.team"
local Town_center = require "modules.towny.town_center"
require "modules.custom_death_messages"
require "modules.flashlight_toggle_button"
require "modules.global_chat_toggle"
require "modules.biters_yield_coins"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	Info.toggle_button(player)
	Info.show(player)
	
	Team.set_player_color(player)
	
	if player.force.index ~= 1 then return end
	
	Team.set_player_to_outlander(player)	
	
	if player.online_time == 0 then
		Team.give_outlander_items(player)
		return
	end
	
	if not global.towny.requests[player.index] then return end
	if global.towny.requests[player.index] ~= "kill-character" then return end	
	if player.character then
		if player.character.valid then
			player.character.die()
		end
	end
	global.towny.requests[player.index] = nil
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]	
	if player.force.index ~= 1 then return end
	Team.set_player_to_outlander(player)
	Team.give_outlander_items(player)
	Biters.clear_spawn_for_player(player)
end

local function on_player_used_capsule(event)
	Combat_balance.fish(event)
end

local function on_built_entity(event)
	if Town_center.found(event) then return end
	if Building.prevent_isolation(event) then return end
	Building.restrictions(event)
end

local function on_robot_built_entity(event)
	if Building.prevent_isolation(event) then return end
	Building.restrictions(event)
end

local function on_player_built_tile(event)
	Building.prevent_isolation_landfill(event)
end

local function on_robot_built_tile(event)
	Building.prevent_isolation_landfill(event)
end

local function on_entity_died(event)	
	local entity = event.entity
	if entity.name == "market" then
		Team.kill_force(entity.force.name)
	end
end

local function on_entity_damaged(event)	
	local entity = event.entity
	if entity.name == "market" then
		Town_center.set_market_health(entity, event.final_damage_amount)
	end
end

local function on_player_repaired_entity(event)	
	local entity = event.entity
	if entity.name == "market" then
		Town_center.set_market_health(entity, -4)
	end
end

local function on_player_dropped_item(event)
	local player = game.players[event.player_index]
	local entity = event.entity	
	if entity.stack.name == "raw-fish" then 
		Team.ally_town(player, entity)
		return
	end
	if entity.stack.name == "coal" then 
		Team.declare_war(player, entity)
		return
	end
end

local function on_console_command(event)
	Team.set_town_color(event)
end

local function on_market_item_purchased(event)
	Market.offer_purchased(event)
	Market.refresh_offers(event)
end

local function on_gui_opened(event)
	Market.refresh_offers(event)
end

local function on_gui_click(event)
	Info.close(event)
	Info.toggle(event)
end

local function on_research_finished(event)
	Combat_balance.research(event)
	local town_center = global.towny.town_centers[event.research.force.name]
	if not town_center then return end
	town_center.research_counter = town_center.research_counter + 1
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if not player.character.valid then return end
	Team.reveal_entity_to_all(player.character)
end

local tick_actions = {
	[60 * 5] = Team.update_town_chart_tags,
	[60 * 10] = Team.set_all_player_colors,
	[60 * 20] = Biters.wipe_units_out_of_evo_range,
	[60 * 25] = Biters.unit_groups_start_moving,
	[60 * 45] = Biters.validate_swarms,
	[60 * 50] = Biters.swarm,
	[60 * 55] = Biters.set_evolution,
}

local function on_nth_tick(event)
	local tick = game.tick % 3600	
	if not tick_actions[tick] then return end 
	tick_actions[tick]()
end

local function on_init()
	global.towny = {}
	global.towny.requests = {}
	global.towny.request_cooldowns = {}
	global.towny.town_centers = {}
	global.towny.cooldowns = {}
	global.towny.size_of_town_centers = 0
	global.towny.swarms = {}
	
	game.difficulty_settings.technology_price_multiplier = 0.30
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false
	game.map_settings.enemy_expansion.enabled = true	
	
	Team.setup_player_force()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_console_command, on_console_command)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_gui_opened, on_gui_opened)
Event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_player_dropped_item, on_player_dropped_item)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_used_capsule, on_player_used_capsule)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)