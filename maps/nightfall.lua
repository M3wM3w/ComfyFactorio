-- nightfall -- by mewmew --

local event = require 'utils.event'
local math_random = math.random
local insert = table.insert
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
local simplex_noise = simplex_noise.d2
require "maps.nightfall_map_intro"
require "modules.splice_double"
require "modules.spitters_spit_biters"
require "modules.biters_double_damage"
require "modules.explosive_biters"
require "modules.spawners_contain_biters"
require "modules.railgun_enhancer"
require "modules.dynamic_landfill"
require "modules.satellite_score"

local spawn_turret_amount = 8

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_time_gui(player)
	if player.gui.top["time_gui"] then player.gui.top["time_gui"].destroy() end
	local frame = player.gui.top.add({ type = "frame", name = "time_gui"})
	frame.style.maximal_height = 38

	local night_count = 0
	if global.night_count then night_count = global.night_count end
		
	local label = frame.add({ type = "label", caption = "Night: " .. night_count })
	label.style.font_color = {r=0.75, g=0.0, b=0.25}
	label.style.font = "default-listbox"
	label.style.left_padding = 4
	label.style.right_padding = 4
	label.style.minimal_width = 50	
end

local function spawn_shipwreck(surface, position)
	local raffle = {}
	local loot = {					
		{{name = "submachine-gun", count = math_random(1,3)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "slowdown-capsule", count = math_random(16,32)}, weight = 1, evolution_min = 0.0, evolution_max = 1},
		{{name = "poison-capsule", count = math_random(16,32)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "uranium-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 0.7},
		{{name = "explosive-uranium-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "explosive-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "shotgun", count = 1}, weight = 2, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "shotgun-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "combat-shotgun", count = 1}, weight = 10, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "piercing-shotgun-shell", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "flamethrower", count = 1}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "flamethrower-ammo", count = math_random(16,32)}, weight = 5, evolution_min = 0.3, evolution_max = 1},
		{{name = "rocket-launcher", count = 1}, weight = 5, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "rocket", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 0.7},		
		{{name = "explosive-rocket", count = math_random(16,32)}, weight = 10, evolution_min = 0.3, evolution_max = 1},
		{{name = "land-mine", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "grenade", count = math_random(16,32)}, weight = 10, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "cluster-grenade", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 1},
		{{name = "firearm-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0, evolution_max = 0.3},
		{{name = "piercing-rounds-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0.1, evolution_max = 0.8},
		{{name = "uranium-rounds-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0.5, evolution_max = 1},
		{{name = "railgun", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "railgun-dart", count = math_random(16,32)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "defender-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.0, evolution_max = 0.7},
		{{name = "distractor-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "destroyer-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.3, evolution_max = 1},
		{{name = "atomic-bomb", count = math_random(8,16)}, weight = 1, evolution_min = 0.3, evolution_max = 1},		
		{{name = "light-armor", count = 1}, weight = 3, evolution_min = 0, evolution_max = 0.1},		
		{{name = "heavy-armor", count = 1}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "modular-armor", count = 1}, weight = 2, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "power-armor", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		{{name = "power-armor-mk2", count = 1}, weight = 1, evolution_min = 0.8, evolution_max = 1},
		{{name = "battery-equipment", count = 1}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "battery-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		{{name = "belt-immunity-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "solar-panel-equipment", count = math_random(1,4)}, weight = 5, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "discharge-defense-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 0.8},
		{{name = "energy-shield-equipment", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "energy-shield-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "fusion-reactor-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "night-vision-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "personal-laser-defense-equipment", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
						
		
		{{name = "iron-gear-wheel", count = math_random(80,100)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "copper-cable", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "battery", count = math_random(100,200)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "advanced-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "electronic-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "processing-unit", count = math_random(100,200)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "explosives", count = math_random(25,50)}, weight = 1, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, evolution_min = 0.3, evolution_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "computer", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "steel-plate", count = math_random(50,100)}, weight = 2, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
				
		{{name = "burner-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},		
		{{name = "fast-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 1},
		{{name = "filter-inserter", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(4,8)}, weight = 1, evolution_min = 0.4, evolution_max = 1},
		{{name = "stack-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},				
		{{name = "small-electric-pole", count = math_random(16,32)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.2, evolution_max = 1},
		{{name = "big-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "substation", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "wooden-chest", count = math_random(25,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "iron-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 0.4},
		{{name = "steel-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "small-lamp", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail", count = math_random(50,75)}, weight = 3, evolution_min = 0.1, evolution_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "assembling-machine-3", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "accumulator", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "offshore-pump", count = math_random(1,2)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "beacon", count = math_random(1,2)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "boiler", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "steam-engine", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "steam-turbine", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		--{{name = "nuclear-reactor", count = 1}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "centrifuge", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-pipe", count = math_random(8,12)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-exchanger", count = math_random(2,4)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "arithmetic-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "constant-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "decider-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "power-switch", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},		
		{{name = "programmable-speaker", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "green-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "red-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "chemical-plant", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "burner-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		{{name = "express-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0, evolution_max = 0.3},		
		{{name = "oil-refinery", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 1},
		{{name = "pipe", count = math_random(40,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 0.5},
		{{name = "pumpjack", count = math_random(1,2)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "pump", count = math_random(1,4)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "solar-panel", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 0.9},
		{{name = "electric-furnace", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "steel-furnace", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "stone-furnace", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "radar", count = math_random(1,2)}, weight = 1, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},		
		{{name = "stone-wall", count = math_random(25,75)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "gate", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "storage-tank", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "express-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "lab", count = math_random(2,4)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
	
		--{{name = "roboport", count = math_random(2,4)}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		--{{name = "flamethrower-turret", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		--{{name = "laser-turret", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},	
		{{name = "gun-turret", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.9}		
	}

	local distance_to_center = math.sqrt(position.x^2 + position.y^2)
	if distance_to_center < 1 then
		distance_to_center = 0.1
	else
		distance_to_center = distance_to_center / 5000
	end
	if distance_to_center > 1 then distance_to_center = 1 end
	
	for _, t in pairs (loot) do
		for x = 1, t.weight, 1 do
			if t.evolution_min <= distance_to_center and t.evolution_max >= distance_to_center then
				table.insert(raffle, t[1])
			end
		end			
	end
	local name_raffle = {"big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3"}
	local e = surface.create_entity{name = name_raffle[math_random(1,#name_raffle)], position = position, force = "player"}	
	for x = 1, math_random(2,3), 1 do
		local loot = raffle[math_random(1,#raffle)]
		e.insert(loot)
	end	
end

local function clear_corpses(surface)
	for _, entity in pairs(surface.find_entities_filtered{type = "corpse"}) do		
		if math_random(1, 2) == 1 then
			entity.destroy()
		end
	end
end

local function get_spawner(surface)
	local spawners = {}
	for r = 512, 51200, 512 do		 
		spawners = surface.find_entities_filtered({type = "unit-spawner", area = {{0 - r, 0 - r}, {0 + r, 0 + r}}})
		if #spawners > 16 then break end
	end
	
	if not spawners[1] then return false end
	spawners = shuffle(spawners)
	
	if not global.last_spawners then
		global.last_spawners = {{x = spawners[1].position.x, y = spawners[1].position.y}}
		return spawners[1]
	end
	
	for i = 1, #spawners, 1 do
		local spawner_valid = true
		for i2 = #global.last_spawners, #global.last_spawners - 4, -1 do
			if i2 < 1 then break end
			local distance = math.sqrt((spawners[i].position.x - global.last_spawners[i2].x)^2 + (spawners[i].position.y - global.last_spawners[i2].y)^2)
			if distance < 200 then
				spawner_valid = false
				break
			end
		end
		if spawner_valid then
			global.last_spawners[#global.last_spawners + 1] = {x = spawners[i].position.x, y = spawners[i].position.y}
			if #global.last_spawners > 8 then global.last_spawners[#global.last_spawners - 8] = nil end
			return spawners[i]
		end
	end
	
	return false
end
	
local function send_attack_group(surface)	
	local spawner = get_spawner(surface)
	if not spawner then return false end
	
	local biters = surface.find_enemy_units(spawner.position, 128, "player")	
	if not biters[1] then return end
	
	biters = shuffle(biters)
	
	local pos = surface.find_non_colliding_position("rocket-silo", spawner.position, 64, 1)
	if not pos then return end
	
	local unit_group = surface.create_unit_group({position=pos, force="enemy"})
	
	local group_size = 6 + (global.night_count * 6)
	if group_size > 200 then group_size = 200 end
	
	for i = 1, group_size, 1 do
		if not biters[i] then break end
		unit_group.add_member(biters[i])
	end
	
	if global.rocket_silo.valid then
		unit_group.set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
						{
							type = defines.command.attack_area,
							destination = {x = 0, y = 0},
							radius = 48,
							distraction=defines.distraction.by_anything
						},									
						{
							type = defines.command.attack,
							target = global.rocket_silo,
							distraction = defines.distraction.by_enemy
						}
				}
			})
	else
		unit_group.set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
						{
							type = defines.command.attack_area,
							destination = {x = 0, y = 0},
							radius = 48,
							distraction=defines.distraction.by_anything
						}														
				}
			})
	end
end

local daytime_messages = {
	"It´s daytime!",
	"The sun is rising, they are calming down."
}

local function set_daytime_modifiers(surface)
	if game.map_settings.enemy_expansion.enabled == false then return end
	
	game.map_settings.enemy_expansion.enabled = false
	--surface.peaceful_mode = true
	
	--game.print(daytime_messages[math_random(1, #daytime_messages)], {r = 255, g = 255, b = 50})
	
	clear_corpses(surface)
end

local nightfall_messages = {
	"Night is falling.",
	"It is getting dark.",
	"They are becoming restless."
}

local function set_nighttime_modifiers(surface)
	if game.map_settings.enemy_expansion.enabled == true then return end
	
	if not global.night_count then
		global.night_count = 1
		--global.splice_modifier = 1
	else
		global.night_count = global.night_count + 1
		--if game.forces["enemy"].evolution_factor > 0.25 then
			--global.splice_modifier = global.splice_modifier + 0.05
			--if global.splice_modifier > 4 then global.splice_modifier = 4 end
		--end	
	end
	
	for _, player in pairs(game.connected_players) do
		create_time_gui(player)
	end
	
	surface.peaceful_mode = false	
	game.map_settings.enemy_expansion.enabled = true
	
	local max_expansion_distance = math.ceil(global.night_count / 3)
	if max_expansion_distance > 20 then max_expansion_distance = 20 end
	game.map_settings.enemy_expansion.max_expansion_distance = max_expansion_distance
	
	local settler_group_min_size = math.ceil(global.night_count / 6)
	if settler_group_min_size > 20 then settler_group_min_size = 20 end
	game.map_settings.enemy_expansion.settler_group_min_size = settler_group_min_size
	
	local settler_group_max_size = math.ceil(global.night_count / 3)
	if settler_group_max_size > 50 then settler_group_max_size = 50 end
	game.map_settings.enemy_expansion.settler_group_max_size = settler_group_max_size
	
	local min_expansion_cooldown = 54000 - global.night_count * 540
	if min_expansion_cooldown < 3600 then min_expansion_cooldown = 3600 end
	game.map_settings.enemy_expansion.min_expansion_cooldown = min_expansion_cooldown
	
	local max_expansion_cooldown = 108000 - global.night_count * 1080
	if max_expansion_cooldown < 3600 then max_expansion_cooldown = 3600 end
	game.map_settings.enemy_expansion.max_expansion_cooldown = max_expansion_cooldown

	game.print(nightfall_messages[math_random(1, #nightfall_messages)], {r = 150, g = 0, b = 0})	
end

local function generate_spawn_area(surface)		
	local entities = {}
	local tiles = {}	
	local fort_size = 64
	local fort_wall_width = 4
	local turrets = {}
	
	for x = -160, 160, 1 do
		for y = -160, 160, 1 do
			local pos = {x = x, y = y}
			if pos.x > fort_size * -1 and pos.x < fort_size and pos.y > fort_size * -1 and pos.y < fort_size then
				
				if pos.x > (fort_size - fort_wall_width) * -1 and pos.x < fort_size - fort_wall_width and pos.y > (fort_size - fort_wall_width) * -1 and pos.y < fort_size - fort_wall_width then
					if pos.x <= (fort_size - fort_wall_width * 2) * -1 or pos.x >= (fort_size - fort_wall_width * 2) or pos.y <= (fort_size - fort_wall_width * 2) * -1 or pos.y >= (fort_size - fort_wall_width * 2) then
						table.insert(turrets, {name = "gun-turret", position = {x = pos.x, y = pos.y}, force = "player"})
					end
				end
				
				for _, entity in pairs(surface.find_entities_filtered({area = {{pos.x, pos.y}, {pos.x + 0.99, pos.y + 0.99}}})) do
					if entity.name ~= "character" then
						entity.destroy()
					end
				end
								
				table.insert(tiles, {name = "stone-path", position = {x = pos.x, y = pos.y}})				
				
				if pos.x <= (fort_size - fort_wall_width) * -1 or pos.x >= (fort_size - fort_wall_width) or pos.y <= (fort_size - fort_wall_width) * -1 or pos.y >= (fort_size - fort_wall_width) then
					if math_random(1, 3) ~= 1 then
						table.insert(entities, {name = "stone-wall", position = {x = pos.x, y = pos.y}, force = "player"})
					end
				end
			end
		end						
	end
	surface.set_tiles(tiles, true)
	
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
	
	local ore_positions = {{x = -16, y = -16},{x = 16, y = -16},{x = -16, y = 16},{x = 16, y = 16}}
	ore_positions = shuffle(ore_positions)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[1], "copper-ore", surface, 18, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[2], "iron-ore", surface, 18, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[3], "coal", surface, 18, 2500)
	map_functions.draw_smoothed_out_ore_circle(ore_positions[4], "stone", surface, 18, 2500)	
	
	local lake_size = 14
	local lake_distance = fort_size - (lake_size + fort_wall_width)
	local lake_positions = {{x = lake_distance * -1, y = lake_distance * -1},{x = lake_distance, y = lake_distance * -1},{x = lake_distance, y = lake_distance},{x = lake_distance * -1, y = lake_distance}}
	lake_positions = shuffle(lake_positions)
	map_functions.draw_noise_tile_circle(lake_positions[1], "water-green", surface, lake_size)
	map_functions.draw_oil_circle(lake_positions[2], "crude-oil", surface, 8, 200000)
	
	turrets = shuffle(turrets)	
	local x = spawn_turret_amount
	for _, entity in pairs(turrets) do
		if surface.can_place_entity(entity) then
			local turret = surface.create_entity(entity)
			if math_random(1, 3) ~= 1 then
				turret.health = turret.health - math_random(1, 250)
			end
			turret.insert({name = "firearm-magazine", count = math_random(4, 16)})
			x = x - 1
			if x == 0 then break end
		end
	end
	
	global.rocket_silo = surface.create_entity({name = "rocket-silo", position = {0, 0}, force = "player"})
	global.rocket_silo.minable = false
	
	local p = game.permissions.get_group("Default")
	p.set_allows_action(defines.input_action.start_walking, true)
end
			
local function on_chunk_generated(event)
	local surface = game.surfaces["nightfall"]
	if event.surface.name ~= surface.name then return end
	local left_top = event.area.left_top
	local tiles = {}		
	
	if left_top.x > 160 then
		if not global.nightfall_spawn_generated then
			generate_spawn_area(surface)
			global.nightfall_spawn_generated = true
		end					
	end
	
	local out_of_map_start = 63
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			
			local tile_to_insert = false
			if global.out_of_map_position == 1 then
				if pos.x > out_of_map_start then tile_to_insert = "out-of-map" end
				if pos.y > out_of_map_start then tile_to_insert = "out-of-map" end
			end
			if global.out_of_map_position == 2 then
				if pos.x < out_of_map_start * -1 then tile_to_insert = "out-of-map" end
				if pos.y < out_of_map_start * -1 then tile_to_insert = "out-of-map" end
			end
			if global.out_of_map_position == 3 then
				if pos.x > out_of_map_start then tile_to_insert = "out-of-map" end
				if pos.y < out_of_map_start * -1 then tile_to_insert = "out-of-map" end
			end
			if global.out_of_map_position == 4 then
				if pos.y > out_of_map_start then tile_to_insert = "out-of-map" end
				if pos.x < out_of_map_start * -1 then tile_to_insert = "out-of-map" end
			end						
			
			if tile_to_insert then insert(tiles, {name = "out-of-map", position = pos}) end			
			
			if math_random(1, 2500) == 1 and tile_to_insert == false then
				--if surface.can_place_entity({name = "big-ship-wreck-1", position = pos}) then
					spawn_shipwreck(surface, pos)
				--end
			end
		end
	end
	
	if #tiles == 0 then return end
	surface.set_tiles(tiles, true)
end

local function on_entity_damaged(event)	
	if event.cause then
		if event.cause.force.name == "enemy" then
			if global.night_count then
				event.entity.health = event.entity.health - (event.final_damage_amount * global.night_count * 0.05)
				if event.entity.health <= 0 then event.entity.die() end
			end
		end
		if event.cause.force.name == "enemy" then return end				
	end
	if event.entity.valid then
		if event.entity == global.rocket_silo then		
			event.entity.health = event.entity.health + event.final_damage_amount		
		end
	end
end

local function on_tick(event)
	if game.tick % 600 ~= 0 then return end
	local surface = game.surfaces["nightfall"]
	if surface.daytime > 0.25 and surface.daytime < 0.75 then
		set_nighttime_modifiers(surface)
		if surface.daytime < 0.65 then
			send_attack_group(surface)
		end
	else
		set_daytime_modifiers(surface)
	end
	
	if global.rocket_silo then
		if global.rocket_silo.valid then return end
	end
	
	if game.tick < 3600 then return end
			
	if not global.game_restart_timer then
		global.game_restart_timer = 7200
		game.print("The Rocket Silo has fallen!", {r=0.22, g=0.88, b=0.22})
	else
		if global.game_restart_timer < 0 then return end
		global.game_restart_timer = global.game_restart_timer - 600
	end
	if global.game_restart_timer % 1800 == 0 then 
		if global.game_restart_timer > 0 then game.print("Map will restart in " .. global.game_restart_timer / 60 .. " seconds!", {r=0.22, g=0.88, b=0.22}) end
		if global.game_restart_timer == 0 then
			game.print("Map is restarting!", { r=0.22, g=0.88, b=0.22})
			game.write_file("commandPipe", ":loadscenario --force", false, 0)
		end							
	end			
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.fish_defense_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.starting_area = "very-small"		 
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 35, cliff_elevation_0 = 35}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "high", size = "very-big", richness = "normal"},
			["stone"] = {frequency = "high", size = "very-big", richness = "normal"},
			["copper-ore"] = {frequency = "high", size = "very-big", richness = "normal"},
			["iron-ore"] = {frequency = "high", size = "very-big", richness = "normal"},
			["crude-oil"] = {frequency = "very-high", size = "very-big", richness = "normal"},
			["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
			["enemy-base"] = {frequency = "very-high", size = "big", richness = "very-good"}
		}		
		game.create_surface("nightfall", map_gen_settings)							
		local surface = game.surfaces["nightfall"]
		
		global.out_of_map_position = math_random(1,4)
		
		surface.ticks_per_day = surface.ticks_per_day * 2
		
		local radius = 512
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})											
		
		game.map_settings.pollution.enabled = true
		game.map_settings.enemy_evolution.enabled = true
		game.map_settings.enemy_evolution.destroy_factor = 0.006
		game.map_settings.enemy_evolution.time_factor = 0.00001
		game.map_settings.enemy_evolution.pollution_factor = 0.00004
		
		game.forces.player.set_ammo_damage_modifier("shotgun-shell", 1)		
		
		local p = game.permissions.get_group("Default")
		p.set_allows_action(defines.input_action.start_walking, false)
		
		global.fish_defense_init_done = true
	end

	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})		
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 32})
		player.insert({name = "iron-plate", count = 64})
		player.insert({name = "stone", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["nightfall"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0, 16}, 50, 1), "nightfall")
	else
		if player.online_time < 2 then
			player.teleport({0, 16}, "nightfall")
		end
	end
	
	create_time_gui(player)
end

local function on_research_finished(event)	
	game.forces.player.recipes["flamethrower-turret"].enabled = false
end

event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)