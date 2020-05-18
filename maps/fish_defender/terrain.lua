local map_functions = require "tools.map_functions"
local simplex_noise = require "utils.simplex_noise".d2
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_sqrt = math.sqrt

local hourglass_center_piece_length = 64
local worm_raffle_table = {
		[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"},
		[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"},
		[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[9] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[10] = {"medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
	}	
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}

local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "grass-1"
end

local function is_enemy_territory(p)
	if p.x - 64 < math_abs(p.y) then return false end
	--if p.x - 64 < p.y then return false end
	if p.x < 160 then return false end
	if p.x > 1024 then return false end
	if p.y > 512 then return false end
	if p.y < -512 then return false end
	local noise = math_abs(simplex_noise(0, p.y * 0.015, game.surfaces[1].map_gen_settings.seed) * 96)
	local noise_2 = math_abs(simplex_noise(0, p.y * 0.1, game.surfaces[1].map_gen_settings.seed) * 16)
	if p.x > 288 + noise + noise_2 + math_abs(p.y * 0.75) then return false end
	return true
end

local body_radius = 3072
local body_square_radius = body_radius ^ 2
local body_center_position = {x = -1500, y = 0}
local body_spacing = math_floor(body_radius * 0.82)
local body_circle_center_1 = {x = body_center_position.x, y = body_center_position.y - body_spacing}
local body_circle_center_2 = {x = body_center_position.x, y = body_center_position.y + body_spacing}

local fin_radius = 800
local square_fin_radius = fin_radius ^ 2
local fin_circle_center_1 = {x = -480, y = 0}
local fin_circle_center_2 = {x = -480 - 360, y = 0}

local function is_body(p)	
	if p.y <= map_height and p.y >= map_height * -1 and p.x <= 160 and p.x > body_center_position.x then return true end
	
	--Main Fish Body			
	local distance_to_center_1 = ((p.x - body_circle_center_1.x)^2 + (p.y - body_circle_center_1.y)^2)
	local distance_to_center_2 = ((p.x - body_circle_center_2.x)^2 + (p.y - body_circle_center_2.y)^2)	
	--if distance_to_center_1 < body_square_radius and distance_to_center_2 < body_square_radius then return true end
	if distance_to_center_1 < body_square_radius then 
		if distance_to_center_2 < body_square_radius then return true end 
	end
	
	--Fish Fins
	local distance_to_center_1 = ((p.x - fin_circle_center_1.x)^2 + (p.y - fin_circle_center_1.y)^2)
	if distance_to_center_1 + math_abs(simplex_noise(0, p.y * 0.075, game.surfaces[1].map_gen_settings.seed) * 32000) > square_fin_radius then
		local distance_to_center_2 = ((p.x - fin_circle_center_2.x)^2 + (p.y - fin_circle_center_2.y)^2)
		if distance_to_center_2 < square_fin_radius then
			return true
		end
	end
	
	return false
end

local function is_out_of_map_tile(p)
	if p.y > 850 then return true end
	if p.y < -850 then return true end
	if p.x < -3264 then return true end
	if p.x > 800 then return true end
	if is_enemy_territory(p) then return false end
	if is_body(p) then return false end
	return true
end

local function generate_spawn_area(surface)
	surface.request_to_generate_chunks({x = 0, y = 0}, 7)
	surface.request_to_generate_chunks({x = 160, y = 0}, 5)
	--surface.force_generate_chunk_requests()
	if global.spawn_area_generated then return end
	if not surface.is_chunk_generated({-7, 0}) then return end
	if not surface.is_chunk_generated({5, 0}) then return end
	global.spawn_area_generated = true

	local spawn_position_x = -128

	surface.create_entity({name = "electric-beam", position = {160, -96}, source = {160, -96}, target = {160,96}})

	for _, tile in pairs(surface.find_tiles_filtered({name = {"water", "deepwater"}, area = {{-160, -160},{160, 160}}})) do
		local noise = math_abs(simplex_noise(tile.position.x * 0.02, tile.position.y * 0.02, game.surfaces[1].map_gen_settings.seed) * 16)
		if tile.position.x > -160 + noise then	surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true) end
	end

	for _, entity in pairs(surface.find_entities_filtered({type = {"resource", "cliff"}, area = {{spawn_position_x - 32, -256},{160, 256}}})) do
		if is_body(entity.position) then
			if entity.position.x > spawn_position_x - 32 + math_abs(simplex_noise(entity.position.x * 0.02, entity.position.y * 0.02, game.surfaces[1].map_gen_settings.seed) * 16) then
				entity.destroy() 
			end
		end
	end	

	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	for x = -4, 4, 1 do
		for y = -3, 3, 1 do
			surface.regenerate_decorative(decorative_names, {{x,y}})
		end
	end
	
	local y = 80
	local ore_positions = {{x = spawn_position_x - 52, y = y},{x = spawn_position_x - 52, y = y * 0.5},{x = spawn_position_x - 52, y = 0},{x = spawn_position_x - 52, y = y * -0.5},{x = spawn_position_x - 52, y = y * -1}}
	table.shuffle_table(ore_positions)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[1], "copper-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[2], "iron-ore", surface, 15, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[3], "coal", surface, 15, 1500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[4], "stone", surface, 15, 1500)
	map_functions.draw_noise_tile_circle({x = spawn_position_x - 20, y = 0}, "water", surface, 16)
	map_functions.draw_oil_circle(ore_positions[5], "crude-oil", surface, 8, 200000)

	local pos = surface.find_non_colliding_position("market",{spawn_position_x, 0}, 50, 1)
	global.market = place_fish_market(surface, pos)
	
	local r = 16
	for _, entity in pairs(surface.find_entities_filtered({area = {{global.market.position.x - r, global.market.position.y - r}, {global.market.position.x + r, global.market.position.y + r}}, type = "tree"})) do
		local distance_to_center = math_sqrt((entity.position.x - global.market.position.x)^2 + (entity.position.y - global.market.position.y)^2)
		if distance_to_center < r then
			if math_random(1, r) > distance_to_center then entity.destroy() end
		end
	end
	
	local pos = surface.find_non_colliding_position("gun-turret",{spawn_position_x + 5, 1}, 50, 1)
	local turret = surface.create_entity({name = "gun-turret", position = pos, force = "player"})
	turret.insert({name = "firearm-magazine", count = 32})

	for x = -20, 20, 1 do
		for y = -20, 20, 1 do
			local pos = {x = global.market.position.x + x, y = global.market.position.y + y}
			--local distance_to_center = math_sqrt(x^2 + y^2)
			--if distance_to_center > 8 and distance_to_center < 15 then
			local distance_to_center = x^2 + y^2
			if distance_to_center > 64 and distance_to_center < 225 then
				if math_random(1,3) == 1 and surface.can_place_entity({name = "wooden-chest", position = pos, force = "player"}) then
					local chest = surface.create_entity({name = "wooden-chest", position = pos, force = "player"})
				end
			end
		end
	end

	local area = {{x = -160, y = -96}, {x = 160, y = 96}}
	for _, tile in pairs(surface.find_tiles_filtered({name = "water", area = area})) do
		if math_random(1, 32) == 1 then
			surface.create_entity({name = "fish", position = tile.position})
		end
	end

	local pos = surface.find_non_colliding_position("character",{spawn_position_x + 1, 4}, 50, 1)
	game.forces["player"].set_spawn_position(pos, surface)
	for _, player in pairs(game.connected_players) do
		local pos = surface.find_non_colliding_position("character",{spawn_position_x + 1, 4}, 50, 1)
		player.teleport(pos, surface)
	end
end

local function enemy_territory(surface, left_top)
	--surface.request_to_generate_chunks({x = 256, y = 0}, 16)
	--surface.force_generate_chunk_requests()
	
	if left_top.x < 160 then return end
	if left_top.x > 750 then return end
	if left_top.y > 512 then return end
	if left_top.y < -512 then return end
	
	local area = {{left_top.x, left_top.y},{left_top.x + 32, left_top.y + 32}}
	
	--local area = {{160, -512},{750, 512}}
	--for _, tile in pairs(surface.find_tiles_filtered({area = area})) do
	--	if is_enemy_territory(tile.position) then
	--		surface.set_tiles({{name = "water-mud", position = {tile.position.x, tile.position.y}}}, true)
	--	end
	--end
	if left_top.x > 256 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos = {x = left_top.x + x, y = left_top.y + y}
				if is_enemy_territory(pos) then
					if math_random(1, 512) == 1 then
						if surface.can_place_entity({name = "biter-spawner", force = "decoratives", position = pos}) then
							local entity
							if math_random(1,4) == 1 then
								entity = surface.create_entity({name = "spitter-spawner", force = "decoratives", position = pos})
							else
								entity = surface.create_entity({name = "biter-spawner", force = "decoratives", position = pos})
							end
							entity.active = false
							entity.destructible = false
						end
					end
					--if pos.x % 32 == 0 and pos.y % 32 == 0 then
					--	local decorative_names = {}
					--	for k,v in pairs(game.decorative_prototypes) do
					--		if v.autoplace_specification then
					--		  decorative_names[#decorative_names+1] = k
					--		end
					--	 end
					--	surface.regenerate_decorative(decorative_names, {{x=math_floor(pos.x/32),y=math_floor(pos.y/32)}})
					--end
				end
			end
		end
	end
	for _, entity in pairs(surface.find_entities_filtered({area = area, type = {"tree", "cliff"}})) do
		if is_enemy_territory(entity.position) then entity.destroy() end
	end
	for _, entity in pairs(surface.find_entities_filtered({area = area, type = "resource"})) do
		if is_enemy_territory(entity.position) then
			surface.create_entity({name = "uranium-ore", position = entity.position, amount = math_random(200, 8000)})
			entity.destroy()
		end
	end
	for _, tile in pairs(surface.find_tiles_filtered({name = {"water", "deepwater"}, area = area})) do
		if is_enemy_territory(tile.position) then
			surface.set_tiles({{name = get_replacement_tile(surface, tile.position), position = {tile.position.x, tile.position.y}}}, true)
		end
	end	
end

local function fish_mouth(surface, left_top)
	if left_top.x > -2300 then return end
	if left_top.y > 64 then return end
	if left_top.y < -64 then return end
	if left_top.x < -3292 then return end

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local noise = simplex_noise(pos.x * 0.006, 0, game.surfaces[1].map_gen_settings.seed) * 20		
			if pos.y <= 12 + noise and pos.y >= -12 + noise then surface.set_tiles({{name = "water", position = pos}}) end
		end
	end	
end

function fish_eye(surface, position)
	surface.request_to_generate_chunks(position, 2)
	surface.force_generate_chunk_requests()
	for x = -48, 48, 1 do
		for y = -48, 48, 1 do
			local p = {x = position.x + x, y = position.y + y}
			--local distance = math_sqrt(((position.x - p.x) ^ 2) + ((position.y - p.y) ^ 2))
			--if distance < 44 then
			--	surface.set_tiles({{name = "water-green", position = p}}, true)
			--end
			--if distance < 22 then
			--	surface.set_tiles({{name = "out-of-map", position = p}}, true)
			--end

			local distance = ((position.x - p.x) ^ 2) + ((position.y - p.y) ^ 2)
			if distance < 1936 then
				if distance < 484 then
					surface.set_tiles({{name = "out-of-map", position = p}}, true)
				else
					surface.set_tiles({{name = "water-green", position = p}}, true)
				end
			end
			
		end
	end
end

local ores = {"coal", "iron-ore", "copper-ore", "stone"}

local function plankton_territory(surface, position, seed)		
	local noise = simplex_noise(position.x * 0.009, position.y * 0.009, seed)	
	local d = 196
	local tile_to_set = "out-of-map"
	if position.x + position.y > (d * -1) - (math_abs(noise) * d * 3) and position.x > position.y - (d + (math_abs(noise) * d * 3)) then return "out-of-map" end
	
	local noise_2 = simplex_noise(position.x * 0.0075, position.y * 0.0075, seed + 10000)
	--if noise_2 > 0.87 then surface.set_tiles({{name = "deepwater-green", position = position}}, true) return true end
	if noise_2 > 0.87 then return "deepwater-green" end
	if noise_2 > 0.75 then
		local i = math_floor(noise * 6) % 4 + 1
		--surface.set_tiles({{name = "grass-" .. i, position = position}}, true)
		surface.create_entity({name = ores[i], position = position, amount = 1 + 2500 * math_abs(noise_2 * 3)})	
		return ("grass-" .. i)  
	end	
	if noise_2 < -0.76 then
		local i = math_floor(noise * 6) % 4 + 1
		--surface.set_tiles({{name = "grass-" .. i, position = position}}, true)
		if noise_2 < -0.86 then surface.create_entity({name = "uranium-ore", position = position, amount = 1 + 1000 * math_abs(noise_2 * 2)}) return ("grass-" .. i) end
		if math_random(1, 3) ~= 1 then surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = position}) end
		return ("grass-" .. i) 
	end
	
	if noise < 0.12 and noise > -0.12 then
		local i = math_floor(noise * 32) % 4 + 1
		--surface.set_tiles({{name = "grass-" .. i, position = position}}, true)
		if math_random(1, 5) == 1 then surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = position}) end
		return ("grass-" .. i)
	end
		
	--surface.set_tiles({{name = "water", position = position}}, true)
	if math_random(1, 128) == 1 then surface.create_entity({name = "fish", position = position}) end
	
	return "water"	
end

local function process_chunk(left_top)
	local surface = game.surfaces["fish_defender"]
	local seed = game.surfaces[1].map_gen_settings.seed
	
	generate_spawn_area(surface)
	enemy_territory(surface, left_top)
	fish_mouth(surface, left_top)
	
	local tiles = {}
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map_tile(pos) then	
				--if not plankton_territory(surface, pos, seed) then surface.set_tiles({{name = "out-of-map", position = pos}}, true) end
				local tile_to_set = plankton_territory(surface, pos, seed)
				--local tile_to_set = "out-of-map"
				table.insert(tiles, {name = tile_to_set, position = pos})	
			end
		end
	end
	
	surface.set_tiles(tiles,true)
	
	--if game.tick == 0 then return end
	--if game.forces.player.is_chunk_charted(surface, {left_top.x / 32, left_top.y / 32}) then
		game.forces.player.chart(surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	--end
end

local function process_chunk_queue()
	for k, left_top in pairs(global.chunk_queue) do
		process_chunk(left_top)
		table.remove(global.chunk_queue, k)
		return
	end
end

local function on_chunk_generated(event)
	if game.surfaces["fish_defender"].index ~= event.surface.index then return end
	local left_top = event.area.left_top
	
	if game.tick == 0 then
		process_chunk(left_top)
	else
		table.insert(global.chunk_queue, {x = left_top.x, y = left_top.y})
	end
end

local event = require 'utils.event'
event.on_nth_tick(25, process_chunk_queue)
event.add(defines.events.on_chunk_generated, on_chunk_generated)