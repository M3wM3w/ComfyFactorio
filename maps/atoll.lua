--atoll-- mewmew made this --

require "modules.spawners_contain_biters"
require "modules.surrounded_by_worms"

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "tools.map_functions"

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == "ocean" then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		noise[4] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.3 + noise[3] * 0.2 + noise[4] * 0.1
		--noise = noise * 0.5
		return noise
	end	
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not global.map_init_done then
		game.forces["player"].technologies["landfill"].researched=true
		global.average_worm_amount_per_chunk = 6
		global.map_init_done = true	
	end	
	
	if player.online_time == 0 then		
		--player.insert{name = 'iron-axe', count = 1}
		player.insert{name = 'landfill', count = 200}
		player.insert{name = 'iron-plate', count = 32}
		player.insert{name = 'iron-gear-wheel', count = 16}
	end	
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "fish" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local types = {"resource", "simple-entity", "player"}
local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	local tiles = {}
	local entities = {}	
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = false
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local ocean_noise = get_noise("ocean", pos)
			if ocean_noise > -0.5 then			
				tile_to_insert = "water"
				if ocean_noise > -0.25 then tile_to_insert = "deepwater" end				
			end
			if tile_to_insert then
				local count = surface.count_entities_filtered({area = {{pos.x - 1, pos.y - 1}, {pos.x + 1.99, pos.y + 1.99}}, limit = 1, type = types})
				if count == 0 then
					table_insert(tiles, {name = tile_to_insert, position = pos})
					if math_random(1, 128) == 1 then
						table_insert(entities, {name = "fish", position = pos})
					end
				end
			end
		end
	end
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
	
	if not global.spawn_generated and left_top.x <= -64 then
		--map_functions.draw_noise_tile_circle({x = 0, y = 0}, "concrete", surface, 5)
		--map_functions.draw_smoothed_out_ore_circle({x = -32, y = -32}, "copper-ore", surface, 15, 2500)
		--map_functions.draw_smoothed_out_ore_circle({x = -32, y = 32}, "iron-ore", surface, 15, 2500)
		--map_functions.draw_smoothed_out_ore_circle({x = 32, y = 32}, "coal", surface, 15, 2500)
		--map_functions.draw_smoothed_out_ore_circle({x = 32, y = -32}, "stone", surface, 15, 2500)							
		--map_functions.draw_oil_circle({x = 0, y = 0}, "crude-oil", surface, 5, 200000)
		global.spawn_generated = true
	end
end

event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)