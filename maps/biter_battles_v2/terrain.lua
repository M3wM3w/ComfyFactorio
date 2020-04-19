local Public = {}
local BiterRaffle = require "functions.biter_raffle"
local bb_config = require "maps.biter_battles_v2.config"
local math_floor = math.floor
local math_random = math.random
local math_abs = math.abs
local simplex_noise = require 'utils.simplex_noise'.d2
local spawn_circle_size = 40
local ores = {"copper-ore", "iron-ore", "stone", "coal"}
local rocks = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big", "rock-huge"}

local chunk_tile_vectors = {}
for x = 0, 31, 1 do
	for y = 0, 31, 1 do
		chunk_tile_vectors[#chunk_tile_vectors + 1] = {x, y}
	end
end
local size_of_chunk_tile_vectors = #chunk_tile_vectors

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
	local noise_seed_add = 25000
	if name == 1 then
		local noise = simplex_noise(pos.x * 0.0042, pos.y * 0.0042, seed)
		seed = seed + noise_seed_add
		noise = noise + simplex_noise(pos.x * 0.031, pos.y * 0.031, seed) * 0.08
		seed  = seed + noise_seed_add
		noise = noise + simplex_noise(pos.x * 0.1, pos.y * 0.1, seed) * 0.025
		return noise
	end

	if name == 2 then
		local noise = simplex_noise(pos.x * 0.011, pos.y * 0.011, seed)
		seed = seed + noise_seed_add
		noise = noise + simplex_noise(pos.x * 0.08, pos.y * 0.08, seed) * 0.2
		return noise
	end

	if name == 3 then
		local noise = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		noise = noise + simplex_noise(pos.x * 0.02, pos.y * 0.02, seed) * 0.3
		noise = noise + simplex_noise(pos.x * 0.15, pos.y * 0.15, seed) * 0.025
		return noise
	end
end

local function create_mirrored_tile_chain(surface, tile, count, straightness)
	if not surface then return end
	if not tile then return end
	if not count then return end

	local position = {x = tile.position.x, y = tile.position.y}
	
	local modifiers = {
		{x = 0, y = -1},{x = -1, y = 0},{x = 1, y = 0},{x = 0, y = 1},
		{x = -1, y = 1},{x = 1, y = -1},{x = 1, y = 1},{x = -1, y = -1}
	}	
	modifiers = shuffle(modifiers)
	
	for a = 1, count, 1 do
		local tile_placed = false
		
		if math.random(0, 100) > straightness then modifiers = shuffle(modifiers) end
		for b = 1, 4, 1 do
			local pos = {x = position.x + modifiers[b].x, y = position.y + modifiers[b].y}
			if surface.get_tile(pos).name ~= tile.name then
				surface.set_tiles({{name = "landfill", position = pos}}, true)
				surface.set_tiles({{name = tile.name, position = pos}}, true)
				surface.set_tiles({{name = "landfill", position = {pos.x * -1, (pos.y * -1) - 1}}}, true)
				surface.set_tiles({{name = tile.name, position = {pos.x * -1, (pos.y * -1) - 1}}}, true)
				position = {x = pos.x, y = pos.y}
				tile_placed = true
				break
			end			
		end						
		
		if not tile_placed then
			position = {x = position.x + modifiers[1].x, y = position.y + modifiers[1].y}
		end		
	end			
end

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then
				if tile.name ~= "stone-path" then
					return tile.name
				end
			end
		end
	end
	return "grass-1"
end

local function get_chunk_position(position)
	local chunk_position = {}
	position.x = math.floor(position.x, 0)
	position.y = math.floor(position.y, 0)
	for x = 0, 31, 1 do
		if (position.x - x) % 32 == 0 then chunk_position.x = (position.x - x)  / 32 end
	end
	for y = 0, 31, 1 do
		if (position.y - y) % 32 == 0 then chunk_position.y = (position.y - y)  / 32 end
	end
	return chunk_position
end

local function regenerate_decoratives(surface, position)
	local chunk = get_chunk_position(position)
	if not chunk then return end
	surface.destroy_decoratives({area = {{chunk.x * 32, chunk.y * 32}, {chunk.x * 32 + 32, chunk.y * 32 + 32}}})
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {chunk})
end

local function draw_noise_ore_patch(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x + 0.5, y = y + position.y + 0.5}			
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed + 25000)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}

					local mirror_pos = {x = pos.x * -1, y = pos.y * -1}
					surface.create_entity{name = name, position = mirror_pos, amount = a}
					
					for _, e in pairs(surface.find_entities_filtered({position = pos, name = {"wooden-chest", "stone-wall", "gun-turret"}})) do					
						e.destroy()
					end
					for _, e in pairs(surface.find_entities_filtered({position = mirror_pos, name = {"wooden-chest", "stone-wall", "gun-turret"}})) do
						e.destroy()
					end
				end
			end
		end
	end
end

function is_within_spawn_circle(pos)
	if math_abs(pos.x) > spawn_circle_size then return false end
	if math_abs(pos.y) > spawn_circle_size then return false end
	if math.sqrt(pos.x ^ 2 + pos.y ^ 2) > spawn_circle_size then return false end
	return true
end

local river_y_1 = bb_config.border_river_width * -1.5
local river_y_2 = bb_config.border_river_width * 1.5
local river_width_half = math.floor(bb_config.border_river_width * -0.5)
function is_horizontal_border_river(pos)
	if pos.y < river_y_1 then return false end
	if pos.y > river_y_2 then return false end
	if pos.y > -5 and pos.x > -5 and pos.x < 5 then return false end
	if pos.y >= river_width_half - (math_abs(get_noise(1, pos)) * 4) then return true end
	return false
end

local function generate_inner_spawn_circle(pos, distance_to_center, surface)
	-- assert(distance_to_center < spawn_circle_size) == true
	local tile = false
	if distance_to_center < 7 then 
		tile = "sand-1"
	elseif distance_to_center < 9.5 then 
		tile = "refined-concrete"
	else
		tile = "deepwater"
		if math_random(1, 48) == 1 then surface.create_entity({name = "fish", position = pos}) end
	end

	surface.set_tiles({{name = tile, position = pos}}, true)
end

local function generate_starting_area(pos, distance_to_center, surface)
	-- assert(distance_to_center >= spawn_circle_size) == true
	local spawn_wall_radius = 116
	local noise_multiplier = 15 
	local min_noise = -noise_multiplier * 1.25

	-- Avoid calculating noise, see comment below
	if (distance_to_center + min_noise - spawn_wall_radius) > 4.5 then
		return
	end

	local noise = get_noise(2, pos) * noise_multiplier
	local distance_from_spawn_wall = distance_to_center + noise - spawn_wall_radius
	-- distance_from_spawn_wall is the difference between the distance_to_center (with added noise) 
	-- and our spawn_wall radius (spawn_wall_radius=116), i.e. how far are we from the ring with radius spawn_wall_radius.
	-- The following shows what happens depending on distance_from_spawn_wall:
	--   	min     max
    --  	N/A     -10	    => replace water
	-- if noise_2 > -0.5:
	--      -1.75    0 	    => wall
	-- else:
	--   	-6      -3 	 	=> 1/16 chance of turrent or turret-remnants
	--   	-1.95    0 	 	=> wall
	--    	 0       4.5    => chest-remnants with 1/3, chest with 1/(distance_from_spawn_wall+2)
	--
	-- => We never do anything for (distance_to_center + min_noise - spawn_wall_radius) > 4.5

	if distance_from_spawn_wall < 0 then
		if math_random(1, 100) > 23 then
			for _, tree in pairs(surface.find_entities_filtered({type = "tree", area = {{pos.x, pos.y}, {pos.x + 1, pos.y + 1}}})) do
				tree.destroy()
			end
		end
	end

	if distance_from_spawn_wall < -10 and not is_horizontal_border_river(pos) then
		local tile_name = surface.get_tile(pos).name
		if tile_name == "water" or tile_name == "deepwater" then
			surface.set_tiles({{name = get_replacement_tile(surface, pos), position = pos}}, true)
		end
		return
	end

	if surface.can_place_entity({name = "wooden-chest", position = pos}) and surface.can_place_entity({name = "coal", position = pos}) then
		local noise_2 = get_noise(3, pos)
		if noise_2 < 0.25 then
			if noise_2 > -0.5 then
				if distance_from_spawn_wall > -1.75 and distance_from_spawn_wall < 0 then				
					surface.create_entity({name = "stone-wall", position = pos, force = "north"})
				end
			else
				if distance_from_spawn_wall > -1.95 and distance_from_spawn_wall < 0 then				
					surface.create_entity({name = "stone-wall", position = pos, force = "north"})

				elseif distance_from_spawn_wall > 0 and distance_from_spawn_wall < 4.5 then
						local name = "wooden-chest"
					local r_max = math.floor(math.abs(distance_from_spawn_wall)) + 2
						if math_random(1,3) == 1 then name = name .. "-remnants" end
						if math_random(1,r_max) == 1 then surface.create_entity({name = name, position = pos, force = "north"}) end

				elseif distance_from_spawn_wall > -6 and distance_from_spawn_wall < -3 then
					if math_random(1, 16) == 1 then
						if surface.can_place_entity({name = "gun-turret", position = pos}) then
							local t = surface.create_entity({name = "gun-turret", position = pos, force = "north"})
							t.insert({name = "firearm-magazine", count = math_random(6,12)})
						end
					else
						if math_random(1, 16) == 1 then
							if surface.can_place_entity({name = "gun-turret", position = pos}) then
								surface.create_entity({name = "gun-turret-remnants", position = pos, force = "north"})
							end
						end
					end
				end
			end
		end
	end
end

local function generate_circle_spawn(event)
	if global.bb_spawn_generated then return end

	local surface = event.surface

	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y

	if left_top_x < -160 then return end
	if left_top_x > 160 then return end
	if left_top_y < -160 then return end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)

			if distance_to_center < spawn_circle_size then
				generate_inner_spawn_circle(pos, distance_to_center, surface) 
			else 
				generate_starting_area(pos, distance_to_center, surface)
			end
		end
	end

	regenerate_decoratives(surface, event.area.left_top)
end

function Public.generate_north_silo(surface)
	local pos = {x = -32 + math.random(0, 64), y = -72}
	local mirror_position = {x = pos.x * -1, y = pos.y * -1}
	
	for _, t in pairs(surface.find_tiles_filtered({area = {{pos.x - 6, pos.y - 6},{pos.x + 6, pos.y + 6}}, name = {"water", "deepwater"}})) do
		surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
	end
	for _, t in pairs(surface.find_tiles_filtered({area = {{mirror_position.x - 6, mirror_position.y - 6},{mirror_position.x + 6, mirror_position.y + 6}}, name = {"water", "deepwater"}})) do
		surface.set_tiles({{name = get_replacement_tile(surface, t.position), position = t.position}})
	end
	
	global.rocket_silo["north"] = surface.create_entity({
		name = "rocket-silo",
		position = pos,
		force = "north"
	})
	global.rocket_silo["north"].minable = false

	for i = 1, 32, 1 do
		create_mirrored_tile_chain(surface, {name = "stone-path", position = global.rocket_silo["north"].position}, 32, 10)
	end
end

local function generate_river(event)
	if event.area.left_top.y < -32 then return end
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)
			if is_horizontal_border_river(pos) then
				surface.set_tiles({{name = "deepwater", position = pos}})
				if math_random(1, 64) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end
		end
	end
end

local function generate_potential_spawn_ore(surface)
	local r = 130
	local area = {{r * -1, r * -1}, {r, 0}}
	local ores = {}
	ores["iron-ore"] = surface.count_entities_filtered({name = "iron-ore", area = area})
	ores["copper-ore"] = surface.count_entities_filtered({name = "copper-ore", area = area})
	ores["coal"] = surface.count_entities_filtered({name = "coal", area = area})
	ores["stone"] = surface.count_entities_filtered({name = "stone", area = area})
	for ore, ore_count in pairs(ores) do
		if ore_count < 1000 or ore_count == nil then
			local pos = {}
			for a = 1, 32, 1 do
				pos = {x = -96 + math_random(0, 192), y = -20 - math_random(0, 96)}
				if surface.can_place_entity({name = "coal", position = pos, amount = 1}) then
					break
				end
			end
			draw_noise_ore_patch(pos, ore, surface, math_random(18, 24), math_random(1500, 2000))
		end
	end
end

local scrap_vectors = {}
for x = -5, 5, 1 do
	for y = -5, 5, 1 do
		if math.sqrt(x^2 + y^2) <= 5 then
			scrap_vectors[#scrap_vectors + 1] = {x, y}
		end
	end
end
local size_of_scrap_vectors = #scrap_vectors

local function generate_extra_worm_turrets(surface, left_top)
	local chunk_distance_to_center = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
	if bb_config.bitera_area_distance > chunk_distance_to_center then return end
	
	local amount = (chunk_distance_to_center - bb_config.bitera_area_distance) * 0.0005
	if amount < 0 then return end
	local floor_amount = math.floor(amount)
	local r = math.round(amount - floor_amount, 3) * 1000
	if math_random(0, 999) <= r then floor_amount = floor_amount + 1 end 
	
	if floor_amount > 64 then floor_amount = 64 end
	
	for _ = 1, floor_amount, 1 do	
		local worm_turret_name = BiterRaffle.roll("worm", chunk_distance_to_center * 0.0001)
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = surface.find_non_colliding_position(worm_turret_name, {left_top.x + v[1], left_top.y + v[2]}, 8, 1)
		if position then
			local worm = surface.create_entity({name = worm_turret_name, position = position, force = "north_biters"})
			
			-- add some scrap piles
			if math_random(1,2) == 1 then
				for c = 1, math_random(2,12), 1 do
					local vector = scrap_vectors[math_random(1, size_of_scrap_vectors)]
					local position = {position.x + vector[1], position.y + vector[2]}
					if surface.can_place_entity({name = "mineable-wreckage", position = position, force = "neutral"}) then
						surface.create_entity({name = "mineable-wreckage", position = position, force = "neutral"})
					end
				end
			end
			
		end
	end
end

local bitera_area_distance = bb_config.bitera_area_distance * -1
local biter_area_angle = 0.45

local function is_biter_area(position)
	if position.y - 96 > bitera_area_distance - (math_abs(position.x) * biter_area_angle) then return false end
	if position.y + 96 < bitera_area_distance - (math_abs(position.x) * biter_area_angle) then return true end
	
	
	if position.y + (get_noise(3, position) * 64) > bitera_area_distance - (math_abs(position.x) * biter_area_angle) then return false end
	return true
end

local function draw_biter_area(surface, left_top)
	local left_top_x = left_top.x
	local left_top_y = left_top.y
	
	if left_top_y > bb_config.bitera_area_distance * -1 + 32 then return end
	
	local out_of_map = {}
	local tiles = {}
	local i = 1
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			if is_biter_area(position) then
				local noise_index = math_floor(math_abs(get_noise(3, position)) * 7) + 1
				if noise_index > 7 then noise_index = 7 end
				out_of_map[i] = {name = "out-of-map", position = position}
				tiles[i] = {name = "dirt-" .. noise_index, position = position}
				i = i + 1			
			end
		end
	end
	
	surface.set_tiles(out_of_map, false)
	surface.set_tiles(tiles, true)
	
	for _ = 1, 4, 1 do
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = {x = left_top_x + v[1], y = left_top_y + v[2]}
		if is_biter_area(position) and surface.can_place_entity({name = "spitter-spawner", position = position}) then
			if math_random(1, 4) == 1 then
				table.insert(global.unit_spawners.north_biters, surface.create_entity({name = "spitter-spawner", position = position, force = "north_biters"}))
			else
				table.insert(global.unit_spawners.north_biters, surface.create_entity({name = "biter-spawner", position = position, force = "north_biters"}))
			end
		end
	end

	local e = (math_abs(left_top_y) - bb_config.bitera_area_distance) * 0.0005	
	for _ = 1, math_random(3, 6), 1 do
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = {x = left_top_x + v[1], y = left_top_y + v[2]}
		local worm_turret_name = BiterRaffle.roll("worm", e)
		if is_biter_area(position) and surface.can_place_entity({name = worm_turret_name, position = position}) then			
			surface.create_entity({name = worm_turret_name, position = position, force = "north_biters"})			
		end
	end
	
	for _ = 1, math_random(8, 16), 1 do
		local v = chunk_tile_vectors[math_random(1, size_of_chunk_tile_vectors)]
		local position = {x = left_top_x + v[1], y = left_top_y + v[2]}
		if is_biter_area(position) and surface.can_place_entity({name = "mineable-wreckage", position = position}) then
			surface.create_entity({name = "mineable-wreckage", position = position, force = "neutral"})		
		end
	end
end

local function mixed_ore(event)
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y

	--Draw noise text values to determine which chunks are valid for mixed ore.
	--rendering.draw_text{text = get_noise(1, {x = left_top_x + 16, y = left_top_y + 16}), surface = surface, target = {x = left_top_x + 16, y = left_top_y + 16}, color = {255, 255, 255}, time_to_live = 3600, scale = 2, font = "default-game"}

	--Skip chunks that are too far off the ore noise value.
	if get_noise(1, {x = left_top_x + 16, y = left_top_y + 16}) < 0.52 then return end

	--Draw the mixed ore patches.
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			if surface.can_place_entity({name = "iron-ore", position = pos}) then
				local noise = get_noise(1, pos)
				if noise > 0.81 then
					local amount = math_random(1250, 1500) + math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 1.1
					local m = (noise - 0.75) * 16
					amount = amount * m
					local i = math.ceil(math.abs(noise * 35)) % 4
					if i == 0 then i = 4 end
					surface.create_entity({name = ores[i], position = pos, amount = amount})
				end
			end
		end
	end
end

function Public.generate(event)
	if event.area.left_top.y >= 0 then return end
	local surface = event.surface
	local left_top = event.area.left_top
	if surface.name ~= "biter_battles" then return end

	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do		
		surface.create_entity({name = e.name, position = e.position, force = "north_biters", direction = e.direction})
		e.destroy()
	end
	
	mixed_ore(event)
	generate_river(event)
	generate_circle_spawn(event)
	
	draw_biter_area(surface, left_top)
	--[[
	if bb_config.builders_area then
		for _, t in pairs(surface.find_tiles_filtered({area = event.area, name = {"water", "deepwater"}})) do
			builders_area_process_tile(t, surface)
		end
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			builders_area_process_entity(e)
		end
	end
	]]
	
	generate_extra_worm_turrets(surface, left_top)

	if global.bb_spawn_generated then return end
	if game.tick > 0 then
		generate_potential_spawn_ore(surface)

		local area = {{-10,-10},{10,10}}
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.name ~= "character" then e.destroy() end
		end
		surface.destroy_decoratives({area = area})

		for _, silo in pairs(global.rocket_silo) do
			for _, entity in pairs(surface.find_entities({{silo.position.x - 4, silo.position.y - 4}, {silo.position.x + 4, silo.position.y + 4}})) do
				if entity.type == "simple-entity" or entity.type == "tree" or entity.type == "resource" then
					entity.destroy()
				end
			end
		end

		global.bb_spawn_generated = true
	end
end

--Landfill Restriction
function Public.restrict_landfill(surface, inventory, tiles)
	for _, t in pairs(tiles) do
		local distance_to_center = math.sqrt(t.position.x ^ 2 + t.position.y ^ 2)
		local check_position = t.position
		if check_position.y > 0 then check_position = {x = check_position.x * -1, y = (check_position.y * -1) - 1} end
		if is_horizontal_border_river(check_position) or distance_to_center < spawn_circle_size then
			surface.set_tiles({{name = t.old_tile.name, position = t.position}}, true)
			inventory.insert({name = "landfill", count = 1})
		end
	end
end

--Construction Robot Restriction
local robot_build_restriction = {
	["north"] = function(y)
		if y >= -10 then return true end
	end,
	["south"] = function(y)
		if y <= 10 then return true end
	end
}

function Public.deny_construction_bots(event)
	if not robot_build_restriction[event.robot.force.name] then return end
	if not robot_build_restriction[event.robot.force.name](event.created_entity.position.y) then return end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	game.print("Team " .. event.robot.force.name .. "'s construction drone had an accident.", {r = 200, g = 50, b = 100})
	event.created_entity.destroy()
end

return Public