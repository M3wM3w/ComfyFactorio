local simplex_noise = require "utils.simplex_noise".d2
local math_random = math.random
local wod_logo_tiles = require "maps.wave_of_death.logo"
local noises = {
	["biter_territory_decoratives"] = {{modifier = 0.03, weight = 1}, {modifier = 0.05, weight = 0.3}, {modifier = 0.1, weight = 0.05}},
	["biter_territory_beach"] = {{modifier = 0.07, weight = 1}, {modifier = 0.03, weight = 0.3}, {modifier = 0.1, weight = 0.1}},
	["rocks"] = {{modifier = 0.01, weight = 1}, {modifier = 0.04, weight = 0.3}, {modifier = 0.1, weight = 0.05}},
	["trees"] = {{modifier = 0.01, weight = 1}, {modifier = 0.04, weight = 0.3}, {modifier = 0.1, weight = 0.05}},
	["ore"] = {{modifier = 0.008, weight = 1}, {modifier = 0.025, weight = 0.25}, {modifier = 0.1, weight = 0.1}},
	["ponds"] = {{modifier = 0.012, weight = 1}, {modifier = 0.035, weight = 0.25}, {modifier = 0.1, weight = 0.1}},
	["grass"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.1, weight = 0.03}},
	["decoratives"] = {{modifier = 0.03, weight = 1}, {modifier = 0.015, weight = 0.25}, {modifier = 0.1, weight = 0.1}},
	["random_things"] = {{modifier = 3, weight = 1}}
}
local decorative_whitelist = {"garballo", "garballo-mini-dry", "green-asterisk", "green-bush-mini", "green-carpet-grass", "green-hairy-grass", "green-pita", "green-pita-mini", "green-small-grass"}

local function get_noise(name, pos, seed)
	local noise = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		seed = seed + 10000
	end
	return noise
end

local function wod_logo(surface, left_top)
	if left_top.y ~= -320 then return end
	if left_top.x ~= -256 then return end
	for _, tile in pairs(wod_logo_tiles.data) do
		surface.set_tiles({{name = wod_logo_tiles.index[tile[2]], position = {tile[1][1] - 50, tile[1][2] - 436}}})
	end
end

local function init(surface, left_top)
	if left_top.x ~= 256 then return end
	if left_top.y ~= 256 then return end
	
	global.loaders = {}
	for i = 1, 4, 1 do
		local position = {x = -208 + 160*(i - 1), y = 32}
		
		for x = -12, 12, 1 do
			for y = -12, 12, 1 do	
				local pos = {x = position.x + x, y = position.y + y}
				local distance_to_center = math.sqrt(x ^ 2 + y ^ 2)
				if distance_to_center < 3.5 then
					surface.set_tiles({{name = "stone-path", position = pos}})
				else
					if distance_to_center < 9 then		
						if surface.get_tile(pos).name == "water" then
							surface.set_tiles({{name = "grass-2", position = pos}})
						end
					end
				end
			end
		end
		
		for _, e in pairs(surface.find_entities_filtered({area = {{position.x - 2, position.y - 2},{position.x + 3, position.y + 3}}, force = "neutral"})) do
			e.destroy()
		end
		
		global.loaders[i] = surface.create_entity({name = "loader", position = position, force = i})
		global.loaders[i].minable = false
		
		game.forces[i].set_spawn_position({x = position.x, y = position.y + 8}, surface)
		
		--rendering.draw_sprite({sprite = "file/maps/wave_of_death/WoD.png", target = {x = -140 + 160*(i - 1), y = 0}, surface = surface, orientation = 0, x_scale = 2, y_scale = 2, render_layer = "ground-tile"})
	end
	
	local center_position = {x = 32, y = 0}
	for x = -6, 6, 1 do
		for y = -6, 6, 1 do
			if math.sqrt(x ^ 2 + y ^ 2) < 6 then
				local pos = {x = center_position.x + x, y = center_position.y + y}
				surface.set_tiles({{name = "water-shallow", position = pos}})
			end
		end
	end
end

local function place_entities(surface, position, noise_position, seed)
	local noise = get_noise("ponds", noise_position, seed + 50000)
	local noise_2 = get_noise("decoratives", noise_position, seed + 60000)
	if noise > -0.1 and noise < 0.1 and noise_2 > 0.3 then
		surface.set_tiles({{name = "water", position = position}})
		if get_noise("random_things", noise_position, seed) > 0.82 then surface.create_entity({name = "fish", position = position}) end
		return
	end
	local noise = get_noise("ore", noise_position, seed + 5000)
	if noise > 0.75 then surface.create_entity({name = "iron-ore", position = position, amount = 1000 + math.abs(noise * 1000)}) return end
	local noise = get_noise("ore", noise_position, seed + 10000)
	if noise > 0.75 then surface.create_entity({name = "copper-ore", position = position, amount = 1000 + math.abs(noise * 1000)}) return end
	local noise = get_noise("ore", noise_position, seed + 15000)
	if noise > 0.82 then surface.create_entity({name = "coal", position = position, amount = 1000 + math.abs(noise * 1000)}) return end
	local noise = get_noise("ore", noise_position, seed + 20000)
	if noise > 0.82 then surface.create_entity({name = "stone", position = position, amount = 1000 + math.abs(noise * 1000)}) return end
	local noise = get_noise("ore", noise_position, seed + 25000)
	if noise > 0.93 then surface.create_entity({name = "uranium-ore", position = position, amount = 1000 + math.abs(noise * 1000)}) return end
	if noise < -0.93 then
		if surface.can_place_entity({name = "crude-oil", position = position, amount = 1000}) and get_noise("random_things", noise_position, seed) > 0.5 then
			surface.create_entity({name = "crude-oil", position = position, amount = 200000 + math.abs(noise * 1000)})
		end
		return
	end
	
	if get_noise("rocks", noise_position, seed + 30000) > 0.82 then
		local random_noise = get_noise("random_things", noise_position, seed)
		if random_noise > 0.5 then
			if random_noise > 0.75 then
				surface.create_entity({name = "rock-big", position = position})
			else
				surface.create_entity({name = "rock-huge", position = position})
			end
		end
		return
	end
	
	local noise = get_noise("trees", noise_position, seed + 35000)
	if noise > 0.65 then
		if get_noise("random_things", noise_position, seed) > 0.35 then surface.create_entity({name = "tree-04", position = position}) end
		return
	end
	if noise < -0.85 then
		if get_noise("random_things", noise_position, seed) > 0.45 then surface.create_entity({name = "dry-hairy-tree", position = position}) end
		return
	end
	
	local noise = get_noise("decoratives", noise_position, seed + 50000)
	if noise > 0.4 then
		if get_noise("random_things", noise_position, seed) > 0 then
			surface.create_decoratives({check_collision=false, decoratives={{name = "green-asterisk", position = position, amount = 1}}})
		end
		return
	end
	if noise < -0.4 then
		if get_noise("random_things", noise_position, seed) > 0 then
			surface.create_decoratives({check_collision=false, decoratives={{name = "green-pita", position = position, amount = 1}}})
		end
		return
	end
end

local function draw_lanes(surface, left_top)
	local seed = game.surfaces[1].map_gen_settings.seed + 4096
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			local noise_position = {x = left_top.x % 160 + x, y = left_top.y + y}
			local noise = get_noise("biter_territory_beach", noise_position, seed)
			if position.y < -160 - math.abs(noise * 12) then
				surface.set_tiles({{name = "water-shallow", position = position}}, true)
				local noise = get_noise("biter_territory_decoratives", noise_position, seed)
				if noise > -0.3 and noise < 0.3 then
					if math_random(1,1) == 1 then surface.create_decoratives({check_collision=false, decoratives={{name = "green-hairy-grass", position = position, amount = 1}}}) end
				else
					if noise > 0.75 then
						if math_random(1,2) == 1 then surface.create_decoratives({check_collision=false, decoratives={{name = "green-carpet-grass", position = position, amount = 1}}}) end
					end
				end
			else
				local position = {x = left_top.x + x, y = left_top.y + y}
				local noise_position = {x = left_top.x % 160 + x, y = left_top.y + y}
				local i = (math.floor(get_noise("grass", noise_position, seed + 5000) * 5) % 4) + 1
				surface.set_tiles({{name = "grass-" .. i, position = position}})
				place_entities(surface, position, noise_position, seed)
			end	
		end
	end
end

local function draw_void(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "out-of-map", position = position}})
		end
	end
end

local function clear_chunk(surface, area)
	surface.destroy_decoratives{area = area, name=decorative_whitelist, invert=true}
	for _, e in pairs(surface.find_entities_filtered({area = area})) do
		if e.name ~= "character" then
			e.destroy()
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.index == 1 then return end
	
	local left_top = event.area.left_top
	if left_top.x % 160 < 64 or left_top.x > 288 or left_top.x < - 256 or left_top.y < -320 then
		draw_void(surface, left_top)
	else
		clear_chunk(surface, event.area)
		draw_lanes(surface, left_top)
	end	
	init(surface, left_top)
	wod_logo(surface, left_top)
end

return on_chunk_generated