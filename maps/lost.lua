--lost-- mewmew made this --

require "modules.landfill_reveals_nauvis"
require "modules.satellite_score"
require "modules.spawners_contain_biters"

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
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
	if name == "ocean" then		
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
end

local function generate_outer_content(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = false
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local noise = get_noise("ocean", pos)				
			if math.floor(noise * 8) % 2 == 1 then
				surface.set_tiles({{name = "deepwater", position = pos}})
			else
				surface.set_tiles({{name = "water", position = pos}})
			end
			if math_random(1,256) == 1 then surface.create_entity({name = "fish", position = pos}) end
		end
	end
end

local function generate_inner_content(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = false
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if pos.x < 2 and pos.y < 2 and pos.x > -3 and pos.y > -3 then
				surface.set_tiles({{name = "grass-1", position = pos}})
				surface.create_entity({name = "stone", position = pos, amount = 999999})
			else
				local noise = get_noise("ocean", pos)				
				if math.floor(noise * 8) % 2 == 1 then
					surface.set_tiles({{name = "deepwater", position = pos}})
				else
					surface.set_tiles({{name = "water", position = pos}})
				end
				if math_random(1,256) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end
			if pos.x == 0 and pos.y == 0 then
				surface.create_entity({name = "rock-big", position = pos})
			end
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "lost" then return end
	local left_top = event.area.left_top
	local tiles = {}
	local entities = {}		
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
		if e.name ~= "character" then
			e.destroy()
		end		
	end
	
	if event.area.left_top.x < 64 and event.area.left_top.y < 64 and event.area.left_top.x > -64 and event.area.left_top.y > -64 then
		generate_inner_content(event)
	else
		generate_outer_content(event)
	end	
end

local function init_map()
	if game.surfaces["lost"] then return end
	
	local map_gen_settings = {}
	map_gen_settings.water = "small"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "none", size = "none", richness = "none"},
		["stone"] = {frequency = "none", size = "none", richness = "none"},
		["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
		["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
		["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
		["trees"] = {frequency = "none", size = "none", richness = "none"},
		["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
	}		
	game.create_surface("lost", map_gen_settings)
	game.surfaces["lost"].ticks_per_day = game.surfaces["lost"].ticks_per_day * 2
	
	game.surfaces["lost"].request_to_generate_chunks({0,0}, 3)
	game.surfaces["lost"].force_generate_chunk_requests()
	
	game.forces.player.manual_mining_speed_modifier = 0.5
	
	game.forces["player"].technologies["landfill"].researched=true
end

local function on_player_joined_game(event)
	init_map()
	
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.teleport(game.surfaces["lost"].find_non_colliding_position("character", {0, 2}, 50, 0.5), "lost")
	end		
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type ~= "simple-entity" then return end
	if entity.position.x == 0 and entity.position.y == 0 then
		entity.surface.create_entity({name = "rock-big", position = {0,0}})
	end
end

local function on_entity_died(event)
	on_player_mined_entity(event)
end

local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_chunk_generated, on_chunk_generated)