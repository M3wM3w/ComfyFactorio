local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local f = {}
local math_random = math.random
local insert = table.insert

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

f.draw_noise_tile_ring = function(surface, position, name, radius_min, radius_max)			
	local modifier_1 = math_random(2,5) * 0.01
	local seed = game.surfaces[1].map_gen_settings.seed
	local tiles = {}
	
	for y = radius_max * -2, radius_max * 2, 1 do
		for x = radius_max * -2, radius_max * 2, 1 do
			local pos = {x = x + position.x, y = y + position.y}			
			local noise = simplex_noise(pos.x * modifier_1, pos.y * modifier_1, seed)
			local distance_to_center = math.sqrt(x^2 + y^2)
			
			if distance_to_center + noise * radius_max * 0.25 < radius_max and distance_to_center + noise * radius_min * 0.25 > radius_min then
				surface.set_tiles({{name = name, position = pos}}, true)																
			end							
		end
	end		
end

f.draw_noise_entity_ring = function(surface, position, name, force, radius_min, radius_max)			
	local modifier_1 = 1 / (radius_max * 2)
	local modifier_2 = 1 / (radius_max * 0.5)
	local seed = game.surfaces[1].map_gen_settings.seed
	local tiles = {}
	
	for y = radius_max * -2, radius_max * 2, 1 do
		for x = radius_max * -2, radius_max * 2, 1 do
			local pos = {x = x + position.x, y = y + position.y}			
			local noise = simplex_noise(pos.x * modifier_1, pos.y * modifier_1, seed) + simplex_noise(pos.x * modifier_2, pos.y * modifier_2, seed) * 0.2
			local distance_to_center = math.sqrt(x^2 + y^2)
			
			if distance_to_center + noise * radius_max * 0.25 < radius_max and distance_to_center + noise * radius_min * 0.25 > radius_min then
				if surface.can_place_entity({name = name, position = pos}) then
					surface.create_entity({name = name, position = pos, force = force})
				end
			end							
		end
	end		
end

f.draw_rainbow_patch = function(position, surface, radius, richness)
	if not position then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local modifier_1 = math_random(3,7)
	local modifier_2 = math_random(1,10) * 0.005
	local modifier_3 = math_random(1,10) * 0.05
	local modifier_4 = math_random(5,30) * 0.01	
	local seed = game.surfaces[1].map_gen_settings.seed
	local ores = {"stone", "coal", "iron-ore", "copper-ore"}
	local richness_part = richness / (radius * 2)
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x, y = y + position.y}			
			local noise = simplex_noise(pos.x * modifier_2, pos.y * modifier_2, seed) + simplex_noise(pos.x * modifier_3, pos.y * modifier_3, seed) * modifier_4
			local distance_to_center = math.sqrt(x^2 + y^2)
			local ore = ores[(math.ceil(noise * modifier_1) % 4) + 1]
			local amount = richness - richness_part * distance_to_center		
			if amount > 1 then
				if surface.can_place_entity({name = ore, position = pos, amount = amount}) then
					if distance_to_center + (noise * radius * 0.5) < radius then					
						surface.create_entity{name = ore, position = pos, amount = amount}									
					end	
				end
			end
		end
	end
end

f.draw_rainbow_patch_v2 = function(position, surface, radius, richness)
	if not position then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local modifier_1 = math_random(2,7)
	local modifier_2 = math_random(100,200) * 0.0002
	local modifier_3 = math_random(100,200) * 0.0015
	local modifier_4 = math_random(15,30) * 0.01	
	local seed = game.surfaces[1].map_gen_settings.seed
	local ores = {"stone", "coal", "iron-ore", "copper-ore"}
	ores = shuffle(ores)
	local richness_part = richness / (radius * 2)
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x, y = y + position.y}			
			local noise = simplex_noise(pos.x * modifier_2, pos.y * modifier_2, seed) + simplex_noise(pos.x * modifier_3, pos.y * modifier_3, seed) * modifier_4
			local distance_to_center = math.sqrt(x^2 + y^2)
			local ore = ores[(math.ceil(noise * modifier_1) % 4) + 1]
			local amount = richness - richness_part * distance_to_center		
			if amount > 1 then
				if surface.can_place_entity({name = ore, position = pos, amount = amount}) then
					if distance_to_center + (noise * radius * 0.5) < radius then					
						surface.create_entity{name = ore, position = pos, amount = amount}									
					end	
				end
			end
		end
	end
end

f.draw_entity_circle = function(position, name, surface, radius, check_collision, amount)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end						
	for y = radius * -1, radius, 1 do
		for x = radius * -1, radius, 1 do
			local pos = {x = x + position.x, y = y + position.y}				
			local distance_to_center = math.sqrt(x^2 + y^2)								
			if distance_to_center <= radius then
				if check_collision then
					if surface.can_place_entity({name = name, position = pos}) then
						if amount then
							surface.create_entity({name = name, position = pos, amount = amount})
						else
							surface.create_entity({name = name, position = pos})
						end				
					end					
				else
					if amount then
						surface.create_entity({name = name, position = pos, amount = amount})
					else
						surface.create_entity({name = name, position = pos})
					end				
				end						
			end			
		end
	end	
end

f.draw_noise_tile_circle = function(position, name, surface, radius)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end	
	local noise_seed_add = 25000
	local tiles = {}			
	for y = radius * -2, radius * 2, 1 do
		for x = radius * -2, radius * 2, 1 do
			local pos = {x = x + position.x, y = y + position.y}	
			local seed = game.surfaces[1].map_gen_settings.seed
			local noise_1 = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
			seed = seed + noise_seed_add
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
			local noise = noise_1 + noise_2 * 0.5
			local distance_to_center = math.sqrt(x^2 + y^2)								
			if distance_to_center + noise * radius * 0.3 < radius then			
				insert(tiles, {name = name, position = pos})
			end			
		end
	end
	surface.set_tiles(tiles, true)
end

f.draw_oil_circle = function(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random		
	local count = 0
	local max_count = 0
	while count < radius and max_count < 100000 do
		for y = radius * -1, radius, 1 do
			for x = radius * -1, radius, 1 do					
				if math_random(1, 200) == 1 then
					local pos = {x = x + position.x, y = y + position.y}
					local a = math_random(richness * 0.5, richness * 1.5)
					local distance_to_center = math.sqrt(x^2 + y^2)						
					if distance_to_center < radius then			
						if surface.can_place_entity({name = name, position = pos, amount = a}) then
							surface.create_entity{name = name, position = pos, amount = a}
							count = count + 1
						end
					end
				end
			end
		end
		max_count = max_count + 1
	end					
end

f.draw_smoothed_out_ore_circle = function(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random	
	local noise_seed_add = 25000	
	local richness_part = richness / radius
	for y = radius * -2, radius * 2, 1 do
		for x = radius * -2, radius * 2, 1 do
			local pos = {x = x + position.x, y = y + position.y}
			local seed = game.surfaces[1].map_gen_settings.seed
			local noise_1 = simplex_noise(pos.x * 0.08, pos.y * 0.08, seed)
			seed = seed + noise_seed_add
			local noise_2 = simplex_noise(pos.x * 0.15, pos.y * 0.15, seed)
			local noise = noise_1 + noise_2 * 0.2
			local distance_to_center = math.sqrt(x^2 + y^2)						
			local a = richness - richness_part * distance_to_center
			if distance_to_center + ((1 + noise) * 3) < radius and a > 1 then			
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}									
				end
			end			
		end
	end
end

f.draw_crazy_smoothed_out_ore_circle = function(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local math_random = math.random	
	local noise_seed_add = 25000	
	local richness_part = richness / radius
	for y = radius*-1, radius, 1 do
		for x = radius*-1, radius, 1 do
			local pos = {x = x + position.x, y = y + position.y}	
			local seed = game.surfaces[1].map_gen_settings.seed
			local noise_1 = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
			seed = seed + noise_seed_add
			local noise_2 = simplex_noise(pos.x * 0.2, pos.y * 0.2, seed)
			local noise = noise_1 + noise_2 * 0.2
			local distance_to_center = math.sqrt(x^2 + y^2)						
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius * noise and a > 1 then			
				if surface.can_place_entity({name = name, position = pos, amount = a}) then
					surface.create_entity{name = name, position = pos, amount = a}									
				end
			end			
		end
	end
end

f.create_cluster = function(name, pos, size, surface, spread, resource_amount)		
	local p = {x = pos.x, y = pos.y}
	local math_random = math.random
	local original_pos = {x = pos.x, y = pos.y}
	local entity_has_been_placed = false
	for z = 1, size, 1 do
		entity_has_been_placed = false
		local y = 1
		if spread then y = math_random(1, spread) end	
		local modifier_raffle = {{0,y*-1},{y*-1,0},{y,0},{0,y},{y*-1,y*-1},{y,y},{y,y*-1},{y*-1,y}}
		modifier_raffle = shuffle(modifier_raffle)
		for x = 1, 8, 1 do					
			local m = modifier_raffle[x]
			local pos = {x = p.x + m[1], y = p.y + m[2]}
			if resource_amount then
				if surface.can_place_entity({name=name, position=pos, amount=resource_amount}) then
					surface.create_entity {name=name, position=pos, amount=resource_amount}				
					p = {x = pos.x, y = pos.y}
					entity_has_been_placed = true
					break
				end
			else
				if surface.can_place_entity({name=name, position=pos}) then
					surface.create_entity {name=name, position=pos}
					p = {x = pos.x, y = pos.y}	
					entity_has_been_placed = true
					break
				end
			end
		end
		if entity_has_been_placed == false then
			p = {x = original_pos.x, y = original_pos.y}
		end
	end
end

return f