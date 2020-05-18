local Tabs = require 'comfy_panel.main'
local Map_score = require "modules.map_score"
local Terrain = require "maps.junkyard_pvp.terrain"
local Gui = require "maps.junkyard_pvp.gui"
require "maps.junkyard_pvp.surrounded_by_worms"
require "modules.flashlight_toggle_button"
require "modules.rocks_heal_over_time"
require "maps.junkyard_pvp.share_chat"
require "modules.mineable_wreckage_yields_scrap"
local Team = require "maps.junkyard_pvp.team"
local Reset = require "functions.soft_reset"
local Map = require "modules.map_info"
local math_random = math.random
local Public = {}

local map_gen_settings = {
		["seed"] = 1,
		["water"] = 1,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = false,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
	}


local function set_player_colors()
	for _, player in pairs(game.forces.west.players) do
		player.color = {50, 255, 50}
	end
	for _, player in pairs(game.forces.east.players) do
		player.color = {50, 50, 255}
	end
end

function Public.reset_map()
	Terrain.create_mirror_surface()
	
	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("pvp_junkyard", map_gen_settings).index		
	else
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], map_gen_settings, Team.starting_items).index
	end
	
	local surface = game.surfaces[global.active_surface_index]
	
	surface.request_to_generate_chunks({0,0}, 6)
	surface.force_generate_chunk_requests()
	game.forces.spectator.set_spawn_position({0, -128}, surface)
	game.forces.west.set_spawn_position({-85, 5}, surface)
	game.forces.east.set_spawn_position({85, 5}, surface)		
	
	Team.set_force_attributes()	
	Team.assign_random_force_to_active_players()
	
	for _, player in pairs(game.connected_players) do
		Team.teleport_player_to_active_surface(player)		
	end
	
	for _, player in pairs(game.forces.spectator.connected_players) do
		player.character.destroy()
		Team.set_player_to_spectator(player)	
	end	
	for _, player in pairs(game.forces.spectator.players) do
		Gui.rejoin_question(player)
	end
	
	set_player_colors()
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then	return end
	if global.game_reset_tick then return end
	
	if entity.name ~= "cargo-wagon" then return end
	if entity == global.map_forces.east.cargo_wagon or entity == global.map_forces.west.cargo_wagon then
	
		if entity.force.name == "east" then
			game.print("East lost their cargo-wagon.", {100, 100, 100})
			game.print(string.upper(">>>> West team has won the game!!! <<<<"), {250, 120, 0})
			game.forces.east.play_sound{path="utility/game_lost", volume_modifier=0.85}
			game.forces.west.play_sound{path="utility/game_won", volume_modifier=0.85}
			for _, player in pairs(game.forces.west.connected_players) do
				if global.map_forces.east.player_count > 0 then
					Map_score.set_score(player, Map_score.get_score(player) + 1)
				end
			end
		else
			game.print("West lost their cargo-wagon.", {100, 100, 100})
			game.print(string.upper(">>>> East team has won the game!!! <<<<"), {250, 120, 0})
			game.forces.west.play_sound{path="utility/game_lost", volume_modifier=0.85}
			game.forces.east.play_sound{path="utility/game_won", volume_modifier=0.85}
			for _, player in pairs(game.forces.east.connected_players) do
				if global.map_forces.west.player_count > 0 then
					Map_score.set_score(player, Map_score.get_score(player) + 1)
				end
			end
		end
	
		game.print("Next round starting in 60 seconds..", {150, 150, 150})
		
		for _, player in pairs(game.forces.spectator.connected_players) do
			player.play_sound{path="utility/game_won", volume_modifier=0.85}
		end
		
		global.game_reset_tick = game.tick + 3600
		game.delete_surface("mirror_terrain")
		
		for _, player in pairs(game.connected_players) do
			for _, child in pairs(player.gui.left.children) do child.destroy() end
			Tabs.comfy_panel_call_tab(player, "Map Scores")
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces[global.active_surface_index]
	
	set_player_colors()
	Gui.spectate_button(player)
	
	if player.surface.index ~= global.active_surface_index then		
		if player.force.name == "spectator" then 
			Team.set_player_to_spectator(player)
			Team.teleport_player_to_active_surface(player)		
			return 
		end
		Team.assign_force_to_player(player)
		Team.teleport_player_to_active_surface(player)
		Team.put_player_into_random_team(player)
		set_player_colors()
	end
end

local function set_player_spawn_and_refill_fish()
	for key, force in pairs(global.map_forces) do
		local cargo_wagon = force.cargo_wagon
		if cargo_wagon then 
			if cargo_wagon.valid then
				local surface = cargo_wagon.surface
			
				--fill fish in cargo wagon
				cargo_wagon.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math.random(1, 2)})
				
				--set player spawn to cargo wagon position
				local position = surface.find_non_colliding_position("stone-furnace", cargo_wagon.position, 16, 2)
				if not position then return end
				game.forces[key].set_spawn_position({x = position.x, y = position.y}, surface)
				
				--set fish chart tag
				if force.fish_tag then
					if force.fish_tag.valid then
						force.fish_tag.destroy() 
					end
				end
				force.fish_tag = cargo_wagon.force.add_chart_tag(
					surface,
					{icon = {type = 'item', name = 'raw-fish'},
					position = cargo_wagon.position,
					text = " ",
				})
			end
		end
	end
end

local function on_console_command(event)
	set_player_colors()
end

local function tick()
	local game_tick = game.tick
	if game_tick % 240 == 0 then
		local surface = game.surfaces[global.active_surface_index]	
		local area = {{-256, -127}, {255, 128}}
		game.forces.west.chart(surface, area)
		game.forces.east.chart(surface, area)
	end		
	if global.game_reset_tick then
		if global.game_reset_tick < game_tick then
			global.game_reset_tick = nil
			Public.reset_map()
		end		
		return
	end
	if game_tick % 1800 == 0 then
		set_player_spawn_and_refill_fish()
	end
end

local function on_init()
	game.difficulty_settings.technology_price_multiplier = 0.25 
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0	
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = false
	game.map_settings.pollution.enabled = false
	global.map_forces = {
		["west"] = {},
		["east"] = {},
	}
	
	local T = Map.Pop_info()
	T.main_caption = "Junkyard PVP"
	T.sub_caption =  "a playground made of scrap"
	T.text = table.concat({
		"The opponent team wants your fish cargo!\n",
		"\n",
		"Destroy their cargo wagon to win the round!\n",
		"\n",
		--"Sometimes you will encounter impassable dark chasms or ponds.\n",
		--"Some explosives may cause parts of the ceiling to crumble, filling the void, creating new ways.\n",
		--"All they need is a container and a well aimed shot.\n",
	})
	T.main_caption_color = {r = 150, g = 0, b = 255}
	T.sub_caption_color = {r = 0, g = 250, b = 150}

	global.rocks_yield_ore_base_amount = 150

	Team.create_forces()
	Public.reset_map()
end

local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(60, tick)
event.add(defines.events.on_console_command, on_console_command)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "modules.rocks_yield_ore"