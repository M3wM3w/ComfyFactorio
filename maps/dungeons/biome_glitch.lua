local Functions = require "maps.dungeons.functions"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs

local ores = {"iron-ore", "copper-ore", "coal", "stone"}

local function glitch(surface, room)
	for _, tile in pairs(room.path_tiles) do		
		surface.set_tiles({{name = "lab-white", position = tile.position}}, true)	
	end
	
	if not room.room_border_tiles[1] then return end

	table_shuffle_table(room.room_tiles)
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "lab-dark-1", position = tile.position}}, true)
		if math_random(1, 3) == 1 then
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = Functions.get_common_resource_amount()})
		end
		if math_random(1, 12) == 1 then
			surface.create_entity({name = Functions.roll_worm_name(), position = tile.position})
		end
		if math_random(1, 96) == 1 then
			Functions.common_loot_crate(surface, tile.position)
		else
			if math_random(1, 160) == 1 then
				Functions.uncommon_loot_crate(surface, tile.position)
			end
		end	
	end
	
	if room.center then
		if math_random(1, 8) == 1 then
			for x = -1, 1, 1 do
				for y = -1, 1, 1 do
					local p = {room.center.x + x, room.center.y + y}
					local tile = "water"
					if math_random(1,2) == 1 then tile = "deepwater" end
					surface.set_tiles({{name = tile, position = p}})
					if math_random(1, 4) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		else
			if math_random(1, 4) == 1 then
				surface.create_entity({name = "crude-oil", position = room.center, amount = Functions.get_crude_oil_amount()})
			end
		end	
	end
	
	table_shuffle_table(room.room_border_tiles)
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "lab-dark-2", position = tile.position}}, true)
	end
	
	for key, tile in pairs(room.room_border_tiles) do
		if key % 8 == 1 then
			Functions.place_border_rock(surface, tile.position)
		end
	end
end

return glitch