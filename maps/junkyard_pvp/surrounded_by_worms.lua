local event = require 'utils.event'
local math_random = math.random
local turrets = {
	[1] = "small-worm-turret",
	[2] = "medium-worm-turret",
	[3] = "big-worm-turret",
	[4] = "behemoth-worm-turret"
}

local tile_coords = {}
for x = 0, 31, 1 do
	for y = 0, 31, 1 do
		tile_coords[#tile_coords + 1] = {x, y}
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "mirror_terrain" then return end
	local starting_distance = surface.map_gen_settings.starting_area * 200
	local left_top = event.area.left_top
	local chunk_distance_to_center = math.sqrt(left_top.x ^ 2 + left_top.y ^ 2)
	if starting_distance > chunk_distance_to_center then return end
	
	local highest_worm_tier = math.floor((chunk_distance_to_center - starting_distance) * 0.0025) + 1
	if highest_worm_tier > 4 then highest_worm_tier = 4 end
	
	for a = 1, 4, 1 do
		local coord_modifier = tile_coords[math_random(1, #tile_coords)]
		local pos = {left_top.x + coord_modifier[1], left_top.y + coord_modifier[2]}
		local name = turrets[math_random(1, highest_worm_tier)]
		local position = surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
		if position then
			surface.create_entity({name = name, position = position, force = "enemy"})
		end
	end
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)