local math_abs = math.abs
local math_random = math.random
local math_floor = math.floor
local Treasure = require 'maps.junkyard_pvp.treasure'
local Map_functions = require "tools.map_functions"
local simplex_noise = require "utils.simplex_noise".d2
local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local spawner_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}
local noises = {
	["no_rocks"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},
	["no_rocks_2"] = {{modifier = 0.013, weight = 1}, {modifier = 0.1, weight = 0.1}},
	["large_caves"] = {{modifier = 0.0033, weight = 1}, {modifier = 0.01, weight = 0.22}, {modifier = 0.05, weight = 0.05}, {modifier = 0.1, weight = 0.04}},	
	["small_caves"] = {{modifier = 0.008, weight = 1}, {modifier = 0.03, weight = 0.15}, {modifier = 0.25, weight = 0.05}},
	["small_caves_2"] = {{modifier = 0.009, weight = 1}, {modifier = 0.05, weight = 0.25}, {modifier = 0.25, weight = 0.05}},
	["cave_ponds"] = {{modifier = 0.01, weight = 1}, {modifier = 0.1, weight = 0.06}},
	["cave_rivers"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.25}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_2"] = {{modifier = 0.003, weight = 1}, {modifier = 0.01, weight = 0.21}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_3"] = {{modifier = 0.002, weight = 1}, {modifier = 0.01, weight = 0.15}, {modifier = 0.05, weight = 0.01}},
	["cave_rivers_4"] = {{modifier = 0.001, weight = 1}, {modifier = 0.01, weight = 0.11}, {modifier = 0.05, weight = 0.01}},
	["scrapyard"] = {{modifier = 0.005, weight = 1}, {modifier = 0.01, weight = 0.35}, {modifier = 0.05, weight = 0.23}, {modifier = 0.1, weight = 0.11}},
}
local cargo_wagon_position = {x = 86, y = 0}
local Public = {}

local function get_noise(name, pos, seed)
	local noise = 0
	local d = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		d = d + n.weight
		seed = seed + 10000
	end
	noise = noise / d
	return noise
end

local function create_objectives(surface)
	local d = 6
	
	for key, modifier in pairs({west = -1, east = 1}) do	
		for x = -6, 6, 2 do surface.create_entity({name = "straight-rail", position = {(cargo_wagon_position.x + x) * modifier, cargo_wagon_position.y}, force = key, direction = 2}) end
		local e = surface.create_entity({name = "locomotive", position = {(cargo_wagon_position.x + 3) * modifier, cargo_wagon_position.y}, force = key, direction = d})
		e.color = {0, 255, 0}
		if key == "east" then e.color = {0, 0, 255} end
		e.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 50})
		local e = surface.create_entity({name = "cargo-wagon", position = {(cargo_wagon_position.x - 3) * modifier, cargo_wagon_position.y}, force = key})
		e.minable = false
		global.map_forces[key].cargo_wagon = e
		d = d - 4
	end
end

function Public.create_mirror_surface()
	if game.surfaces["mirror_terrain"] then return end

	local map_gen_settings = {}
	map_gen_settings.seed = math_random(1, 99999999)
	map_gen_settings.water = 0.2
	map_gen_settings.starting_area = 1.5
	map_gen_settings.terrain_segmentation = 8
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}	
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 10, size = 0.6, richness = 0.5,},
		["stone"] = {frequency = 10, size = 0.6, richness = 0.5,},
		["copper-ore"] = {frequency = 20, size = 0.6, richness = 0.75,},
		["iron-ore"] = {frequency = 20, size = 0.6, richness = 1,},
		["uranium-ore"] = {frequency = 5, size = 0.5, richness = 0.5,},
		["crude-oil"] = {frequency = 10, size = 1, richness = 1,},
		["trees"] = {frequency = math_random(5, 15) * 0.1, size = math_random(4, 8) * 0.1, richness = 0.1},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}	
	}
	local surface = game.create_surface("mirror_terrain", map_gen_settings)
	
	local x = cargo_wagon_position.x - 16
	local offset = 38
	
	surface.request_to_generate_chunks({x, 0}, 5)
	surface.force_generate_chunk_requests()
	
	local r = 15
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			local p = {x = cargo_wagon_position.x + x, y = cargo_wagon_position.y + y}
			if math.sqrt(x ^ 2 + y ^ 2) < r then
				local tile = surface.get_tile(p)
				if tile.collides_with("resource-layer") then
					surface.set_tiles({{name = "landfill", position = p}}, true)
				end
			end
		end
	end
	for _, e in pairs(surface.find_entities_filtered({area = {{cargo_wagon_position.x - r, cargo_wagon_position.y - r}, {cargo_wagon_position.x + r, cargo_wagon_position.y + r}}, force = {"neutral", "enemy"}})) do
		if math.sqrt(e.position.x ^ 2 + e.position.y ^ 2) < r then
			e.destroy()
		end
	end
end

local function mirror_chunk(event, source_surface, x_modifier)
	local surface = event.surface	
	local left_top = event.area.left_top
	local offset = 0
	if x_modifier == -1 then offset = 32 end
	local mirror_left_top = {x = left_top.x * x_modifier - offset, y = left_top.y * x_modifier - offset}
	
	source_surface.request_to_generate_chunks(mirror_left_top, 1)
	source_surface.force_generate_chunk_requests()
	
	local mirror_area = {{mirror_left_top.x, mirror_left_top.y}, {mirror_left_top.x + 32, mirror_left_top.y + 32}}
	
	for _, tile in pairs(source_surface.find_tiles_filtered({area = mirror_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * x_modifier, y = tile.position.y * x_modifier}}}, true)
	end
	for _, entity in pairs(source_surface.find_entities_filtered({area = mirror_area})) do
		--if surface.can_place_entity({name = entity.name, position = {x = entity.position.x * x_modifier, y = entity.position.y * x_modifier}}) then
			entity.clone({position = {x = entity.position.x * x_modifier, y = entity.position.y * x_modifier}, surface = surface})
		--end
	end	
	for _, decorative in pairs(source_surface.find_decoratives_filtered{area = mirror_area}) do
		surface.create_decoratives{
			check_collision=false,
			decoratives={{name = decorative.decorative.name, position = {x = decorative.position.x * x_modifier, y = decorative.position.y * x_modifier}, amount = decorative.amount}}
		}
	end
end

local scrap_entities = {"crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-lab-broken",
 "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck", "medium-ship-wreck", "small-ship-wreck",
 "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2"}
local scrap_entities_index = #scrap_entities

--SCRAPYARD
local function process_junk_position(p, seed, tiles, entities, markets, treasure)
	local scrapyard = get_noise("scrapyard", p, seed)
	
	if p.x < 5 + scrapyard * 3 then tiles[#tiles + 1] = {name = "water-shallow", position = p} return end
	if p.x < cargo_wagon_position.x + 16 + scrapyard * 32 then return end
	--Chasms
	local noise_cave_ponds = get_noise("cave_ponds", p, seed)
	local small_caves = get_noise("small_caves", p, seed)
	if noise_cave_ponds < 0.15 and noise_cave_ponds > -0.15 then
		if small_caves > 0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
		if small_caves < -0.35 then
			tiles[#tiles + 1] = {name = "out-of-map", position = p}
			return
		end
	end
	
	if scrapyard < -0.25 or scrapyard > 0.25 then
		if math_random(1, 1024) == 1 then
			entities[#entities + 1] = {name="gun-turret", position=p, force = "enemy"}
		end
		tiles[#tiles + 1] = {name = "dirt-7", position = p}
		if scrapyard < -0.65 or scrapyard > 0.65 then
			if math_random(1,5) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
			return
		end
		if scrapyard < -0.28 or scrapyard > 0.28 then
			--if math_random(1,2048) == 1 then
				--entities[#entities + 1] = {name = "small-worm-turret", position = p, force = "enemy"} 
			--end
			if math_random(1,96) == 1 then entities[#entities + 1] = {name = scrap_entities[math_random(1, scrap_entities_index)], position = p, force = "enemy"} end	
			if math_random(1,3) > 1 then entities[#entities + 1] = {name="mineable-wreckage", position=p} end
			return
		end
		return
	end
	
	local cave_ponds = get_noise("cave_ponds", p, seed)
	if cave_ponds < -0.6 and scrapyard > -0.2 and scrapyard < 0.2 then
		tiles[#tiles + 1] = {name = "deepwater-green", position = p}
		if math_random(1,128) == 1 then entities[#entities + 1] = {name="fish", position=p} end
		return
	end
	
	local large_caves = get_noise("large_caves", p, seed)
	if scrapyard > -0.15 and scrapyard < 0.15 then
		if math_floor(large_caves * 10) % 4 < 1 then
			tiles[#tiles + 1] = {name = "dirt-7", position = p}
			if math_random(1,2) > 1 then entities[#entities + 1] = {name = rock_raffle[math_random(1, #rock_raffle)], position = p} end
			return
		end
	end
	
	if noise_cave_ponds < 0.7 then return end 
	tiles[#tiles + 1] = {name = "stone-path", position = p}
end

local function is_out_of_map(p)
	if p.y < 96 and p.y >= -96 then return end
	if (p.x + 128) * 0.4 >= math_abs(p.y) then return end
	if (p.x - 128) * -0.4 > math_abs(p.y) then return end
	return true
end

local function out_of_map_area(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = -1, 32, 1 do
		for y = -1, 32, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}			
			if is_out_of_map(p) then
				surface.set_tiles({{name = "out-of-map", position = p}}, true) 
			end
		end
	end
end

local function process_main_surface(event)
	local source_surface = game.surfaces["mirror_terrain"]
	if not source_surface then return end
	if not source_surface.valid then return end
	if event.surface.index == source_surface.index then return end
	
	local left_top = event.area.left_top
		
	if left_top.x >= 0 then
		mirror_chunk(event, source_surface, 1)
	else
		mirror_chunk(event, source_surface, -1)
	end	
	
	out_of_map_area(event)
	
	if left_top.x == -160 and left_top.y == -160 then 
		create_objectives(event.surface) 
	end
	
	--game.forces.west.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	--game.forces.east.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	
	return true
end

local entity_functions = {
	["turret"] = function(surface, entity) surface.create_entity(entity) end,
	["simple-entity"] = function(surface, entity) surface.create_entity(entity) end,
	["ammo-turret"] = function(surface, entity) 
		local e = surface.create_entity(entity)
		e.insert({name = "firearm-magazine", count = math_random(16, 64)})
	end,
	["container"] = function(surface, entity) 
		Treasure(surface, entity.position, entity.name) 
	end,	
}

local function process_mirror_surface(event)
	local surface = event.surface
	local left_top = event.area.left_top
	local tiles = {}
	local entities = {}
	local treasure = {}
	local seed = surface.map_gen_settings.seed
	for y = 0, 31, 1 do
		for x = 0, 31, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			process_junk_position(p, seed, tiles, entities, treasure)
		end
	end
	surface.set_tiles(tiles, true)

	for _, p in pairs(treasure) do
		local name = "wooden-chest"
		if math_random(1, 6) == 1 then name = "iron-chest" end
		Treasure(surface, p, name) 
	end
	
	for _, entity in pairs(entities) do
		if entity_functions[game.entity_prototypes[entity.name].type] then
			entity_functions[game.entity_prototypes[entity.name].type](surface, entity)
		else
			if surface.can_place_entity(entity) then
				surface.create_entity(entity)
			end
		end
	end
end

local function on_chunk_generated(event)
	if process_main_surface(event) then return end
	process_mirror_surface(event)
end

local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public