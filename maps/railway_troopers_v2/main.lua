require "modules.biters_yield_ore"
require "modules.difficulty_vote"
require "modules.satellite_score"

local difficulties_votes = {
	[1] = 32,
	[2] = 16,
	[3] = 8,
	[4] = 6,
	[5] = 4,
	[6] = 2,
	[7] = 1
}

local Get_noise = require "utils.get_noise"
local Immersive_cargo_wagons = require "modules.immersive_cargo_wagons.main"
local LootRaffle = require "functions.loot_raffle"

local map_height = 64

local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove
local math_sqrt = math.sqrt
local math_round = math.round
local math_abs = math.abs

local function place_spawn_entities(surface)
	for x = 0, 96, 2 do
		surface.create_entity({name = "straight-rail", position = {-96 + x, 0}, direction = 2, force = "player"})
	end

	local entity = surface.create_entity({name = "cargo-wagon", position = {-24, 1}, force = "player", direction = 2})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "submachine-gun", count = 3})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "firearm-magazine", count = 600})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "shotgun", count = 2})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "shotgun-shell", count = 128})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "light-armor", count = 5})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "grenade", count = 32})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "pistol", count = 10})
	entity.get_inventory(defines.inventory.cargo_wagon).insert({name = "rail", count = 200})
	Immersive_cargo_wagons.register_wagon(entity)
	
	local entity = surface.create_entity({name = "locomotive", position = {-18, 0}, force = "player", direction = 2})
	entity.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 25})
	Immersive_cargo_wagons.register_wagon(entity)
end

local function treasure_chest(surface, position)
	local budget = 32 + math_abs(position.x) * 2
	budget = budget * math_random(25, 175) * 0.01
	if math_random(1,200) == 1 then 
		budget = budget * 10
		container_name = "crash-site-chest-" .. math_random(1, 2)
	end
	budget = math_floor(budget) + 1

	local item_stacks = LootRaffle.roll(budget, 16)
	local container = surface.create_entity({name = "wooden-chest", position = position, force = "neutral"})
	for _, item_stack in pairs(item_stacks) do
		container.insert(item_stack)
	end
	container.minable = false
end

local infini_ores = {"iron-ore", "iron-ore", "copper-ore", "coal", "stone"}

local function on_player_joined_game(event)
	local surface = game.surfaces["railway_troopers"]
	local player = game.players[event.player_index]	
	player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)	
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.type == "unit" and entity.spawner then
		entity.spawner.damage(20, game.forces[1])
	end
end

local function is_out_of_map(p)	
	local b = math_abs(p.y)
	if b > map_height then return true end
end

local function map_reset()
	game.reset_time_played()
	Immersive_cargo_wagons.reset()
	
	global.drop_schedule = {}
	global.on_entity_spawned_counter = 0
	global.collapse_x = -96
	global.collapse_tiles = {}
	
	reset_difficulty_poll()
	global.difficulty_poll_closing_timeout = game.tick + 7200
	
	game.difficulty_settings.technology_price_multiplier = 0.5
	game.map_settings.enemy_evolution.destroy_factor = 0.001
	game.map_settings.enemy_evolution.pollution_factor = 0	
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 96
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.enemy_expansion.max_expansion_distance = 16
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.25
	
	local surface = game.surfaces.railway_troopers
	local map_gen_settings = surface.map_gen_settings
	map_gen_settings.seed = math_random(1, 999999999)
	surface.map_gen_settings = map_gen_settings	
	surface.clear(true)
	
	surface.request_to_generate_chunks({0,0}, 8)
	surface.force_generate_chunk_requests()
		
	for _, force in pairs(game.forces) do 
		force.reset() 
		force.reset_evolution()
	end
	local force = game.forces.player	
	force.set_spawn_position({-30, 0}, surface)		
	force.technologies["railway"].researched = true
	force.technologies["engine"].researched = true
	force.technologies["fluid-wagon"].researched = true
	
	local types_to_disable = {
		["ammo"] = true,
		["armor"] = true,
		["car"] = true,
		["gun"] = true,
		["capsule"] = true,
	}	
	for _, recipe in pairs(game.recipe_prototypes) do
		if types_to_disable[recipe.subgroup.name] then
			force.set_hand_crafting_disabled_for_recipe(recipe.name, true)
		end
	end
end

local function draw_west_side(surface, left_top)
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			surface.set_tiles({{name = "out-of-map", position = position}}, true)			
		end
	end
end

local function draw_east_side(surface, left_top)	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map(position) then
				surface.set_tiles({{name = "out-of-map", position = position}}, true)
			else
				if math_random(1, 256) == 1 and surface.can_place_entity({name = "wooden-chest", position = position}) then
					treasure_chest(surface, position)
				end
				if math_random(1, 4096) == 1 and surface.can_place_entity({name = "wooden-chest", position = position}) then
					surface.create_entity({name = "crude-oil", position = position, amount = math_abs(position.x) * 10000 + 1000000})
				end
			end		
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "railway_troopers" then return end
	local left_top = event.area.left_top

	if left_top.x <= 0 then
		for _, e in pairs(surface.find_entities_filtered({force = "enemy", area = event.area})) do
			e.destroy()
		end
	else
		local seed = game.surfaces["railway_troopers"].map_gen_settings.seed
		for _, e in pairs(surface.find_entities_filtered({force = "enemy", area = event.area})) do
			local noise = Get_noise("n3", e.position, seed)
			if noise > 0.05 then e.destroy() end
		end	
	end

	if left_top.x < -96 then
		draw_west_side(surface, left_top)
	else
		draw_east_side(surface, left_top)
	end
end

local function on_research_finished(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 200
	event.research.force.character_item_pickup_distance_bonus = game.forces.player.mining_drill_productivity_bonus * 10
end

local negative_map_height = map_height * -1

local function on_tick()
	local tick = game.ticks_played
	local surface = game.surfaces.railway_troopers
	
	if tick % 3600 == 60 then	
		if global.reset_railway_troopers then
			if global.reset_railway_troopers == 1 then
				global.reset_railway_troopers = 2
				map_reset()
				for _, player in pairs(game.players) do
					if player.character and player.character.valid then
						player.character.die()
					else
						player.clear_items_inside()
						player.teleport({-30, 0}, surface)
					end				
				end
				return
			end
			if global.reset_railway_troopers == 2 then
				place_spawn_entities(surface)
				global.reset_railway_troopers = nil
				return
			end
			return
		end
		
		local wagons = surface.find_entities_filtered({name = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}, limit = 1})		
		if not wagons[1] then
			game.print("All the choos have have been destroyed! Game Over!", {200, 0, 0})
			global.reset_railway_troopers = 1
			return
		else
			game.forces.player.set_spawn_position(wagons[1].position, game.surfaces.railway_troopers)
		end
	end
	
	local speed = difficulties_votes[global.difficulty_vote_index]
	if tick % speed ~= 0 then return end	
	if not global.collapse_tiles then
		local area = {{global.collapse_x - 1, negative_map_height}, {global.collapse_x, map_height + 1}}
		game.forces.player.chart(surface, area)
		global.collapse_tiles = surface.find_tiles_filtered({area = area})
		global.size_of_collapse_tiles = #global.collapse_tiles
		global.collapse_x = global.collapse_x + 1
		if global.size_of_collapse_tiles == 0 then global.collapse_tiles = nil return end
		table.shuffle_table(global.collapse_tiles)		
	end
	for _ = 1, 2, 1 do
		local tile = global.collapse_tiles[global.size_of_collapse_tiles]
		if not tile then global.collapse_tiles = nil return end
		global.size_of_collapse_tiles = global.size_of_collapse_tiles - 1
		local position = tile.position
		for _, e in pairs(surface.find_entities_filtered({area = {{position.x, position.y - 1}, {position.x + 2, position.y + 1}}})) do e.die() end
		surface.set_tiles({{name = "out-of-map", position = tile.position}}, true)
	end
end

local function on_init()
	local surface = game.surfaces[1]
	local map_gen_settings = surface.map_gen_settings
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	surface.map_gen_settings = map_gen_settings
	for chunk in surface.get_chunks() do		
		surface.delete_chunk({chunk.x, chunk.y})		
	end

	local map_gen_settings = {
	["water"] = 0.50,
	["starting_area"] = 0.60,
	terrain_segmentation = 20,
	["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["autoplace_controls"] = {
			["coal"] = {frequency = 15, size = 0.20, richness = 0.25},
			["stone"] = {frequency = 15, size = 0.20, richness = 0.25},
			["copper-ore"] = {frequency = 15, size = 0.20, richness = 0.25},
			["iron-ore"] = {frequency = 15, size = 0.20, richness = 0.25},
			["uranium-ore"] = {frequency = 15, size = 0.20, richness = 0.25},
			["crude-oil"] = {frequency = 15, size = 0.20, richness = 10},
			["trees"] = {frequency = 5, size = 0.30, richness = 1},
			["enemy-base"] = {frequency = 256, size = 2, richness = 1},
		},
	}
	game.create_surface("railway_troopers", map_gen_settings)

	global.reset_railway_troopers = 2
	
	map_reset()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)