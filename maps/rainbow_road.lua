local event = require 'utils.event'
local simplex_noise = require 'utils.simplex_noise'.d2
local rainbow_colors = require 'tools.rainbow_colors'
local map_functions = require "tools.map_functions"
require "modules.satellite_score"

local ore_spawn_raffle = {"iron-ore","iron-ore","iron-ore","iron-ore","copper-ore","copper-ore","copper-ore","coal","coal","coal","stone","uranium-ore","crude-oil"}
local stars = {"☆", "☆", "☆", "★", "★"}

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.0015, pos.y * 0.0015, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		local noise = noise[1] + noise[2] * 0.005-- + noise[3] * 0.15 + noise[4] * 0.05		
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.0015, pos.y * 0.0015, seed)
		local noise = noise[1]
		return noise
	end	
end

local function process_tile(surface, pos)
	local noise = get_noise(1, pos)	
	
	if noise > 0.15 or noise < -0.15 then
		surface.set_tiles({{name = "out-of-map", position = pos}})
		if noise > 0.25 or noise < -0.25 then
			if math.random(1,1024) == 1 then
				local scale = math.random(20, 100) * 0.1
				--rendering.draw_sprite({sprite = "file/star.png", target = pos, surface = surface, render_layer = "ground", orientation = math.random(0,100) * 0.01, x_scale = scale, y_scale = scale})
				rendering.draw_text{text = stars[math.random(1, #stars)], surface = surface, target = pos, color={r = 1, g = 1, b = 0}, orientation = math.random(0,100) * 0.01, scale = scale, font = "heading-1", alignment = "center", scale_with_zoom = false}			
			end
		end
		return
	end
	
	local tile = surface.get_tile(pos).name
	if tile == "deepwater" then return end
	
	surface.set_tiles({{name = "lab-dark-2", position = pos}})
	
	local noise_2 = get_noise(2, pos)
	
	local color_index = (math.floor(math.abs(noise_2) * 2500) % #rainbow_colors) + 1
	rendering.draw_sprite({sprite = "tile/lab-dark-2", target = pos, surface = surface, tint = rainbow_colors[color_index], render_layer = "ground"})
	
	if noise < 0.10 and noise > -0.10 then
		--if noise_2 < 0.3 and noise_2 > -0.3 then
			if math.random(1, 2048) == 1 then
				local n = ore_spawn_raffle[math.random(1,#ore_spawn_raffle)]
				
				local distance_to_center = math.sqrt(pos.x^2 + pos.y^2)
				local amount = 750 + distance_to_center * 2
				
				if n == "crude-oil" then				
					map_functions.draw_oil_circle(pos, n, surface, 6, 500 * amount)
				else				
					map_functions.draw_smoothed_out_ore_circle(pos, n, surface, math.random(8, 11), amount)
				end
			end
		--end
	end
end

local function get_spawn_position()
	for y = 0, 1024, 1 do
		for x = 0, 1024, 1 do
			local pos = {x = x, y = y}
			local noise = get_noise(1, pos)			
			if noise < 0.1 and noise > -0.1 then
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
		player.insert {name = 'rocket-fuel', count = 1}
	end
end

local function on_init()
	local surface = game.surfaces[1]
	global.sprites = {}
	game.forces["player"].set_spawn_position(get_spawn_position(surface), surface)
end

event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)