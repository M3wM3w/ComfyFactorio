--deep jungle-- mewmew made this --
require "modules.no_deconstruction_of_neutral_entities"
require "modules.spawners_contain_biters"
require "modules.biters_yield_coins"
require "modules.rocks_yield_coins"
require "modules.flashlight_toggle_button"

local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local math_random = math.random

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
    {price = {{"coin", math_random(300,600)}}, offer = {type = 'give-item', item = 'combat-shotgun'}},
    {price = {{"coin", math_random(200,400)}}, offer = {type = 'give-item', item = 'rocket-launcher'}},	 
    {price = {{"coin", math_random(5,10)}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine'}},
    --{price = {{"coin", math_random(150,250)}}, offer = {type = 'give-item', item = 'uranium-rounds-magazine'}},  
    {price = {{"coin", math_random(15,30)}}, offer = {type = 'give-item', item = 'piercing-shotgun-shell'}},
    {price = {{"coin", math_random(10,20)}}, offer = {type = 'give-item', item = 'rocket'}},
    {price = {{"coin", math_random(20,30)}}, offer = {type = 'give-item', item = 'explosive-rocket'}},        
    {price = {{"coin", math_random(30,60)}}, offer = {type = 'give-item', item = 'cluster-grenade'}}, 
	{price = {{"coin", math_random(8,16)}}, offer = {type = 'give-item', item = 'land-mine'}},	
	{price = {{"coin", math_random(200,300)}}, offer = {type = 'give-item', item = 'heavy-armor'}},
    {price = {{"coin", math_random(400,800)}}, offer = {type = 'give-item', item = 'modular-armor'}},
    {price = {{"coin", math_random(1000,2000)}}, offer = {type = 'give-item', item = 'power-armor'}},
    {price = {{"coin", math_random(2500,5000)}}, offer = {type = 'give-item', item = 'fusion-reactor-equipment'}},
    {price = {{"coin", math_random(200,400)}}, offer = {type = 'give-item', item = 'battery-equipment'}},
    {price = {{"coin", math_random(150,250)}}, offer = {type = 'give-item', item = 'belt-immunity-equipment'}},
    {price = {{"coin", math_random(100,200)}}, offer = {type = 'give-item', item = 'night-vision-equipment'}},
    {price = {{"coin", math_random(400,800)}}, offer = {type = 'give-item', item = 'exoskeleton-equipment'}},
    {price = {{"coin", math_random(200,300)}}, offer = {type = 'give-item', item = 'personal-roboport-equipment'}},
    {price = {{"coin", math_random(25,50)}}, offer = {type = 'give-item', item = 'construction-robot'}},
   -- {price = {{"coin", math_random(10000,20000)}}, offer = {type = 'give-item', item = 'energy-shield-equipment'}},
   -- {price = {{"coin", math_random(5000,15000)}}, offer = {type = 'give-item', item = 'personal-laser-defense-equipment'}},    
    {price = {{"coin", math_random(800,1600)}}, offer = {type = 'give-item', item = 'railgun'}},
    {price = {{"coin", math_random(60,120)}}, offer = {type = 'give-item', item = 'railgun-dart', count = 1}},
	{price = {{"coin", math_random(100,300)}}, offer = {type = 'give-item', item = 'loader'}},
	{price = {{"coin", math_random(200,400)}}, offer = {type = 'give-item', item = 'fast-loader'}},
	{price = {{"coin", math_random(300,500)}}, offer = {type = 'give-item', item = 'express-loader'}},
	{price = {{"coin", math_random(150,300)}}, offer = {type = 'give-item', item = 'locomotive'}},
	{price = {{"coin", math_random(100,200)}}, offer = {type = 'give-item', item = 'cargo-wagon'}},
	{price = {{"coin", math_random(5,15)}}, offer = {type = 'give-item', item = 'grenade'}},
	{price = {{"coin", math_random(80,160)}}, offer = {type = 'give-item', item = 'cliff-explosives'}},
	 {price = {{"coin", math_random(10,20)}}, offer = {type = 'give-item', item = 'explosives', count = 50}},
	{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'rail', count = 4}},
	{price = {{"coin", math_random(20,30)}}, offer = {type = 'give-item', item = 'train-stop'}},	
	{price = {{"coin", math_random(4,12)}}, offer = {type = 'give-item', item = 'small-lamp'}},
	{price = {{"coin", math_random(1,4)}}, offer = {type = 'give-item', item = 'firearm-magazine'}},			
	{price = {{"coin", math_random(60,150)}}, offer = {type = 'give-item', item = 'car', count = 1}},	
	{price = {{"coin", math_random(75,150)}}, offer = {type = 'give-item', item = 'gun-turret', count = 1}},
	{price = {{"coin", math_random(500,750)}}, offer = {type = 'give-item', item = 'laser-turret', count = 1}},
	{price = {{"coin", math_random(1000,2000)}}, offer = {type = 'give-item', item = 'artillery-turret', count = 1}},
	{price = {{"coin", math_random(100,200)}}, offer = {type = 'give-item', item = 'artillery-shell', count = 1}},
	{price = {{"coin", math_random(50,150)}}, offer = {type = 'give-item', item = 'artillery-targeting-remote', count = 1}},			
	{price = {{"coin", math_random(5,15)}}, offer = {type = 'give-item', item = 'shotgun-shell', count = 1}},	
	{price = {{"coin", math_random(8000,16000)}}, offer = {type = 'give-item', item = 'power-armor-mk2', count = 1}},
	{price = {{"coin", math_random(80,160)}}, offer = {type = 'give-item', item = 'solar-panel-equipment', count = 1}},	
	{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'wood', count = 50}},
	{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
	{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
	{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'stone', count = 50}},
	{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'coal', count = 50}}
	--{price = {{"coin", math_random(4,8)}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}}
	}
	secret_market_items = shuffle(secret_market_items)
										
	local market = surface.create_entity {name = "market", position = pos}
	market.destructible = false			
	
	for i = 1, math.random(6, 10), 1 do
		market.add_market_item(secret_market_items[i])
	end
end

local function treasure_chest(position)	
	if not game.surfaces["deep_jungle"].can_place_entity({name="steel-chest",position=position, force="player"}) then return end
	treasure_chest_raffle_table = {}
	treasure_chest_loot_weights = {}
	table.insert(treasure_chest_loot_weights, {{name = 'landfill', count = math_random(8,16)},16})
	table.insert(treasure_chest_loot_weights, {{name = 'iron-gear-wheel', count = math_random(16,48)},8})	
	table.insert(treasure_chest_loot_weights, {{name = 'coal', count = math_random(16,48)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'copper-cable', count = math_random(64,128)},8})
	table.insert(treasure_chest_loot_weights, {{name = 'inserter', count = math_random(4,8)},4})		
	table.insert(treasure_chest_loot_weights, {{name = 'fast-inserter', count = math_random(4,8)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'burner-inserter', count = math_random(4,8)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'rocket-fuel', count = math_random(1,5)},3})
	table.insert(treasure_chest_loot_weights, {{name = "small-electric-pole", count = math_random(4,8)},7})
	table.insert(treasure_chest_loot_weights, {{name = "firearm-magazine", count = math_random(16,48)},8})
	table.insert(treasure_chest_loot_weights, {{name = "submachine-gun", count = 1},4})
	table.insert(treasure_chest_loot_weights, {{name = 'grenade', count = math_random(6,12)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'land-mine', count = math_random(8,16)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'light-armor', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'heavy-armor', count = 1},2})		
	table.insert(treasure_chest_loot_weights, {{name = 'pipe', count = math_random(10,100)},6})		
	table.insert(treasure_chest_loot_weights, {{name = 'explosives', count = math_random(40,50)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'shotgun', count = 1},3})
	table.insert(treasure_chest_loot_weights, {{name = 'shotgun-shell', count = math_random(8,16)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'stone-brick', count = math_random(80,100)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'small-lamp', count = math_random(2,4)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'rail', count = math_random(16,48)},3})	
	table.insert(treasure_chest_loot_weights, {{name = 'coin', count = math_random(32,320)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-1', count = math_random(1,3)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-2', count = math_random(1,3)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-3', count = math_random(1,2)},1})		
	for _, t in pairs (treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(treasure_chest_raffle_table, t[1])
		end			
	end
	
	local e = game.surfaces["deep_jungle"].create_entity {name="wooden-chest",position=position, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math_random(3,7), 1 do
		local loot = treasure_chest_raffle_table[math_random(1,#treasure_chest_raffle_table)]
		i.insert(loot)
	end		
end

local function rare_treasure_chest(position)
	if not game.surfaces["deep_jungle"].can_place_entity({name="steel-chest",position=position, force="player"}) then return end
	local rare_treasure_chest_raffle_table = {}
	local rare_treasure_chest_loot_weights = {}
	table.insert(rare_treasure_chest_loot_weights, {{name = 'combat-shotgun', count = 1},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'piercing-shotgun-shell', count = math_random(8,16)},5})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'rocket-launcher', count = 1},5})		
	table.insert(rare_treasure_chest_loot_weights, {{name = 'rocket', count = math_random(4,8)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'explosive-rocket', count = math_random(4,8)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'modular-armor', count = 1},3})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'piercing-rounds-magazine', count = math_random(32,64)},3})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'railgun', count = 1},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'railgun-dart', count = math_random(4,8)},5})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'defender-capsule', count = math_random(4,8)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'distractor-capsule', count = math_random(3,5)},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'destroyer-capsule', count = math_random(2,3)},3})	
	for _, t in pairs (rare_treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(rare_treasure_chest_raffle_table, t[1])
		end			
	end
	
	local e = game.surfaces["deep_jungle"].create_entity {name="steel-chest",position=position, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math_random(2,3), 1 do
		local loot = rare_treasure_chest_raffle_table[math_random(1,#rare_treasure_chest_raffle_table)]
		i.insert(loot)
	end		
end

local function get_noise(name, pos)	
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.001, pos.y * 0.001, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed + noise_seed_add)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end	
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.015, pos.y * 0.015, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.15, pos.y * 0.15, seed + noise_seed_add)
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	if name == 3 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.025, pos.y * 0.025, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.2, pos.y * 0.2, seed + noise_seed_add)
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	if name == "greenwater" then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.003, pos.y * 0.003, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.03, pos.y * 0.03, seed + noise_seed_add)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
end

local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}
local tree_raffle = {"tree-04", "tree-07", "tree-09", "tree-06", "tree-04", "tree-07", "tree-09", "tree-04"}

local function process_tile(pos)
	local noise_1 = get_noise(1, pos)
	if noise_1 > -0.03 and noise_1 < 0.03 then		
		return "deepwater"
	end
	if noise_1 > -0.05 and noise_1 < 0.05 then
		return "water"								
	end
	local noise_greenwater = get_noise("greenwater", pos)
	if noise_greenwater > -0.035 and noise_greenwater < 0.035 then		
		return "water-green"
	end
	if noise_1 > -0.08 and noise_1 < 0.08 then		
		return false								
	end
	
	local noise_2 = get_noise(2, pos)		
	if noise_2 > 0.37 or noise_2 < -0.37 then		
		if math_random(1, 4) == 1 then return false, tree_raffle[math.ceil(math.abs(noise_1 * 8))] end
	end	
	local noise_3 = get_noise(3, pos)		
	if noise_3 > 0.5 then
		if math_random(1,3) == 1 then return false, rock_raffle[math_random(1,#rock_raffle)] end
	end
	
	return false
end

local function on_chunk_generated(event)
	local surface = game.surfaces["deep_jungle"] 
	if event.surface.name ~= surface.name then return end
	
	local chunk_pos_x = event.area.left_top.x
	local chunk_pos_y = event.area.left_top.y
								
	local tiles = {}
	local entities_to_place = {}
	local treasure_chests = {}
	local rare_treasure_chests = {}	
	local secret_shops = {}
	
	local tile_to_insert = false	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do			
			local pos = {x = chunk_pos_x + x, y = chunk_pos_y + y}		
			
			tile_to_insert, entity_to_place = process_tile(pos)
			if entity_to_place then
				table.insert(entities_to_place, {name = entity_to_place, position = pos, force = "player"})
			end
			
			if tile_to_insert then										
				table.insert(tiles, {name = tile_to_insert, position = pos}) 
				if math_random(1,40) == 1 and tile_to_insert == "deepwater" then surface.create_entity({name = "fish", position = pos}) end
			end
			
			if math_random(1,1500) == 1 then table.insert(treasure_chests, pos) end
			if math_random(1,16000) == 1 then table.insert(rare_treasure_chests, pos) end
			if math_random(1,8000) == 1 then table.insert(secret_shops, pos) end			
		end							
	end
	surface.set_tiles(tiles,true)	

	for _, e in pairs(entities_to_place) do
		if not surface.get_tile(e.position).collides_with("player-layer") then
			surface.create_entity(e)
		end
	end
	for _, p in pairs(treasure_chests) do
		treasure_chest(p)
	end
	for _, p in pairs(rare_treasure_chests) do
		rare_treasure_chest(p)
	end	
	for _, p in pairs(secret_shops) do
		if not surface.get_tile(p).collides_with("player-layer") then
			local area = {{p.x - 128, p.y - 128}, {p.x + 128, p.y + 128}}
			if surface.count_entities_filtered({name = "market", area = area}) == 0 then
				secret_shop(p, surface)
			end
		end
	end
end

local function on_chunk_charted(event)
	if not global.chunks_charted then global.chunks_charted = {} end
	local surface = game.surfaces[event.surface_index]
	local position = event.position
	if global.chunks_charted[tostring(position.x) .. tostring(position.y)] then return end
	global.chunks_charted[tostring(position.x) .. tostring(position.y)] = true
	
	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
			decorative_names[#decorative_names+1] = k
		end
	end
	surface.regenerate_decorative(decorative_names, {position})	
	
	if math_random(1,14) ~= 1 then return end	
	map_functions.draw_rainbow_patch({x = position.x * 32 + math_random(1,32), y = position.y * 32 + math_random(1,32)}, surface, math_random(14,26), 2000)
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	local surface = game.surfaces["deep_jungle"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "deep_jungle")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "deep_jungle")
		end
	end
	if player.online_time < 2 then									
		player.insert {name = 'iron-plate', count = 32}
	end	
end

local function on_entity_died(event)
	local surface = event.entity.surface
	if event.entity.type == "tree" then 	
		if math_random(1,8) == 1 then			
			local p = surface.find_non_colliding_position("small-biter" , event.entity.position, 2, 0.5)			
			if p then surface.create_entity {name="small-biter", position=event.entity.position} end
			return
		end
		if math_random(1,16) == 1 then			
			local p = surface.find_non_colliding_position("medium-biter" , event.entity.position, 2, 0.5)			
			if p then surface.create_entity {name="medium-biter", position=event.entity.position} end
			return
		end
		if math_random(1,32) == 1 then			
			local p = surface.find_non_colliding_position("big-biter" , event.entity.position, 2, 0.5)			
			if p then surface.create_entity {name="big-biter", position=event.entity.position} end
			return
		end
		if math_random(1,512) == 1 then			
			local p = surface.find_non_colliding_position("behemoth-biter" , event.entity.position, 2, 0.5)			
			if p then surface.create_entity {name="behemoth-biter", position=event.entity.position} end
			return
		end
	end
	if event.entity.type == "simple-entity" then 	
		if math_random(1,8) == 1 then								
			surface.create_entity {name="small-worm-turret", position=event.entity.position}
			return
		end
		if math_random(1,16) == 1 then							
			surface.create_entity {name="medium-worm-turret", position=event.entity.position}
			return
		end
		if math_random(1,32) == 1 then							
			surface.create_entity {name="big-worm-turret", position=event.entity.position}
			return
		end
	end
end

local function on_init()
	local map_gen_settings = {}
	map_gen_settings.moisture = 0.99
	map_gen_settings.water = "none"
	map_gen_settings.starting_area = "normal"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 0.1}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "none", size = "none", richness = "none"},
		["stone"] = {frequency = "none", size = "none", richness = "none"},
		["copper-ore"] = {frequency = "none", size = "none", richness = "none"},
		["iron-ore"] = {frequency = "none", size = "none", richness = "none"},
		["crude-oil"] = {frequency = "very-high", size = "big", richness = "normal"},
		["trees"] = {frequency = "none", size = "none", richness = "none"},
		["enemy-base"] = {frequency = "high", size = "big", richness = "good"}			
	}
	game.create_surface("deep_jungle", map_gen_settings)		
	game.forces["player"].set_spawn_position({0,0},game.surfaces["deep_jungle"])
end

event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "modules.rocks_yield_ore"