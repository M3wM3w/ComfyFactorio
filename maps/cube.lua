-- cuuuubee
local event = require 'utils.event'

function draw_entity_line(surface, name, position_a, position_b)
	local distance = math.sqrt((position_a[1] - position_b[1]) ^ 2 + (position_a[2] - position_b[2]) ^ 2)
	local modifier = {(position_b[1] - position_a[1]) / distance, (position_b[2] - position_a[2]) / distance}	
	local position = {position_a[1], position_a[2]}
	local entities = {}
	for i = 1, distance, 1 do
		if surface.can_place_entity({name = name, position = position}) then
			entities[#entities + 1] = surface.create_entity({name = name, position = position, create_build_effect_smoke = false})
		end
		position = {position[1] + modifier[1], position[2] + modifier[2]}
	end
	return entities
end

local function on_chunk_generated(event)
	local surface = game.surfaces["cube"]
	if event.surface.name ~= surface.name then return end	 
	local chunk_pos_x = event.area.left_top.x
	local chunk_pos_y = event.area.left_top.y
	local area = {
			left_top = {x = chunk_pos_x, y = chunk_pos_y},
			right_bottom = {x = chunk_pos_x + 31, y = chunk_pos_y + 31}
			}							
	surface.destroy_decoratives({area = event.area})
	local decoratives = {}	
	 
	for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
		if e.valid then
			if e.name ~= "character" then
				e.destroy()							
			end
		end
	end
	
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}	
			table.insert(tiles, {name = "sand-1", position = pos})
		end
	end
	surface.set_tiles(tiles,true)		
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 20, cliff_elevation_0 = 20}		
		map_gen_settings.autoplace_controls = {
			--["coal"] = {frequency = "none", size = "none", richness = "none"},
			--["stone"] = {frequency = "none", size = "none", richness = "none"},
			--["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			--["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			--["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			--["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			--["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("cube", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["cube"])
		local surface = game.surfaces["cube"]
		
		surface.daytime = 1
		surface.freeze_daytime = 1
		
		global.cube_pixels = {}
		global.rotation = {x = 0, y = 0, z = 0}
		
		
		global.map_init_done = true						
	end	
	local surface = game.surfaces["cube"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "cube")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "cube")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'light-armor', count = 1}
	end	
end

local cube_vectors = {
	{-16,-16, 16},
	{16,-16, 16},
	{16,16, 16},
	{-16,16, 16},
	
	{-16,-16, -16},
	{16,-16, -16},
	{16,16, -16},
	{-16,16, -16}
}

local function wipe_pixels()
	for _, line in pairs(global.cube_pixels) do
		for _, pixel in pairs(line) do
			pixel.destroy()
		end
		global.cube_pixels[_] = nil
	end
end

local function draw_lines(vectors)
	wipe_pixels()
	local surface = game.surfaces["cube"]
	for i = 1, 4, 1 do
		local position_a = vectors[i]
		local position_b = vectors[i + 1]
		if i == 4 then position_b = vectors[1] end
		global.cube_pixels[#global.cube_pixels + 1] = draw_entity_line(surface, "stone-wall", position_a, position_b)		
	end
	for i = 5, 8, 1 do
		local position_a = vectors[i]
		local position_b = vectors[i + 1]
		if i == 8 then position_b = vectors[5] end
		global.cube_pixels[#global.cube_pixels + 1] = draw_entity_line(surface, "stone-wall", position_a, position_b)		
	end
	
	global.cube_pixels[#global.cube_pixels + 1] = draw_entity_line(surface, "stone-wall", vectors[1], vectors[5])
	global.cube_pixels[#global.cube_pixels + 1] = draw_entity_line(surface, "stone-wall", vectors[2], vectors[6])
	global.cube_pixels[#global.cube_pixels + 1] = draw_entity_line(surface, "stone-wall", vectors[3], vectors[7])
	global.cube_pixels[#global.cube_pixels + 1] = draw_entity_line(surface, "stone-wall", vectors[4], vectors[8])
end

local function draw_cube()
	global.rotation = {x = global.rotation.x + 0.025, y = global.rotation.y + 0.025, z = global.rotation.z + 0.025}

	local vectors = {}
	for _, vector in pairs(cube_vectors) do
		local new_vector = {vector[1], vector[2]}
				
		--new_vector = {
		--	vector[1] * math.cos(global.rotation.x) - vector[2] * math.sin(global.rotation.y) - new_vector[1] - vector[3] * math.sin(global.rotation.y),
		--	vector[2] * math.sin(global.rotation.x) + vector[2] * math.cos(global.rotation.y) + new_vector[2] + vector[3] * math.cos(global.rotation.y),
		--}
		
		new_vector[1] = new_vector[1] + vector[3] * math.cos(global.rotation.z) * 0.75
		new_vector[2] = new_vector[2] + vector[3] * math.sin(global.rotation.z) * 0.75
		
		vectors[#vectors + 1] = new_vector
	end
	draw_lines(vectors)
end

local function on_tick(event)
	if game.tick % 4 ~= 0 then return end
	
	draw_cube()
	
	--if game.tick % 300 ~= 0 then return end
	
	--local radius = 256
	--game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_player_joined_game, on_player_joined_game)