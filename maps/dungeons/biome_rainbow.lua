local Functions = require "maps.dungeons.functions"
local BiterRaffle = require "functions.biter_raffle"
local Get_noise = require "utils.get_noise"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_sqrt = math.sqrt
local math_floor = math.floor

local rainbow_tiles = {
	"red-refined-concrete", "orange-refined-concrete", "yellow-refined-concrete", "green-refined-concrete",
	"cyan-refined-concrete", "blue-refined-concrete" , "pink-refined-concrete", "purple-refined-concrete",
}

local ores = {
	"copper-ore", "iron-ore", "stone", "coal"
}

local function rainbow(surface, room)
	local tiles = {}
	for _, tile in pairs(room.path_tiles) do table_insert(tiles, tile) end
	for _, tile in pairs(room.room_border_tiles) do table_insert(tiles, tile) end
	for _, tile in pairs(room.room_tiles) do table_insert(tiles, tile) end
	
	local seed = game.surfaces[1].map_gen_settings.seed + math_random(1, 1000000)
	for _, tile in pairs(tiles) do
		local noise = Get_noise("n3", tile.position, seed)
		local index = math_floor(noise * 32) % 8 + 1
		surface.set_tiles({{name = rainbow_tiles[index], position = tile.position}}, true)
		
		if math_random(1, 2) == 1 and index % 2 == 0 then
			surface.create_entity({name = ores[index * 0.5], position = tile.position, amount = Functions.get_common_resource_amount()})
		end
	end
	
	if not room.room_border_tiles[1] then return end
	
	table_shuffle_table(room.room_tiles)
	for key, tile in pairs(room.room_tiles) do
		if math_random(1, 512) == 1 or key == 1 then
			Functions.rare_loot_crate(surface, tile.position)
		else
			if math_random(1, 512) == 1 then
				Functions.epic_loot_crate(surface, tile.position)
			end
		end
	end
	
	table_shuffle_table(room.room_border_tiles)
	for key, tile in pairs(room.room_border_tiles) do
		if key % 8 == 1 then
			Functions.place_border_rock(surface, tile.position)
		end
	end
end

return rainbow