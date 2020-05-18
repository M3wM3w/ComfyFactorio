local event = require 'utils.event'
local simplex_noise = require 'utils.simplex_noise'.d2
require "on_tick_schedule"
require "modules.satellite_score"
require "modules.biter_noms_you"
require "modules.dangerous_goods"
require "modules.biters_avoid_damage"
require "modules.dynamic_landfill"
require "modules.biters_double_damage"
require "modules.splice_double"
require "modules.spawners_contain_acid"
require "modules.spawners_contain_biters"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.rocks_yield_ore"
global.rock_yield_amount_modifier = 0.5
require "modules.manual_mining_booster"
require "modules.no_deconstruction_of_neutral_entities"
require "modules.no_robots"
require "modules.no_blueprint_library"

local function init_surface()
	if game.surfaces["rocky_waste"] then return game.surfaces["rocky_waste"] end

	local map_gen_settings = {}
	map_gen_settings.water = "0.12"
	map_gen_settings.starting_area = "0.5"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 7, cliff_elevation_0 = 7}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0", size = "7", richness = "1"},
		["stone"] = {frequency = "0", size = "2.0", richness = "0.5"},
		["iron-ore"] = {frequency = "0", size = "2.0", richness = "0.5"},
		["copper-ore"] = {frequency = "0", size = "2.0", richness = "0.5"},
		["uranium-ore"] = {frequency = "0", size = "1", richness = "0.5"},		
		["crude-oil"] = {frequency = "5", size = "1", richness = "1"},
		["trees"] = {frequency = "3", size = "0.85", richness = "0.1"},
		["enemy-base"] = {frequency = "5", size = "3", richness = "1"}
	}

	game.difficulty_settings.technology_price_multiplier = 2
		
	local surface = game.create_surface("rocky_waste", map_gen_settings)				
	surface.request_to_generate_chunks({x = 0, y = 0}, 3)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.7
	surface.ticks_per_day = surface.ticks_per_day * 2
	surface.min_brightness = 0.1
	
	game.forces["player"].set_spawn_position({0,0},game.surfaces["rocky_waste"])
	
	return surface
end


local wastes = {"rock-big", "rock-big", "rock-big", "rock-big","rock-big","rock-big","rock-big","mineable-wreckage", "mineable-wreckage", "mineable-wreckage", "rock-huge"}

local function get_noise(name, pos)
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.005, pos.y * 0.005, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[3] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		seed = seed + noise_seed_add
		noise[4] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.35 + noise[3] * 0.23 + noise[4] * 0.11		
		return noise
	end
	seed = seed + noise_seed_add * 5
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)		
		local noise = noise[1] + noise[2] * 0.1	
		return noise
	end
end

local function process_tile(surface, pos)
	
	local tile = surface.get_tile(pos)
	if tile.collides_with("player-layer") then return end

	local noise = get_noise(1, pos)		
	
	if noise < 0.09 and noise > -0.09 then
		return
	end
	
	local noise_2 = get_noise(2, pos)	
	if noise_2 < 0.06 and noise_2 > -0.06 then
		if math.random(1,6) ~= 1 then
			surface.set_tiles({{name = "water", position = pos}})
			if math.random(1,48) == 1 then
				surface.create_entity({name = "fish", position = pos, force = "neutral"})
			end
		end
		return
	end
	
	if math.random(1,6) ~= 1 then
		surface.create_entity({name = "rock-big", position = pos, force = "neutral"})
	end
end

local function clear_entities_around_position(surface, radius, position, entities)
	local square_radius = radius ^ 2
	for _, e in pairs(surface.find_entities_filtered({name = entities, area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})) do
		local square_distance_to_center = ((e.position.x - position.x) ^ 2) + ((e.position.y - position.y) ^ 2)
		if square_distance_to_center <= square_radius then
			e.destroy()
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			process_tile(surface, pos)
		end
	end
	
	for _, e in pairs(surface.find_entities_filtered({type = "unit-spawner", area = event.area})) do
		clear_entities_around_position(surface, 7, e.position, {"rock-big"})
	end
	
	for _, e in pairs(surface.find_entities_filtered({type = "cliff", area = event.area})) do
		clear_entities_around_position(surface, 2.25, e.position, {"rock-big"})
	end
	
	for _, e in pairs(surface.find_entities_filtered({type = "tree", area = event.area})) do
		clear_entities_around_position(surface, 1, e.position, {"rock-big"})
	end
	
	if left_top.x == 128 and left_top.y == 128 then
		clear_entities_around_position(surface, 5, {x = 0, y = 0}, {"rock-big"})
	end
end

local function on_player_joined_game(event)
	local surface = init_surface()	
	local player = game.players[event.player_index]
	
	if player.online_time == 0 then
		if not spawn_pos then spawn_pos = {x = 0, y = 0} end
		game.forces.player.set_spawn_position(spawn_pos, surface)
		player.teleport(spawn_pos, "rocky_waste")
		player.insert({name = 'car', count = 1})
		player.insert({name = 'pistol', count = 1})
		player.insert({name = 'firearm-magazine', count = 16})
	end
end

local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end	
	if entity.force.name ~= "neutral" then return end
	if math.random(1,256) == 1 then unearthing_worm(entity.surface, entity.position) return end
	if math.random(1,256) == 1 then unearthing_biters(entity.surface, entity.position, math.random(4,16)) return end		
end

local function on_init()
	
end

event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)