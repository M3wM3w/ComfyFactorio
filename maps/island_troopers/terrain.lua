local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2

local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}

local function island_noise(p, seed_1, seed_2, seed_3)
	local noise_1 = simplex_noise(p.x * seed_m1, p.y * seed_m1, seed_1)
	local noise_2 = simplex_noise(p.x * seed_m2, p.y * seed_m2, seed_2)
	local noise_3 = simplex_noise(p.x * seed_m3, p.y * seed_m3, seed_3)
	local noise = math.abs(noise_1 + noise_2 * 0.5 + noise_3 * 0.2)
	noise = noise / 1.7
	return noise
end

local function island_noise_radius(position)
	local noise = island_noise(position, seed_1, seed_2, seed_3)
	local radius = global.stages[global.current_stage].size
	return radius * 0.5 + noise * radius * 0.5
end

local function draw_island_tiles(surface, position, radius)
	local tiles = {}
	for y = radius * -1, radius, 1 do
		for x = radius * -1, radius, 1 do
			local p = {x = x + position.x, y = y + position.y}
			if surface.get_tile(p).name == "deepwater" then				
				local distance = math.sqrt(x^2 + y^2)
				local tile = false
				local noise_radius = island_noise_radius(p)
				if distance < noise_radius - radius * 0.15 then
					tile = {name = game.surfaces["island_tiles"].get_tile(x, y).name, position = p}
				else
					if distance < noise_radius then
						tile = {name = "water", position = p}
					end
				end

				if tile then tiles[#tiles + 1] = tile end
			end
		end
	end
	surface.set_tiles(tiles, true)
	return tiles
end

local function get_vector()
	if global.current_stage == 1 then return {0, -1} end
	if global.current_stage == #global.stages then return {0, 1} end
	local position = global.path_tiles[#global.path_tiles].position
	local island_size = global.stages[global.current_stage].size
	local y_modifier = 0
	if math.abs(position.y) < 32 + island_size * 3 then
		y_modifier = math.random(25, 100) * -0.01
	else
		y_modifier = math.random(25, 100) * 0.01
	end
	return {1, y_modifier}
end

local function set_island_surface()	
	local map_gen_settings = {}
	map_gen_settings.height = global.stages[global.current_stage].size * 2
	map_gen_settings.width = global.stages[global.current_stage].size * 2
	map_gen_settings.water = 0
	map_gen_settings.terrain_segmentation = 1
	map_gen_settings.seed = math.random(1, 999999999)
	map_gen_settings.cliff_settings = {cliff_elevation_interval = math.random(2, 16), cliff_elevation_0 = math.random(2, 16)}
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 0, size = 0, richness = 0},
		["stone"] = {frequency = 0, size = 0, richness = 0},
		["copper-ore"] = {frequency = 0, size = 0, richness = 0},
		["iron-ore"] = {frequency = 0, size = 0, richness = 0},
		["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
		["crude-oil"] = {frequency = 0, size = 0, richness = 0},
		["trees"] = {frequency = 50, size = 0.1, richness = math.random(0,10) * 0.1},
		["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
	}
	game.create_surface("island_tiles", map_gen_settings)
	local surface = game.surfaces["island_tiles"]
	surface.request_to_generate_chunks({0, 0}, math.ceil(max_island_radius / 32))
	surface.force_generate_chunk_requests()
end

function draw_the_island()
	if not global.stages[global.current_stage].size then global.gamestate = 4 return end	
	if game.surfaces["island_tiles"] then game.delete_surface(game.surfaces["island_tiles"]) return end
	
	local surface = game.surfaces[1]
	local position = global.path_tiles[#global.path_tiles].position	
	seed_1 = math.random(1, 9999999)
	seed_2 = math.random(1, 9999999)
	seed_3 = math.random(1, 9999999)
	seed_m1 = (math.random(8, 16) * 0.1) / global.stages[global.current_stage].size
	seed_m2 = (math.random(12, 24) * 0.1) / global.stages[global.current_stage].size
	seed_m3 = (math.random(50, 100) * 0.1) / global.stages[global.current_stage].size

	set_island_surface()
	local tiles = draw_island_tiles(surface, position, global.stages[global.current_stage].size)
	
	for _, decorative in pairs(game.surfaces["island_tiles"].find_decoratives_filtered({})) do
		local distance = math.sqrt(decorative.position.x ^ 2 + decorative.position.y ^ 2)
		if distance <= global.stages[global.current_stage].size then
			surface.create_decoratives{
				check_collision=true,
				decoratives={{name = decorative.decorative.name, position = {position.x + decorative.position.x, position.y + decorative.position.y}, amount = decorative.amount}}
			}
		end
	end
	
	for _, e in pairs(game.surfaces["island_tiles"].find_entities_filtered({})) do
		local distance = math.sqrt(e.position.x ^ 2 + e.position.y ^ 2)
		local p = {x = position.x + e.position.x, y = position.y + e.position.y}
		if distance <= island_noise_radius(p) then			
			if e.type == "simple-entity" then
				e.clone({position = p, surface = surface, force = "neutral"})
			else
				if surface.can_place_entity({name = "tree-01", position = p}) then
					e.clone({position = p, surface = surface, force = "neutral"})
				end		
			end		
		end
	end
			

	--local tree = global.tree_raffle[math.random(1, #global.tree_raffle)]
	local seed = math.random(1, 1000000)
	
	for _, t in pairs(tiles) do
		if math.random(1, 32) == 1 then
			local noise = simplex_noise(t.position.x * 0.02, t.position.y * 0.02, seed)
			if noise > 0.75 or noise < -0.75 then
				surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = t.position})
			end
		end
		
		--if surface.can_place_entity({name = "wooden-chest", position = t.position}) then
		--	if math.random(1, 64) == 1 then
		--		if simplex_noise(t.position.x * 0.02, t.position.y * 0.02, seed) > 0.25 then
		--			surface.create_entity({name = tree, position = t.position}) 
		--		end
		--	end
		--end
	end

	add_enemies(surface, tiles)
	global.gamestate = 4
end

local function add_path_decoratives(surface, tiles)
	local d = global.decorative_names[math.random(1, #global.decorative_names)]
	for _, t in pairs(tiles) do
		local noise = simplex_noise(t.position.x * 0.075, t.position.y * 0.075, game.surfaces[1].map_gen_settings.seed)
		if math.random(1,3) == 1 and noise > 0 then
			surface.create_decoratives{check_collision=false, decoratives={{name = d, position = t.position, amount = math.floor(math.abs(noise * 3)) + 1}}}
		end
	end
end

local draw_path_tile_whitelist = {
	["water"] = true,
	["deepwater"] = true,
}

local path_tile_names = {"grass-2", "grass-3", "grass-4", "dirt-1", "dirt-2", "dirt-3", "dirt-4", "dirt-5", "dirt-6", "dirt-7", "water-shallow"}
function draw_path_to_next_stage()
	local surface = game.surfaces[1]
	
	--if global.current_stage ~= #global.stages then
	--	if global.current_stage == #global.stages - 1 then
			--game.print("--Final Stage--")
	--	else
			--game.print("--Stage " .. global.current_stage .. "--")
	--	end
	--end
	
	local position = {x = 0, y = 0}
	if global.path_tiles then position = global.path_tiles[#global.path_tiles].position end
	--game.print(get_vector()[1] .. " " .. get_vector()[2])
	global.path_tiles = noise_vector_tile_path(surface, path_tile_names[math_random(1, #path_tile_names)], position, get_vector(), global.stages[global.current_stage].path_length, math.random(2, 4), draw_path_tile_whitelist)
	add_path_decoratives(surface, global.path_tiles)
	
	if global.current_stage ~= #global.stages and global.current_stage > 2 then
		if math_random(1, 3) == 1 then
			add_path_decoratives(surface, noise_vector_tile_path(surface, path_tile_names[math_random(1, #path_tile_names - 1)], position, {0, 1}, global.stages[#global.stages].path_length, math.random(2, 4), draw_path_tile_whitelist))
		end
	end
	
	global.gamestate = 3
end

local tile_reset_blacklist = {
	["deepwater"] = true,
	["out-of-map"] = true,
}

local function get_level_tiles(surface)
	global.level_tiles = {}
	for chunk in surface.get_chunks() do
		if chunk.y < 0 and game.forces.player.is_chunk_charted(surface, chunk) then
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local tile = surface.get_tile({chunk.x * 32 + x, chunk.y * 32 + y})
					if not tile_reset_blacklist[tile.name] then
						local index = math.abs(tile.position.y)
						if not global.level_tiles[index] then global.level_tiles[index] = {} end
						global.level_tiles[index][#global.level_tiles[index] + 1] = tile
					end
				end
			end
		end
	end
	for k, tile_row in pairs(global.level_tiles) do
		table.shuffle_table(global.level_tiles[k])
	end
end

local function wipe_vision(surface)
	for chunk in surface.get_chunks() do
		if chunk.y < 0 then game.forces.player.unchart_chunk(chunk, surface) end
	end
end

local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
local function create_particles(surface, position)
	local particle = particles[math_random(1, #particles)]
	local m = math_random(10, 30)
	local m2 = m * 0.005
	for i = 1, 4, 1 do 
		surface.create_entity({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
end

function kill_the_level()
	local surface = game.surfaces[1]
	if not global.level_tiles then get_level_tiles(surface) end
	if not global.kill_the_level_speed then global.kill_the_level_speed = 0 end
	global.kill_the_level_speed = global.kill_the_level_speed + 0.0025
	local amount = global.kill_the_level_speed 
	for i = #global.level_tiles, 1, -1 do
		if global.level_tiles[i] then
			for k, tile in pairs(global.level_tiles[i]) do
				surface.set_tiles({{name = "deepwater", position = tile.position}}, true)
				create_particles(surface, tile.position)
				global.level_tiles[i][k] = nil
				amount = amount - 1
				if amount <= 0 then return end
			end
			global.level_tiles[i] = nil
		end
	end
	
	if #global.level_tiles == 0 then
		wipe_vision(surface)
		global.kill_the_level_speed = nil
		global.level_tiles = nil
		global.gamestate = 1 
	end
end

local function process_tile(surface, position)
	if position.x < -128 then surface.set_tiles({{name = "out-of-map", position = position}}, true) return end
	if position.x > 8192 then surface.set_tiles({{name = "out-of-map", position = position}}, true) return end
	if position.y < 0 then surface.set_tiles({{name = "deepwater", position = position}}, true) return end
	if position.y > 32 then 
		surface.set_tiles({{name = "water-green", position = position}}, true)
		if math.random(1, 4096) == 1 then
			if math.random(1, 4) == 1 then
				surface.set_tiles({{name = "sand-1", position = position}}, true)
				create_dump_chest(surface, position, false)
			else
				surface.set_tiles({{name = "sand-1", position = position}}, true)
				create_shopping_chest(surface, position, false) 
			end
		end
		return
	end
	
	if position.y > 10 + simplex_noise(position.x * 0.010, 0, game.surfaces[1].map_gen_settings.seed) * 4 then surface.set_tiles({{name = "water-green", position = position}}, true) return end
	
	local index = math.floor((simplex_noise(position.x * 0.01, position.y * 0.01, game.surfaces[1].map_gen_settings.seed) * 10) % 3) + 1
	surface.set_tiles({{name = "sand-" .. index, position = position}}, true)
	
	if position.x > 32 then return true end
	
	if position.y == 6 then
		if position.x == -16 then
			create_shopping_chest(surface, position, false) 
		end
		if position.x == 16 then
			create_dump_chest(surface, position, false)
		end
	end
	
	return true
end

local function on_chunk_generated(event)
	if event.surface.index ~= 1 then return end
	local left_top = event.area.left_top
	local surface = event.surface
	local decoratives = {}
	
	for k, e in pairs(surface.find_entities_filtered({area = event.area})) do
		if e.force.name ~= "player" then e.destroy() end
	end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if process_tile(surface, position) then
				local noise = simplex_noise(position.x * 0.050, position.y * 0.050, game.surfaces[1].map_gen_settings.seed)
				if math.random(1, 2) == 1 and noise < -0.75 then
					decoratives[#decoratives + 1] = {name = "green-pita", position = position, amount = math.random(1,3)}				
				end
				if math.random(1, 4) == 1 and noise > 0.50 then
					decoratives[#decoratives + 1] = {name = "garballo", position = position, amount = math.random(1,3)}				
				end
				if math.random(1, 32) == 1 then
					decoratives[#decoratives + 1] = {name = "sand-dune-decal", position = position, amount = math.random(1,3)}				
				end
			end
		end
	end	
	surface.destroy_decoratives({area = event.area})
	surface.create_decoratives{check_collision=true, decoratives=decoratives}
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)