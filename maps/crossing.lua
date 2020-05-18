-- crossing -- by mewmew --

local event = require 'utils.event'
local math_random = math.random
local insert = table.insert
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
local simplex_noise = simplex_noise.d2

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		player.insert({name = "raw-fish", count = 1})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		
		pos = player.character.surface.find_non_colliding_position("character",{0, -40}, 50, 1)
		game.forces.player.set_spawn_position(pos, player.character.surface)
		player.teleport(pos, player.character.surface)
		
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end		
	end
end

local function on_chunk_generated(event)
	local surface = game.surfaces[1]
	local seed = game.surfaces[1].map_gen_settings.seed
	if event.surface.name ~= surface.name then return end
	local left_top = event.area.left_top
					
	local entities = surface.find_entities_filtered({area = event.area, name = {"iron-ore", "copper-ore", "coal", "stone"}})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	
	if left_top.x > 128 then
		if not global.spawn_ores_generated then
			map_functions.draw_noise_tile_circle({x = 0, y = 0}, "water", surface, 24)
			global.spawn_ores_generated = true
		end
	end
	
	if left_top.x < 64 and left_top.x > -64 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
								
				local pos = {x = left_top.x + x, y = left_top.y + y}								
				local noise_1 = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)				
				
				if pos.x > -80 + (noise_1 * 8) and pos.x < 80 + (noise_1 * 8) then
					local tile = surface.get_tile(pos)
					if tile.name == "water" or tile.name == "deepwater" then
						surface.set_tiles({{name = "grass-2", position = pos}})
					end
				end
								
				if pos.x > -14 + (noise_1 * 8) and pos.x < 14 + (noise_1 * 8) then								
					if pos.y > 0 then
						surface.create_entity({name = "stone", position = pos, amount = 1 + pos.y * 0.5})
					else
						surface.create_entity({name = "coal", position = pos, amount = 1 + pos.y * -1 * 0.5})
					end											
				end				
			end
		end
	end
	
	if left_top.y < 64 and left_top.y > -64 then
		for x = 0, 31, 1 do
			for y = 0, 31, 1 do
				local pos = {x = left_top.x + x, y = left_top.y + y}								
				local noise_1 = simplex_noise(pos.x * 0.015, pos.y * 0.015, seed)				
				
				if pos.y > -80 + (noise_1 * 8) and pos.y < 80 + (noise_1 * 8) then
					local tile = surface.get_tile(pos)		
					if tile.name == "water" or tile.name == "deepwater" then
						surface.set_tiles({{name = "grass-2", position = pos}})
					end
				end
				
				if pos.y > -14 + (noise_1 * 8) and pos.y < 14 + (noise_1 * 8) then					
					if pos.x > 0 then
						surface.create_entity({name = "copper-ore", position = pos, amount = 1 + pos.x * 0.5})
					else
						surface.create_entity({name = "iron-ore", position = pos, amount = 1 + pos.x * -1 * 0.5})
					end											
				end				
			end
		end
	end	
end

local biter_building_inhabitants = {
	[1] = {{"small-biter",8,16}},
	[2] = {{"small-biter",12,24}},
	[3] = {{"small-biter",8,16},{"medium-biter",1,2}},
	[4] = {{"small-biter",4,8},{"medium-biter",4,8}},
	[5] = {{"small-biter",3,5},{"medium-biter",8,12}},
	[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}},
	[7] = {{"medium-biter",6,8},{"big-biter",3,5}},
	[8] = {{"medium-biter",2,4},{"big-biter",6,8}},
	[9] = {{"medium-biter",2,3},{"big-biter",7,9}},
	[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}
}

local function on_entity_died(event)
	if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
		local e = math.ceil(game.forces.enemy.evolution_factor*10, 0)
		for _, t in pairs (biter_building_inhabitants[e]) do
			for x = 1, math.random(t[2],t[3]), 1 do
				local p = event.entity.surface.find_non_colliding_position(t[1] , event.entity.position, 6, 1)
				if p then event.entity.surface.create_entity {name=t[1], position=p} end
			end
		end
	end
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_entity_died, on_entity_died)
