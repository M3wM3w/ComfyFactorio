local event = require 'utils.event'
local simplex_noise = require 'utils.simplex_noise'.d2
require "modules.satellite_score"
require "modules.biter_noms_you"
require "modules.dangerous_goods"
require "modules.biters_avoid_damage"
require "modules.dynamic_landfill"
require "modules.biters_double_damage"
require "modules.spawners_contain_biters"
require "modules.splice_double"

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
	local noise = get_noise(1, pos)	
	local noise_2 = get_noise(2, pos)
	
	if noise < 0.12 and noise > -0.12 then
		return
	end
	
	if noise_2 < 0.12 and noise_2 > -0.12 then
		return
	end
	
	local tile = surface.get_tile(pos)
	if tile.collides_with("player-layer") then return end
		
	if surface.can_place_entity({name = "wooden-chest", position = pos, force = "neutral"}) then
		local e = surface.create_entity({name = "wooden-chest", position = pos, force = "neutral"})
		
		
		if noise_2 > -0.85 and noise_2 < 0.85 then return end
		e.insert({name = global.loot[math.random(1, #global.loot)], count = math.random(1, 8)})
	end
end

local function get_spawn_position()
	for y = 0, 1024, 1 do
		for x = 0, 1024, 1 do
			local pos = {x = x, y = y}
			local noise = get_noise(1, pos)			
			if noise < 0.08 and noise > -0.08 then
				return pos
			end
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
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		player.insert {name = 'pistol', count = 1}
		player.insert {name = 'firearm-magazine', count = 16}
		player.insert {name = 'iron-plate', count = 100}
		player.insert {name = 'copper-plate', count = 50}
		player.insert {name = 'car', count = 1}
	end
end

local blacklist = {
	["atomic-bomb"] = true,
	["battery-mk2-equipment"] = true,
	["blueprint"] = true,
	["blueprint-book"] = true,
	["centrifuge"] = true,
	["compilatron-chest"] = true,
	["copy-paste-tool"] = true,
	["cut-paste-tool"] = true,
	["deconstruction-planner"] = true,
	["dummy-steel-axe"] = true,
	["effectivity-module-2"] = true,
	["effectivity-module-3"] = true,
	["electric-energy-interface"] = true,
	["energy-shield-equipment"] = true,
	["energy-shield-mk2-equipment"] = true,
	["escape-pod-assembler"] = true,
	["escape-pod-lab"] = true,
	["escape-pod-power"] = true,
	["fusion-reactor-equipment"] = true,
	["heat-exchanger"] = true,
	["heat-interface"] = true,
	["heat-pipe"] = true,
	["hidden-electric-energy-interface"] = true,
	["infinity-chest"] = true,
	["infinity-pipe"] = true,
	["laser-turret"] = true,
	["nuclear-reactor"] = true,
	["oil-refinery"] = true,
	["player-port"] = true,
	["pollution"] = true,
	["power-armor"] = true,
	["power-armor-mk2"] = true,
	["productivity-module-2"] = true,
	["productivity-module-3"] = true,
	["rocket-silo"] = true,
	["satellite"] = true,
	["selection-tool"] = true,
	["simple-entity-with-force"] = true,
	["simple-entity-with-owner"] = true,
	["speed-module-2"] = true,
	["speed-module-3"] = true,
	["steam-turbine"] = true,
	["tank"] = true,
	["upgrade-planner"] = true
}

local function on_init()
	local surface = game.surfaces[1]
	game.forces["player"].set_spawn_position(get_spawn_position(surface), surface)
	
	global.loot = {}
	for _, i in pairs(game.item_prototypes) do
		if not blacklist[i.name] then
			global.loot[#global.loot + 1] = i.name
		end			
	end
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	if event.entity.type == "tree" then 
		for _, entity in pairs (event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 4, event.entity.position.y - 4},{event.entity.position.x + 4, event.entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
			if entity.valid then entity.destroy() end
		end
	end		
end

event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)