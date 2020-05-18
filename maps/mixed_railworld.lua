local event = require 'utils.event'

require "modules.spawners_contain_acid"
require "modules.spawners_contain_biters"
require "modules.dangerous_goods"
require "modules.satellite_score"
require "modules.splice_double"
require "modules.mineable_wreckage_yields_scrap"

local function init_surface()
	if game.surfaces["mixed_railworld"] then return game.surfaces["mixed_railworld"] end

	local map_gen_settings = {}
	map_gen_settings.water = "0.5"
	map_gen_settings.starting_area = "2.5"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 40, cliff_elevation_0 = 40}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "8", size = "4", richness = "1"},
		["stone"] = {frequency = "0.3", size = "2.0", richness = "0.5"},
		["iron-ore"] = {frequency = "0.3", size = "2.0", richness = "0.5"},
		["copper-ore"] = {frequency = "0.3", size = "2.0", richness = "0.5"},
		["uranium-ore"] = {frequency = "0.5", size = "1", richness = "0.5"},		
		["crude-oil"] = {frequency = "0.5", size = "1", richness = "1"},
		["trees"] = {frequency = "0.5", size = "0.75", richness = "1"},
		["enemy-base"] = {frequency = "1", size = "1", richness = "1"}
	}
		
	local surface = game.create_surface("mixed_railworld", map_gen_settings)				
	surface.request_to_generate_chunks({x = 0, y = 0}, 1)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.7
	surface.ticks_per_day = surface.ticks_per_day * 2.5
	surface.min_brightness = 0.1
	
	game.forces["player"].set_spawn_position({0,0},game.surfaces["mixed_railworld"])
	
	return surface
end

local function on_player_joined_game(event)	
	local surface = init_surface()	
	local player = game.players[event.player_index]
	
	if player.online_time == 0 then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "mixed_railworld")
		player.insert({name = 'car', count = 1})
		player.insert({name = 'small-lamp', count = 1})
	end	
end

local function on_chunk_generated(event)	
	for _, coal in pairs(event.surface.find_entities_filtered({area = event.area, name = {"coal"}})) do
		local pos = coal.position
		if math.random(1,2) ~= 1 then		
			event.surface.create_entity({name = "mineable-wreckage", position = coal.position, force = "neutral"})
		end
		coal.destroy()
	end
end

local function on_init()
	game.difficulty_settings.technology_price_multiplier = 2
	game.map_settings.enemy_expansion.enabled = false
end

event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "modules.ores_are_mixed"