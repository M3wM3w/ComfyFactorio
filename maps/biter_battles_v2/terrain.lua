-- Terrain for Biter Battles -- by MewMew
local event = require 'utils.event' 
local math_random = math.random
local simplex_noise = require 'utils.simplex_noise'.d2
local create_tile_chain = require "functions.create_tile_chain"
local spawn_circle_size = 28
local ores = {"copper-ore", "iron-ore", "stone", "coal"}	
	
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
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.0042, pos.y * 0.0042, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.031, pos.y * 0.031, seed)
		--seed = seed + noise_seed_add
		--noise[3] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.08-- + noise[3] * 0.015
		return noise
	end
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.011, pos.y * 0.011, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.08, pos.y * 0.08, seed)
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	if name == 3 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.08, pos.y * 0.08, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
end

local function draw_noise_ore_patch(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random	
	local noise_seed_add = 25000	
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x, y = y + position.y}
			local seed = game.surfaces[1].map_gen_settings.seed
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			seed = seed + noise_seed_add
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)						
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then			
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}
					
					local mirror_pos = {x = pos.x * -1, y = pos.y * -1}
					surface.create_entity{name = name, position = mirror_pos, amount = a}
				end
			end			
		end
	end
end

local function generate_horizontal_river(surface, pos)
	if pos.y < -32 then return false end
	if pos.y > -5 and pos.x > -5 and pos.x < 5 then return false end
	if -11 < pos.y + (get_noise(1, pos) * 5) then return true end
	--if -13 < pos.y + (get_noise(1, pos) * 5) then return true end
	return false	
end

local function generate_circle_spawn(event)
	if event.area.left_top.y < -160 then return end
	if event.area.left_top.x < -160 then return end
	if event.area.left_top.x > 160 then return end	
	local surface = event.surface		
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local distance_to_center = math.sqrt(pos.x ^ 2 + pos.y ^ 2)
			
			local tile = false
			if distance_to_center < spawn_circle_size then
				tile = "deepwater"
				if math_random(1, 48) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end						
			if distance_to_center < 9.5 then tile = "refined-concrete" end
			if distance_to_center < 7 then tile = "sand-1" end					
			if tile then surface.set_tiles({{name = tile, position = pos}}, true) end
			
			if surface.can_place_entity({name = "stone-wall", position = pos}) then
				local noise = get_noise(2, pos) * 15
				local r = 100
				if distance_to_center + noise < r and distance_to_center + noise > r - 1.75 then
					surface.create_entity({name = "stone-wall", position = pos, force = "north"})
				end
				if distance_to_center + noise < r - 4 and distance_to_center + noise > r - 6 then
					if math_random(1,75) == 1 then
						if surface.can_place_entity({name = "gun-turret", position = pos}) then
							local t = surface.create_entity({name = "gun-turret", position = pos, force = "north"})
							t.insert({name = "firearm-magazine", count = math_random(15,30)})
						end
					end
				end
			end
			
		end
	end
end

local function generate_silos(event)
	if global.bb_game_won_by_team then return end
	if global.rocket_silo["north"] then
		if global.rocket_silo["north"].valid then return end
	end	
	
	local surface = event.surface
	local pos = surface.find_non_colliding_position("rocket-silo", {0,-64}, 32, 1)
	if not pos then pos = {x = 0, y = -64} end
	global.rocket_silo["north"] = surface.create_entity({
		name = "rocket-silo",
		position = pos,
		force = "north"
	})
	global.rocket_silo["north"].minable = false
	
	for i = 1, 32, 1 do
		create_tile_chain(surface, {name = "stone-path", position = global.rocket_silo["north"].position}, 32, 10)
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
			if generate_horizontal_river(surface, pos) then
				surface.set_tiles({{name = "deepwater", position = pos}})
				if math_random(1, 64) == 1 then surface.create_entity({name = "fish", position = pos}) end
			end			
		end
	end
end

local function rainbow_ore_and_ponds(event)
	local surface = event.surface
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			if surface.can_place_entity({name = "iron-ore", position = pos}) then
				local noise = get_noise(1, pos)
				if noise > 0.83 then
					local amount = math_random(1000, 2000) + math.sqrt(pos.x ^ 2 + pos.y ^ 2) * 2
					local m = (noise - 0.82) * 40
					amount = amount * m
					local i = math.ceil(math.abs(noise * 50)) % 4
					if i == 0 then i = 4 end
					surface.create_entity({name = ores[i], position = pos, amount = amount})					
				end
				if noise < -0.86 then
					if noise < -0.92 then 
						surface.set_tiles({{name = "deepwater", position = pos}})
					else
						surface.set_tiles({{name = "water", position = pos}})
					end					
					if math_random(1, 48) == 1 then surface.create_entity({name = "fish", position = pos}) end
				end
			end
		end
	end
end

local function generate_potential_spawn_ore(event)
	if event.area.left_top.x ~= -320 then return end
	if event.area.left_top.y ~= -320 then return end
	local surface = event.surface
	local r = 130
	local area = {{r * -1, r * -1}, {r, 0}}
	local ores = {}
	ores["iron-ore"] = surface.count_entities_filtered({name = "iron-ore", area = area})
	ores["copper-ore"] = surface.count_entities_filtered({name = "copper-ore", area = area})
	ores["coal"] = surface.count_entities_filtered({name = "coal", area = area})
	ores["stone"] = surface.count_entities_filtered({name = "stone", area = area})
	for ore, ore_count in pairs(ores) do
		if ore_count < 750 or ore_count == nil then
			local pos = {}
			for a = 1, 32, 1 do
				pos = {x = -96 + math_random(0, 192), y = -20 - math_random(0, 96)}
				if surface.can_place_entity({name = "coal", position = pos, amount = 1}) then
					break					
				end
			end
			draw_noise_ore_patch(pos, ore, surface, math_random(18, 28), math_random(2000, 3000))
		end
	end
end

local function on_chunk_generated(event)
	if event.area.left_top.y >= 0 then return end
	local surface = event.surface
	if surface.name ~= "biter_battles" then return end		 	
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do
		surface.create_entity({name = e.name, position = e.position, force = "north_biters", direction = e.direction})
		e.destroy()
	end
	
	rainbow_ore_and_ponds(event)
	generate_river(event)
	generate_circle_spawn(event)		
	generate_potential_spawn_ore(event)
	generate_silos(event)
	
	if event.area.left_top.y == -320 and event.area.left_top.x == -320 then
		local area = {{-10,-10},{10,10}}
		for _, e in pairs(surface.find_entities_filtered({area = area})) do
			if e.name ~= "player" then e.destroy() end
		end
		surface.destroy_decoratives({area = area})
		
		for _, silo in pairs(global.rocket_silo) do
			for _, entity in pairs(surface.find_entities({{silo.position.x - 4, silo.position.y - 4}, {silo.position.x + 4, silo.position.y + 4}})) do
				if entity.type == "simple-entity" or entity.type == "tree" or entity.type == "resource" then
					entity.destroy()					
				end
			end
		end
	end
end

--Landfill Restriction
local function restrict_landfill(surface, inventory, tiles)
	for _, t in pairs(tiles) do
		local distance_to_center = math.sqrt(t.position.x ^ 2 + t.position.y ^ 2)
		local check_position = t.position
		if check_position.y > 0 then check_position = {x = check_position.x * -1, y = (check_position.y * -1) - 1} end
		if generate_horizontal_river(surface, check_position) or distance_to_center < spawn_circle_size then																			
			surface.set_tiles({{name = t.old_tile.name, position = t.position}}, true)
			inventory.insert({name = "landfill", count = 1})
		end				
	end	
end
local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	restrict_landfill(player.surface, player, event.tiles)
end
local function on_robot_built_tile(event)
	restrict_landfill(event.robot.surface, event.robot.get_inventory(defines.inventory.robot_cargo), event.tiles)	
end

--Construction Robot Restriction
local function on_robot_built_entity(event)
	local deny_building = false
	local force_name = event.robot.force.name
	if force_name == "north" then
		if event.created_entity.position.y >= -10 then deny_building = true end
	end
	if force_name == "player" then
		if event.created_entity.position.y <= 10 then deny_building = true end
	end	
	if not deny_building then return end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	event.created_entity.destroy()			
end

local function on_marked_for_deconstruction(event)
	if not event.entity.valid then return end
	if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
end

event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_chunk_generated, on_chunk_generated)