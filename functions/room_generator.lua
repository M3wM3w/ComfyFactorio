local Public = {}
local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random

local room_spacing = 4

local function build_room(surface, position, vector, room_center_position, room_radius)
	local room = {}
	
	local a = room_radius - 1
	local room_area = {
		left_top = {x = room_center_position.x - a, y = room_center_position.y - a},
		right_bottom = {x = room_center_position.x + room_radius, y = room_center_position.y + room_radius}	
	}		
	room.room_tiles = surface.find_tiles_filtered({area = room_area})
	
	room.path_tiles = {}
	for d = 1, room_spacing, 1 do
		local p = {position.x + vector[1] * d, position.y + vector[2] * d}
		local tile = surface.get_tile(p)
		table_insert(room.path_tiles, tile)
	end
	
	room.entrance_tile = surface.get_tile({position.x + vector[1] * (room_spacing + 1), position.y + vector[2] * (room_spacing + 1)})

	room.room_border_tiles = {}
	local left_top = {x = room_area.left_top.x - 1, y = room_area.left_top.y - 1}
	local right_bottom = {x = room_area.right_bottom.x, y = room_area.right_bottom.y}
	local t = room.room_border_tiles
	for d = 1, room_radius * 2, 1 do
		table_insert(t, surface.get_tile({left_top.x + d, left_top.y}))
		table_insert(t, surface.get_tile({left_top.x, left_top.y + d}))
		table_insert(t, surface.get_tile({right_bottom.x - d, right_bottom.y}))
		table_insert(t, surface.get_tile({right_bottom.x, right_bottom.y - d}))
	end
	table_insert(t, surface.get_tile(left_top))
	table_insert(t, surface.get_tile(right_bottom))
	table_insert(t, surface.get_tile({left_top.x + room_radius * 2, left_top.y + room_radius * 2}))
	table_insert(t, surface.get_tile({right_bottom.x - (room_radius * 2), right_bottom.y - (room_radius * 2)}))
	
	room.center = room_center_position
	room.radius = room_radius
	
	return room
end

local function scan_direction(surface, position, vector, room_radius)
	local valid_tile_count = 0
		
	for d = 1, room_radius * 2 + room_spacing * 2, 1 do
		local p = {position.x + vector[1] * d, position.y + vector[2] * d}
		local tile = surface.get_tile(p)
		if not tile.collides_with("resource-layer") then 
			return false
		end
	end
	
	local a = room_radius + room_spacing + 1
	local b = room_radius + room_spacing
	
	local room_center_position = {x = position.x + vector[1] * a, y = position.y + vector[2] * a}
	
	local search_area = {
		{x = room_center_position.x - b, y = room_center_position.y - b},
		{x = room_center_position.x + b + 1, y = room_center_position.y + b + 1}
	}
	
	local tiles = surface.find_tiles_filtered({area = search_area})
	for _, tile in pairs(tiles) do
		if not tile.collides_with("resource-layer") then 
			return false
		end
	end
	
	return build_room(surface, position, vector, room_center_position, room_radius)
end

local function get_room_tiles(surface, position, room_radius)
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)

	for _, v in pairs(vectors) do
		local room = scan_direction(surface, position, v, room_radius)
		if room then 
			return room
		end
	end
	
	for _, v in pairs(vectors) do
		local room = scan_direction(surface, position, v, room_radius)
		if room then 
			return room
		end
	end
end

local function expand_path_tiles_width(surface, room)
	if not room then return end
	
	local max_expansion_count = 0
	if math_random(1, 3) == 1 then max_expansion_count = 1 end
	if math_random(1, 9) == 1 then max_expansion_count = 2 end
	if max_expansion_count == 0 then return end
	
	local path_tiles = room.path_tiles
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	
	local entrance_tile
	local exit_tile
	
	local position = path_tiles[1].position
	local expansion_vectors = {}
	for _, v in pairs(vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if not tile.collides_with("resource-layer") then		
			entrance_tile = tile
			exit_tile = surface.get_tile({path_tiles[#path_tiles].position.x + v[1] * -1, path_tiles[#path_tiles].position.y + v[2] * -1})
			if v[1] == 0 then
				expansion_vectors = {{1, 0}, {-1, 0}}
			else
				expansion_vectors = {{0, 1}, {0, -1}}
			end
			break
		end
	end
	
	if not entrance_tile then return end
	local position = entrance_tile.position
	for k, v in pairs(expansion_vectors) do
		local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
		if tile.collides_with("resource-layer") then		
			table_remove(expansion_vectors, k)
		end
	end
	if #expansion_vectors == 0 then return end
	
	if not exit_tile.collides_with("resource-layer") then
		local position = exit_tile.position
		for k, v in pairs(expansion_vectors) do
			local tile = surface.get_tile({position.x + v[1], position.y + v[2]})
			if tile.collides_with("resource-layer") then		
				table_remove(expansion_vectors, k)
			end
		end
	end	
	if #expansion_vectors == 0 then return end
	if #expansion_vectors > 1 then table_shuffle_table(expansion_vectors) end
	
	local tiles = {}
	for k, v in pairs(expansion_vectors) do
		if k > max_expansion_count then break end
		for k2, path_tile in pairs(path_tiles) do
			local tile = surface.get_tile({path_tile.position.x + v[1], path_tile.position.y + v[2]})
			if tile.collides_with("resource-layer") then		
				table_insert(tiles, tile)
			end
		end		
	end

	for k, tile in pairs(tiles) do table_insert(path_tiles, tile) end
end

local function is_bridge_valid(surface, vector, room)
	local bridge_tiles = room.path_tiles
	local scan_vector
	if vector[1] == 0 then
		scan_vector = {1, 0}
	else
		scan_vector = {0, 1}
	end
	
	for _, tile in pairs(bridge_tiles) do
		for d = -5, 5, 1 do
			local p = {tile.position.x + scan_vector[1] * d, tile.position.y + scan_vector[2] * d}
			local tile = surface.get_tile(p)
			if not tile.collides_with("resource-layer") then		
				return
			end
		end
	end
	
	return true
end

local function build_bridge(surface, position)
	if math_random(1, 8) == 1 then return end
	
	local vectors = {{0, -1}, {0, 1}, {1, 0}, {-1, 0}}
	table_shuffle_table(vectors)

	local room = {}
	room.path_tiles = {}
	room.room_border_tiles = {}
	room.room_tiles = {}
	
	local a = room_spacing * 4

	for _, v in pairs(vectors) do		
		for d = 1, a, 1 do
			local p = {position.x + v[1] * d, position.y + v[2] * d}
			local tile = surface.get_tile(p)
			if not tile.collides_with("resource-layer") then 
				break
			end			
			table_insert(room.path_tiles, tile)
			if d == a then room.path_tiles = {} end
		end
		if room.path_tiles[1] then
			if is_bridge_valid(surface, v, room) then
				return room
			else
				room.path_tiles = {}
			end
		end
	end

end

function Public.get_room(surface, position)
	local room_sizes = {}
	for i = 1, 14, 1 do
		room_sizes[i] = i + 1
	end
	table_shuffle_table(room_sizes)
	
	local last_size = room_sizes[1]
	for i = 1, #room_sizes, 1 do
		if room_sizes[i] <= last_size then
			last_size = room_sizes[i]
			local room = get_room_tiles(surface, position, last_size)
			expand_path_tiles_width(surface, room)
			if room then 
				return room 			
			end
		end	
	end
	
	local room = build_bridge(surface, position)
	expand_path_tiles_width(surface, room)
	if room then return room end
end

function Public.draw_random_room(surface, position)
	local room = Public.get_room(surface, position)
	if not room then return end
	
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "dirt-3", position = tile.position}}, true)
	end
	
	for _, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "dirt-7", position = tile.position}}, true)
		if math_random(1, 2) == 1 then
			surface.create_entity({name = "rock-big", position = tile.position})
		end
	end
	
	for _, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "dirt-5", position = tile.position}}, true)
	end
end

return Public