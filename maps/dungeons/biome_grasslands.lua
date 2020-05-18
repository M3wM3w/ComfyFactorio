local Functions = require "maps.dungeons.functions"
local Get_noise = require "utils.get_noise"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local decoratives = {"green-asterisk", "green-bush-mini", "green-carpet-grass", "green-hairy-grass",  "green-small-grass"}
local ores = {"iron-ore", "iron-ore", "coal"}
local trees = {"tree-01", "tree-02", "tree-04", "tree-05", "tree-06", "tree-07", "tree-08"}
local size_of_trees = #trees

local function draw_deco(surface, position, decorative_name, seed)
	if surface.get_tile(position).name == "water" then return end
	if surface.count_entities_filtered({type = "resource", position = position}) > 0 then return end
	local noise = Get_noise("decoratives", position, seed)
	if math_abs(noise) > 0.28 then
		surface.create_decoratives{check_collision = false, decoratives = {{name = decorative_name, position = position, amount = math.floor(math.abs(noise * 3)) + 1}}}
	end
end

local function draw_room_decoratives(surface, room)
	local seed = game.surfaces[1].map_gen_settings.seed + math_random(1, 1000000)
	local decorative_name = decoratives[math_random(1, #decoratives)]
	for _, tile in pairs(room.path_tiles) do draw_deco(surface, tile.position, decorative_name, seed) end
	for _, tile in pairs(room.room_border_tiles) do draw_deco(surface, tile.position, decorative_name, seed) end
	for _, tile in pairs(room.room_tiles) do draw_deco(surface, tile.position, decorative_name, seed) end
end

local function add_enemy_units(surface, room)
	for _, tile in pairs(room.room_border_tiles) do if math_random(1, 32) == 1 then Functions.spawn_random_biter(surface, tile.position) end end
	for _, tile in pairs(room.room_tiles) do if math_random(1, 32) == 1 then Functions.spawn_random_biter(surface, tile.position) end end
end

local function grasslands(surface, room)
	for _, tile in pairs(room.path_tiles) do
		surface.set_tiles({{name = "grass-1", position = tile.position}}, true)
	end
	
	if not room.room_tiles[1] then draw_room_decoratives(surface, room) return end
	
	local seed = game.surfaces[1].map_gen_settings.seed + math_random(1, 1000000)
	local tree_name = trees[math_random(1, size_of_trees)]

	table_shuffle_table(room.room_tiles)
	for key, tile in pairs(room.room_tiles) do
		surface.set_tiles({{name = "grass-2", position = tile.position}}, true)
		if math_random(1, 16) == 1 and Get_noise("n3", tile.position, seed) > 0.1 then	
			surface.create_entity({name = ores[math_random(1, #ores)], position = tile.position, amount = Functions.get_common_resource_amount()})		
		else
			if math_random(1, math_random(2, 20)) == 1 and math_abs(Get_noise("decoratives", tile.position, seed + 100000)) > 0.2 then
				surface.create_entity({name = tree_name, position = tile.position})
			end
		end
		if key % 128 == 1 and math_random(1, 3) == 1 then
			Functions.set_spawner_tier(surface.create_entity({name = Functions.roll_spawner_name(), position = tile.position, force = "enemy"}))
		end
		if math_random(1, 320) == 1 then
			surface.create_entity({name = Functions.roll_worm_name(), position = tile.position})
		end		
		if math_random(1, 1024) == 1 then
			surface.create_entity({name = "rock-huge", position = tile.position})
		end		
	end
	
	Functions.add_room_loot_crates(surface, room)
	
	
	if math_random(1, 4) == 1 then
		local r_max = math_floor(room.radius * 0.75)
		local r = math_random(1, r_max)
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
	
	
	table_shuffle_table(room.room_border_tiles)
	for key, tile in pairs(room.room_border_tiles) do
		surface.set_tiles({{name = "grass-3", position = tile.position}}, true)
	end
	
	for key, tile in pairs(room.room_border_tiles) do
		if key % 8 == 1 then
			Functions.place_border_rock(surface, tile.position)
		end
	end
	
	draw_room_decoratives(surface, room)
	draw_room_decoratives(surface, room)
	add_enemy_units(surface, room)
end

return grasslands