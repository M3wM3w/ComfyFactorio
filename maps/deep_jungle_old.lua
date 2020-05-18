--deep jungle-- mewmew made this --
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local event = require 'utils.event' 
local math_random = math.random

local function treasure_chest(position)
	local p = game.surfaces["deep_jungle"].find_non_colliding_position("wooden-chest",position, 2,0.5)
	if not p then return end
	
	treasure_chest_raffle_table = {}
	treasure_chest_loot_weights = {}
	table.insert(treasure_chest_loot_weights, {{name = 'iron-gear-wheel', count = math_random(16,48)},10})	
	table.insert(treasure_chest_loot_weights, {{name = 'coal', count = math_random(16,48)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'copper-cable', count = math_random(64,128)},10})
	table.insert(treasure_chest_loot_weights, {{name = 'inserter', count = math_random(8,16)},4})		
	table.insert(treasure_chest_loot_weights, {{name = 'fast-inserter', count = math_random(4,8)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'stack-filter-inserter', count = math_random(2,4)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'stack-inserter', count = math_random(2,4)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'burner-inserter', count = math_random(16,32)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'electric-engine-unit', count = math_random(1,16)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'engine-unit', count = math_random(1,16)},3})	
	table.insert(treasure_chest_loot_weights, {{name = 'rocket-fuel', count = math_random(1,5)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'empty-barrel', count = math_random(1,10)},7})
	table.insert(treasure_chest_loot_weights, {{name = 'lubricant-barrel', count = math_random(1,10)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'crude-oil-barrel', count = math_random(1,10)},3})
	table.insert(treasure_chest_loot_weights, {{name = 'iron-stick', count = math_random(1,100)},8})
	table.insert(treasure_chest_loot_weights, {{name = "small-electric-pole", count = math_random(8,32)},9})
	table.insert(treasure_chest_loot_weights, {{name = "firearm-magazine", count = math_random(16,48)},8})
	table.insert(treasure_chest_loot_weights, {{name = 'grenade', count = math_random(16,32)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'land-mine', count = math_random(24,48)},5})
	table.insert(treasure_chest_loot_weights, {{name = 'light-armor', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'heavy-armor', count = 1},2})		
	table.insert(treasure_chest_loot_weights, {{name = 'pipe', count = math_random(10,100)},6})		
	table.insert(treasure_chest_loot_weights, {{name = 'wooden-chest', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'burner-mining-drill', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'iron-axe', count = 1},1})
	table.insert(treasure_chest_loot_weights, {{name = 'steel-axe', count = 1},3})
	table.insert(treasure_chest_loot_weights, {{name = 'raw-wood', count = math_random(5,50)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'sulfur', count = math_random(20,50)},7})
	table.insert(treasure_chest_loot_weights, {{name = 'explosives', count = math_random(20,50)},6})
	table.insert(treasure_chest_loot_weights, {{name = 'shotgun', count = 1},2})
	table.insert(treasure_chest_loot_weights, {{name = 'stone-brick', count = math_random(80,100)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'small-lamp', count = math_random(3,10)},4})
	table.insert(treasure_chest_loot_weights, {{name = 'rail', count = math_random(32,100)},4})	
	table.insert(treasure_chest_loot_weights, {{name = 'coin', count = math_random(32,100)},1})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-1', count = math_random(1,4)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-2', count = math_random(1,3)},2})
	table.insert(treasure_chest_loot_weights, {{name = 'assembling-machine-3', count = math_random(1,2)},1})		
	for _, t in pairs (treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(treasure_chest_raffle_table, t[1])
		end			
	end
	
	
	local e = game.surfaces["deep_jungle"].create_entity {name="wooden-chest",position=p, force="player"}
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math_random(3,7), 1 do
		local loot = treasure_chest_raffle_table[math_random(1,#treasure_chest_raffle_table)]
		i.insert(loot)
	end		
end

local function rare_treasure_chest(position)
	local p = game.surfaces["deep_jungle"].find_non_colliding_position("steel-chest",position, 2,0.5)
	if not p then return end
	
	local rare_treasure_chest_raffle_table = {}
	local rare_treasure_chest_loot_weights = {}
	table.insert(rare_treasure_chest_loot_weights, {{name = 'combat-shotgun', count = 1},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'piercing-shotgun-shell', count = math_random(16,48)},5})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'rocket-launcher', count = 1},5})		
	table.insert(rare_treasure_chest_loot_weights, {{name = 'rocket', count = math_random(16,48)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'explosive-rocket', count = math_random(16,48)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'modular-armor', count = 1},3})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'power-armor', count = 1},1})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'uranium-rounds-magazine', count = math_random(16,48)},3})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'piercing-rounds-magazine', count = math_random(64,128)},3})	
	table.insert(rare_treasure_chest_loot_weights, {{name = 'railgun', count = 1},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'railgun-dart', count = math_random(16,48)},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'exoskeleton-equipment', count = 1},2})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'defender-capsule', count = math_random(8,16)},5})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'distractor-capsule', count = math_random(4,8)},4})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'destroyer-capsule', count = math_random(4,8)},3})
	table.insert(rare_treasure_chest_loot_weights, {{name = 'atomic-bomb', count = 1},1})		
	for _, t in pairs (rare_treasure_chest_loot_weights) do
		for x = 1, t[2], 1 do
			table.insert(rare_treasure_chest_raffle_table, t[1])
		end			
	end
	
	local e = game.surfaces["deep_jungle"].create_entity {name="steel-chest",position=p, force="player"}
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
	seed = seed + noise_seed_add
	if name == 1 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 2 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 3 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.001, pos.y * 0.001, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		local noise = noise[1] + noise[2] * 0.1
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 4 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.01, pos.y * 0.01, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 5 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)
		local noise = noise[1]
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == 6 then
		local noise = {}
		noise[1] = simplex_noise(pos.x * 0.05, pos.y * 0.05, seed)		
		local noise = noise[1]
		return noise
	end
end

local worm_raffle = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"}
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}

local function on_chunk_generated(event)
	local surface = game.surfaces["deep_jungle"] 
	if event.surface.name ~= surface.name then return end
	
	local chunk_pos_x = event.area.left_top.x
	local chunk_pos_y = event.area.left_top.y
								
	local tiles = {}
	local entities_to_place = {
		rocks = {},
		worms = {},
		enemy_buildings = {},
		trees = {},
		fish = {},		
		treasure_chests = {},
		rare_treasure_chests = {}
	}	
	local decoratives = {}
	
	local entities = surface.find_entities(event.area)
	for _, e in pairs(entities) do
		if e.type == "tree" or e.force.name == "enemy" then
			e.destroy()				
		end
	end	
	
	local tile_to_insert = false	
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do			
			local pos_x = chunk_pos_x + x
			local pos_y = chunk_pos_y + y
			local pos = {x = pos_x, y = pos_y}			
			tile_to_insert = false								
			
			local noise_3 = get_noise(3, pos)
			if noise_3 > -0.1 and noise_3 < 0.1 then
				if noise_3 > -0.05 and noise_3 < 0.05 then
					tile_to_insert = "water"
					if math_random(1,40) == 1 then table.insert(entities_to_place.fish, pos) end
				end
				if noise_3 > -0.03 and noise_3 < 0.03 then
					tile_to_insert = "deepwater"
					if math_random(1,40) == 1 then table.insert(entities_to_place.fish, pos) end
				end
			else
				local tile_distance_to_center = pos_x^2 + pos_y^2
				local noise_1 = get_noise(1, pos)
				local noise_2 = get_noise(2, pos)
				local noise_4 = get_noise(4, pos)				
				if tile_distance_to_center > 10000 then
					if math_random(1,500) == 1 then table.insert(entities_to_place.worms, pos) end					
					if noise_4 > -0.1 and noise_4 < 0.1 and noise_1 > 0.3 and noise_2 > 0.3 then
						if math_random(1,8) == 1 then table.insert(entities_to_place.rocks, pos) end
					end					
				end
				
				if noise_4 < -0.8 or noise_4 > 0.8 then tile_to_insert = "dirt-6" end
				if noise_3 < -0.1 then												
					if noise_1 > 0.2 then
						if math_random(1,4) == 1 then table.insert(entities_to_place.trees, {"tree-02", pos}) end
						if math_random(1,7500) == 1 then table.insert(entities_to_place.rare_treasure_chests, pos) end
						if math_random(1,1250) == 1 then table.insert(entities_to_place.treasure_chests, pos) end
						if noise_1 > 0.8 and tile_distance_to_center > 8000 then
							 tile_to_insert = "water-green"
							 if math_random(1,24) == 1 then table.insert(entities_to_place.fish, pos) end
						end
					end
					if noise_1 < -0.2 then
						if math_random(1,4) == 1 then table.insert(entities_to_place.trees, {"tree-04", pos}) end
						if math_random(1,7500) == 1 then table.insert(entities_to_place.rare_treasure_chests, pos) end
						if math_random(1,1250) == 1 then table.insert(entities_to_place.treasure_chests, pos) end
						if noise_1 < -0.75 and tile_distance_to_center > 8000 then
							if math_random(1,36) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end
						end
					end					
				else																													
					if noise_2 > 0.2 then
						if math_random(1,4) == 1 then table.insert(entities_to_place.trees, {"tree-07", pos}) end
						if math_random(1,7500) == 1 then table.insert(entities_to_place.rare_treasure_chests, pos) end
						if math_random(1,1250) == 1 then table.insert(entities_to_place.treasure_chests, pos) end
						if noise_2 > 0.75 and tile_distance_to_center > 8000 then
							if math_random(1,36) == 1 then table.insert(entities_to_place.enemy_buildings, pos) end
						end
					end						
					if noise_2 < -0.2 then
						if math_random(1,4) == 1 then table.insert(entities_to_place.trees, {"tree-09", pos}) end
						if math_random(1,7500) == 1 then table.insert(entities_to_place.rare_treasure_chests, pos) end
						if math_random(1,1250) == 1 then table.insert(entities_to_place.treasure_chests, pos) end
						if noise_2 < -0.8 and tile_distance_to_center > 8000 then
							 tile_to_insert = "water-green"
							 if math_random(1,24) == 1 then table.insert(entities_to_place.fish, pos) end
						end
					end
				end
			end			
			
			if tile_to_insert ~= "deepwater" and tile_to_insert ~= "water" and tile_to_insert ~= "water-green" then								
				if math_random(1,3) == 1 then
					local noise = get_noise(5, pos)
					if noise > 0.2 then
						table.insert(decoratives, {name = "green-hairy-grass", position = pos, amount = 2})
					end
					if noise < -0.7 then
						table.insert(decoratives, {name = "green-pita", position = pos, amount = 2})
					end				
					local noise = get_noise(6, pos)
					if noise > 0.7 then
						table.insert(decoratives, {name = "green-croton", position = pos, amount = 3})
					end
					if noise < -0.2 then
						table.insert(decoratives, {name = "green-asterisk", position = pos, amount = 2})
					end
				end				
			end
			
			if tile_to_insert == false then
				table.insert(tiles, {name = "grass-1", position = {pos_x,pos_y}}) 
			else
				table.insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}}) 
			end					
		end							
	end		
	surface.set_tiles(tiles,true)
	surface.create_decoratives{check_collision=false, decoratives=decoratives}	
		
	for _, p in pairs(entities_to_place.enemy_buildings) do						
		if math_random(1,3) == 1 then
			if surface.can_place_entity({name="spitter-spawner", position=p}) then surface.create_entity {name="spitter-spawner", position=p} end	
		else
			if surface.can_place_entity({name="biter-spawner", position=p}) then surface.create_entity {name="biter-spawner", position=p} end	
		end							
	end
	for _, p in pairs(entities_to_place.worms) do				
		local e = worm_raffle[math_random(1,#worm_raffle)]
		if surface.can_place_entity({name=e, position=p}) then surface.create_entity {name=e, position=p} end					
	end	
	for _, p in pairs(entities_to_place.rocks) do			
		local e = rock_raffle[math_random(1,#rock_raffle)]
		surface.create_entity {name=e, position=p} 				
	end
	for _, p in pairs(entities_to_place.trees) do			 
		if surface.can_place_entity({name=p[1], position=p[2]}) then surface.create_entity {name=p[1], position=p[2]} end				
	end			
	for _, p in pairs(entities_to_place.treasure_chests) do			 
		treasure_chest(p)		
	end
	for _, p in pairs(entities_to_place.rare_treasure_chests) do			
		rare_treasure_chest(p)		
	end				
	for _, p in pairs(entities_to_place.fish) do					
		surface.create_entity {name="fish",position=p}				
	end	
end

local function on_chunk_charted(event)
	if not global.chunks_charted then global.chunks_charted = {} end
	local surface = game.surfaces[event.surface_index]
	local position = event.position
	if global.chunks_charted[tostring(position.x) .. tostring(position.y)] then return end
	global.chunks_charted[tostring(position.x) .. tostring(position.y)] = true
	local force = event.force
	
	if math_random(1,12) ~= 1 then return end	
	map_functions.draw_rainbow_patch({x = position.x * 32 + math_random(1,32), y = position.y * 32 + math_random(1,32)}, surface, math_random(14,26), 2000)
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	if not global.map_init_done then	
		game.forces["player"].technologies["flamethrower"].enabled = false	
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 4, cliff_elevation_0 = 0.1}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "high", size = "big", richness = "normal"},
			["stone"] = {frequency = "high", size = "big", richness = "normal"},
			["copper-ore"] = {frequency = "high", size = "big", richness = "normal"},
			["iron-ore"] = {frequency = "high", size = "big", richness = "normal"},
			["crude-oil"] = {frequency = "high", size = "big", richness = "normal"},
			["trees"] = {frequency = "none", size = "none", richness = "none"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"},
			--["grass"] = {frequency = "none", size = "none", richness = "none"},
			["sand"] = {frequency = "none", size = "none", richness = "none"},
			["desert"] = {frequency = "none", size = "none", richness = "none"},
			["dirt"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.map_settings.pollution.pollution_restored_per_tree_damage = 0
		game.create_surface("deep_jungle", map_gen_settings)		
		game.forces["player"].set_spawn_position({0,0},game.surfaces["deep_jungle"])								
		global.map_init_done = true									
	end	
	local surface = game.surfaces["deep_jungle"]
	if player.online_time < 5 and surface.is_chunk_generated({0,0}) then 
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1), "deep_jungle")
	else
		if player.online_time < 5 then
			player.teleport({0,0}, "deep_jungle")
		end
	end
	if player.online_time < 10 then		
		player.insert {name = 'submachine-gun', count = 1}
		player.insert {name = 'raw-fish', count = 12}		
		player.insert {name = 'firearm-magazine', count = 32}			
		player.insert {name = 'steel-axe', count = 1}	
		player.insert {name = 'light-armor', count = 1}
	end			
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" or event.entity.name == "fish" or event.entity.type == "tree" then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_entity_died(event)
	if event.entity.type == "tree" then
		if math_random(1,6) == 1 then
			local surface = game.surfaces["deep_jungle"]
			local p = surface.find_non_colliding_position("small-biter" , event.entity.position, 2, 0.5)			
			if p then surface.create_entity {name="small-biter", position=event.entity.position} end
		end
	end
end
	
function cheat_mode()
	local cheat_mode_enabed = true
	if cheat_mode_enabed == true then
		local surface = game.surfaces["deep_jungle"]
		game.player.cheat_mode=true
		game.players[1].insert({name="power-armor-mk2"})
		game.players[1].insert({name="fusion-reactor-equipment", count=4})
		game.players[1].insert({name="personal-laser-defense-equipment", count=8})
		game.players[1].insert({name="rocket-launcher"})		
		game.players[1].insert({name="explosive-rocket", count=200})		
		game.speed = 2
		surface.daytime = 1
		game.player.force.research_all_technologies()
		game.forces["enemy"].evolution_factor = 0.2
		local chart = 300
		local surface = game.surfaces["deep_jungle"]	
		game.forces["player"].chart(surface, {lefttop = {x = chart*-1, y = chart*-1}, rightbottom = {x = chart, y = chart}})		
	end
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
