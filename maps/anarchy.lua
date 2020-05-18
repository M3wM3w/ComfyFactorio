--anarchy mode map -- by mewmew --

require "maps.hunger_games_map_intro"
require "modules.hunger_games"
require "modules.dynamic_player_spawn"

local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "tools.map_functions"

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not global.map_init_done then				
		game.map_settings.enemy_expansion.enabled = false		
		game.map_settings.enemy_evolution.time_factor = 0
		game.map_settings.enemy_evolution.pollution_factor = 0					
		--game.map_settings.pollution.enabled = false
		global.map_init_done = true
	end			
	
	if player.online_time == 0 then		
		player.insert{name = 'iron-plate', count = 32}		
	end	
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	
	--[[
	local entities = surface.find_entities_filtered({area = event.area, force = "enemy"})
	for _, entity in pairs(entities) do
		entity.destroy()
	end
	local entities = {}	
	]]
		
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}			
			if math_random(1, 60000) == 1 then
				map_functions.draw_entity_circle(pos, "stone", surface, 6, true, 1000000)
				map_functions.draw_entity_circle(pos, "coal", surface, 12, true, 1000000)
				map_functions.draw_entity_circle(pos, "copper-ore", surface, 18, true, 1000000)
				map_functions.draw_entity_circle(pos, "iron-ore", surface, 24, true, 1000000)
				map_functions.draw_noise_tile_circle(pos, "water", surface, 4)		
			end
			--[[
			if math_random(1, 75000) == 1 and pos.x^2 + pos.y^2 > 60000 then							
				if surface.can_place_entity({name = "biter-spawner", position = pos}) then
					if math_random(1, 4) == 1 then
						table_insert(entities, {name = "spitter-spawner", position = pos})					
					else
						table_insert(entities, {name = "biter-spawner", position = pos})						
					end
				end
			end
			]]
		end
	end
	
	--[[
	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
	]]
	
	if not global.spawn_generated and left_top.x <= -96 then
		map_functions.draw_noise_tile_circle({x = 0, y = 0}, "stone-path", surface, 21)
		map_functions.draw_noise_tile_circle({x = 0, y = 0}, "concrete", surface, 7)		
		global.spawn_generated = true
	end
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_chunk_generated, on_chunk_generated)