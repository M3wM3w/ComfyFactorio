local Chrono_table = require 'maps.chronosphere.table'
local Rand = require 'maps.chronosphere.random'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local math_random = math.random
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil

local Public = {}


local function treasure_chest_loot(difficulty, planet)
	
	local function loot_data_sensible(loot_data_item)
		return {weight = loot_data_item[1], d_min = loot_data_item[2], d_max = loot_data_item[3], scaling = loot_data_item[4], name = loot_data_item[5], min_count = loot_data_item[6], max_count = loot_data_item[7]}
	end
	
	local loot_data_raw= {
		--always there (or normally always there):

		{8, 0, 1, false, "railgun-dart", 8, 16}, -- thesixthroc: this should not scale with jumps. reward treasure hunting currency the same at all jump numbers
		{8, 0, 1, false, "coin", 4, 60},

		{4, 0, 1, false, "pistol", 1, 2},
		{1, 0, 1, false, "gun-turret", 2, 4},
		{6, 0, 1, false, "grenade", 2, 21},
		{4, 0, 1, false, "stone-wall", 24, 100},
		{4, 0, 1, false, "gate", 14, 32},
		{1, 0, 1, false, "radar", 1, 2},
		{1, 0, 1, false, "explosives", 10, 50},
		{6, 0, 1, false, "small-lamp", 8, 32},
		{2, 0, 1, false, "electric-mining-drill", 2, 4},
		{3, 0, 1, false, "long-handed-inserter", 4, 16},
		{0.5, 0, 1, false, "filter-inserter", 2, 12},
		{0.2, 0, 1, false, "stack-filter-inserter", 2, 6},
		{0.2, 0, 1, false, "slowdown-capsule", 2, 4},
		{0.2, 0, 1, false, "destroyer-capsule", 2, 4},
		{0.2, 0, 1, false, "defender-capsule", 2, 4},
		{0.2, 0, 1, false, "distractor-capsule", 2, 4},
		{0.25, 0, 1, false, "rail", 50, 100},
		{0.25, 0, 1, false, "uranium-rounds-magazine", 1, 4},
		{1, 0.15, 1, false, "pump", 1, 2},
		{2, 0.15, 1, false, "pumpjack", 1, 3},
		{0.02, 0.15, 1, false, "oil-refinery", 1, 2},

		--shotgun meta:
		{10, -0.2, 0.4, true, "shotgun-shell", 12, 24},
		{5, 0, 0.4, true, "shotgun", 1, 1},
		{3, 0, 1.2, true, "piercing-shotgun-shell", 8, 24},
		{2, 0, 1.2, true, "combat-shotgun", 1, 1},

		--modular armor meta:
		{0.7, -3, 1, true, "modular-armor", 1, 1},
		{0.4, 0.3, 1, true, "power-armor", 1, 1},
		-- {0.5, -1,3, true, "power-armor-mk2", 1, 1},
		{2, 0, 1, true, "solar-panel-equipment", 1, 2},
		{2, 0, 1, true, "battery-equipment", 1, 1},
		{1.6, 0, 1, true, "energy-shield-equipment", 1, 2},
		{0.8, 0, 1, true, "night-vision-equipment", 1, 1},
		{0.4, 0.5, 1.5, true, "personal-laser-defense-equipment", 1, 1},
		
		--loader meta:
		{math_max(1.5 * difficulty - 1.25, 0), 0, 0.2, false, "loader", 1, 2},
		{math_max(1.5 * difficulty - 1.25, 0), 0.2, 0.6, false, "fast-loader", 1, 2},
		{math_max(1.5 * difficulty - 1.25, 0), 0.6, 1, false, "express-loader", 1, 2},

		--science meta:
		{8, -0.5, 0.5, true, "automation-science-pack", 4, 12},
		{8, -0.6, 0.6, true, "logistic-science-pack", 4, 12},
		{6, -0.1, 1, true, "military-science-pack", 8, 8}, --careful with this
		{6, 0.2, 1.4, true, "chemical-science-pack", 16, 24},
		{6, 0.3, 1.5, true, "production-science-pack", 16, 24},
		{4, 0.4, 1.5, true, "utility-science-pack", 16, 24},
		{10, 0.5, 1.5, true, "space-science-pack", 16, 24},

		--early-game:
		{3, -0.1, 0.1, true, "wooden-chest", 8, 40},
		{5, -0.1, 0.1, true, "burner-inserter", 8, 20},
		{1, -0.2, 0.2, true, "offshore-pump", 1, 3},
		{3, -0.2, 0.2, true, "boiler", 3, 6},
		{6, -0.2, 0.2, true, "lab", 1, 2},
		{3, -0.2, 0.2, true, "steam-engine", 2, 4},
		{3, -0.2, 0.2, true, "burner-mining-drill", 2, 4},
		{2.7, 0, 0.15, false, "submachine-gun", 1, 3},
		{0.3, 0, 0.15, false, "vehicle-machine-gun", 1, 1},
		{3, 0, 0.3, true, "iron-chest", 8, 40},
		{4, -0.3, 0.3, true, "light-armor", 1, 1},
		{4, -0.3, 0.3, true, "inserter", 8, 16},
		{8, -0.3, 0.3, true, "small-electric-pole", 16, 32},
		{6, -0.4, 0.4, true, "stone-furnace", 8, 16},
		{8, -0.5, 0.5, true, "firearm-magazine", 32, 128},
		{1, -0.3, 0.3, true, "underground-belt", 3, 10},
		{1, -0.3, 0.3, true, "splitter", 1, 5},
		{1, -0.3, 0.3, true, "assembling-machine-1", 2, 4},
		{5, -0.8, 0.8, true, "transport-belt", 15, 120},

		--mid-game:
		{5, -0.2, 0.7, true, "pipe", 30, 50},
		{1, -0.2, 0.7, true, "pipe-to-ground", 4, 8},
		{5, -0.2, 0.7, true, "iron-gear-wheel", 40, 160},
		{5, -0.2, 0.7, true, "copper-cable", 60, 200},
		{5, -0.2, 0.7, true, "electronic-circuit", 30, 200},
		{4, -0.1, 0.8, true, "fast-transport-belt", 15, 90},
		{4, -0.1, 0.8, true, "fast-underground-belt", 3, 10},
		{4, -0.1, 0.8, true, "fast-splitter", 1, 5},
		{2, 0, 0.6, true, "storage-tank", 2, 6},
		{4, 0, 0.6, true, "heavy-armor", 1, 1},
		{3, 0, 0.7, true, "steel-plate", 15, 100},
		{8, 0, 0.9, true, "piercing-rounds-magazine", 20, 128},
		{4, 0.2, 0.6, true, "engine-unit", 16, 32},
		{4, 0, 1, true, "fast-inserter", 8, 16},
		{5, 0, 1, true, "steel-furnace", 4, 8},
		{5, 0, 1, true, "assembling-machine-2", 2, 4},
		{5, 0, 1, true, "medium-electric-pole", 6, 20},
		{5, 0, 1, true, "accumulator", 4, 8},
		{5, 0, 1, true, "solar-panel", 3, 6},
		{8, 0, 1, true, "steel-chest", 8, 16},
		{3, 0.2, 1, true, "chemical-plant", 1, 3},

		--late-game:
		{3, 0, 1.2, true, "rocket-launcher", 1, 1},
		{5, 0, 1.2, true, "rocket", 16, 32},
		{3, 0, 1.2, true, "land-mine", 16, 32},
		{4, 0.2, 1.2, true, "lubricant-barrel", 4, 10},
		{1, 0.2, 1.2, true, "battery", 50, 150},
		{5, 0.2, 1.8, true, "explosive-rocket", 16, 32},
		{4, 0.2, 1.4, true, "advanced-circuit", 30, 200},
		{3, 0.2, 1.8, true, "stack-inserter", 4, 8},
		{3, 0.2, 1.4, true, "big-electric-pole", 4, 8},
		{2, 0.3, 1, true, "rocket-fuel", 4, 10},
		{5, 0.4, 0.7, true, "cannon-shell", 16, 32},
		{5, 0.4, 0.8, true, "explosive-cannon-shell", 16, 32},
		{2, 0.4, 1, true, "electric-engine-unit", 16, 32},
		{5, 0.2, 1.8, true, "cluster-grenade", 8, 16},
		{5, 0.2, 1.4, true, "construction-robot", 5, 25},
		{2, 0.25, 1.75, true, "logistic-robot", 5, 25},
		{2, 0.25, 1.75, true, "substation", 2, 4},
		{3, 0.25, 1.75, true, "assembling-machine-3", 2, 4},
		{3, 0.25, 1.75, true, "express-transport-belt", 15, 90},
		{3, 0.25, 1.75, true, "express-underground-belt", 3, 10},
		{3, 0.25, 1.75, true, "express-splitter", 1, 5},
		{3, 0.25, 1.75, true, "electric-furnace", 2, 4},
		{3, 0.25, 1.75, true, "laser-turret", 3, 6},
		{4, 0.4, 1.6, true, "processing-unit", 30, 200},
		{2, 0.6, 1.4, true, "roboport", 1, 1},

		-- super late-game:
		{1, 0.9, 1.1, true, "power-armor-mk2", 1, 1},

		--{2, 0, 1, , "computer", 1, 1},
		--{1, 0.2, 1, , "railgun", 1, 1},
		--{1, 0.9, 1, , "personal-roboport-mk2-equipment", 1, 1},
	}
	local specialised_loot_raw = {}

	if planet.type.id == 3 then --stonewrld
		specialised_loot_raw = {
		{20, 0, 1, false, "stone-brick", 10, 300},
		{25, 0, 1, false, "stone-wall", 20, 100},
		{25, 0, 1, false, "refined-hazard-concrete", 50, 200}
		}
	end

	if planet.type.id == 5 then --uraniumwrld
		specialised_loot_raw = {
			{3, 0, 0.8, true, "steam-turbine", 1, 2},
			{3, 0, 0.8, true, "heat-exchanger", 2, 4},
			{3, 0, 0.8, true, "heat-pipe", 4, 8},
			{2, 0, 2, true, "uranium-rounds-magazine", 6, 48},
			{2, 0, 1, true, "uranium-cannon-shell", 12, 32},
			{4, 0.4, 1.6, true, "explosive-uranium-cannon-shell", 12, 32},
			{10, 0, 1, false, "uranium-238", 8, 32},
			{0.1, 0, 1, false, "uranium-235", 2, 12},
			{2, 0.2, 1, false, "nuclear-reactor", 1, 1},
			{2, 0.2, 1, false, "centrifuge", 1, 1},
			{1, 0.25, 1, false, "nuclear-fuel", 1, 1},
			{1, 0.25, 1, false, "fusion-reactor-equipment", 1, 1},
			{1, 0.5, 1, false, "atomic-bomb", 1, 1},
		}
	end

	--[[
	if planet.type.id == 7 then --biterwrld
		specialised_loot_raw = {
			{4, 0, 1, false, "effectivity-module", 1, 4},
			{4, 0, 1, false, "productivity-module", 1, 4},
			{4, 0, 1, false, "speed-module", 1, 4},
			{2, 0, 1, false, "beacon", 1, 1},
			{0.5, 0, 1, false, "effectivity-module-2", 1, 4},
			{0.5, 0, 1, false, "productivity-module-2", 1, 4},
			{0.5, 0, 1, false, "speed-module-2", 1, 4},
			{0.1, 0, 1, false, "effectivity-module-3", 1, 4},
			{0.1, 0, 1, false, "productivity-module-3", 1, 4},
			{0.1, 0, 1, false, "speed-module-3", 1, 4},

		}
	end
	]]

	if planet.type.id == 14 then --ancient battlefield
		specialised_loot_raw = {
			{5, -0.7, 0.7, true, "light-armor", 1, 1},
			{5, -0.3, 0.9, true, "heavy-armor", 1, 1},
			{5, 0.4, 0.7, true, "cannon-shell", 16, 32},
			{8, -0.7, 0.7, true, "firearm-magazine", 32, 128},
			{4, -0.2, 1.2, true, "piercing-rounds-magazine", 32, 128},
			{3, 0.2, 1.8, true, "uranium-rounds-magazine", 32, 128},
			{3, 0, 2, true, "rocket-launcher", 1, 1},
			{1, -1, 3, true, "flamethrower", 1, 1},
			{1, -1, 3, true, "flamethrower-ammo", 16, 32},
		}
	end

	if planet.type.id == 14 then --lavawrld
		specialised_loot_raw = {
			{6, -1, 3, true, "flamethrower-turret", 1, 1},
			{7, -1, 2, true, "flamethrower", 1, 1},
			{14, -1, 2, true, "flamethrower-ammo", 16, 32},
		}
	end

	if planet.type.id == 16 then --mazewrld
		specialised_loot_raw = {
			{2, 0, 1, false, "programmable-speaker", 2, 4},
			{6, 0, 1, false, "arithmetic-combinator", 4, 8},
			{6, 0, 1, false, "constant-combinator", 4, 8},
			{6, 0, 1, false, "decider-combinator", 4, 8},
			{6, 0, 1, false, "power-switch", 1, 1},
			{9, 0, 1, false, "green-wire", 10, 29},
			{9, 0, 1, false, "red-wire", 10, 29},

			{11, 0, 0.6, true, "modular-armor", 1, 1},
			{7, -0.2,1, true, "power-armor", 1, 1},
			{3, 0,2, true, "power-armor-mk2", 1, 1},

			{4, 0, 1, false, "exoskeleton-equipment", 1, 1},
			{4, 0, 1, false, "belt-immunity-equipment", 1, 1},
			{4, 0, 1, true, "energy-shield-equipment", 1, 2},
			{4, 0, 1, false, "night-vision-equipment", 1, 1},
			{4, 0, 1, false, "discharge-defense-equipment", 1, 1},
			{4, 0.2, 1, false, "personal-roboport-equipment", 1, 2},
			{4, 0.4, 1, false, "personal-laser-defense-equipment", 1, 1},
			{8, 0, 1, false, "solar-panel-equipment", 1, 2},
			{8, 0, 1, false, "battery-equipment", 1, 1},

			{1, 0.5, 1, false, "energy-shield-mk2-equipment", 1, 1},
			{1, 0.5, 1, false, "battery-mk2-equipment", 1, 1},

			{3, 0, 1, true, "copper-cable", 20, 400},
			{3, -0.3, 0.6, true, "electronic-circuit", 50, 100},
			{3, 0.2, 1.4, true, "advanced-circuit", 50, 100},
			{3, 0.5, 1.5, true, "processing-unit", 50, 100},
		}
	end

	if planet.type.id == 18 then --swampwrld
		specialised_loot_raw = {
			{25, 0, 1, false, "poison-capsule", 4, 16},
			{45, 0, 1, false, "sulfuric-acid-barrel", 4, 8},
		}
	end

	local loot_data = {}
	for l=1,#loot_data_raw,1 do
		table.insert(loot_data, loot_data_sensible(loot_data_raw[l]))
	end
	for l=1,#specialised_loot_raw,1 do
		table.insert(loot_data, loot_data_sensible(specialised_loot_raw[l]))
	end

	return loot_data
end

function Public.treasure_chest(surface, position, container_name)
	local objective = Chrono_table.get_table()

  	local jumps = 0
	if objective.chronojumps then jumps = objective.chronojumps end
	local difficulty = 1
	if Difficulty.get().difficulty_vote_value then difficulty = Difficulty.get().difficulty_vote_value end
	if jumps == 0 then difficulty = 1 end --Always treat the first level as normal difficulty

	local chest_raffle = {}

	local distance_to_center = (jumps / 40)
	if distance_to_center > 1 then distance_to_center = 1 end

	local loot_data = treasure_chest_loot(difficulty, objective.planet[1])
	local loot_types, loot_weights = {}, {}
	for i = 1,#loot_data,1 do
		table.insert(loot_types, {["name"] = loot_data[i].name, ["min_count"] = loot_data[i].min_count, ["max_count"] = loot_data[i].max_count})

		if loot_data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
			local midpoint = (loot_data[i].d_max + loot_data[i].d_min) / 2
			local difference = (loot_data[i].d_max - loot_data[i].d_min)
			table.insert(loot_weights,loot_data[i].weight * math_max(0, 1 - (math_abs(distance_to_center - midpoint) / (difference / 2))))
		else -- no scaling
			if loot_data[i].d_min <= distance_to_center and loot_data[i].d_max >= distance_to_center then
				table.insert(loot_weights, loot_data[i].weight)
			else
				table.insert(loot_weights, 0)
			end
		end
	end

	local e = surface.create_entity({name = container_name, position=position, force="neutral", create_build_effect_smoke = false})
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for _ = 1, math_random(2,5), 1 do -- 20/04/04: max 5 items better than 6, so that if you observe 4 items in alt-mode the chance of an extra one is 1/2 rather than 2/3
		local loot = Rand.raffle(loot_types,loot_weights)
		local difficulty_scaling = Balance.treasure_quantity_difficulty_scaling(difficulty)
		if objective.chronojumps == 0 then difficulty_scaling = 1 end
		local low = math_max(1, math_ceil(loot.min_count * difficulty_scaling))
		local high = math_max(1, math_ceil(loot.max_count * difficulty_scaling))
		local _count = math_random(low, high)
		local lucky = math_random(1,180)
		if lucky == 1 then --lucky
			_count = _count * 3
		elseif lucky <= 10 then
			_count = _count * 2
		end
		i.insert({name = loot.name, count = _count})
	end
end

return Public.treasure_chest
