-- Refactor-io -- made by mewmew and p.p

require "modules.satellite_score"
require "modules.spawners_contain_biters"
require "modules.no_blueprint_library"
require "modules.map_info"

global.map_info = {}
global.map_info.main_caption = "Refactor-io"
global.map_info.sub_caption = ""
global.map_info.text = [[
	Hello visitor.

	You cannot mine things.
	You cannot deconstruct things ... except for with your railgun.
	You cannot destroy things ... except the biters, who have been known to hoard railgun darts in their nests.
	
	Have fun <3
]]

local math_random = math.random

-- noobs spawn with things
local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	local surface = game.surfaces["refactor-io"]

	if player.online_time == 0 then
		local non_colliding_position = surface.find_non_colliding_position("character", {0,0}, 96, 1)
		player.teleport(non_colliding_position, surface)
		player.insert{name = 'iron-plate', count = 32}
		player.insert{name = 'iron-gear-wheel', count = 16}
		player.insert{name = 'wood', count = 100}
		player.insert{name = 'stone', count = 50}
		player.insert{name = 'pistol', count = 1}
		player.insert{name = 'firearm-magazine', count = 16}
		player.insert{name = 'railgun', count = 1}
		player.insert{name = 'railgun-dart', count = 1}
	end
end

-- players always spawn with railgun
local function on_player_respawned(event)  
	local player = game.players[event.player_index]
    player.insert{name = 'railgun', count = 1}
    player.insert{name = 'wood', count = 25}
end

-- decon planner doesn't work
local function on_marked_for_deconstruction(event)
	event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
end

local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if event.entity.force.index == 2 then return end
	if event.entity.name == "character" then return end
	if event.cause then
		if event.cause.force.index == 2 then return end
		if event.cause.name == "character" then
			if event.damage_type.name == "physical" then
				if event.original_damage_amount == 100 then
					event.entity.die("player")
					return
				end
			end
		end		
	end
	event.entity.health = event.entity.health + event.final_damage_amount			
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	if event.entity.type == "unit-spawner" or event.entity.type == "turret" then
		event.entity.surface.spill_item_stack({event.entity.position.x, event.entity.position.y + 2}, {name = "railgun-dart", count = math.random(0, 3)}, false)
	end	
end

local function on_init()
	game.forces.player.technologies["steel-axe"].researched=true
	game.forces.player.manual_mining_speed_modifier = -1000000
	
	local map_gen_settings = {}
	map_gen_settings.seed = math.random(1, 999999999)
	map_gen_settings.water = 1.25
	map_gen_settings.starting_area = 1.5
	map_gen_settings.terrain_segmentation = 3.5
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 6, cliff_elevation_0 = 6}
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 3, size = 0.75, richness = 0.75},
		["stone"] = {frequency = 3, size = 0.75, richness = 0.75},
		["copper-ore"] = {frequency = 3.5, size = 0.95, richness = 0.85},
		["iron-ore"] = {frequency = 3.5, size = 0.95, richness = 0.85},
		["uranium-ore"] = {frequency = 3.5, size = 0.95, richness = 0.85},
		["crude-oil"] = {frequency = 3, size = 0.85, richness = 1},
		["trees"] = {frequency = 2.5, size = 0.85, richness = 1},
		["enemy-base"] = {frequency = 8, size = 1.5, richness = 1}	
	}	
	local surface = game.create_surface("refactor-io", map_gen_settings)
	surface.request_to_generate_chunks({0,0}, 5)
	surface.force_generate_chunk_requests()
	
	game.forces.player.set_spawn_position(surface.find_non_colliding_position("character", {0,0}, 96, 1), surface)
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_respawned, on_player_respawned)