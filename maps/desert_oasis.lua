require "modules.satellite_score"
require "modules.thirst"

local Map_info = require "modules.map_info"

local get_noise = require "utils.get_noise"
local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local string_sub = string.sub

local oasis_start = 0.50
local water_start = 0.78
local sand_damage = oasis_start * 100 + 16

local trees = {"tree-01", "tree-04", "tree-06", "tree-08-red", "tree-08", "tree-09",}

local tile_to_item = {
	["stone-path"] = "stone-brick",
	["hazard-concrete-left"] = "hazard-concrete",
	["hazard-concrete-right"] = "hazard-concrete",
	["refined-hazard-concrete-left"] = "refined-hazard-concrete",
	["refined-hazard-concrete-right"] = "refined-hazard-concrete",
}

local save_tiles = {
	["stone-path"] = true,
	["hazard-concrete-left"] = true,
	["hazard-concrete-right"] = true,
	["refined-concrete"] = true,
	["refined-hazard-concrete-left"] = true,
	["refined-hazard-concrete-right"] = true,
	["water"] = true,
	["grass-1"] = true,
	["grass-2"] = true,
	["grass-3"] = true,
	["water"] = true,
	["deepwater"] = true,
}

local function get_moisture(position)	
	local moisture = get_noise("oasis", position, global.desert_oasis_seed)	
	moisture = moisture * 128
	moisture = math.round(moisture, 1)
	return moisture
end

local function moisture_meter(player, moisture)
	local moisture_meter = player.gui.top.moisture_meter
	
	if not moisture_meter then
		moisture_meter = player.gui.top.add({type = "frame", name = "moisture_meter"})
		moisture_meter.style.padding = 3
		
		local label = moisture_meter.add({type = "label", caption = "Moisture Meter:"})
		label.style.font = "heading-2"
		label.style.font_color = {0, 150, 0}
		local label = moisture_meter.add({type = "label", caption = 0})
		label.style.font = "heading-2"
		label.style.font_color = {175, 175, 175}
	end
	
	moisture_meter.children[2].caption = moisture
end

local function draw_oasis(surface, left_top, seed)
	local tiles = {}
	local size_of_tiles = 0
	local entities = {}
	local size_of_entities = 0
	local left_top_x = left_top.x
	local left_top_y = left_top.y
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top_x + x, y = left_top_y + y}
			local noise = get_noise("oasis", position, seed)
			if noise >= oasis_start then		
				if noise > water_start or noise > oasis_start + 0.035 and get_noise("cave_ponds", position, seed) > 0.72 then
					size_of_tiles = size_of_tiles + 1
					
					if noise > 0.85 then
						tiles[size_of_tiles] = {name = "deepwater", position = position}
					else
						tiles[size_of_tiles] = {name = "water", position = position}
					end
					
					if math_random(1, 64) == 1 then
						size_of_entities = size_of_entities + 1
						entities[size_of_entities] = {name = "fish", position = position}
					end
				else
					size_of_tiles = size_of_tiles + 1
					tiles[size_of_tiles] = {name = "grass-" .. math_floor(noise * 32) % 3 + 1, position = position}
					
					for _, cliff in pairs(surface.find_entities_filtered({type = "cliff", position = position})) do
						cliff.destroy()
					end
	
					if math_random(1, 12) == 1 and surface.can_place_entity({name = "coal", position = position, amount = 1}) then
						size_of_entities = size_of_entities + 1
						if math_abs(get_noise("n3", position, seed)) > 0.50 then
							entities[size_of_entities] = {name = trees[math_floor(get_noise("n2", position, seed) * 9) % 6 + 1], position = position}
						end
					end
				end
			end
		end
	end
	
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(entities) do
		if surface.can_place_entity(entity) then
			surface.create_entity(entity)
		end
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "desert_oasis" then return end
	local seed = global.desert_oasis_seed
	local left_top = event.area.left_top

	for _, entity in pairs(surface.find_entities_filtered({area = event.area, type = "resource"})) do
		if get_noise("oasis", entity.position, seed) <= oasis_start then
			entity.destroy()
		else
			if game.item_prototypes[entity.name] then
				surface.create_entity({name = entity.name, position = entity.position, amount = math_random(200, 300) + math.sqrt(entity.position.x ^ 2 + entity.position.y ^ 2) * 0.65})
				entity.destroy()
			end
		end
	end

	for _, entity in pairs(surface.find_entities_filtered({area = event.area, force = "enemy"})) do
		if get_noise("oasis", entity.position, seed) > -0.25 then
			entity.destroy()
		end
	end

	local noise = get_noise("oasis", left_top, seed)
	if noise > oasis_start - 0.35 then draw_oasis(surface, left_top, seed) return end
end

local function on_init()
	if game.surfaces["desert_oasis"] then return end
	
	local T = Map_info.Pop_info()
	T.localised_category = "desert_oasis"
	T.main_caption_color = {r = 170, g = 170, b = 0}
	T.sub_caption_color = {r = 120, g = 120, b = 0}
	
	local map_gen_settings = {
		water = 0.0,		
		property_expression_names = {
			temperature = 50,
			moisture = 0,
		},
		starting_area = 1,
		terrain_segmentation = 0.1,
		cliff_settings = {cliff_elevation_interval = 8, cliff_elevation_0 = 8},
		autoplace_controls = {
			["coal"] = {frequency = 23, size = 0.5, richness = 0.5},
			["stone"] = {frequency = 20, size = 0.5, richness = 0.5},
			["copper-ore"] = {frequency = 25, size = 0.5, richness = 0.5},
			["iron-ore"] = {frequency = 35, size = 0.5, richness = 0.5},
			["uranium-ore"] = {frequency = 20, size = 0.5, richness = 0.5},
			["crude-oil"] = {frequency = 80, size = 0.55, richness = 1},
			["trees"] = {frequency = 0.75, size = 0.75, richness = 0.1},
			["enemy-base"] = {frequency = 15, size = 1, richness = 1},
		},
	}
	
	global.desert_oasis_seed = 0
	local noise
	local seed = 0
	local position = {x = 0, y = 0}
	for _ = 1, 1024 ^ 2, 1 do
		seed = math_random(1, 999999999)
		noise = get_noise("oasis", position, seed)
		if noise > water_start + 0.02 then
			global.desert_oasis_seed = seed
			break
		end
	end
	
	game.create_surface("desert_oasis", map_gen_settings)
	
	local surface = game.surfaces["desert_oasis"]
	surface.request_to_generate_chunks({0,0}, 5)
	surface.force_generate_chunk_requests()
	
	local force = game.forces.player
	force.research_queue_enabled = true
	force.technologies["landfill"].enabled = false
	force.technologies["cliff-explosives"].enabled = false
end

local type_whitelist = {
	["artillery-wagon"] = true,
	["car"] = true,
	["cargo-wagon"] = true,
	["construction-robot"] = true,
	["entity-ghost"] = true,
	["fluid-wagon"] = true,
	["heat-pipe"] = true,
	["locomotive"] = true,
	["logistic-robot"] = true,
	["rail-chain-signal"] = true,
	["rail-signal"] = true,
	["straight-rail"] = true,
	["train-stop"] = true,	
}

local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	
	if type_whitelist[event.created_entity.type] then return end

	if save_tiles[entity.surface.get_tile(entity.position).name] then return end

	if event.player_index then
		game.players[event.player_index].insert({name = entity.name, count = 1})		
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})													
	end
	
	event.created_entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Can not be built in the sands!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	entity.destroy()
end

local function on_built_entity(event)
	deny_building(event)
end

local function on_robot_built_entity(event)
	deny_building(event)
end

local function deny_tile_building(surface, inventory, tiles, tile)
	for _, t in pairs(tiles) do
		if not save_tiles[t.old_tile.name] then
			surface.set_tiles({{name = t.old_tile.name, position = t.position}}, true)
			if game.item_prototypes[tile.name] then
				inventory.insert({name = tile.name, count = 1})
			else
				if tile_to_item[tile.name] then
					inventory.insert({name = tile_to_item[tile.name], count = 1})
				else
					inventory.insert({name = "stone-brick", count = 1})
				end				
			end
		end		
	end
end

local function on_player_built_tile(event)
	local player = game.players[event.player_index]
	deny_tile_building(player.surface, player, event.tiles, event.tile)
end

local function on_robot_built_tile(event)
	deny_tile_building(event.robot.surface, event.robot.get_inventory(defines.inventory.robot_cargo), event.tiles, event.tile)
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "grenade", count = 1})
		player.insert({name = "computer", count = 1})
		player.insert({name = "iron-plate", count = 16})
		player.insert({name = "iron-gear-wheel", count = 8})
		player.insert({name = "stone", count = 5})
		player.insert({name = "pistol", count = 1})
		player.insert({name = "repair-pack", count = 2})
		player.insert({name = "firearm-magazine", count = 8})
		player.insert({name = "water-barrel", count = 1})
		player.teleport(game.surfaces["desert_oasis"].find_non_colliding_position("character", {64, 64}, 50, 0.5), "desert_oasis")
	end		
end

local function on_player_changed_position(event)
	if math_random(1, 4) ~= 1 then return end
	local player = game.players[event.player_index]
	
	local moisture = get_moisture(player.position)
	moisture_meter(player, moisture)
	
	if not player.character then return end
	if not player.character.valid then return end
	if player.vehicle then return end
	
	if save_tiles[player.surface.get_tile(player.position).name] then return end

	if math_random(1, 64) == 1 then 
		player.surface.create_entity({name = "fire-flame", position = player.position})
	end

	player.character.health = player.character.health - (sand_damage - moisture) * 0.60
	if player.character.health == 0 then player.character.die() end
end

local Event = require 'utils.event' 
Event.on_init(on_init)
Event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
Event.add(defines.events.on_player_built_tile, on_player_built_tile)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)