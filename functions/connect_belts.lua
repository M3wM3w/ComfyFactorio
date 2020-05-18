local direction_translation = {
	["north"] = 1,
	["east"] = 2,
	["south"] = 3,
	["west"] = 4,
}

local direction_tendencies = {
	[1] = {0, 2, 4, 6},
	[2] = {2, 4, 6, 0},
	[3] = {4, 6, 0, 2},
	[4] = {6, 0, 2, 4},
}

local function get_optimal_direction(entity, direction_tendency)
	local original_direction = entity.direction
	local optimal_direction = entity.direction
	local max_connection_count = #entity.belt_neighbours["inputs"] + #entity.belt_neighbours["outputs"]
	local original_count = #entity.belt_neighbours["inputs"] + #entity.belt_neighbours["outputs"]
	
	for _, d in pairs(direction_tendency) do
		entity.direction = d
		local count = #entity.belt_neighbours["inputs"] + #entity.belt_neighbours["outputs"]
		--if #entity.belt_neighbours["inputs"] > 0 and #entity.belt_neighbours["outputs"] > 0 then
		--	optimal_direction = d
		--	break
		--end	
		if count > max_connection_count then
			max_connection_count = count
			optimal_direction = d
		end		
	end
	
	if max_connection_count == 1 then	
		for _, d in pairs(direction_tendency) do
			entity.direction = d		
			if #entity.belt_neighbours["inputs"] > 0 then
				if d == entity.belt_neighbours["inputs"][1].direction then
					optimal_direction = d					
					break
				end
			end		
			if #entity.belt_neighbours["outputs"] > 0 then
				if d == entity.belt_neighbours["outputs"][1].direction then
					optimal_direction = d
					break
				end
			end
		end		
	end
		
	entity.direction = original_direction
	
	return optimal_direction
end

function connect_belts(entities, d)
	for a = 1, 4, 1 do
		local r = d
		if not r then r = math.random(1, 4) end
		for k, entity in pairs(entities) do
			entity.direction = get_optimal_direction(entity, direction_tendencies[r])
		end
	end
end

return connect_belts