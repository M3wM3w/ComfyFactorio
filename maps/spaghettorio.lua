--spaghettorio-- mewmew made this -- inspired by redlabel

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event'

local function disable_recipes()
	game.forces.player.recipes["splitter"].enabled = false
	game.forces.player.recipes["fast-splitter"].enabled = false
	game.forces.player.recipes["express-splitter"].enabled = false
	game.forces.player.recipes["steam-engine"].enabled = false
	game.forces.player.recipes["boiler"].enabled = false
	game.forces.player.recipes["assembling-machine-1"].enabled = false
	game.forces.player.recipes["assembling-machine-2"].enabled = false
	game.forces.player.recipes["assembling-machine-3"].enabled = false	
	game.forces.player.recipes["steel-furnace"].enabled = false			
	game.forces.player.recipes["chemical-plant"].enabled = false
	game.forces.player.recipes["centrifuge"].enabled = false
	game.forces.player.recipes["heat-exchanger"].enabled = false
	game.forces.player.recipes["steam-turbine"].enabled = false	
	game.forces.player.recipes["oil-refinery"].enabled = false
	game.forces.player.recipes["lab"].enabled = false
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.map_init_done then			
		local map_gen_settings = {}
		map_gen_settings.water = "none"	
		game.create_surface("spaghettorio", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["spaghettorio"])
		game.forces["player"].technologies["logistic-system"].enabled = false
		global.map_init_done = true						
	end	
	local surface = game.surfaces["spaghettorio"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "spaghettorio")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "spaghettorio")
		end
	end		
	disable_recipes()
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "water" then		
		noise[1] = simplex_noise(pos.x * 0.002, pos.y * 0.002, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	seed = seed + noise_seed_add
	if name == "assembly" then		
		noise[1] = simplex_noise(pos.x * 0.004, pos.y * 0.004, seed)
		seed = seed + noise_seed_add
		local noise = noise[1]
		return noise
	end
end

local splitter_raffle = {"splitter", "splitter", "splitter", "fast-splitter", "fast-splitter", "express-splitter"}
local assembly_raffle = {"assembling-machine-1", "assembling-machine-2", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3", "assembling-machine-1", "assembling-machine-2", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3","chemical-plant", "chemical-plant", "chemical-plant", "oil-refinery", "lab"}
local smelting_raffle = {"steel-furnace", "stone-furnace"}
local steampower_raffle = {"steam-engine", "steam-engine", "boiler"}
local nuclearpower_raffle = {"steam-turbine", "steam-turbine", "steam-turbine", "heat-exchanger", "heat-exchanger", "centrifuge"}
local direction_raffle = {0,2,4,6}

local function on_chunk_generated(event)
	local surface = game.surfaces["spaghettorio"]
	if event.surface.name ~= surface.name then return end
	local entities = {}
	local tiles = {}
	local math_random = math.random
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = event.area.left_top.x + x, y = event.area.left_top.y + y}
			local noise_water = get_noise("water", pos)
			local noise_assembly = get_noise("assembly", pos)
			while true do
				if noise_water > 0.8 or noise_water < -0.8 then
					table.insert(tiles, {name = "water", position = pos})
					break
				end
				if noise_water > 0.68 then
					if math_random(1,50) == 1 then
						local a = {
								left_top = {x = pos.x - 75, y = pos.y - 75},
								right_bottom = {x = pos.x + 75, y = pos.y + 75}
								}								
						local z = surface.count_tiles_filtered{area = a, limit = 1, name = "water"}
						if z == 1 then table.insert(entities, {name = steampower_raffle[math_random(1, #steampower_raffle)], position = pos}) end
					end
					break
				end
				if noise_water < -0.7 then
					if math_random(1,100) == 1 then 
						local a = {
								left_top = {x = pos.x - 75, y = pos.y - 75},
								right_bottom = {x = pos.x + 75, y = pos.y + 75}
								}								
						local z = surface.count_tiles_filtered{area = a, limit = 1, name = "water"}
						if z == 1 then table.insert(entities, {name = nuclearpower_raffle[math_random(1, #nuclearpower_raffle)], position = pos}) end
					end
					break
				end
				if noise_assembly > 0.6 then
					if math_random(1,75) == 1 then
						table.insert(entities, {name = assembly_raffle[math_random(1, #assembly_raffle)], position = pos})
					end
				end
				if noise_assembly < -0.8 then
					if math_random(1,35) == 1 then
						table.insert(entities, {name = smelting_raffle[math_random(1, #smelting_raffle)], position = pos})
					end
				end
				if math_random(1,250) == 1 then
					if noise_assembly < -0.6 or noise_assembly > 0.6 or noise_water < -0.6 or noise_water > 0.6 then
						table.insert(entities, {name = splitter_raffle[math_random(1, #splitter_raffle)], position = pos})
					end
				end
				break
			end			
		end
	end
	surface.set_tiles(tiles, true)
	
	for _, e in pairs(entities) do		
		local d = direction_raffle[math_random(1, #direction_raffle)]
		if surface.can_place_entity({name = e.name, position = e.position, direction = d}) then
			local entity = surface.create_entity{name = e.name, position = e.position, direction = d, force = "player"}
			entity.minable = false
			entity.destructible = false
			if entity.name == "stone-furnace" or entity.name == "steel-furnace" then
				entity.energy = 1
			end
		end
	end
end

local disabled_entities = {"stone-furnace", "electric-furnace", "solar-panel"}
local function on_built_entity(event)
	for _, e in pairs(disabled_entities) do
		if e == event.created_entity.name then
			if event.player_index then
				local player = game.players[event.player_index]
				player.insert({name = event.created_entity.name, count = 1})
			end
			event.created_entity.destroy()
		end
	end
end

local function on_robot_built_entity(event)
	on_built_entity(event)
end

local function on_research_finished(event)
	disable_recipes()
end

event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)