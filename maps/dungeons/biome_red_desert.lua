local Functions = require "maps.dungeons.functions"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local trees = {"dead-dry-hairy-tree", "dead-grey-trunk", "dead-tree-desert", "dry-hairy-tree", "dry-tree"}
local ores = {"stone", "stone", "coal"}
local size_of_trees = #trees

local function add_enemy_units(surface, room)
	for _, tile in pairs(room.room_border_tiles) do if math_random(1, 24) == 1 then Functions.spawn_random_biter(surface, tile.position) end end
	for _, tile in pairs(room.room_tiles) do if math_random(1, 24) == 1 then Functions.spawn_random_biter(surface, tile.position) end end
end

local function red_desert(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "red-desert-0", position = tile.position}}, true)
	end
	
	if #room.room_tiles > 1 then table_shuffle_table(room.room_tiles) end
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "dry-dirt", position = tile.position}}, true)
		if math_random(1, 32) == 1 then
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = Functions.get_common_resource_amount()})
		else
			if math_random(1, 4) == 1 and surface.can_place_entity({name = trees[math_random(1, size_of_trees)], position = tile.position}) then			
				surface.create_entity({name = trees[math_random(1, size_of_trees)], position = tile.position})
			end
		end
		if key % 16 == 0 and math_random(1, 32) == 1 then
			Functions.set_spawner_tier(surface.create_entity({name = Functions.roll_spawner_name(), position = tile.position, force = "enemy"}))
		end
		if math_random(1, 256) == 1 then
			surface.create_entity({name = Functions.roll_worm_name(), position = tile.position, force = "enemy"})
		end		
		if math_random(1, 32) == 1 then			
			surface.create_entity({name = "rock-huge", position = tile.position})
		end
	end
	
	Functions.add_room_loot_crates(surface, room)
	
	if room.center then
		if math_random(1, 8) == 1 then
			local r = math_floor(math_sqrt(#room.room_tiles) * 0.15) + 1
			for x = r * -1, r, 1 do
				for y = r * -1, r, 1 do
					local p = {room.center.x + x, room.center.y + y}
					surface.set_tiles({{name = "water", position = p}})
					if math_random(1, 8) == 1 then
						surface.create_entity({name = "fish", position = p})
					end
				end
			end
		end	
	end
	
	if #room.room_border_tiles > 1 then table_shuffle_table(room.room_border_tiles) end
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "red-desert-1", position = tile.position}}, true)
	end
	
	for key, tile in pairs(room.room_border_tiles) do
		if key % 8 == 1 then
			Functions.place_border_rock(surface, tile.position)
		else
			if math_random(1, 3) > 1 then
				surface.create_entity({name = "rock-huge", position = tile.position})
			end
		end
	end
	
	if room.entrance_tile then
		local p = room.entrance_tile.position
		local area = {{p.x - 0.5, p.y - 0.5}, {p.x + 0.5, p.y + 0.5}}
		for _, entity in pairs(surface.find_entities_filtered({area = area})) do
			entity.destroy()
		end
	end
	
	add_enemy_units(surface, room)
end

return red_desert