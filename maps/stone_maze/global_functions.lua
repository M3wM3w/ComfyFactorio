function get_biter()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].biter end
	end
end

function get_spitter()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].spitter end
	end
end

function get_worm()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].worm end
	end
end

function get_ammo()
	local max_chance = 0	
	for i = 1, 4, 1 do
		max_chance = max_chance + global.enemy_appearances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 4, 1 do
		current_chance = current_chance + global.enemy_appearances[i].chance
		if r <= current_chance then return global.enemy_appearances[i].ammo end
	end
end

local special_scraps = {"crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-lab-broken", "medium-ship-wreck"}
function get_scrap()
	if math.random(1, 128) == 1 then return special_scraps[math.random(1, 4)] end
	return "mineable-wreckage"
end

function spawn_enemy_gun_turret(surface, position)
	if not surface.can_place_entity({name = "gun-turret", position = position}) then return end
	local e = surface.create_entity({name = "gun-turret", position = position, force = "enemy"})
	e.insert({name = get_ammo(), count = math.random(16, 64)})
end

function get_biter_amount()
	local average = math.ceil(1 + (global.maze_depth * 0.3))
	return math.random(math.ceil(average * 0.7), math.ceil(average * 1.3))
end

function get_ore_amount()
	return 256 + global.maze_depth * 4
end

function get_loot_item_stack()
	local math_random = math.random
	local chest_raffle = {}
	local chest_loot = {					
		{{name = "submachine-gun", count = math_random(1,3)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "slowdown-capsule", count = math_random(4,8)}, weight = 1, evolution_min = 0.0, evolution_max = 1},
		{{name = "poison-capsule", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "uranium-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 0.7},
		{{name = "explosive-uranium-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.6, evolution_max = 1},
		{{name = "explosive-cannon-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "shotgun", count = 1}, weight = 2, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "shotgun-shell", count = math_random(16,32)}, weight = 5, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "combat-shotgun", count = 1}, weight = 10, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "piercing-shotgun-shell", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "flamethrower", count = 1}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "flamethrower-ammo", count = math_random(16,32)}, weight = 5, evolution_min = 0.3, evolution_max = 1},
		{{name = "rocket-launcher", count = 1}, weight = 5, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "rocket", count = math_random(16,32)}, weight = 10, evolution_min = 0.2, evolution_max = 0.7},		
		{{name = "explosive-rocket", count = math_random(16,32)}, weight = 10, evolution_min = 0.3, evolution_max = 1},
		{{name = "land-mine", count = math_random(8,16)}, weight = 10, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "grenade", count = math_random(8,16)}, weight = 10, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "cluster-grenade", count = math_random(8,16)}, weight = 5, evolution_min = 0.4, evolution_max = 1},
		{{name = "firearm-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0, evolution_max = 0.3},
		{{name = "piercing-rounds-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0.1, evolution_max = 0.8},
		{{name = "uranium-rounds-magazine", count = math_random(32,128)}, weight = 10, evolution_min = 0.5, evolution_max = 1},
		{{name = "railgun", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "railgun-dart", count = math_random(16,32)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "defender-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.0, evolution_max = 0.7},
		{{name = "distractor-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.2, evolution_max = 1},
		{{name = "destroyer-capsule", count = math_random(8,16)}, weight = 10, evolution_min = 0.3, evolution_max = 1},
		{{name = "atomic-bomb", count = math_random(8,16)}, weight = 1, evolution_min = 0.3, evolution_max = 1},		
		{{name = "light-armor", count = 1}, weight = 3, evolution_min = 0, evolution_max = 0.1},		
		{{name = "heavy-armor", count = 1}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "modular-armor", count = 1}, weight = 2, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "power-armor", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		{{name = "power-armor-mk2", count = 1}, weight = 1, evolution_min = 0.8, evolution_max = 1},
		{{name = "battery-equipment", count = 1}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "battery-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		{{name = "belt-immunity-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "solar-panel-equipment", count = math_random(1,4)}, weight = 5, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "discharge-defense-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 0.8},
		{{name = "energy-shield-equipment", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "energy-shield-mk2-equipment", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
		{{name = "fusion-reactor-equipment", count = 1}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "night-vision-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "personal-laser-defense-equipment", count = 1}, weight = 2, evolution_min = 0.4, evolution_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, evolution_min = 0.3, evolution_max = 1},
						
		
		{{name = "iron-gear-wheel", count = math_random(80,100)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "copper-cable", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(16,32)}, weight = 2, evolution_min = 0.4, evolution_max = 0.8},
		{{name = "battery", count = math_random(100,200)}, weight = 2, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "advanced-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "electronic-circuit", count = math_random(100,200)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "processing-unit", count = math_random(100,200)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "explosives", count = math_random(25,50)}, weight = 1, evolution_min = 0.2, evolution_max = 0.6},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, evolution_min = 0.3, evolution_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, evolution_min = 0.3, evolution_max = 0.7},
		{{name = "computer", count = 1}, weight = 1, evolution_min = 0.2, evolution_max = 1},
		{{name = "steel-plate", count = math_random(50,100)}, weight = 2, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, evolution_min = 0.7, evolution_max = 1},
				
		{{name = "burner-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.4},		
		{{name = "fast-inserter", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 1},
		{{name = "filter-inserter", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(4,8)}, weight = 1, evolution_min = 0.4, evolution_max = 1},
		{{name = "stack-inserter", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},				
		{{name = "small-electric-pole", count = math_random(16,32)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.2, evolution_max = 1},
		{{name = "big-electric-pole", count = math_random(8,16)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "substation", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "wooden-chest", count = math_random(25,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "iron-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.1, evolution_max = 0.4},
		{{name = "steel-chest", count = math_random(4,8)}, weight = 3, evolution_min = 0.3, evolution_max = 1},		
		{{name = "small-lamp", count = math_random(8,16)}, weight = 3, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail", count = math_random(50,75)}, weight = 3, evolution_min = 0.1, evolution_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "assembling-machine-3", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "accumulator", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 1},
		{{name = "offshore-pump", count = math_random(1,2)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
		{{name = "beacon", count = math_random(1,2)}, weight = 3, evolution_min = 0.7, evolution_max = 1},
		{{name = "boiler", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "steam-engine", count = math_random(2,4)}, weight = 3, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "steam-turbine", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		--{{name = "nuclear-reactor", count = 1}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "centrifuge", count = math_random(1,2)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-pipe", count = math_random(8,12)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "heat-exchanger", count = math_random(2,4)}, weight = 2, evolution_min = 0.5, evolution_max = 1},
		{{name = "arithmetic-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "constant-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "decider-combinator", count = math_random(8,16)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "power-switch", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},		
		{{name = "programmable-speaker", count = math_random(2,4)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "green-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "red-wire", count = math_random(50,100)}, weight = 1, evolution_min = 0.1, evolution_max = 1},
		{{name = "chemical-plant", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 1},
		{{name = "burner-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.0, evolution_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.6},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		{{name = "express-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "fast-splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, evolution_min = 0, evolution_max = 0.3},
		{{name = "splitter", count = math_random(2,4)}, weight = 3, evolution_min = 0, evolution_max = 0.3},		
		{{name = "oil-refinery", count = math_random(1,2)}, weight = 2, evolution_min = 0.3, evolution_max = 1},
		{{name = "pipe", count = math_random(40,50)}, weight = 3, evolution_min = 0.0, evolution_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(8,16)}, weight = 1, evolution_min = 0.2, evolution_max = 0.5},
		{{name = "pumpjack", count = math_random(1,2)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "pump", count = math_random(1,4)}, weight = 1, evolution_min = 0.3, evolution_max = 0.8},
		{{name = "solar-panel", count = math_random(4,8)}, weight = 3, evolution_min = 0.4, evolution_max = 0.9},
		{{name = "electric-furnace", count = math_random(2,4)}, weight = 3, evolution_min = 0.5, evolution_max = 1},
		{{name = "steel-furnace", count = math_random(4,8)}, weight = 3, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "stone-furnace", count = math_random(8,16)}, weight = 3, evolution_min = 0.0, evolution_max = 0.1},		
		{{name = "radar", count = math_random(1,2)}, weight = 1, evolution_min = 0.1, evolution_max = 0.3},
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, evolution_min = 0.2, evolution_max = 0.8},		
		{{name = "stone-wall", count = math_random(25,75)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "gate", count = math_random(4,8)}, weight = 1, evolution_min = 0.1, evolution_max = 0.5},
		{{name = "storage-tank", count = math_random(2,4)}, weight = 3, evolution_min = 0.3, evolution_max = 0.6},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "express-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.5, evolution_max = 1},
		{{name = "fast-loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.2, evolution_max = 0.7},
		{{name = "loader", count = math_random(1,2)}, weight = 1, evolution_min = 0.0, evolution_max = 0.5},
		{{name = "lab", count = math_random(2,4)}, weight = 2, evolution_min = 0.0, evolution_max = 0.1},
	
		--{{name = "roboport", count = math_random(2,4)}, weight = 2, evolution_min = 0.6, evolution_max = 1},
		--{{name = "flamethrower-turret", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},		
		--{{name = "laser-turret", count = math_random(4,8)}, weight = 3, evolution_min = 0.5, evolution_max = 1},	
		{{name = "gun-turret", count = math_random(2,4)}, weight = 3, evolution_min = 0.2, evolution_max = 0.9}		
	}		
	for _, t in pairs (chest_loot) do
		for x = 1, t.weight, 1 do
			if t.evolution_min <= game.forces.enemy.evolution_factor and t.evolution_max >= game.forces.enemy.evolution_factor then
				table.insert(chest_raffle, t[1])
			end
		end			
	end
	
	return chest_raffle[math_random(1,#chest_raffle)]
end

function spawn_market(surface, position)
	local market = surface.create_entity({name = "market", position = position, force = "neutral"})
	market.destructible = false
	--[[
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'stone', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'coal', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'uranium-ore', count = 25}})
	market.add_market_item({price = {{'iron-ore', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'copper-ore', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'stone', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{'coal', 50}}, offer = {type = 'give-item', item = "coin", count = 5}})
	market.add_market_item({price = {{"uranium-ore", 25}}, offer = {type = 'give-item', item = 'coin', count = 5}})	
	market.add_market_item({price = {{'coin', 1}}, offer = {type = 'give-item', item = "wood", count = 50}})
	]]
	
	market.add_market_item({price = {{'coin', 2}}, offer = {type = 'give-item', item = "raw-fish", count = 1}})
	market.add_market_item({price = {{'coin', 10}}, offer = {type = 'give-item', item = "grenade", count = 1}})
	market.add_market_item({price = {{'coin', 1}}, offer = {type = 'give-item', item = "firearm-magazine", count = 1}})
	market.add_market_item({price = {{'coin', 16}}, offer = {type = 'give-item', item = "submachine-gun", count = 1}})
	market.add_market_item({price = {{'coin', 64}}, offer = {type = 'give-item', item = "car", count = 1}})
end