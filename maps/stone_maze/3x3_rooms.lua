local room = {}

room.empty = function(surface, cell_left_top, direction)
	
end

room.biters = function(surface, cell_left_top, direction)
	local amount = get_biter_amount() * 2
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size * 3 - 0.5, 1 do
		for y = 0.5, grid_size * 3 - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		local enemy = get_biter()
		if surface.can_place_entity({name = enemy, position = pos}) then
			surface.create_entity({name = enemy, position = pos, force = "enemy"})
			amount = amount - 1
		end
		if amount < 1 then break end
	end		
end

room.spitters = function(surface, cell_left_top, direction)
	local amount = get_biter_amount() * 2
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size * 3 - 0.5, 1 do
		for y = 0.5, grid_size * 3 - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		local enemy = get_spitter()
		if surface.can_place_entity({name = enemy, position = pos}) then
			surface.create_entity({name = enemy, position = pos, force = "enemy"})
			amount = amount - 1
		end
		if amount < 1 then break end
	end		
end

room.nests = function(surface, cell_left_top, direction)	
	local amount = math.ceil(get_biter_amount() * 0.1)
	local tile_positions = {}
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 0.5, grid_size * 3 - 0.5, 1 do
		for y = 0.5, grid_size * 3 - 0.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			tile_positions[#tile_positions + 1] = pos
		end
	end
	
	table.shuffle_table(tile_positions)
	
	for _, pos in pairs(tile_positions) do
		if surface.can_place_entity({name = "spitter-spawner", position = pos}) then
			if math.random(1,4) == 1 then
				surface.create_entity({name = "spitter-spawner", position = pos, force = "enemy"})			
			else
				surface.create_entity({name = "biter-spawner", position = pos, force = "enemy"})
			end
			amount = amount - 1
		end			
		if amount < 1 then break end
	end
end

room.uranium_wasteland = function(surface, cell_left_top, direction)
	
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	local center_pos = {x = left_top.x + grid_size * 1.5, y = left_top.y + grid_size * 1.5}
	
	map_functions.draw_noise_tile_circle(center_pos, "water-green", surface, grid_size * 0.65)
	map_functions.draw_smoothed_out_ore_circle(center_pos, "uranium-ore", surface, grid_size * 1.3, get_ore_amount())
	
	for x = math.floor(grid_size * 3 * 0.1), math.floor(grid_size * 3 * 0.9), 1 do
		for y = math.floor(grid_size * 3 * 0.1), math.floor(grid_size * 3 * 0.9), 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			local distance_to_center = math.sqrt((center_pos.x - pos.x) ^ 2 + (center_pos.y - pos.y) ^ 2)
			if math.random(1,128) == 1 and distance_to_center < grid_size * 1.4 then			
				spawn_enemy_gun_turret(surface, pos)
			end
			if math.random(1,10) == 1 and distance_to_center < grid_size * 1.4 then
				if surface.can_place_entity({name = "mineable-wreckage", position = pos, force = "neutral"}) then
					surface.create_entity({name = get_scrap(), position = pos, force = "neutral"}) 
				end
			end
		end
	end
	
	room.biters(surface, cell_left_top, direction)
end

room.stone_block = function(surface, cell_left_top, direction)	
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	for x = 3.5, grid_size * 3 - 3.5, 1 do
		for y = 3.5, grid_size * 3 - 3.5, 1 do
			local pos = {left_top.x + x, left_top.y + y}			
			if math.random(1,5) ~= 1 then surface.create_entity({name = rock_raffle[math.random(1, #rock_raffle)], position = pos, force = "neutral"}) end
		end
	end
	
	for a = 1, math.random(1, 3), 1 do
		local chest = surface.create_entity({
			name = "steel-chest",
			position = {left_top.x + math.random(math.floor(grid_size * 0.5), math.floor(grid_size * 2.5)), left_top.y + math.random(math.floor(grid_size * 0.5), math.floor(grid_size * 2.5))},
			force = "neutral",
		})
		for a = 1, math.random(1, 4), 1 do
			chest.insert(get_loot_item_stack())
		end
	end
end

room.tree_square_nests = function(surface, cell_left_top, direction)
	local left_top = {x = cell_left_top.x * grid_size, y = cell_left_top.y * grid_size}
	
	local tree = tree_raffle[math.random(1, #tree_raffle)]
	
	for x = 0, grid_size * 3 - 1, 1 do
		for y = 0, grid_size * 3 - 1, 1 do
			local pos = {left_top.x + x, left_top.y + y}
			if x <= 1 or x >= grid_size * 3 - 2 or y <= 1 or y >= grid_size * 3 - 2 then
				surface.create_entity({name = tree, position = pos, force = "neutral"})			
			end
		end
	end	
	room.nests(surface, cell_left_top, direction)
	room.spitters(surface, cell_left_top, direction)
	room.biters(surface, cell_left_top, direction)
end

local room_weights = {
	{func = room.uranium_wasteland, weight = 1},
	{func = room.stone_block, weight = 3},
	{func = room.tree_square_nests, weight = 3}	
}

local room_shuffle = {}
for _, r in pairs(room_weights) do
	for c = 1, r.weight, 1 do
		room_shuffle[#room_shuffle + 1] = r.func
	end
end

return room_shuffle