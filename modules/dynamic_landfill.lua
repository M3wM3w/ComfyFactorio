-- changes placed landfill tiles, adapting the new tile to adjecant tiles -- by mewmew

local regenerate_decoratives = true
local event = require 'utils.event'
local math_random = math.random
local table_insert = table.insert
local water_tile_whitelist = {
		["water"] = true,
		["deepwater"] = true,
		["water-green"] = true,
		["deepwater-green"] = true
	}

local spiral_coords = {}
for r = 1, 96, 1 do
	for x = r * -1, r - 1, 1 do
		table_insert(spiral_coords, {x = x, y = r * -1})
	end
	for y = r * -1, r - 1, 1 do
		table_insert(spiral_coords, {x = r, y = y})
	end	
	for x = r, r * -1 + 1, -1 do
		table_insert(spiral_coords, {x = x, y = r})
	end	
	for y = r, r * -1 + 1, -1 do
		table_insert(spiral_coords, {x = r * -1, y = y})
	end	
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

local function is_this_a_valid_source_tile(pos, tiles)
	for _, tile in pairs(tiles) do
		if tile.position.x == pos.x and tile.position.y == pos.y then
			return false
		end
	end
	return true
end

local function place_fitting_tile(position, surface, tiles_placed)		
	for _, coord in pairs(spiral_coords) do
		local tile = surface.get_tile({position.x + coord.x, position.y + coord.y})
		if not tile.collides_with("player-layer") then
			local valid_source_tile = is_this_a_valid_source_tile(tile.position, tiles_placed)			
			if tile.name == "out-of-map" then valid_source_tile = false end
			
			if valid_source_tile then
				if tile.hidden_tile then
					surface.set_tiles({{name = tile.hidden_tile, position = position}}, true)			
				else
					surface.set_tiles({{name = tile.name, position = position}}, true)				
				end
				return
			end	
		end				
	end		
end	
	
local function on_player_built_tile(event)
	if event.item.name ~= "landfill" then return end
	local surface = game.surfaces[event.surface_index]
	
	for _, placed_tile in pairs(event.tiles) do
		if water_tile_whitelist[placed_tile.old_tile.name] then
			place_fitting_tile(placed_tile.position, surface, event.tiles)
			if regenerate_decoratives then
				if math_random(1, 5) == 1 then
					regenerate_decoratives(surface, placed_tile.position)
				end
			end
		end
	end		
end

local function on_robot_built_tile(event)
	if event.item.name ~= "landfill" then return end
	local surface = event.robot.surface
	
	for _, placed_tile in pairs(event.tiles) do
		if water_tile_whitelist[placed_tile.old_tile.name] then
			place_fitting_tile(placed_tile.position, surface, event.tiles)
			if regenerate_decoratives then
				if math_random(1, 4) == 1 then
					regenerate_decoratives(surface, placed_tile.position)
				end
			end
		end
	end
end

event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_robot_built_tile, on_robot_built_tile)