-- territorial control by Gerkiz

local Map = require "modules.map_info"
require "on_tick_schedule"
require "modules.fish_respawner"
global.fish_respawner_water_tiles_per_fish = 16

require "modules.satellite_score"
require "modules.dangerous_nights"
require "modules.dynamic_landfill"
require "modules.splice_double"
require "modules.spawners_contain_biters"
require "modules.rocks_broken_paint_tiles"
require "modules.rocks_yield_ore"
require "modules.biters_yield_coins"
require "modules.mineable_wreckage_yields_scrap"

local shapes = require "tools.shapes"
local Event = require 'utils.event'
local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"
local tick_tack_trap = require "functions.tick_tack_trap"
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2

local math_random = math.random
local insert = table.insert
local uncover_radius = 8

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

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

local biters_in_the_void = {
		[1] = {"small-biter","small-biter","small-biter","small-biter","small-spitter","small-spitter"},
		[2] = {"small-biter","small-biter","small-biter","small-spitter","small-spitter","medium-biter"},
		[3] = {"small-biter","small-biter","small-biter","small-biter","medium-biter","medium-spitter"},
		[4] = {"small-biter","small-biter","small-biter","medium-biter","medium-biter","medium-spitter"},
		[5] = {"small-biter","small-biter","medium-biter","medium-biter","medium-biter","medium-spitter"},
		[6] = {"small-biter","medium-biter","medium-biter","medium-biter","medium-biter","medium-spitter"},
		[7] = {"medium-biter","medium-biter","medium-biter","medium-biter","big-biter","medium-spitter"},
		[8] = {"medium-biter","medium-biter","medium-biter","medium-biter","big-biter","big-spitter"},
		[9] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"},
		[10] = {"medium-biter","medium-biter","medium-biter","big-biter","big-biter","big-spitter"},
		[11] = {"medium-biter","medium-biter","big-biter","big-biter","big-biter","big-spitter"},
		[12] = {"medium-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"},
		[13] = {"big-biter","big-biter","big-biter","big-biter","big-biter","big-spitter"},
		[14] = {"big-biter","big-biter","big-biter","big-biter","behemoth-biter","big-spitter"},
		[15] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","big-spitter"},
		[16] = {"big-biter","big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[17] = {"big-biter","big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[18] = {"big-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[19] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter"},
		[20] = {"behemoth-biter","behemoth-biter","behemoth-biter","behemoth-biter","behemoth-spitter","behemoth-spitter"}
	}

local ore_spawn_raffle = {
		"iron-ore","iron-ore","iron-ore","iron-ore", "iron-ore","iron-ore","iron-ore","iron-ore", "iron-ore","iron-ore",
		"copper-ore","copper-ore","copper-ore", "copper-ore","copper-ore","copper-ore", "copper-ore",
		"coal","coal", "coal","coal", "coal",
		"stone", "stone", "stone",
		"uranium-ore",
		"crude-oil"
	}

local rock_raffle = {"sand-rock-big","sand-rock-big", "rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local tree_raffle = {"tree-02-red","tree-09-red", "tree-02-red","tree-09-red","tree-02-red","tree-09-red","tree-02-red","tree-09-red","tree-02-red","tree-09-red","tree-02-red"}

local function secret_shop(pos, surface)
	local secret_market_items = {
    {price = {{"coin", math_random(75,125)}}, offer = {type = 'give-item', item = 'combat-shotgun'}},
    {price = {{"coin", math_random(40,60)}}, offer = {type = 'give-item', item = 'rocket-launcher'}},
    {price = {{"coin", math_random(1,2)}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine'}},
    {price = {{"coin", math_random(3,6)}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine'}},
    {price = {{"coin", math_random(1,4)}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell'}},
    {price = {{"coin", math_random(1,2)}}, offer = {type = 'give-item', item = 'rocket'}},
    {price = {{"coin", math_random(2,3)}}, offer = {type = 'give-item', item = 'explosive-rocket'}},
    {price = {{"coin", math_random(1,2)}}, offer = {type = 'give-item', item = 'explosive-cannon-shell'}},
    {price = {{"coin", math_random(3,6)}}, offer = {type = 'give-item', item = 'explosive-uranium-cannon-shell'}},
    {price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'cluster-grenade'}},
	{price = {{"coin", math_random(1,2)}}, offer = {type = 'give-item', item = 'land-mine'}},
	{price = {{"coin", math_random(25,50)}}, offer = {type = 'give-item', item = 'heavy-armor'}},
    {price = {{"coin", math_random(125,250)}}, offer = {type = 'give-item', item = 'modular-armor'}},
    {price = {{"coin", math_random(300,600)}}, offer = {type = 'give-item', item = 'power-armor'}},
    {price = {{"coin", math_random(300,600)}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment'}},
    {price = {{"coin", math_random(20,40)}}, offer = {type = 'give-item', item = 'battery-equipment'}},
    {price = {{"coin", math_random(100,150)}}, offer = {type = 'give-item', item = 'belt-immunity-equipment'}},
    {price = {{"coin", math_random(40,80)}}, offer = {type = 'give-item', item = 'night-vision-equipment'}},
    {price = {{"coin", math_random(60,120)}}, offer = {type = 'give-item', item = 'exoskeleton-equipment'}},
    {price = {{"coin", math_random(60,120)}}, offer = {type = 'give-item', item = 'personal-roboport-equipment'}},
    {price = {{"coin", math_random(3,9)}}, offer = {type = 'give-item', item = 'construction-robot'}},
    {price = {{"coin", math_random(100,200)}}, offer = {type = 'give-item', item = 'energy-shield-equipment'}},
    {price = {{"coin", math_random(200,400)}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment'}},
    {price = {{"coin", math_random(25,50)}}, offer = {type = 'give-item', item = 'railgun'}},
    {price = {{"coin", math_random(1,2)}}, offer = {type = 'give-item', item = 'railgun-dart', count = 2}},
	{price = {{"coin", math_random(30,60)}}, offer = {type = 'give-item', item = 'loader'}},
	{price = {{"coin", math_random(50,80)}}, offer = {type = 'give-item', item = 'fast-loader'}},
	{price = {{"coin", math_random(70,100)}}, offer = {type = 'give-item', item = 'express-loader'}},
	{price = {{"coin", math_random(30,60)}}, offer = {type = 'give-item', item = 'locomotive'}},
	{price = {{"coin", math_random(15,35)}}, offer = {type = 'give-item', item = 'cargo-wagon'}},
	{price = {{"coin", math_random(1,4)}}, offer = {type = 'give-item', item = 'grenade'}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'rail', count = 4}},
	{price = {{"coin", 5}}, offer = {type = 'give-item', item = 'train-stop'}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'small-lamp'}},
	{price = {{"coin", 2}}, offer = {type = 'give-item', item = 'firearm-magazine'}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'wood', count = math_random(25,75)}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'iron-ore', count = math_random(25,75)}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'copper-ore', count = math_random(25,75)}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'stone', count = math_random(25,75)}},
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'coal', count = math_random(25,75)}},	
	{price = {{"coin", 1}}, offer = {type = 'give-item', item = 'uranium-ore', count = math_random(25,75)}}
	}
	secret_market_items = shuffle(secret_market_items)
	local market = surface.create_entity {name = "market", position = pos}
	market.destructible = false

	for i = 1, math.random(4, 8), 1 do
		market.add_market_item(secret_market_items[i])
	end
end

local function spawn_biter(surface, position)
	local e = math.ceil(game.forces.enemy.evolution_factor*20)
	if e < 1 then e = 1 end
	if e > 20 then e = 20 end
	local biter = biters_in_the_void[e][math_random(1, #biters_in_the_void[e])]
	local p = surface.find_non_colliding_position(biter , position, 16, 0.5)
	if not p then return end
	surface.create_entity{name = biter, position = p}
end

local function get_noise(name, pos)
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "water" then
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local value = noise[1] + noise[2] * 0.2
		return value
	end
	seed = seed + noise_seed_add
	if name == "dirt" then
		noise[1] = simplex_noise(pos.x * 0.08, pos.y * 0.08, seed)
		local value = noise[1]
		return value
	end
	seed = seed + noise_seed_add
	if name == "trees" then
		noise[1] = simplex_noise(pos.x * 0.045, pos.y * 0.045, seed)
		local value = noise[1]
		return value
	end
	seed = seed + noise_seed_add
	if name == "spawners" then
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		local value = noise[1]
		return value
	end
end

local function get_entity(position)
	local noise = get_noise("trees", position)
	local entity_name = false
	if noise > 0 then
		if math_random(1, 3) ~= 1 then
			entity_name = "mineable-wreckage"
			if noise > 0.59 then
				entity_name = rock_raffle[math_random(1, #rock_raffle)]
				if math_random(1, 128) == 1 then
					if position.x > 32 or position.x < -32 or position.y > 32 or position.y < -32 then
						local e = math.ceil(game.forces.enemy.evolution_factor*10)
						if e < 1 then e = 1 end
						entity_name = worm_raffle_table[e][math_random(1, #worm_raffle_table[e])]
					end
				end
			end
			if noise > 0.61 then
				entity_name = tree_raffle[math_random(1, #tree_raffle)]

				if math_random(1, 128) == 1 then
					if position.x > 32 or position.x < -32 or position.y > 32 or position.y < -32 then
						local e = math.ceil(game.forces.enemy.evolution_factor*10)
						if e < 1 then e = 1 end
						entity_name = worm_raffle_table[e][math_random(1, #worm_raffle_table[e])]
					end
				end
			end
		end
	else
		if math_random(1, 2048) == 1 then
			entity_name = "market"
		end

		if math_random(1, 64) == 1 then
			local noise_spawners = get_noise("spawners", position)
			if noise_spawners > 0.25 and position.x^2 + position.y^2 > 3000 then
				entity_name = "biter-spawner"
				if math_random(1,5) == 1 then
					entity_name = "spitter-spawner"
				end
			end
		end
	end
	return entity_name
end

local function get_noise_tile(position)
	local noise = get_noise("dirt", position)
	local tile_name

	if noise > 0 then
		tile_name = "grass-1"
		if noise > 0.5 then
			tile_name = "dirt-5"
		end
	else
		tile_name = "dirt-7"
	end

	local noise_2 = get_noise("water", position)
	if noise_2 > 0.71 then
		tile_name = "water"	
		if noise_2 > 0.78 then
			tile_name = "deepwater"
		end
	end

	if noise < -0.76 then
		tile_name = "water"
	end

	return tile_name
end

local function uncover_map(surface, position, radius_min, radius_max)
	local circles = shapes.circles
	local tiles = {}
	local fishes = {}
	for r = radius_min, radius_max, 1 do
		for _, position_modifier in pairs(circles[r]) do
			local pos = {x = position.x + position_modifier.x, y = position.y + position_modifier.y} 
			if surface.get_tile(pos).name == "out-of-map" then
				local tile_name = get_noise_tile(pos)
				insert(tiles, {name = tile_name, position = pos})
				if tile_name == "water" or tile_name == "deepwater" then
					if math_random(1, 24) == 1 then insert(fishes, pos) end
				else
					local entity = get_entity(pos)
					if entity then
						if entity == "market" then
							local area = {{pos.x - 64, pos.y - 64}, {pos.x + 64, pos.y + 64}}
							if surface.count_entities_filtered({name = "market", area = area}) == 0 then
								secret_shop(pos, surface)
							end
						else
							if entity == "biter-spawner" or entity == "spitter-spawner" then
								local area = {{pos.x - 4, pos.y - 4}, {pos.x + 4, pos.y + 4}}
								if surface.count_entities_filtered({name = "biter-spawner", area = area}) == 0 then
									surface.create_entity({name = entity, position = pos})
								end
							else
								surface.create_entity({name = entity, position = pos})
							end
						end
					end
				end
			end
		end
	end
	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish}) 
	end
end

local function uncover_map_for_player(player)
	local position = player.position
	local surface = player.surface
	local circles = shapes.circles
	local tiles = {}
	local fishes = {}
	local uncover_map_schedule = {}
	for r = uncover_radius - 1, uncover_radius, 1 do
		for _, position_modifier in pairs(circles[r]) do
			local pos = {x = position.x + position_modifier.x, y = position.y + position_modifier.y}
			if surface.get_tile(pos).name == "out-of-map" then
				local tile_name = get_noise_tile(pos)
				insert(tiles, {name = tile_name, position = pos})
				if tile_name == "water" or tile_name == "deepwater" then
					if math_random(1, 24) == 1 then insert(fishes, pos) end
				else
					local entity = get_entity(pos)
					if entity then
						if entity == "market" then
							local area = {{pos.x - 64, pos.y - 64}, {pos.x + 64, pos.y + 64}}
							if surface.count_entities_filtered({name = "market", area = area}) == 0 then
								secret_shop(pos, surface)
							end
						else
							if entity == "biter-spawner" or entity == "spitter-spawner" then
								local area = {{pos.x - 4, pos.y - 4}, {pos.x + 4, pos.y + 4}}
								if surface.count_entities_filtered({name = "biter-spawner", area = area}) == 0 then
									surface.create_entity({name = entity, position = pos})
								end
							else
								surface.create_entity({name = entity, position = pos})
							end
						end
						if entity == "biter-spawner" or entity == "spitter-spawner" then
							insert(uncover_map_schedule, {x = pos.x, y = pos.y})
						end
					end
				end
			end
		end
	end

	if #tiles > 0 then
		surface.set_tiles(tiles, true)
	end

	for _, pos in pairs(uncover_map_schedule) do
		uncover_map(surface, pos, 1, 16)
	end
	for _, fish in pairs(fishes) do
		surface.create_entity({name = "fish", position = fish}) 
	end

end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.territorial_control_init_done then
		local map_gen_settings = {}
		map_gen_settings.water = "small"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 22, cliff_elevation_0 = 22}
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "none", size = "none", richness = "none"},
			["stone"] = {frequency = "none", size = "none", richness = "none"},
			["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
			["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
			["crude-oil"] = {frequency = "none", size = "none", richness = "none"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.create_surface("territorial_control", map_gen_settings)
		local surface = game.surfaces["territorial_control"]
		--surface.daytime = 0.5
		--surface.freeze_daytime = 1
		surface.ticks_per_day = surface.ticks_per_day * 2
		surface.min_brightness = 0.08
		game.forces["player"].set_spawn_position({0, 0}, surface)

		game.map_settings.enemy_expansion.enabled = true
		game.map_settings.enemy_evolution.destroy_factor = 0.0016
		game.map_settings.enemy_evolution.time_factor = 0
		game.map_settings.enemy_evolution.pollution_factor = 0

		local turret_positions = {{6, 6}, {-5, -5}, {-5, 6}, {6, -5}}
		for _, pos in pairs(turret_positions) do
			local turret = surface.create_entity({name = "gun-turret", position = pos, force = "player"})
			turret.insert({name = "firearm-magazine", count = 32})
		end

		local radius = 320
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})

		global.territorial_control_init_done = true
	end

	if player.online_time < 1 then
		player.insert({name = "submachine-gun", count = 1})
		player.insert({name = "iron-plate", count = 64})
		player.insert({name = "grenade", count = 3})
		player.insert({name = "raw-fish", count = 5})
		player.insert({name = "coin", count = 5})
		player.insert({name = "land-mine", count = 5})
		player.insert({name = "light-armor", count = 1})
		player.insert({name = "firearm-magazine", count = 128})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end

	local surface = game.surfaces["territorial_control"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 1), "territorial_control")
	else
		if player.online_time < 2 then
			player.teleport({0, 0}, "territorial_control")
		end
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if player.surface.name == "territorial_control" then
		uncover_map_for_player(player)
	end
end

local function generate_spawn_area(position_left_top)
	if position_left_top.x > 32 then return end
	if position_left_top.y > 32 then return end
	if position_left_top.x < -32 then return end
	if position_left_top.y < -32 then return end

	local surface = game.surfaces["territorial_control"]
	local entities = {}
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = false
			local pos = {x = position_left_top.x + x, y = position_left_top.y + y}
			if pos.x > -9 and pos.x < 9 and pos.y > -9 and pos.y < 9 then
				tile_to_insert = get_noise_tile(pos)
				tile_to_insert = "stone-path"
				if pos.x <= -7 or pos.x >= 7 or pos.y <= -7 or pos.y >= 7 then
					if math_random(1, 3) ~= 1 then
						table.insert(entities, {name = "stone-wall", position = {x = pos.x, y = pos.y}, force = "player"})
					end
				end
			end
			if tile_to_insert == "water" or tile_to_insert == "deepwater" then
				tile_to_insert = "grass-2"
			end
			if tile_to_insert then
				insert(tiles, {name = tile_to_insert, position = pos})
			end
		end
	end
	surface.set_tiles(tiles, true)

	for _, entity in pairs(entities) do
		surface.create_entity(entity)
	end
end

local function on_chunk_generated(event)
	if not game.surfaces["territorial_control"] then return end
	local surface = game.surfaces["territorial_control"]
	if surface.name ~= event.surface.name then return end

	local position_left_top = event.area.left_top
	generate_spawn_area(position_left_top)

	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local tile_to_insert = "out-of-map"
			local pos = {x = position_left_top.x + x, y = position_left_top.y + y}
			local tile_name = surface.get_tile(pos).name
			if tile_name ~= "stone-path" then
				insert(tiles, {name = tile_to_insert, position = pos})
			end
		end
	end
	surface.set_tiles(tiles, true)
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end

	if entity.name == "mineable-wreckage" then
		if math_random(1,40) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,12)) end
		if math_random(1,80) == 1 then unearthing_worm(entity.surface, entity.position) end
		if math_random(1,160) == 1 then tick_tack_trap(entity.surface, entity.position) end
	end

	if entity.force.name ~= "scrap" then return end
	local positions = {}
	local r = math.ceil(entity.prototype.max_health / 32)
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			positions[#positions + 1] = {x = entity.position.x + x, y = entity.position.y + y}
		end
	end
	positions = shuffle(positions)
	for i = 1, math.ceil(entity.prototype.max_health / 32), 1 do
		if not positions[i] then return end
		if math_random(1,3) ~= 1 then
			unearthing_biters(entity.surface, positions[i], math_random(5,10))
		else
			unearthing_worm(entity.surface, positions[i])
		end
	end
end

local function on_entity_died(event)
	local surface = event.entity.surface

	if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
		if math_random(1, 2) ~= 1 then
			local name = ore_spawn_raffle[math.random(1,#ore_spawn_raffle)]
			local pos = {x = event.entity.position.x, y = event.entity.position.y}
			local amount_modifier = math.ceil(1 + game.forces.enemy.evolution_factor * 10)
			local size_modifier = math.floor(game.forces.enemy.evolution_factor * 4)
			if name == "crude-oil" then
				map_functions.draw_oil_circle(pos, name, surface, 4, math.ceil(100000 * amount_modifier))
			else
				map_functions.draw_smoothed_out_ore_circle(pos, name, surface, 6 + size_modifier, math.ceil(500 * amount_modifier))
			end
		end
	end

	if event.entity.type == "tree" or event.entity.name == "mineable-wreckage" or event.entity.type == "rock" then
		if math_random(1, 32) == 1 then
			spawn_biter(event.entity.surface, event.entity.position)
		end
	end
	on_player_mined_entity(event)
end

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["tree-02"] = true,
		["tree-04"] = true,
		["dead-tree-desert"] = true,
		["mineable-wreckage"] = true,
		["tree-02-red"] = true,
		["tree-09-red"] = true
	}

local function on_marked_for_deconstruction(event)
	event.research.force.character_inventory_slots_bonus = game.forces.player.mining_drill_productivity_bonus * 300
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_research_finished()
	game.forces.player.recipes["flamethrower-turret"].enabled = false
end

local function on_tick()
	if game.tick % 4500 ~= 0 then return end
	if math_random(1, 4) ~= 1 then return end

	local surface = game.surfaces["territorial_control"]

	local biters = surface.find_entities_filtered({type = "unit", force = "enemy", limit = 32})
	if biters[1] then
		biters = shuffle(biters)
		for _, biter in pairs(biters) do
			biter.set_command({type = defines.command.attack_area, destination = {x = 0, y = 0}, radius = 64, distraction = defines.distraction.by_anything})
		end
	end
end

local function on_init()
	local T = Map.Pop_info()
	T.localised_category = "territorial_control"
	T.main_caption_color = {r = 150, g = 150, b = 0}
	T.sub_caption_color = {r = 0, g = 150, b = 0}
	global.rocks_yield_ore_maximum_amount = 999
	global.rocks_yield_ore_base_amount = 50
	global.rocks_yield_ore_distance_modifier = 0.025
end

Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)