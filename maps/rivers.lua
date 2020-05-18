--rivers-- mewmew made this --

require "modules.satellite_score"
require "modules.spawners_contain_biters"
require "modules.dynamic_landfill"
require "modules.rocks_yield_ore"

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2
local map_functions = require "tools.map_functions"

local disabled_for_deconstruction = {
		["fish"] = true
	}

local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}	
	
local tile_replacements = {
	["water"] = "grass-2",
	["deepwater"] = "grass-2",
	["dirt-1"] = "grass-1",
	["dirt-2"] = "grass-2",
	["dirt-3"] = "grass-3",
	["dirt-4"] = "grass-4",	
	["sand-1"] = "grass-1",
	["sand-2"] = "grass-2",
	["sand-3"] = "grass-3",
	["dry-dirt"] = "grass-2",	
	["red-desert-0"] = "grass-1",
	["red-desert-1"] = "grass-2",
	["red-desert-2"] = "grass-3",
	["red-desert-3"] = "grass-4",
}	
	
local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == 1 then		
		noise[1] = simplex_noise(pos.x * 0.007, pos.y * 0.007, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.1 + noise[3] * 0.025
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 2 then		
		noise[1] = simplex_noise(pos.x * 0.008, pos.y * 0.008, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		local noise = noise[1] + noise[2] * 0.05
		return noise
	end
end

local ore_level = 0.73
local water_level = 0.25
local connections = 0.08

local function process_tiles(surface, pos, noise, noise_2)
	local tile = surface.get_tile(pos)
	if tile_replacements[tile.name] then surface.set_tiles({{name = tile_replacements[tile.name], position = pos}}, true) end
	
	if noise > water_level * -1 and noise < water_level then 
		if noise_2 < connections * -1 or noise_2 > connections then
			surface.set_tiles({{name = "water", position = pos}}, true) 
			if math_random(1,256) == 1 then surface.create_entity({name = "fish", position = pos}) end
			return
		else
			if math_random(1,2) == 1 then surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos}) end
		end
	end		
end

local function process_entities(surface, pos, noise, noise_2)
	if not surface.can_place_entity({name = "iron-ore", position = pos, amount = 1}) then return end
		
	if noise > ore_level then
		local distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
		local amount = (600 + distance_to_center) * math.abs(noise)
		if math.floor(noise * 15) % 3 ~= 0 then
			surface.create_entity({name = "iron-ore", position = pos, amount = amount})
			return
		else
			surface.create_entity({name = "coal", position = pos, amount = amount})
			return
		end
	end
	
	if noise < ore_level * -1 then
		local distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
		local amount = (600 + distance_to_center) * math.abs(noise)
		if math.floor(noise * 15) % 3 ~= 0 then
			surface.create_entity({name = "copper-ore", position = pos, amount = amount})
			return
		else
			surface.create_entity({name = "stone", position = pos, amount = amount})
			return
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "rivers" then return end
	local left_top = event.area.left_top
	local tiles = {}
	local entities = {}			
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local noise_1 = get_noise(1, pos)
			local noise_2 = get_noise(2, pos)
			process_tiles(surface, pos, noise_1, noise_2)
			process_entities(surface, pos, noise_1, noise_2)
		end
	end
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end										
	surface.regenerate_decorative(decorative_names, {{left_top.x / 32, left_top.y / 32}})
end

local function init_map()
	if game.surfaces["rivers"] then return end
	
	local map_gen_settings = {}
	map_gen_settings.water = "0"
	map_gen_settings.starting_area = "1"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "none", size = "none", richness = "none"},
		["stone"] = {frequency = "none", size = "none", richness = "none"},
		["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
		["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
		["crude-oil"] = {frequency = "4", size = "1", richness = "1"},
		["trees"] = {frequency = "4", size = "1", richness = "1"},
		["enemy-base"] = {frequency = "50", size = "1.5", richness = "1"}
	}		
	game.create_surface("rivers", map_gen_settings)
	
	local surface = game.surfaces["rivers"]
	surface.ticks_per_day = game.surfaces["rivers"].ticks_per_day * 1.5
	
	game.map_settings.enemy_expansion.enabled = true					
	game.map_settings.enemy_expansion.min_expansion_cooldown = 18000
	game.map_settings.enemy_expansion.max_expansion_cooldown = 36000
	
	surface.request_to_generate_chunks({0,0}, 3)
	surface.force_generate_chunk_requests()
	
	game.forces.player.research_queue_enabled = true
	
	map_functions.draw_smoothed_out_ore_circle({x = -3, y = -3}, "iron-ore", surface, 8, 5000)
	map_functions.draw_smoothed_out_ore_circle({x = 3, y = 3}, "copper-ore", surface, 8, 5000)
	map_functions.draw_smoothed_out_ore_circle({x = 3, y = -3}, "stone", surface, 8, 5000)
	map_functions.draw_smoothed_out_ore_circle({x = -3, y = 3}, "coal", surface, 8, 5000)
end

local function on_player_joined_game(event)
	init_map()
	
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.insert({name = "iron-plate", count = 32})
		player.insert({name = "iron-gear-wheel", count = 16})
		player.teleport(game.surfaces["rivers"].find_non_colliding_position("character", {0, 2}, 50, 0.5), "rivers")
	end		
end

local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)