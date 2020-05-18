-- digging thingie -- by mewmew --

require "modules.satellite_score"
require "modules.dynamic_landfill"
require "modules.backpack_research"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.rocks_yield_ore"
require "modules.biters_yield_coins"
require "modules.spawners_contain_biters"
--require "modules.splice_double"
--require "modules.spitters_spit_biters"
--require "modules.biters_avoid_damage"
require "modules.flashlight_toggle_button"
require "modules.more_attacks"
require "modules.evolution_extended"

local event = require 'utils.event'
local math_random = math.random
local insert = table.insert
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
local simplex_noise = simplex_noise.d2

local spawn_point = {x = 0, y = 2}

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,		
	}
local worm_raffle_table = {
		[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"},
		[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"},
		[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[9] = {"medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[10] = {"medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
	}
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local nest_raffle = {"biter-spawner", "biter-spawner", "biter-spawner", "spitter-spawner"}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function secret_shop(pos, surface)
	local secret_market_items = {
	{price = {{"coin", math_random(8,16)}}, offer = {type = 'give-item', item = 'grenade'}},
    {price = {{"coin", math_random(25,50)}}, offer = {type = 'give-item', item = 'cluster-grenade'}}, 
	{price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'defender-capsule'}}, 
	{price = {{"coin", math_random(25,50)}}, offer = {type = 'give-item', item = 'distractor-capsule'}}, 
	{price = {{"coin", math_random(35,70)}}, offer = {type = 'give-item', item = 'destroyer-capsule'}}, 
	--{price = {{"coin", math_random(60,120)}}, offer = {type = 'give-item', item = 'cliff-explosives'}},
    {price = {{"coin", math_random(250,350)}}, offer = {type = 'give-item', item = 'belt-immunity-equipment'}},
    {price = {{"coin", math_random(30,60)}}, offer = {type = 'give-item', item = 'construction-robot'}},  
	{price = {{"coin", math_random(100,200)}}, offer = {type = 'give-item', item = 'loader'}},
	{price = {{"coin", math_random(200,300)}}, offer = {type = 'give-item', item = 'fast-loader'}},
	{price = {{"coin", math_random(300,500)}}, offer = {type = 'give-item', item = 'express-loader'}},
	{price = {{"coin", math_random(100,200)}}, offer = {type = 'give-item', item = 'locomotive'}},
	{price = {{"coin", math_random(75,150)}}, offer = {type = 'give-item', item = 'cargo-wagon'}},	
	{price = {{"coin", math_random(2,3)}}, offer = {type = 'give-item', item = 'rail'}},
	--{price = {{"coin", math_random(20,40)}}, offer = {type = 'give-item', item = 'train-stop'}},	
	{price = {{"coin", math_random(4,12)}}, offer = {type = 'give-item', item = 'small-lamp'}},			
	{price = {{"coin", math_random(80,160)}}, offer = {type = 'give-item', item = 'car'}},
	{price = {{"coin", math_random(300,600)}}, offer = {type = 'give-item', item = 'electric-furnace'}},
	--{price = {{"coin", math_random(300,600)}}, offer = {type = 'give-item', item = "assembling-machine-3"}},
	{price = {{"coin", math_random(80,160)}}, offer = {type = 'give-item', item = 'effectivity-module'}},
	{price = {{"coin", math_random(80,160)}}, offer = {type = 'give-item', item = 'productivity-module'}},
	{price = {{"coin", math_random(80,160)}}, offer = {type = 'give-item', item = 'speed-module'}},
	
	{price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'wood', count = 50}},
	{price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
	{price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
	{price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'stone', count = 50}},
	{price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'coal', count = 50}},
	{price = {{"coin", math_random(8,16)}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
	
	{price = {{'wood', math_random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
	{price = {{'iron-ore', math_random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
	{price = {{'copper-ore', math_random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
	{price = {{'stone', math_random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
	{price = {{'coal', math_random(10,12)}}, offer = {type = 'give-item', item = "coin"}},
	{price = {{'uranium-ore', math_random(8,10)}}, offer = {type = 'give-item', item = "coin"}}
	}
	secret_market_items = shuffle(secret_market_items)
										
	local market = surface.create_entity {name = "market", position = pos}
	market.destructible = false			
	
	for i = 1, math.random(8, 10), 1 do
		market.add_market_item(secret_market_items[i])
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.surface_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 6, cliff_elevation_0 = 6}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "normal", size = "normal", richness = "normal"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}		
		game.create_surface("stoneblock", map_gen_settings)							
		local surface = game.surfaces["stoneblock"]
		
		local radius = 512
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
		
		game.map_settings.pollution.enabled = true
		game.map_settings.enemy_expansion.enabled = true
		game.map_settings.enemy_evolution.destroy_factor = 0.006
		game.map_settings.enemy_evolution.time_factor = 0.00003
		game.map_settings.enemy_evolution.pollution_factor = 0.00005					
		game.map_settings.enemy_expansion.max_expansion_distance = 15
		game.map_settings.enemy_expansion.settler_group_min_size = 15
		game.map_settings.enemy_expansion.settler_group_max_size = 30
		game.map_settings.enemy_expansion.min_expansion_cooldown = 7200
		game.map_settings.enemy_expansion.max_expansion_cooldown = 10800
				
		surface.ticks_per_day = surface.ticks_per_day * 2
		surface.daytime = 0.5
		surface.freeze_daytime = 1
		
		game.forces.player.manual_mining_speed_modifier = 1.75
		
		global.surface_init_done = true
	end
	
	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})		
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "wood", count = 16})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["stoneblock"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", spawn_point, 50, 1), "stoneblock")
	else
		if player.online_time < 2 then
			player.teleport(spawn_point, "stoneblock")
		end
	end		
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	--local noise_seed_add = 25000
	if name == "rock_border" then		
		noise[1] = simplex_noise(pos.x * 0.008, pos.y * 0.008, seed)		
		--noise[2] = simplex_noise(pos.x * 0.04, pos.y * 0.04, seed)
		local noise = noise[1]-- + noise[2] * 0.2
		return noise
	end	
end

local function generate_north_chunk(area, surface)
	local left_top = area.left_top
	local tile_positions = {}				
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "tree"})) do
		e.destroy()
	end
	
	local tiles_to_set = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}			
			tile_positions[#tile_positions + 1] = pos			
			insert(tiles_to_set, {name = "dirt-7", position = pos})
		end
	end
	surface.set_tiles(tiles_to_set, true)
	if #tile_positions == 0 then return end
	
	local rock_amount = math.ceil(#tile_positions * 0.75)
	tile_positions = shuffle(tile_positions)
	for _, pos in pairs(tile_positions) do					
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})	
		rock_amount = rock_amount - 1
		if rock_amount < 1 then break end
	end	
	
	local waters = {"water-green", "deepwater-green"}
	if math_random(1,8) == 1 then
		local pos = tile_positions[math_random(1, #tile_positions)]
		map_functions.draw_noise_tile_circle(pos, waters[math_random(1, #waters)], surface, math_random(2, 8))			
		for x = 1, math_random(2,7), 1 do
			surface.create_entity({name = "fish", position = pos})
		end		
	end
	
	if math_random(1,32) == 1 then
		local pos = tile_positions[math_random(1, #tile_positions)]
		local size = math_random(3, 8)
		map_functions.draw_noise_tile_circle(pos, "water", surface, size - 1)
		map_functions.draw_noise_tile_circle(pos, "grass-2", surface, size)
		secret_shop(pos, surface)		
	end
	
	if math_random(1,26) == 1 then
		map_functions.draw_noise_tile_circle(pos, "water", surface, 5)
		map_functions.draw_noise_tile_circle(pos, "sand-3", surface, 6)
		map_functions.draw_oil_circle(tile_positions[math_random(1, #tile_positions)], "crude-oil", surface, math_random(1, 4), math_random(100000, 500000))
	end
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	surface.regenerate_decorative(decorative_names, {{x=math.floor(left_top.x/32),y=math.floor(left_top.y/32)}})	
end

local function generate_south_chunk(event, surface)	
	local left_top = event.area.left_top
		
	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "cliff"})) do
		e.destroy()
	end			
			
	local current_depth = math.sqrt(left_top.x^2 + left_top.y^2) * 0.05
	
	local i = math.ceil(current_depth / 32)
	if i > 10 then i = 10 end
	if i < 1 then i = 1 end
	local worm_raffle = worm_raffle_table[i]
	
	local worm_amount = math.ceil(current_depth / 32)
	if worm_amount > 16 then worm_amount = 16 end
	local nests_amount = math.ceil(current_depth / 8)
	if nests_amount > 16 then nests_amount = 16 end
	local ore_patch_amount = math.floor(current_depth / 96)
	
	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if not surface.get_tile(pos).collides_with("player-layer") then
				tile_positions[#tile_positions + 1] = pos
			end
		end
	end			
	if #tile_positions == 0 then return end
	
	tile_positions = shuffle(tile_positions)
	for _, pos in pairs(tile_positions) do
		if surface.can_place_entity({name = "biter-spawner", position = pos, force = "enemy"}) then
			surface.create_entity({name = nest_raffle[math_random(1, #nest_raffle)], position = pos, force = "enemy"})
			nests_amount = nests_amount - 1
			if nests_amount < 1 then break end
		end
	end	
	
	tile_positions = shuffle(tile_positions)			
	for _, pos in pairs(tile_positions) do		
		if surface.can_place_entity({name = "big-worm-turret", position = pos, force = "enemy"}) then
			surface.create_entity({name = worm_raffle[math_random(1, #worm_raffle)], position = pos, force = "enemy"})
			worm_amount = worm_amount - 1
			if worm_amount < 1 then break end
		end
	end		
end

local function on_chunk_charted(event)
	if not global.chunks_charted then global.chunks_charted = {} end
	local surface = game.surfaces[event.surface_index]
	local position = event.position
	if global.chunks_charted[tostring(position.x) .. tostring(position.y)] then return end
	global.chunks_charted[tostring(position.x) .. tostring(position.y)] = true
	local area = {
			left_top = {x = position.x * 32, y = position.y * 32},
			right_bottom = {x = position.x * 32 + 31, y = position.y * 32 + 31}
		}		
	
	local left_top = {x = position.x * 32, y = position.y * 32}
	local size = 320
	if left_top.y < size and left_top.y >= size * -1 and left_top.x < size and left_top.x >= size * -1 then				
		return	
	end		
	
	if math_random(1,3) ~= 1 then return end	
	local distance_to_center = math.sqrt(left_top.x^2 + left_top.y^2)
	map_functions.draw_rainbow_patch({x = position.x * 32 + math_random(1,32), y = position.y * 32 + math_random(1,32)}, surface, math_random(8, 16), distance_to_center * 3)
	game.forces.player.chart(surface, area)
end

local function on_chunk_generated(event)
	local surface = game.surfaces["stoneblock"]
	if event.surface.name ~= surface.name then return end
	local left_top = event.area.left_top							
	
	local size = 320
	if left_top.y < size and left_top.y >= size * -1 and left_top.x < size and left_top.x >= size * -1 then		
		generate_north_chunk(event.area, surface)
		return
	else
		generate_south_chunk(event, surface)
		return
	end							
end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "simple-entity" then
		if event.force.name == "player" then 
			event.entity.health = event.entity.health + (event.final_damage_amount * 0.5)
			if event.entity.health <= event.final_damage_amount then				
				event.entity.die("player")
			end			
		end
	end
end
	
local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

--[[
local function on_tick(event)	
	if game.tick % 3600 ~= 1 then return end
	if math_random(1,8) ~= 1 then return end
	
	local surface = game.surfaces["stoneblock"]
	
	local spawners = surface.find_entities_filtered({force = "enemy", type = "unit-spawner"})
	if not spawners[1] then return end
	
	local target = surface.find_nearest_enemy({position = spawners[math_random(1, #spawners)].position, max_distance=1500, force="enemy"})
	if not target then return end
	
	surface.set_multi_command({
		command={
				type=defines.command.attack_area,
				destination=target.position,
				radius=16,
				distraction=defines.distraction.by_anything
			},
		unit_count = math_random(6,12),
		force = "enemy",
		unit_search_distance=1024
	})	
end

event.add(defines.events.on_tick, on_tick)
]]--
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)