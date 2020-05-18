local math_random = math.random

local Public = {}

function Public.treasure_chest(surface, position, container_name)
	
	local chest_raffle = {}
	local chest_loot = {			
		{{name = "submachine-gun", count = math_random(1,3)}, weight = 3, d_min = 0.0, d_max = 0.1},		
		{{name = "slowdown-capsule", count = math_random(16,32)}, weight = 1, d_min = 0.3, d_max = 0.7},
		{{name = "poison-capsule", count = math_random(8,16)}, weight = 3, d_min = 0.3, d_max = 1},		
		{{name = "uranium-cannon-shell", count = math_random(16,32)}, weight = 5, d_min = 0.6, d_max = 1},
		{{name = "cannon-shell", count = math_random(16,32)}, weight = 5, d_min = 0.4, d_max = 0.7},
		{{name = "explosive-uranium-cannon-shell", count = math_random(16,32)}, weight = 5, d_min = 0.6, d_max = 1},
		{{name = "explosive-cannon-shell", count = math_random(16,32)}, weight = 5, d_min = 0.4, d_max = 0.8},
		{{name = "shotgun", count = 1}, weight = 2, d_min = 0.0, d_max = 0.2},
		{{name = "shotgun-shell", count = math_random(16,32)}, weight = 5, d_min = 0.0, d_max = 0.2},
		{{name = "combat-shotgun", count = 1}, weight = 3, d_min = 0.3, d_max = 0.8},
		{{name = "piercing-shotgun-shell", count = math_random(16,32)}, weight = 10, d_min = 0.2, d_max = 1},
		{{name = "flamethrower", count = 1}, weight = 3, d_min = 0.3, d_max = 0.6},
		{{name = "flamethrower-ammo", count = math_random(16,32)}, weight = 5, d_min = 0.3, d_max = 1},
		{{name = "rocket-launcher", count = 1}, weight = 3, d_min = 0.2, d_max = 0.6},
		{{name = "rocket", count = math_random(16,32)}, weight = 5, d_min = 0.2, d_max = 0.7},		
		{{name = "explosive-rocket", count = math_random(16,32)}, weight = 5, d_min = 0.3, d_max = 1},
		{{name = "land-mine", count = math_random(16,32)}, weight = 5, d_min = 0.2, d_max = 0.7},
		{{name = "grenade", count = math_random(8,16)}, weight = 5, d_min = 0.0, d_max = 0.5},
		{{name = "cluster-grenade", count = math_random(8,16)}, weight = 5, d_min = 0.4, d_max = 1},
		{{name = "firearm-magazine", count = math_random(32,128)}, weight = 5, d_min = 0, d_max = 0.3},
		{{name = "piercing-rounds-magazine", count = math_random(32,128)}, weight = 5, d_min = 0.1, d_max = 0.8},
		{{name = "uranium-rounds-magazine", count = math_random(32,128)}, weight = 5, d_min = 0.5, d_max = 1},
		{{name = "railgun", count = 1}, weight = 1, d_min = 0.2, d_max = 1},
		{{name = "railgun-dart", count = math_random(16,32)}, weight = 3, d_min = 0.2, d_max = 0.7},
		{{name = "defender-capsule", count = math_random(8,16)}, weight = 2, d_min = 0.0, d_max = 0.7},
		{{name = "distractor-capsule", count = math_random(8,16)}, weight = 2, d_min = 0.2, d_max = 1},
		{{name = "destroyer-capsule", count = math_random(8,16)}, weight = 2, d_min = 0.3, d_max = 1},
		{{name = "atomic-bomb", count = 1}, weight = 1, d_min = 0.8, d_max = 1},		
		{{name = "light-armor", count = 1}, weight = 3, d_min = 0, d_max = 0.1},		
		{{name = "heavy-armor", count = 1}, weight = 3, d_min = 0.1, d_max = 0.3},
		{{name = "modular-armor", count = 1}, weight = 2, d_min = 0.2, d_max = 0.6},
		{{name = "power-armor", count = 1}, weight = 1, d_min = 0.4, d_max = 1},
		--{{name = "power-armor-mk2", count = 1}, weight = 1, d_min = 0.9, d_max = 1},
		{{name = "battery-equipment", count = 1}, weight = 2, d_min = 0.3, d_max = 0.7},
		--{{name = "battery-mk2-equipment", count = 1}, weight = 2, d_min = 0.7, d_max = 1},
		{{name = "belt-immunity-equipment", count = 1}, weight = 1, d_min = 0.5, d_max = 1},
		{{name = "solar-panel-equipment", count = math_random(1,4)}, weight = 5, d_min = 0.4, d_max = 0.8},
		{{name = "discharge-defense-equipment", count = 1}, weight = 1, d_min = 0.5, d_max = 1},
		{{name = "energy-shield-equipment", count = math_random(1,2)}, weight = 2, d_min = 0.3, d_max = 0.8},
		--{{name = "energy-shield-mk2-equipment", count = 1}, weight = 2, d_min = 0.8, d_max = 1},
		{{name = "exoskeleton-equipment", count = 1}, weight = 1, d_min = 0.3, d_max = 1},
		--{{name = "fusion-reactor-equipment", count = 1}, weight = 1, d_min = 0.8, d_max = 1},
		{{name = "night-vision-equipment", count = 1}, weight = 1, d_min = 0.3, d_max = 0.8},
		{{name = "personal-laser-defense-equipment", count = 1}, weight = 1, d_min = 0.7, d_max = 1},
		
		{{name = "personal-roboport-equipment", count = math_random(1,2)}, weight = 3, d_min = 0.4, d_max = 1},
		--{{name = "personal-roboport-mk2-equipment", count = 1}, weight = 1, d_min = 0.9, d_max = 1},
		{{name = "logistic-robot", count = math_random(5,25)}, weight = 2, d_min = 0.5, d_max = 1},
		{{name = "construction-robot", count = math_random(5,25)}, weight = 5, d_min = 0.4, d_max = 1},
		
		{{name = "iron-gear-wheel", count = math_random(80,100)}, weight = 3, d_min = 0.0, d_max = 0.3},
		{{name = "copper-cable", count = math_random(100,200)}, weight = 3, d_min = 0.0, d_max = 0.3},
		{{name = "engine-unit", count = math_random(16,32)}, weight = 2, d_min = 0.1, d_max = 0.5},
		{{name = "electric-engine-unit", count = math_random(16,32)}, weight = 2, d_min = 0.4, d_max = 0.8},
		{{name = "battery", count = math_random(50,150)}, weight = 2, d_min = 0.3, d_max = 0.8},
		{{name = "advanced-circuit", count = math_random(50,150)}, weight = 3, d_min = 0.3, d_max = 1},
		{{name = "electronic-circuit", count = math_random(50,150)}, weight = 4, d_min = 0.0, d_max = 0.4},
		{{name = "processing-unit", count = math_random(50,150)}, weight = 3, d_min = 0.7, d_max = 1},
		--{{name = "explosives", count = math_random(25,50)}, weight = 1, d_min = 0.0, d_max = 1},
		{{name = "lubricant-barrel", count = math_random(4,10)}, weight = 1, d_min = 0.3, d_max = 0.5},
		{{name = "rocket-fuel", count = math_random(4,10)}, weight = 2, d_min = 0.3, d_max = 0.7},
		--{{name = "computer", count = 1}, weight = 2, d_min = 0, d_max = 1},
		
		{{name = "effectivity-module", count = math_random(1,4)}, weight = 2, d_min = 0.1, d_max = 1},
		{{name = "productivity-module", count = math_random(1,4)}, weight = 2, d_min = 0.1, d_max = 1},
		{{name = "speed-module", count = math_random(1,4)}, weight = 2, d_min = 0.1, d_max = 1},
		
		{{name = "automation-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.0, d_max = 0.2},
		{{name = "logistic-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.1, d_max = 0.5},
		{{name = "military-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.2, d_max = 1},
		{{name = "chemical-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.3, d_max = 1},
		{{name = "production-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.4, d_max = 1},
		{{name = "utility-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.5, d_max = 1},
		{{name = "space-science-pack", count = math_random(16,64)}, weight = 3, d_min = 0.9, d_max = 1},

		{{name = "steel-plate", count = math_random(25,75)}, weight = 2, d_min = 0.1, d_max = 0.3},
		{{name = "nuclear-fuel", count = 1}, weight = 2, d_min = 0.7, d_max = 1},
				
		{{name = "burner-inserter", count = math_random(8,16)}, weight = 3, d_min = 0.0, d_max = 0.1},
		{{name = "inserter", count = math_random(8,16)}, weight = 3, d_min = 0.0, d_max = 0.4},
		{{name = "long-handed-inserter", count = math_random(8,16)}, weight = 3, d_min = 0.0, d_max = 0.4},		
		{{name = "fast-inserter", count = math_random(8,16)}, weight = 3, d_min = 0.1, d_max = 1},
		{{name = "filter-inserter", count = math_random(8,16)}, weight = 1, d_min = 0.2, d_max = 1},		
		{{name = "stack-filter-inserter", count = math_random(4,8)}, weight = 1, d_min = 0.4, d_max = 1},
		{{name = "stack-inserter", count = math_random(4,8)}, weight = 3, d_min = 0.3, d_max = 1},				
		{{name = "small-electric-pole", count = math_random(16,24)}, weight = 3, d_min = 0.0, d_max = 0.3},
		{{name = "medium-electric-pole", count = math_random(8,16)}, weight = 3, d_min = 0.2, d_max = 1},
		{{name = "big-electric-pole", count = math_random(4,8)}, weight = 3, d_min = 0.3, d_max = 1},
		{{name = "substation", count = math_random(2,4)}, weight = 3, d_min = 0.5, d_max = 1},
		{{name = "wooden-chest", count = math_random(8,16)}, weight = 3, d_min = 0.0, d_max = 0.2},
		{{name = "iron-chest", count = math_random(8,16)}, weight = 3, d_min = 0.1, d_max = 0.4},
		{{name = "steel-chest", count = math_random(8,16)}, weight = 3, d_min = 0.3, d_max = 1},		
		{{name = "small-lamp", count = math_random(16,32)}, weight = 3, d_min = 0.1, d_max = 0.3},
		{{name = "rail", count = math_random(25,75)}, weight = 3, d_min = 0.1, d_max = 0.6},
		{{name = "assembling-machine-1", count = math_random(2,4)}, weight = 3, d_min = 0.0, d_max = 0.3},
		{{name = "assembling-machine-2", count = math_random(2,4)}, weight = 3, d_min = 0.2, d_max = 0.8},
		{{name = "assembling-machine-3", count = math_random(2,4)}, weight = 3, d_min = 0.5, d_max = 1},
		{{name = "accumulator", count = math_random(4,8)}, weight = 3, d_min = 0.4, d_max = 1},
		{{name = "offshore-pump", count = math_random(1,3)}, weight = 2, d_min = 0.0, d_max = 0.2},
		{{name = "beacon", count = 1}, weight = 2, d_min = 0.7, d_max = 1},
		{{name = "boiler", count = math_random(3,6)}, weight = 3, d_min = 0.0, d_max = 0.3},
		{{name = "steam-engine", count = math_random(2,4)}, weight = 3, d_min = 0.0, d_max = 0.5},
		{{name = "steam-turbine", count = math_random(1,2)}, weight = 2, d_min = 0.6, d_max = 1},
		{{name = "nuclear-reactor", count = 1}, weight = 1, d_min = 0.7, d_max = 1},
		{{name = "centrifuge", count = 1}, weight = 1, d_min = 0.6, d_max = 1},
		{{name = "heat-pipe", count = math_random(4,8)}, weight = 2, d_min = 0.5, d_max = 1},
		{{name = "heat-exchanger", count = math_random(2,4)}, weight = 2, d_min = 0.5, d_max = 1},
		{{name = "arithmetic-combinator", count = math_random(4,8)}, weight = 2, d_min = 0.1, d_max = 1},
		{{name = "constant-combinator", count = math_random(4,8)}, weight = 2, d_min = 0.1, d_max = 1},
		{{name = "decider-combinator", count = math_random(4,8)}, weight = 2, d_min = 0.1, d_max = 1},
		{{name = "power-switch", count = 1}, weight = 2, d_min = 0.1, d_max = 1},		
		{{name = "programmable-speaker", count = math_random(2,4)}, weight = 1, d_min = 0.1, d_max = 1},
		{{name = "green-wire", count = math_random(50,99)}, weight = 4, d_min = 0.1, d_max = 1},
		{{name = "red-wire", count = math_random(50,99)}, weight = 4, d_min = 0.1, d_max = 1},
		{{name = "chemical-plant", count = math_random(1,3)}, weight = 3, d_min = 0.3, d_max = 1},
		{{name = "burner-mining-drill", count = math_random(2,4)}, weight = 3, d_min = 0.0, d_max = 0.2},
		{{name = "electric-mining-drill", count = math_random(2,4)}, weight = 3, d_min = 0.2, d_max = 1},		
		{{name = "express-transport-belt", count = math_random(25,75)}, weight = 3, d_min = 0.5, d_max = 1},
		{{name = "express-underground-belt", count = math_random(4,8)}, weight = 3, d_min = 0.5, d_max = 1},		
		{{name = "express-splitter", count = math_random(1,4)}, weight = 3, d_min = 0.5, d_max = 1},
		{{name = "fast-transport-belt", count = math_random(25,75)}, weight = 3, d_min = 0.2, d_max = 0.7},
		{{name = "fast-underground-belt", count = math_random(4,8)}, weight = 3, d_min = 0.2, d_max = 0.7},
		{{name = "fast-splitter", count = math_random(1,4)}, weight = 3, d_min = 0.2, d_max = 0.3},
		{{name = "transport-belt", count = math_random(25,75)}, weight = 3, d_min = 0, d_max = 0.3},
		{{name = "underground-belt", count = math_random(4,8)}, weight = 3, d_min = 0, d_max = 0.3},
		{{name = "splitter", count = math_random(1,4)}, weight = 3, d_min = 0, d_max = 0.3},		
		--{{name = "oil-refinery", count = math_random(2,4)}, weight = 2, d_min = 0.3, d_max = 1},
		{{name = "pipe", count = math_random(30,50)}, weight = 3, d_min = 0.0, d_max = 0.3},
		{{name = "pipe-to-ground", count = math_random(4,8)}, weight = 1, d_min = 0.2, d_max = 0.5},
		{{name = "pumpjack", count = math_random(1,3)}, weight = 1, d_min = 0.3, d_max = 0.8},
		{{name = "pump", count = math_random(1,2)}, weight = 1, d_min = 0.3, d_max = 0.8},
		{{name = "solar-panel", count = math_random(3,6)}, weight = 3, d_min = 0.4, d_max = 0.9},
		{{name = "electric-furnace", count = math_random(2,4)}, weight = 3, d_min = 0.5, d_max = 1},
		{{name = "steel-furnace", count = math_random(4,8)}, weight = 3, d_min = 0.2, d_max = 0.7},
		{{name = "stone-furnace", count = math_random(8,16)}, weight = 3, d_min = 0.0, d_max = 0.2},		
		{{name = "radar", count = math_random(1,2)}, weight = 1, d_min = 0.1, d_max = 0.4},
		{{name = "rail-signal", count = math_random(8,16)}, weight = 2, d_min = 0.2, d_max = 0.8},
		{{name = "rail-chain-signal", count = math_random(8,16)}, weight = 2, d_min = 0.2, d_max = 0.8},		
		{{name = "stone-wall", count = math_random(33,99)}, weight = 3, d_min = 0.0, d_max = 0.7},
		{{name = "gate", count = math_random(16,32)}, weight = 3, d_min = 0.0, d_max = 0.7},
		{{name = "storage-tank", count = math_random(2,6)}, weight = 3, d_min = 0.3, d_max = 0.6},
		{{name = "train-stop", count = math_random(1,2)}, weight = 1, d_min = 0.2, d_max = 0.7},
		{{name = "express-loader", count = math_random(1,2)}, weight = 1, d_min = 0.5, d_max = 1},
		{{name = "fast-loader", count = math_random(1,2)}, weight = 1, d_min = 0.2, d_max = 0.7},
		{{name = "loader", count = math_random(1,2)}, weight = 1, d_min = 0.0, d_max = 0.5},
		{{name = "lab", count = math_random(1,2)}, weight = 2, d_min = 0.0, d_max = 0.3},	
		{{name = "roboport", count = 1}, weight = 2, d_min = 0.8, d_max = 1},
		{{name = "flamethrower-turret", count = 1}, weight = 3, d_min = 0.5, d_max = 1},		
		{{name = "laser-turret", count = math_random(3,6)}, weight = 3, d_min = 0.5, d_max = 1},	
		{{name = "gun-turret", count = math_random(2,4)}, weight = 3, d_min = 0.2, d_max = 0.9},
	}
	
	local distance_to_center = (math.abs(position.x) + 1) * 0.0002
	if distance_to_center > 1 then distance_to_center = 1 end
	
	for _, t in pairs (chest_loot) do
		for x = 1, t.weight, 1 do
			if t.d_min <= distance_to_center and t.d_max >= distance_to_center then
				table.insert(chest_raffle, t[1])
			end
		end			
	end
	
	local e = surface.create_entity({name = container_name, position=position, force="neutral"})	
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for x = 1, math_random(2,6), 1 do
		local loot = chest_raffle[math_random(1,#chest_raffle)]
		i.insert(loot)
	end
end

return Public.treasure_chest