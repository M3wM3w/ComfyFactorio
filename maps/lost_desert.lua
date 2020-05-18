--lost desert-- mewmew made this --

require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.rocks_yield_ore"
require "modules.spawners_contain_biters"
require "modules.spawners_contain_acid"
require "modules.satellite_score"
require "modules.flashlight_toggle_button"

local simplex_noise = require 'utils.simplex_noise'.d2
local event = require 'utils.event'
local map_functions = require "tools.map_functions"
local math_random = math.random
require 'utils.table'

local noises = {	
	[1] = {{modifier = 0.001, weight = 1}, {modifier = 0.01, weight = 0.05}, {modifier = 0.05, weight = 0.02}, {modifier = 0.1, weight = 0.001}}
}

local sand_tiles = {"sand-1", "sand-2", "sand-3"}

local decorative_whitelist = {"brown-asterisk", "brown-carpet-grass", "brown-fluff", "brown-fluff-dry", "brown-hairy-grass", "garballo", "garballo-mini-dry", "green-pita", "green-pita-mini"}

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local function get_noise(name, pos, seed)
	local noise = 0
	for _, n in pairs(noises[name]) do
		noise = noise + simplex_noise(pos.x * n.modifier, pos.y * n.modifier, seed) * n.weight
		seed = seed + 10000
	end
	return noise
end

local function shipwreck(position, surface)
	local wrecks = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"}
	local wreck = wrecks[math.random(1,#wrecks)]
	
	local wreck_raffle_table = {}
	local wreck_loot_weights = {}	
	table.insert(wreck_loot_weights, {{name = "firearm-magazine", count = math.random(64,128)},8})
	table.insert(wreck_loot_weights, {{name = 'grenade', count = math.random(16,32)},5})
	table.insert(wreck_loot_weights, {{name = 'land-mine', count = math.random(16,32)},5})		
	table.insert(wreck_loot_weights, {{name = 'assembling-machine-1', count = math.random(1,4)},2})
	table.insert(wreck_loot_weights, {{name = 'assembling-machine-2', count = math.random(1,3)},2})
	table.insert(wreck_loot_weights, {{name = 'assembling-machine-3', count = math.random(1,2)},1})
	table.insert(wreck_loot_weights, {{name = 'combat-shotgun', count = 1},3})
	table.insert(wreck_loot_weights, {{name = 'piercing-shotgun-shell', count = math.random(16,48)},5})
	table.insert(wreck_loot_weights, {{name = 'flamethrower', count = 1},3})
	table.insert(wreck_loot_weights, {{name = 'rocket-launcher', count = 1},4})
	table.insert(wreck_loot_weights, {{name = 'flamethrower-ammo', count = math.random(16,48)},5})		
	table.insert(wreck_loot_weights, {{name = 'rocket', count = math.random(16,48)},5})
	table.insert(wreck_loot_weights, {{name = 'explosive-rocket', count = math.random(16,48)},5})
	table.insert(wreck_loot_weights, {{name = 'uranium-rounds-magazine', count = math.random(16,32)},3})	
	table.insert(wreck_loot_weights, {{name = 'piercing-rounds-magazine', count = math.random(64,128)},5})	
	table.insert(wreck_loot_weights, {{name = 'railgun', count = 1},3})
	table.insert(wreck_loot_weights, {{name = 'railgun-dart', count = math.random(16,48)},4})
	table.insert(wreck_loot_weights, {{name = 'exoskeleton-equipment', count = 1},1})
	table.insert(wreck_loot_weights, {{name = 'defender-capsule', count = math.random(8,16)},5})
	table.insert(wreck_loot_weights, {{name = 'distractor-capsule', count = math.random(4,8)},4})
	table.insert(wreck_loot_weights, {{name = 'destroyer-capsule', count = math.random(4,8)},3})
	table.insert(wreck_loot_weights, {{name = 'atomic-bomb', count = 1},1})		
	for _, t in pairs (wreck_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(wreck_raffle_table, t[1])
		end			
	end	
	local e = surface.create_entity {name=wreck, position=position, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math.random(2,3), 1 do
		local loot = wreck_raffle_table[math.random(1,#wreck_raffle_table)]
		i.insert(loot)
	end		
end

local worm_raffle = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","stone","stone","uranium-ore","crude-oil"}

local function on_chunk_generated(event)
	local surface = game.surfaces["lost_desert"]
	if event.surface.name ~= surface.name then return end	 
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	
	surface.destroy_decoratives{area = event.area, name = decorative_whitelist, invert = true}

	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "tree"})) do
		if e.type == "tree" then
			if math_random(1,3) ~= 1 then e.destroy() end
		end
	end
	
	local seed = game.surfaces[1].map_gen_settings.seed
	
	local tile_to_insert = false	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top_x + x, y = left_top_y + y}
			local noise = get_noise(1, pos, seed)
			if noise < -0.45 then
				if noise < -0.5 then
					surface.set_tiles({{name = "water", position = pos}}, true)
					if math_random(1,256) == 1 then surface.create_entity({name = "fish", position = pos}) end
				else
					surface.set_tiles({{name = "dirt-2", position = pos}}, true)
					if math_random(1,64) == 1 then surface.create_entity({name = "tree-08", position = pos}) end
					if math_random(1,4096) == 1 then
						local market = surface.create_entity({name = "market", position = pos})
						market.add_market_item({price = {{"wood", math.random(4,5)}}, offer = {type = 'give-item', item = 'raw-fish'}})
					end
				end
			else
				local i = (math.floor(noise * 20) % 3) + 1
				surface.set_tiles({{name = sand_tiles[i], position = pos}}, true)
				if noise > 0.5 then
					if math_random(1,3) ~= 1 then	
						if math_random(1,2) == 1 then
							surface.create_entity({name = "rock-big", position = pos})
						else
							surface.create_entity({name = "rock-huge", position = pos})
						end
					else
						if math_random(1,2048) == 1 then
							surface.create_entity({name = "small-worm-turret", position = pos})
						end
					end
				else
					if noise < 0.25 and noise > -0.25 then
						local distance_to_center = pos.x^2 + pos.y^2
						if distance_to_center > 265000 then
							if math_random(1,64) == 1 and surface.can_place_entity({name = "biter-spawner", position = pos}) then
								if math_random(1,64) == 1 then
									shipwreck(pos, surface)									
								else
									if math_random(1,2) == 1 then
										surface.create_entity({name = "biter-spawner", position = pos})
									else
										surface.create_entity({name = "spitter-spawner", position = pos})
									end
								end			
							end
						end
					end
				end
			end				
		end							
	end		
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "0.1"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 16, cliff_elevation_0 = 16}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "0.5", size = "0.75", richness = "0.5"},
			["stone"] = {frequency = "0.5", size = "0.75", richness = "0.5"},
			["copper-ore"] = {frequency = "0.5", size = "0.75", richness = "0.5"},
			["uranium-ore"] = {frequency = "0.5", size = "0.75", richness = "0.5"},
			["iron-ore"] = {frequency = "0.5", size = "0.75", richness = "0.5"},
			["crude-oil"] = {frequency = "1", size = "0.75", richness = "0.5"},
			["trees"] = {frequency = "1", size = "1", richness = "0.1"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}

		game.create_surface("lost_desert", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["lost_desert"])
		local surface = game.surfaces["lost_desert"]
		surface.ticks_per_day = surface.ticks_per_day * 4
		surface.min_brightness = 0.06
		global.map_init_done = true						
	end	
	local surface = game.surfaces["lost_desert"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "lost_desert")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "lost_desert")
		end
	end	
	if player.online_time < 10 then				
		player.insert {name = 'raw-fish', count = 3}
		player.insert {name = 'light-armor', count = 1}
	end	
end

local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)