local Functions = require "maps.dungeons.functions"
local BiterRaffle = require "functions.biter_raffle"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local function horizontal_water_barrier(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.y - center_position.y) < room.radius * 0.4 then
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function vertical_water_barrier(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.x - center_position.x) < room.radius * 0.4 then
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function vertical_bridge(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.x - center_position.x) > room.radius * 0.4 then
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function horizontal_bridge(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.y - center_position.y) > room.radius * 0.4 then
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function island(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.x - center_position.x) < room.radius * 0.6 and math_abs(p.y - center_position.y) < room.radius * 0.6 then
			else
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function cross(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.x - center_position.x) > room.radius * 0.33 and math_abs(p.y - center_position.y) > room.radius * 0.33 then
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function cross_inverted(surface, room)
	local a = room.radius * 2
	local left_top = {x = room.center.x - room.radius, y = room.center.y - room.radius}
	local center_position = room.center
	
	for x = 0, a , 1 do
		for y = 0, a, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}		
			if math_abs(p.x - center_position.x) > room.radius * 0.33 and math_abs(p.y - center_position.y) > room.radius * 0.33 then
			else
				surface.set_tiles({{name = "water", position = p}})
				if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
			end
		end
	end
end

local function squares(surface, room)
	local r_min = 0
	local r_max = room.radius * 2
	local center_position = room.center
	
	local tiles = {}
	for _, tile in pairs(room.room_border_tiles) do table_insert(tiles, tile) end
	for _, tile in pairs(room.room_tiles) do table_insert(tiles, tile) end
		
	for _ = 1, math_random(1, 6), 1 do
		local a = math_random(r_min, r_max)
		local b = math_random(r_min, r_max)
		local square_left_top = tiles[math_random(1, #tiles)].position	
		for x = 0, a , 1 do
			for y = 0, b, 1 do
				local p = {x = square_left_top.x + x, y = square_left_top.y + y}
				if p.x - center_position.x < room.radius and p.y - center_position.y < room.radius then
					if math_random(1, 2) == 1 then
						surface.set_tiles({{name = "water", position = p}})
					else
						surface.set_tiles({{name = "deepwater", position = p}})
					end				
					if math_random(1, 16) == 1 then surface.create_entity({name = "fish", position = p})	end
				end
			end
		end
	end
end

local water_shapes = {
	horizontal_water_barrier,
	vertical_water_barrier,
	vertical_bridge,
	horizontal_bridge,
	island,
	cross,
	cross_inverted,
}
for _ = 1, 16, 1 do table_insert(water_shapes, squares) end

local function biome(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "concrete", position = tile.position}}, true)
	end
	
	if not room.room_border_tiles[1] then return end
	
	table_shuffle_table(room.room_tiles)
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "blue-refined-concrete", position = tile.position}}, true)
	end
	
	table_shuffle_table(room.room_border_tiles)
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "cyan-refined-concrete", position = tile.position}}, true)
	end
	
	water_shapes[math_random(1, #water_shapes)](surface, room)
	
	for key, tile in pairs(room.room_tiles) do
		local tile = surface.get_tile(tile.position)
		if not tile.collides_with("resource-layer") then 
			if math_random(1, 10) == 1 then
				surface.create_entity({name = "stone", position = tile.position, amount = Functions.get_common_resource_amount()})
			end
			if math_random(1, 320) == 1 then
				Functions.crash_site_chest(surface, tile.position)
			end	
			if key % 64 == 1 and math_random(1, 2) == 1 then
				Functions.set_spawner_tier(surface.create_entity({name = Functions.roll_spawner_name(), position = tile.position, force = "enemy"}))
			end
			if math_random(1, 64) == 1 then
				surface.create_entity({name = Functions.roll_worm_name(), position = tile.position})
			end
		end
	end
	
	for key, tile in pairs(room.room_border_tiles) do
		if key % 8 == 1 then
			Functions.place_border_rock(surface, tile.position)
		end
	end
end

return biome