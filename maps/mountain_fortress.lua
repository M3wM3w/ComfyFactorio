-- mountain digger fortress -- by mewmew --

require "modules.rpg"
require "modules.biters_yield_coins"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_heal_over_time"
require "modules.rocks_yield_ore_veins"
require "modules.rocks_yield_ore"
require "modules.satellite_score"
require "modules.spawners_contain_biters"
require "modules.splice_double"
require "modules.biters_attack_moving_players"
--require "modules.flashlight_toggle_button"

local difficulty_factor = 4

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
	
	for i = 1, math.random(6, 8), 1 do
		market.add_market_item(secret_market_items[i])
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.surface_init_done then	
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.height = 960
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 4}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["uranium-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "2", size = "1", richness = 0.2},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			--["grass"] = {frequency = "none", size = "none", richness = "none"},
			--["sand"] = {frequency = "none", size = "none", richness = "none"},
			--["desert"] = {frequency = "none", size = "none", richness = "none"},
			--["dirt"] = {frequency = "normal", size = "normal", richness = "normal"}
		}		
		game.create_surface("mountain_fortress", map_gen_settings)							
		local surface = game.surfaces["mountain_fortress"]
		
		local radius = 160
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})
		
		game.map_settings.pollution.enabled = true
		game.map_settings.enemy_expansion.enabled = true

		--default game setting values
		global.enemy_evolution_destroy_factor = game.map_settings.enemy_evolution.destroy_factor
		global.enemy_evolution_time_factor = game.map_settings.enemy_evolution.time_factor
		global.enemy_evolution_pollution_factor = game.map_settings.enemy_evolution.pollution_factor
		
		game.map_settings.enemy_evolution.destroy_factor = global.enemy_evolution_destroy_factor * difficulty_factor
		game.map_settings.enemy_evolution.time_factor = global.enemy_evolution_time_factor * difficulty_factor
		game.map_settings.enemy_evolution.pollution_factor = global.enemy_evolution_pollution_factor * difficulty_factor
		
		game.map_settings.enemy_expansion.max_expansion_distance = 15
		game.map_settings.enemy_expansion.settler_group_min_size = 8
		game.map_settings.enemy_expansion.settler_group_max_size = 16
		game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
		game.map_settings.enemy_expansion.max_expansion_cooldown = 7200
		
		surface.ticks_per_day = surface.ticks_per_day * 2
		game.forces.player.technologies["steel-axe"].researched = true
		
		global.surface_init_done = true
	end
	
	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
	--	player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end
	
	local surface = game.surfaces["mountain_fortress"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", spawn_point, 50, 1), "mountain_fortress")
	else
		if player.online_time < 2 then
			player.teleport(spawn_point, "mountain_fortress")
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
	
	for _, e in pairs(surface.find_entities_filtered({area = area, type = "tree"})) do
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
	
	if math_random(1,50) == 1 then
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
	
	if left_top.y > 32 then
		for _, e in pairs(surface.find_entities_filtered({area = event.area})) do
			e.destroy()
		end
	else
		for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "cliff"})) do
			e.destroy()
		end
	end		
	
	local current_depth = math.abs(left_top.y) - 32
	
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
		
	if position.y * 32 < 64 then return end
	
	if math_random(1,3) ~= 1 then return end	
	map_functions.draw_rainbow_patch({x = position.x * 32 + math_random(1,32), y = position.y * 32 + math_random(1,32)}, surface, math_random(10, 18), 500 * position.y)
	game.forces.player.chart(surface, area)
end

local function replace_spawn_water(surface)
	if global.spawn_water_replaced then return end
	if not surface.is_chunk_generated({5,5}) then return end
	local tilename = "grass-1"
	for x = -160, 160, 1 do
		for y = -96, 90, 1 do
			local tile = surface.get_tile(x, y)
			if tile.name ~= "water" and tile.name ~= "deepwater" then
				tilename = tile.name
			end
		end
	end
	local tiles = {}
	for x = -128, 128, 1 do
		for y = -128, 128, 1 do
			local tile = surface.get_tile(x, y)
			if tile.name == "water" or tile.name == "deepwater" then
				insert(tiles, {name = tilename, position = {x = tile.position.x, y = tile.position.y}})
			end
		end
	end
	surface.set_tiles(tiles, true)
	global.spawn_water_replaced = true
end

local function on_chunk_generated(event)
	local surface = game.surfaces["mountain_fortress"]
	if event.surface.name ~= surface.name then return end
	local left_top = event.area.left_top					
	
	replace_spawn_water(surface)		
	
	if left_top.y < 0 then		
		generate_north_chunk(event.area, surface)
		return
	end
	
	if left_top.y > 0 then
		generate_south_chunk(event, surface)
		return
	end		
	
	for _, e in pairs(surface.find_entities_filtered({area = event.area, type = "cliff"})) do
		e.destroy()
	end
	
	local trees = {"dead-grey-trunk", "dead-grey-trunk", "dry-tree"}
	for x = 0, 31, 1 do
		for y = 5, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if math_random(1, math.ceil(y + y) + 64) == 1 then
				surface.create_entity({name = trees[math_random(1, #trees)], position = pos})			
			end
		end
	end		
	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}

			if math_random(1, y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-medium", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end
			if math_random(1, y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-small", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end
			if math_random(1, y + 2) == 1 then
				surface.create_decoratives{
				check_collision=false,
				decoratives={
						{name = "rock-tiny", position = pos, amount = math_random(1, 1 + math.ceil(20 - y / 2))}
					}
				}
			end						
			
			--[[
			local noise = get_noise("rock_border", {x = pos.x, y = 0})	
			if math.abs(noise * 6) > y then
				if math_random(1, 3) ~= 1 then surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos}) end
				surface.set_tiles({{name = "dirt-7", position = pos}}, true)
			end]]
			
			if math_random(1, math.ceil(y + y) + 2) == 1 then
				surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})			
			end
		end
	end
	
	if left_top.y ~= 0 then return end
	if left_top.x ~= 96 then return end
	for _, e in pairs(surface.find_entities_filtered({area = {{spawn_point.x - 0.5, spawn_point.y - 0.5},{spawn_point.x + 0.5, spawn_point.y + 0.5}}})) do
		if e.force.name ~= "player" then
			e.destroy()
		end
	end
	for _, e in pairs(surface.find_entities_filtered({area = {{spawn_point.x - 40, spawn_point.y - 40},{spawn_point.x + 40, spawn_point.y + 40}}, force = "enemy"})) do		
		e.destroy()		
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
	
	local surface = game.surfaces["mountain_fortress"]
	
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

event.add(defines.events.on_tick, on_tick)--]]
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)