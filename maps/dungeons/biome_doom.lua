local Functions = require "maps.dungeons.functions"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local function add_enemy_units(surface, room)
	for _, tile in pairs(room.room_border_tiles) do if math_random(1, 24) == 1 then Functions.spawn_random_biter(surface, tile.position) end end
	for _, tile in pairs(room.room_tiles) do if math_random(1, 24) == 1 then Functions.spawn_random_biter(surface, tile.position) end end
end

local function doom(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "refined-concrete", position = tile.position}}, true)
	end
	
	if #room.room_tiles > 1 then table_shuffle_table(room.room_tiles) end
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "red-refined-concrete", position = tile.position}}, true)
		if math_random(1, 16) == 1 then
			surface.create_entity({name = "copper-ore", position = tile.position, amount = Functions.get_common_resource_amount()})
		end
		if math_random(1, 16) == 1 then
			surface.create_entity({name = Functions.roll_worm_name(), position = tile.position})
		end
		if math_random(1, 320) == 1 then
			Functions.rare_loot_crate(surface, tile.position)
		else
			if math_random(1, 640) == 1 then
				Functions.epic_loot_crate(surface, tile.position)
			end
		end	
		if key % 12 == 1 and math_random(1, 2) == 1 then
			Functions.set_spawner_tier(surface.create_entity({name = Functions.roll_spawner_name(), position = tile.position, force = "enemy"}))
		end
	end
	
	if room.center then
		if math_random(1, 5) == 1 then
			local r = math_floor(math_sqrt(#room.room_tiles) * 0.15) + 1
			for x = r * -1, r, 1 do
				for y = r * -1, r, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "deepwater-green", position = p}})
					if math_random(1, 9) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		end	
	end
	
	if #room.room_border_tiles > 1 then table_shuffle_table(room.room_border_tiles) end
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "black-refined-concrete", position = tile.position}}, true)
	end
	
	for key, tile in pairs(room.room_border_tiles) do
		if key % 8 == 1 then
			Functions.place_border_rock(surface, tile.position)
		end
	end
	
	add_enemy_units(surface, room)
end

return doom