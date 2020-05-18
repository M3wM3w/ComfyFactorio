require "modules.no_deconstruction_of_neutral_entities"
require "modules.satellite_score"
require "modules.mineable_wreckage_yields_scrap"

local LootRaffle = require "functions.loot_raffle"
local Get_noise = require "utils.get_noise"
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local math_sqrt = math.sqrt

local loot_containers = {"crash-site-chest-1", "crash-site-chest-2", "big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3",}
local size_of_loot_containers = #loot_containers

local function init_surface()
	local map_gen_settings = {}
	map_gen_settings.water = "0.5"
	map_gen_settings.starting_area = "1"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0.5", size = "1", richness = "0.25"},
		["stone"] = {frequency = "0.5", size = "1", richness = "0.25"},
		["iron-ore"] = {frequency = "0.5", size = "1", richness = "0.25"},
		["copper-ore"] = {frequency = "0.5", size = "1", richness = "0.25"},
		["uranium-ore"] = {frequency = "0.5", size = "1", richness = "0.25"},		
		["crude-oil"] = {frequency = "0.5", size = "1", richness = "1"},
		["trees"] = {frequency = "1", size = "0.5", richness = "1"},
		["enemy-base"] = {frequency = "3", size = "2", richness = "1"}
	}
		
	local surface = game.create_surface("scrap_railworld", map_gen_settings)				
	surface.request_to_generate_chunks({x = 0, y = 0}, 2)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.7
	surface.ticks_per_day = surface.ticks_per_day * 2
	
	game.forces["player"].set_spawn_position({0,0}, surface)
end

local function on_player_joined_game(event)	
	local surface = game.surfaces["scrap_railworld"]
	local player = game.players[event.player_index]
	
	if player.online_time == 0 then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), surface)
	end	
end

local function place_scrap(surface, position)	
	if math_random(1, 1024) == 1 then
		if position.x ^ 2 + position.x ^ 2 > 4096 then
			local e = surface.create_entity({name = "gun-turret", position = position, force = "enemy"})			
			e.insert({name = "piercing-rounds-magazine", count = 100})		
			return
		end
	end

	if math_random(1, 128) == 1 then
		local item_stacks = LootRaffle.roll(math_sqrt(position.x ^ 2 + position.y ^ 2) * 2 + 1, 3)		
		local container = surface.create_entity({name = loot_containers[math_random(1, size_of_loot_containers)], position = position, force = "neutral"})
		local inventory = container.get_inventory(defines.inventory.chest)
		for _, item_stack in pairs(item_stacks) do inventory.insert(item_stack)	end
		container.minable = false
		return
	end		
	
	if math_random(1, 4) == 1 then return end
	
	surface.create_entity({name = "mineable-wreckage", position = position, force = "neutral"})
end

local function move_away_biteys(surface, area)
	for _, e in pairs(surface.find_entities_filtered({type = {"unit-spawner", "turret", "unit"}, area = area})) do
		local position = surface.find_non_colliding_position(e.name, e.position, 96, 4)
		if position then 
			surface.create_entity({name = e.name, position = position, force = "enemy"})
			e.destroy()
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "scrap_railworld" then return end
	local area = event.area
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local seed = surface.map_gen_settings.seed
	
	--if left_top_x <= 0 and left_top_x >= -32 and left_top_y <= 0 and left_top_y >= -32 then return end
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			local noise_1 = Get_noise("n3", position, seed)
			if not surface.get_tile(position).collides_with("resource-layer") and math_abs(noise_1) > 0.3 then
				local noise_2 = Get_noise("scrapyard", position, seed)
				if math_floor(noise_2 * 16) % 5 > 1 then
					surface.set_tiles({{name = "dirt-" .. math_floor(math_abs(noise_2) * 3) % 3 + 5, position = position}}, true)
					place_scrap(surface, position)
				end			
			end			
		end
	end
	
	for _, e in pairs(surface.find_entities_filtered({type = {"tree"}, area = area})) do 
		local noise_1 = Get_noise("n3", e.position, seed)
		if math_abs(noise_1) > 0.3 then e.destroy() end
	end
	
	move_away_biteys(surface, area)
end

local vectors = {{0,0}, {1,0}, {-1,0}, {0,1}, {0,-1}}
local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name ~= "mineable-wreckage" then return end
	local surface = entity.surface
	for _, v in pairs(vectors) do
		local position = {entity.position.x + v[1], entity.position.y + v[2]}
		if not surface.get_tile(position).collides_with("resource-layer") then 
			surface.set_tiles({{name = "landfill", position = position}}, true)
		end
	end
end

local function on_init()
	init_surface()
	game.difficulty_settings.technology_price_multiplier = 2
	game.map_settings.enemy_expansion.enabled = false
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)