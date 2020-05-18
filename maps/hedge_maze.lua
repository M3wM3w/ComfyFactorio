-- forest maze from mewmew

require "modules.satellite_score"
require "modules.biter_pets"
require "modules.no_deconstruction_of_neutral_entities"
require "modules.spawners_contain_biters"

local event = require 'utils.event'
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'.d2
local math_random = math.random

local labyrinth_cell_size = 16 --valid values are 2, 4, 8, 16, 32
local lake_noise_value = -0.55

local modifiers = {
		{x = 0, y = -1},{x = -1, y = 0},{x = 1, y = 0},{x = 0, y = 1}
	}

local modifiers_diagonal = {
		{diagonal = {x = -1, y = 1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = 1}},
		{diagonal = {x = 1, y = -1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = -1}},
		{diagonal = {x = 1, y = 1}, connection_1 = {x = 1, y = 0}, connection_2 = {x = 0, y = 1}},
		{diagonal = {x = -1, y = -1}, connection_1 = {x = -1, y = 0}, connection_2 = {x = 0, y = -1}}
	}	

local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}	
	
local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local wrecks = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"}
local function create_shipwreck(surface, position)
	local raffle = {}
	local loot = {								
		{{name = "iron-gear-wheel", count = math_random(80,100)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "copper-cable", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "battery", count = math_random(40,80)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "advanced-circuit", count = math_random(40,80)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "electronic-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "processing-unit", count = math_random(30,60)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "explosives", count = math_random(25,50)}, weight = 1, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, evolution_min = 0.3, evolution_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},		
		{{name = "steel-plate", count = math_random(50,100)}, weight = 2, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},				
		{{name = "burner-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},		
		{{name = "fast-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 1},
		{{name = "filter-inserter", count = math_random(4,8)}, weight = 1, evolution_min = 0.2, evolution_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(2,4)}, weight = 1, evolution_min = 0.4, evolution_max = 1},
		{{name = "stack-inserter", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 1},				
		{{name = "small-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 1},		
		{{name = "wooden-chest", count = math_random(16,24)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "iron-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 0.4},
		{{name = "steel-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "small-lamp", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail", count = math_random(50,75)}, weight = 3, evolution_min = 0.1, evolution_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(1,2)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(1,2)}, weight = 3, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "offshore-pump", count = 1}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "heat-pipe", count = math_random(8,12)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "arithmetic-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "constant-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "decider-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "power-switch", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},		
		{{name = "programmable-speaker", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "green-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "red-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "burner-mining-drill", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		{{name = "express-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0, evolution_max = 0.3},		
		{{name = "pipe", count = math_random(40,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 0.5},
		{{name = "pump", count = math_random(1,4)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},	
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},		
		{{name = "stone-wall", count = math_random(25,75)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "gate", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "express-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.0, evolution_max = 0.5}
	}

	local distance_to_center = math.sqrt(position.x^2 + position.y^2)
	if distance_to_center < 1 then
		distance_to_center = 0.1
	else
		distance_to_center = distance_to_center / 4000
	end
	if distance_to_center > 1 then distance_to_center = 1 end
	
	for _, t in pairs (loot) do
		for x = 1, t.weight, 1 do
			if t.evolution_min <= distance_to_center and t.evolution_max >= distance_to_center then
				table.insert(raffle, t[1])
			end
		end			
	end
	local e = surface.create_entity{name = wrecks[math_random(1,#wrecks)], position = position, force = "player"}	
	for x = 1, math_random(2,3), 1 do
		local loot = raffle[math_random(1,#raffle)]
		e.insert(loot)
	end	
end

local function get_noise(name, pos)
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.001, pos.y * 0.001, seed)
		local noise = noise[1]
		return noise
	end	
end

local function set_cell_tiles(surface, cell_left_top, tile_name)
	for x = 0.5, labyrinth_cell_size, 1 do
		for y = 0.5, labyrinth_cell_size, 1 do
			local pos = {x = cell_left_top.x + x, y = cell_left_top.y + y}
			surface.set_tiles({{name = tile_name, position = pos}}, true)			
		end
	end
end
	
local function labyrinth_wall(surface, cell_left_top)
	local noise = get_noise(1, cell_left_top)	
	if noise < lake_noise_value then return end
	local tile_name = "grass-2"					
	if noise > 0.6 then
		tile_name = "dirt-6"
		set_cell_tiles(surface, cell_left_top, tile_name)
		for x = 0.5, labyrinth_cell_size, 1 do
			for y = 0.5, labyrinth_cell_size, 1 do
				local pos = {x = cell_left_top.x + x, y = cell_left_top.y + y}
				if math_random(1,3) ~= 1 then
					surface.create_entity({name = "dead-tree-desert", position = pos})
				else
					surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})
				end
			end
		end
		return
	end	
	
	set_cell_tiles(surface, cell_left_top, tile_name)
	for x = 0.5, labyrinth_cell_size, 1 do
		for y = 0.5, labyrinth_cell_size, 1 do
			local pos = {x = cell_left_top.x + x, y = cell_left_top.y + y}
			if math_random(1,3) ~= 1 then
				surface.create_entity({name = "tree-04", position = pos})
			else
				if math_random(1,3) == 1 then surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos}) end
			end			
		end
	end
end
	
local function labyrinth_path(surface, cell_left_top)
	local noise = get_noise(1, cell_left_top)
	if noise < lake_noise_value then return end
	local tile_name = "grass-1"
	if noise > 0.6 then tile_name = "dirt-7" end		
	set_cell_tiles(surface, cell_left_top, tile_name)
end

local function draw_oceans(surface, cell_left_top)	
	if get_noise(1, cell_left_top) >= lake_noise_value then return end	
	set_cell_tiles(surface, cell_left_top, "deepwater")	
	for x = 0.5, labyrinth_cell_size, 1 do
		for y = 0.5, labyrinth_cell_size, 1 do
			local pos = {x = cell_left_top.x + x, y = cell_left_top.y + y}
			if math_random(1, 256) == 1 then surface.create_entity({name = "fish", position = pos}) end
		end
	end			
end

local function get_path_connections_count(cell_pos)
	local connections = 0
	for _, m in pairs(modifiers) do
		if global.labyrinth_cells[tostring(cell_pos.x + m.x) .. "_" .. tostring(cell_pos.y + m.y)] then
			connections = connections + 1
		end
	end
	return connections
end

local function process_labyrinth_cell(pos)
	local cell_position = {x = pos.x / labyrinth_cell_size, y = pos.y / labyrinth_cell_size}
	
	global.labyrinth_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = false
	
	for _, modifier in pairs(modifiers_diagonal) do
		if global.labyrinth_cells[tostring(cell_position.x + modifier.diagonal.x) .. "_" .. tostring(cell_position.y + modifier.diagonal.y)] then			
			local connection_1 = global.labyrinth_cells[tostring(cell_position.x + modifier.connection_1.x) .. "_" .. tostring(cell_position.y + modifier.connection_1.y)]
			local connection_2 = global.labyrinth_cells[tostring(cell_position.x + modifier.connection_2.x) .. "_" .. tostring(cell_position.y + modifier.connection_2.y)]
			if not connection_1 and not connection_2 then
				return false
			end												
		end
	end
	
	for _, m in pairs(modifiers) do
		if get_path_connections_count({x = cell_position.x + m.x, y = cell_position.y + m.y}) >= math_random(2, 3) then return false end
	end
		
	if get_path_connections_count(cell_position) >= math_random(2, 3) then return false end
	
	global.labyrinth_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] = true
	return true
end

local function labyrinth(event)
	local positions = {}
	for x = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do
		for y = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do
			positions[#positions + 1] = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}					
		end
	end
	positions = shuffle(positions)
	
	for _, pos in pairs(positions) do	
		draw_oceans(event.surface, pos)
		if process_labyrinth_cell(pos) then
			labyrinth_path(event.surface, pos)
		else
			labyrinth_wall(event.surface, pos)
		end		
	end	
end

local function on_chunk_generated(event)
	local surface = game.surfaces["forest_maze"]
	if event.surface.name ~= surface.name then return end	 
	local left_top = event.area.left_top
	local area = {
			left_top = {x = left_top.x, y = left_top.y},
			right_bottom = {x = left_top.x + 31, y = left_top.y + 31}
			}							
	surface.destroy_decoratives({area = area})
	
	local entities = surface.find_entities(area)
	for _, e in pairs(entities) do
		if e.valid then
			if e.name ~= "character" then
				e.destroy()				
			end
		end
	end
	
	labyrinth(event)
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end										
	surface.regenerate_decorative(decorative_names, {{x = left_top.x / 32, y = left_top.y / 32}})
end

local function draw_secret_area(surface, position)
	local positions = {}
	for x = 0, labyrinth_cell_size - 1, 1 do
		for y = 0, labyrinth_cell_size - 1, 1 do
			positions[#positions + 1] = {x = position.x + x, y = position.y + y}					
		end
	end
	positions = shuffle(positions)
	
	local wrecks_to_place = math_random(1, math.ceil(labyrinth_cell_size * 0.33))
	for i = 1, #positions, 1 do
		if surface.can_place_entity({name = "big-ship-wreck-1", position = positions[i]}) then			
			create_shipwreck(surface, positions[i])
			wrecks_to_place = wrecks_to_place - 1
			if wrecks_to_place <= 0 then break end
		end
	end
end

local ore_chance_weights = {
	{"iron-ore", 25},
	{"copper-ore",18},
	{"coal",14},
	{"stone",10},
	{"crude-oil",5},
	{"uranium-ore",3}
}
local ore_raffle = {}				
for _, t in pairs (ore_chance_weights) do
	for x = 1, t[2], 1 do
		table.insert(ore_raffle, t[1])
	end			
end

local function draw_ores(surface, position)
	local ore = ore_raffle[math_random(1, #ore_raffle)]
	for x = 0, labyrinth_cell_size - 1, 1 do
		for y = 0, labyrinth_cell_size - 1, 1 do
			local pos = {x = position.x + x, y = position.y + y}
			local amount = 500 + math.sqrt(pos.x^2 + pos.y^2)
			if ore == "crude-oil" then
				if math_random(1, 32) == 1 and surface.can_place_entity({name = ore, position = pos, amount = amount * 100}) then surface.create_entity({name = ore, position = pos, amount = amount * 100}) end
			else
				surface.create_entity({name = ore, position = pos, amount = amount})
			end
		end
	end
end

local function draw_water(surface, position)
	map_functions.draw_noise_tile_circle({x = position.x + labyrinth_cell_size * 0.5, y = position.y + labyrinth_cell_size * 0.5}, "water", surface, math.floor(labyrinth_cell_size * 0.3))
	for _, tile in pairs(surface.find_tiles_filtered({name = "water", area = {{position.x, position.y},{position.x + labyrinth_cell_size, position.y + labyrinth_cell_size}}})) do
		if math_random(1, 12) == 1 then surface.create_entity({name = "fish", position = tile.position}) end
	end
end

local enemy_chances = {
	{"biter-spawner", 20},
	{"spitter-spawner",8},
	{"small-worm-turret",5},
	{"medium-worm-turret",4},
	{"big-worm-turret",3},
	{"behemoth-worm-turret",1},
}
local enemy_raffle = {}				
for _, t in pairs (enemy_chances) do
	for x = 1, t[2], 1 do
		table.insert(enemy_raffle, t[1])
	end			
end

local function draw_enemies(surface, position)
	local positions = {}
	for x = 0, labyrinth_cell_size - 1, 1 do
		for y = 0, labyrinth_cell_size - 1, 1 do
			positions[#positions + 1] = {x = position.x + x, y = position.y + y}					
		end
	end
	positions = shuffle(positions)
	
	for i = 1, labyrinth_cell_size, 1 do
		local enemy = enemy_raffle[math_random(1, #enemy_raffle)]
		if surface.can_place_entity({name = enemy, position = positions[i]}) then
			surface.create_entity({name = enemy, position = positions[i], force = "enemy"})
		end
	end
end

local function draw_rocks(surface, position)
	local r = math_random(0,100)
	if r < 50 then
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = {x = position.x + labyrinth_cell_size * 0.5, y = position.y + labyrinth_cell_size * 0.5}})
		return
	end
	if r <= 100 then
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = {x = position.x + labyrinth_cell_size * 0.5, y = position.y + labyrinth_cell_size * 0.25}})
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = {x = position.x + labyrinth_cell_size * 0.75, y = position.y + labyrinth_cell_size * 0.75}})
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = {x = position.x + labyrinth_cell_size * 0.25, y = position.y + labyrinth_cell_size * 0.75}})
		return
	end
end

local function process_chunk_charted_cell(surface, pos)
	local cell_position = {x = pos.x / labyrinth_cell_size, y = pos.y / labyrinth_cell_size}
	if not global.labyrinth_cells[tostring(cell_position.x) .. "_" .. tostring(cell_position.y)] then return end
	
	local noise = get_noise(1, pos)
	if noise < lake_noise_value then return end --RETURN IF IT IS WATER LAKE
	
	local connection_count = get_path_connections_count(cell_position)
	
	if connection_count == 0 then
		draw_secret_area(surface, pos)
	end
	
	if connection_count == 1 then
		if math_random(1, 2) == 1 then
			draw_ores(surface, pos)
		else
			local distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
			if distance_to_center > 196 then
				if math_random(1, 4) == 1 then
					draw_water(surface, pos)
				else
					draw_enemies(surface, pos)
				end
			else
				if math_random(1, 3) == 1 then draw_water(surface, pos) end
			end					
		end
	end
	
	if connection_count == 3 then		
		if math_random(1, 2) == 1 then draw_rocks(surface, pos) end
	end
end

local function on_chunk_charted(event)
	local surface = game.surfaces[event.surface_index]
	
	if game.tick < 300 then return end
	
	if not global.chunks_charted then
		game.forces.player.clear_chart(surface)
		global.chunks_charted = {}
	end
	
	local left_top = {x = event.position.x * 32, y = event.position.y * 32}
	
	if global.chunks_charted[tostring(left_top.x) .. "_" .. tostring(left_top.y)] then return end
	global.chunks_charted[tostring(left_top.x) .. "_" .. tostring(left_top.y)] = true
	
	for x = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do
		for y = 0, 32 - labyrinth_cell_size, labyrinth_cell_size do	
			local pos = {x = left_top.x + x, y = left_top.y + y}
			process_chunk_charted_cell(surface, pos)
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 20, cliff_elevation_0 = 20}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}
		
		game.map_settings.pollution.ageing = 0
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("forest_maze", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["forest_maze"])
		local surface = game.surfaces["forest_maze"]
		
		surface.daytime = 1
		surface.freeze_daytime = 1
		--local radius = 512
		--game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})	
		global.map_init_done = true						
	end	
	local surface = game.surfaces["forest_maze"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "forest_maze")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "forest_maze")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'iron-gear-wheel', count = 8}
		player.insert {name = 'iron-plate', count = 16}
		--player.insert {name = 'grenade', count = 160}
	end	
end

--TREE BURNING NERF
local function on_entity_died(event)	
	if not event.entity.valid then return end
	if event.entity.type == "tree" then 
		for _, entity in pairs (event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 4, event.entity.position.y - 4},{event.entity.position.x + 4, event.entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
			if entity.valid then entity.destroy() end
		end
	end		
end

local function on_init()
	global.labyrinth_cells = {}
end

event.on_init(on_init)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_player_joined_game, on_player_joined_game)