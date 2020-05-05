local Public = {}
local Rand = require 'maps.chronosphere.random'

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_ceil = math.ceil
local math_pow = math.pow
local math_random = math.random
local math_log = math.log


--- MATHEMATICAL CURVES ---

local function difficulty_sloped(difficulty,slope)
	local difficulty = global.difficulty_vote_value
  
	return 1 + ((difficulty - 1) * slope)
end
-- SLOPE GUIDE
-- slope 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- slope 4/5 -> {0.20, 0.40, 0.60, 0.80, 1.20, 2.40, 4.00}
-- slope 3/5 -> {0.15, 0.30, 0.45, 0.60, 0.90, 1.80, 3.00}
-- slope 2/5 -> {0.10, 0.20, 0.30, 0.40, 0.60, 1.20, 2.00}
  
local function difficulty_exp(difficulty,exponent)
	local difficulty = global.difficulty_vote_value
  
	return math_floor(math_pow(difficulty,exponent))
end
-- EXPONENT GUIDE
-- exponent 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- exponent 1.5 -> {0.13, 0.35, 0.65, 1.00, 1.84, 5.20, 11.18}
-- exponent 2 -> {0.06, 0.25, 0.56, 1.00, 2.25, 9.00, 25.00}
-- exponent -1.2 -> {5.28, 2.30, 1.41, 1.00, 0.61, 0.27, 0.14}

local function scaling_curve_type(jumps,a,b,c,d,e,pivot)
	local val
	if jumps < pivot then
		val = (a * jumps + math_pow(b, jumps)) --normalised to 1 at jumps=0
	else
		val = c - d * math_pow(e, - (jumps - pivot))
	end

	return val
end
-- when used, include imgur links of curve shape



---- CHRONO/POLLUTION BALANCE ----

function Public.train_pollution_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 3/5) end -- applies to all pollution 'from train'

-- Now that we have a dynamic passive charge rate, we can separate the energy needed to charge from the default length of stay. So we can scale these initial values and curves to whatever we like:
Public.initial_passive_jumptime = 1800
Public.initial_MJneeded = 6000
Public.initial_CCneeded = Public.initial_MJneeded -- 1MJ = 1CC

-- and the curves of the scales over time:
function Public.passive_planet_jumptime(jumps)
	-- imgur link
	--local a,b,c,d,e,pivot = 0.05, 1.06, 2.35, 1, 1.04, 16
	local a,b,c,d,e,pivot = 0.05, 1.06, 2.35, 1, 1, 16

	local curveval = scaling_curve_type(jumps,a,b,c,d,e,pivot)
	return math_floor(Public.initial_passive_jumptime * curveval)
end
function Public.MJ_needed_for_full_charge(jumps)
	-- imgur link
	-- local a,b,c,d,e,pivot = 3 * (10 + 2 * jumps) --unchanged

	-- local curveval = scaling_curve_type(jumps,a,b,c,d,e,pivot)
	--return math_floor(Public.initial_MJneeded * curveval)
	return 3 * (2000 + 300 * jumps)
end

function Public.pollution_filter_upgrade_factor(upgrades2) --unchanged
	return 1 / (upgrades2 / 3 + 1)
end

function Public.passive_pollution_rate(jumps, difficulty, filter_upgrades)
	local baserate = 3 * jumps --higher

	local modifiedrate = baserate * Public.train_pollution_difficulty_scaling(difficulty) * Public.pollution_filter_upgrade_factor(filter_upgrades)
  
	return modifiedrate
end

function Public.active_pollution_per_chronocharge(jumps, difficulty, filter_upgrades)
	local baserate = 3 * (10 + 2 * jumps) --unchanged

	local modifiedrate = baserate * Public.train_pollution_difficulty_scaling(difficulty) * Public.pollution_filter_upgrade_factor(filter_upgrades)
	
	return modifiedrate
end

function Public.countdown_pollution_rate(jumps, difficulty)
	local baserate = 20 * (10 + 2 * jumps)

	local modifiedrate = baserate * Public.train_pollution_difficulty_scaling(difficulty) -- immune to filter upgrades
	
	return modifiedrate
end

function Public.pollution_transfer_from_inside_factor(difficulty, filter_upgrades) return 3 * Public.pollution_filter_upgrade_factor(filter_upgrades) * Public.train_pollution_difficulty_scaling(difficulty) end

function Public.post_jump_initial_pollution(jumps, difficulty) return 500 * (1 + jumps) * Public.train_pollution_difficulty_scaling(difficulty) end -- NOT DEPENDENT ON FILTERS




function Public.pollution_spent_per_attack(difficulty) return 50 * difficulty_exp(difficulty, -1.2) end

function Public.defaultai_attack_pollution_consumption_modifier(difficulty) return 0.8 end --unchanged, just exposed here. change?


----- GENERAL BALANCE ----


Public.Chronotrain_max_HP = 10000
Public.Chronotrain_HP_repaired_per_pack = 150
Public.starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 2, ['raw-fish'] = 4, ['wood'] = 16}

function Public.generate_jump_countdown_length()
	return Rand.raffle({90,120,150,180,210,240,270},{1,5,25,125,25,5,1})
end

function Public.coin_reward_per_second_jumped_early(seconds, difficulty)
	local minutes = seconds / 60
	local amount = minutes * 10 * difficulty_sloped(difficulty, 0) -- No difficulty scaling seems best. (if this is changed, change the code so that coins are not awarded on the first jump)
	return math_max(0,math_floor(amount))
end

function Public.upgrades_coin_cost_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 3/5) end

function Public.flamers_nerfs_size(jumps, difficulty) return 0.02 * jumps * difficulty_sloped(difficulty, 1/2) end

function Public.max_new_attack_group_size(difficulty) return math_max(256,math_floor(128 * difficulty_sloped(difficulty, 4/5))) end

function Public.evoramp50_multiplier_per_second(difficulty) return (1 + 1/500 * difficulty_sloped(difficulty, 2/5)) end

Public.biome_weights = {
	ironwrld = 1,
	copperwrld = 1,
	stonewrld = 1,
	oilwrld = 1,
	uraniumwrld = 1,
	mixedwrld = 3,
	biterwrld = 4,
	dumpwrld = 1,
	coalwrld = 1,
	scrapwrld = 3,
	cavewrld = 2,
	forestwrld = 2,
	riverwrld = 2,
	hellwrld = 1,
	startwrld = 0,
	mazewrld = 2,
	endwrld = 0,
	swampwrld = 2,
	nukewrld = 0
}
function Public.ore_richness_weights(difficulty)
  local ores_weights
  if difficulty <= 0.25
  then ores_weights = {9,10,9,4,2,0}
  elseif difficulty <= 0.5
  then ores_weights = {5,11,12,6,2,0}
  elseif difficulty <= 0.75
  then ores_weights = {5,9,12,7,3,0}
  elseif difficulty <= 1
  then ores_weights = {4,8,12,8,4,0}
  elseif difficulty <= 1.5
  then ores_weights = {2,5,15,9,5,0}
  elseif difficulty <= 3
  then ores_weights = {1,4,12,13,6,0}
  elseif difficulty >= 5
  then ores_weights = {1,2,10,17,6,0}
  end
  return {
	vrich = ores_weights[1],
	rich = ores_weights[2],
	normal = ores_weights[3],
	poor = ores_weights[4],
	vpoor = ores_weights[5],
	none = ores_weights[6]
  }
end
Public.dayspeed_weights = {
	static = 2,
	normal = 4,
  	slow = 3,
	superslow = 1,
  	fast = 3,
  	superfast = 1
}
function Public.market_offers()
	return {
    {price = {{'coin', 20}}, offer = {type = 'give-item', item = "raw-fish"}},
    {price = {{"coin", 40}}, offer = {type = 'give-item', item = 'wood', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'stone', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'coal', count = 50}},
    {price = {{"coin", 400}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
    {price = {{"coin", 50}, {"empty-barrel", 1}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
    {price = {{"coin", 200}, {"steel-plate", 20}, {"electronic-circuit", 20}}, offer = {type = 'give-item', item = 'loader', count = 1}},
    {price = {{"coin", 400}, {"steel-plate", 40}, {"advanced-circuit", 10}, {"loader", 1}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
    {price = {{"coin", 600}, {"express-transport-belt", 10}, {"fast-loader", 1}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
    --{price = {{"coin", 5}, {"stone", 100}}, offer = {type = 'give-item', item = 'landfill', count = 1}},
    {price = {{"coin", 5}, {"steel-plate", 1}, {"explosives", 10}}, offer = {type = 'give-item', item = 'land-mine', count = 1}},
    {price = {{"pistol", 1}}, offer = {type = "give-item", item = "iron-plate", count = 100}}
  }
end
function Public.initial_cargo_boxes()
	return {
		-- early-game grenades suppressed to encourage scavenging:
		-- {name = "grenade", count = math_random(2, 3)},
		-- {name = "grenade", count = math_random(2, 3)},
		-- {name = "grenade", count = math_random(2, 3)},
		{name = "submachine-gun", count = 1},
		{name = "submachine-gun", count = 1},
		{name = "submachine-gun", count = 1},
		{name = "land-mine", count = math_random(6, 12)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "shotgun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun-shell", count = math_random(7, 9)},
		{name = "shotgun-shell", count = math_random(7, 9)},
		{name = "shotgun-shell", count = math_random(7, 9)},
		{name = "firearm-magazine", count = math_random(7, 15)},
		{name = "firearm-magazine", count = math_random(7, 15)},
		{name = "firearm-magazine", count = math_random(7, 15)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)},
	}
end

function Public.treasure_quantity_difficulty_scaling(difficulty) return difficulty_exp(difficulty, 1.5) end

function Public.treasure_chest_loot()
	local loot_data= {
		-- no time scaling:
		{weight = 3, d_min = 0, d_max = 0.2, scaling = false, loot = {name = "submachine-gun", count = {min_count = 1, max_count = 3}}},
		{weight = 0.3, d_min = 0, d_max = 0.2, scaling = false, loot = {name = "vehicle-machine-gun", count = {min_count = 1, max_count = 1}}}, --new!
		{weight = 3, d_min = 0, d_max = 0.3, scaling = false, loot = {name = "iron-chest", count = {min_count = 8, max_count = 16}}},
		{weight = 3, d_min = 0, d_max = 0.5, scaling = false, loot = {name = "long-handed-inserter", count = {min_count = 8, max_count = 16}}},
		{weight = 2, d_min = 0, d_max = 0.6, scaling = false, loot = {name = "pistol", count = {min_count = 1, max_count = 2}}},
		{weight = 1, d_min = 0, d_max = 0.8, scaling = false, loot = {name = "gun-turret", count = {min_count = 2, max_count = 4}}},
		{weight = 5, d_min = 0, d_max = 1, scaling = false, loot = {name = "railgun-dart", count = {min_count = 4, max_count = 20}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "explosives", count = {min_count = 20, max_count = 50}}},
		{weight = 5, d_min = 0, d_max = 1, scaling = false, loot = {name = "grenade", count = {min_count = 16, max_count = 32}}},
		{weight = 4, d_min = 0, d_max = 1, scaling = false, loot = {name = "stone-wall", count = {min_count = 33, max_count = 99}}},
		{weight = 4, d_min = 0, d_max = 1, scaling = false, loot = {name = "gate", count = {min_count = 16, max_count = 32}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "radar", count = {min_count = 1, max_count = 2}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "effectivity-module", count = {min_count = 1, max_count = 4}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "productivity-module", count = {min_count = 1, max_count = 4}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "speed-module", count = {min_count = 1, max_count = 4}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "slowdown-capsule", count = {min_count = 16, max_count = 32}}},
		{weight = 1, d_min = 0.1, d_max = 1, scaling = false, loot = {name = "pumpjack", count = {min_count = 1, max_count = 3}}},
		{weight = 1, d_min = 0.2, d_max = 1, scaling = false, loot = {name = "night-vision-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0.2, d_max = 1, scaling = false, loot = {name = "pump", count = {min_count = 1, max_count = 2}}},

		-- time scaling (linearly rises from zero to 2*weight at the midpoint, then back down again):
		{weight = 3, d_min = -0.1, d_max = 0.1, scaling = true, loot = {name = "wooden-chest", count = {min_count = 8, max_count = 16}}},
		{weight = 3, d_min = -0.1, d_max = 0.1, scaling = true, loot = {name = "burner-inserter", count = {min_count = 8, max_count = 16}}},
		{weight = 3, d_min = -0.1, d_max = 0.1, scaling = true, loot = {name = "light-armor", count = {min_count = 1, max_count = 1}}},
		{weight = 10, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "shotgun-shell", count = {min_count = 16, max_count = 32}}},
		{weight = 2, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "offshore-pump", count = {min_count = 1, max_count = 3}}},
		{weight = 3, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "boiler", count = {min_count = 3, max_count = 6}}},
		{weight = 3, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "steam-engine", count = {min_count = 2, max_count = 4}}},
		{weight = 3, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "burner-mining-drill", count = {min_count = 2, max_count = 4}}},
		{weight = 2, d_min = -0.3, d_max = 0.3, scaling = true, loot = {name = "lab", count = {min_count = 1, max_count = 2}}},
		{weight = 3, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "shotgun", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "stone-furnace", count = {min_count = 8, max_count = 16}}},
		{weight = 5, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "firearm-magazine", count = {min_count = 32, max_count = 128}}},
		{weight = 4, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "automation-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 3, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "small-electric-pole", count = {min_count = 16, max_count = 24}}},
		{weight = 3, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "assembling-machine-1", count = {min_count = 2, max_count = 4}}},
		{weight = 3, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "underground-belt", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "splitter", count = {min_count = 1, max_count = 4}}},
		{weight = 4, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "logistic-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 3, d_min = -0.6, d_max = 0.6, scaling = true, loot = {name = "copper-cable", count = {min_count = 100, max_count = 200}}},
		{weight = 3, d_min = -0.7, d_max = 0.7, scaling = true, loot = {name = "pipe", count = {min_count = 30, max_count = 50}}},
		{weight = 3, d_min = -0.7, d_max = 0.7, scaling = true, loot = {name = "iron-gear-wheel", count = {min_count = 80, max_count = 100}}},
		{weight = 3, d_min = -0.7, d_max = 0.7, scaling = true, loot = {name = "transport-belt", count = {min_count = 25, max_count = 75}}},
		{weight = 3, d_min = -0.2, d_max = 0.4, scaling = true, loot = {name = "inserter", count = {min_count = 8, max_count = 16}}},
		{weight = 10, d_min = -0.2, d_max = 0.6, scaling = true, loot = {name = "piercing-shotgun-shell", count = {min_count = 16, max_count = 32}}},
		{weight = 4, d_min = -0.3, d_max = 0.6, scaling = true, loot = {name = "electronic-circuit", count = {min_count = 50, max_count = 150}}},
		{weight = 4, d_min = -0.4, d_max = 0.8, scaling = true, loot = {name = "military-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 2, d_min = -0.2, d_max = 0.7, scaling = true, loot = {name = "defender-capsule", count = {min_count = 8, max_count = 16}}},
		{weight = 1, d_min = -0.2, d_max = 0.6, scaling = true, loot = {name = "loader", count = {min_count = 1, max_count = 2}}},
		{weight = 3, d_min = -0.2, d_max = 0.8, scaling = true, loot = {name = "fast-transport-belt", count = {min_count = 25, max_count = 75}}},
		{weight = 3, d_min = -0.2, d_max = 0.8, scaling = true, loot = {name = "fast-underground-belt", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = -0.2, d_max = 0.8, scaling = true, loot = {name = "fast-splitter", count = {min_count = 1, max_count = 4}}},
		{weight = 3, d_min = 0, d_max = 0.5, scaling = true, loot = {name = "heavy-armor", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0, d_max = 0.6, scaling = false, loot = {name = "filter-inserter", count = {min_count = 8, max_count = 16}}},
		{weight = 2, d_min = 0, d_max = 0.7, scaling = true, loot = {name = "steel-plate", count = {min_count = 25, max_count = 75}}},
		{weight = 3, d_min = 0, d_max = 0.7, scaling = true, loot = {name = "small-lamp", count = {min_count = 16, max_count = 32}}},
		{weight = 2, d_min = 0, d_max = 0.7, scaling = true, loot = {name = "engine-unit", count = {min_count = 16, max_count = 32}}},
		{weight = 1, d_min = 0.1, d_max = 0.6, scaling = true, loot = {name = "lubricant-barrel", count = {min_count = 4, max_count = 10}}},
		{weight = 3, d_min = 0, d_max = 0.8, scaling = true, loot = {name = "combat-shotgun", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0, d_max = 0.8, scaling = true, loot = {name = "fast-loader", count = {min_count = 1, max_count = 2}}},
		{weight = 2, d_min = 0, d_max = 0.8, scaling = true, loot = {name = "modular-armor", count = {min_count = 1, max_count = 1}}},
		{weight = 5, d_min = 0, d_max = 0.9, scaling = true, loot = {name = "piercing-rounds-magazine", count = {min_count = 32, max_count = 128}}},
		{weight = 3, d_min = 0.2, d_max = 0.8, scaling = true, loot = {name = "flamethrower", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "rail", count = {min_count = 25, max_count = 75}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "fast-inserter", count = {min_count = 8, max_count = 16}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "arithmetic-combinator", count = {min_count = 4, max_count = 8}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "constant-combinator", count = {min_count = 4, max_count = 8}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "decider-combinator", count = {min_count = 4, max_count = 8}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "power-switch", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = true, loot = {name = "programmable-speaker", count = {min_count = 2, max_count = 4}}},
		{weight = 4, d_min = 0, d_max = 1, scaling = true, loot = {name = "green-wire", count = {min_count = 10, max_count = 29}}},
		{weight = 4, d_min = 0, d_max = 1, scaling = true, loot = {name = "red-wire", count = {min_count = 10, max_count = 29}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "pipe-to-ground", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = 0, d_max = 1.2, scaling = true, loot = {name = "rocket-launcher", count = {min_count = 1, max_count = 1}}},
		{weight = 5, d_min = 0, d_max = 1.2, scaling = true, loot = {name = "rocket", count = {min_count = 16, max_count = 32}}},
		{weight = 5, d_min = 0, d_max = 1.2, scaling = true, loot = {name = "land-mine", count = {min_count = 16, max_count = 32}}},
		--{weight = 2, d_min = 0, d_max = 1, scaling = , loot = {name = "computer", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "steel-furnace", count = {min_count = 4, max_count = 8}}},
		{weight = 1, d_min = 0, d_max = 1, scaling = true, loot = {name = "train-stop", count = {min_count = 1, max_count = 2}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "assembling-machine-2", count = {min_count = 2, max_count = 4}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "rail-signal", count = {min_count = 8, max_count = 16}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "rail-chain-signal", count = {min_count = 8, max_count = 16}}},
		--{weight = 1, d_min = 0.2, d_max = 1, scaling = , loot = {name = "railgun", count = {min_count = 1, max_count = 1}}},
		{weight = 2, d_min = 0, d_max = 1, scaling = false, loot = {name = "distractor-capsule", count = {min_count = 8, max_count = 16}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "medium-electric-pole", count = {min_count = 8, max_count = 16}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = false, loot = {name = "electric-mining-drill", count = {min_count = 2, max_count = 4}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "accumulator", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "storage-tank", count = {min_count = 2, max_count = 6}}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "solar-panel", count = {min_count = 3, max_count = 6}}},
		{weight = 1, d_min = 0.2, d_max = 1.2, scaling = true, loot = {name = "battery", count = {min_count = 50, max_count = 150}}},
		{weight = 3, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "poison-capsule", count = {min_count = 8, max_count = 16}}},
		{weight = 5, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "flamethrower-ammo", count = {min_count = 16, max_count = 32}}},
		{weight = 5, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "explosive-rocket", count = {min_count = 16, max_count = 32}}},
		{weight = 2, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "destroyer-capsule", count = {min_count = 8, max_count = 16}}},
		{weight = 1, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "exoskeleton-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "advanced-circuit", count = {min_count = 50, max_count = 150}}},
		{weight = 4, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "chemical-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 3, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "stack-inserter", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "big-electric-pole", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "steel-chest", count = {min_count = 8, max_count = 16}}},
		{weight = 3, d_min = 0.2, d_max = 1, scaling = true, loot = {name = "chemical-plant", count = {min_count = 1, max_count = 3}}},
		{weight = 1, d_min = 0.2, d_max = 1, scaling = true, loot = {name = "belt-immunity-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 2, d_min = 0.3, d_max = 1, scaling = true, loot = {name = "energy-shield-equipment", count = {min_count = 1, max_count = 2}}},
		{weight = 2, d_min = 0.3, d_max = 1, scaling = true, loot = {name = "battery-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 2, d_min = 0.3, d_max = 1, scaling = true, loot = {name = "rocket-fuel", count = {min_count = 4, max_count = 10}}},
		--{weight = 2, d_min = 0.3, d_max = 1, scaling = , loot = {name = "oil-refinery", count = {min_count = 2, max_count = 4}}},
		{weight = 5, d_min = 0.4, d_max = 0.7, scaling = true, loot = {name = "cannon-shell", count = {min_count = 16, max_count = 32}}},
		{weight = 5, d_min = 0.4, d_max = 0.8, scaling = true, loot = {name = "explosive-cannon-shell", count = {min_count = 16, max_count = 32}}},
		{weight = 5, d_min = 0.4, d_max = 0.8, scaling = true, loot = {name = "solar-panel-equipment", count = {min_count = 1, max_count = 4}}},
		{weight = 2, d_min = 0.4, d_max = 1, scaling = true, loot = {name = "electric-engine-unit", count = {min_count = 16, max_count = 32}}},
		{weight = 5, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "cluster-grenade", count = {min_count = 8, max_count = 16}}},
		{weight = 1, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "power-armor", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "personal-roboport-equipment", count = {min_count = 1, max_count = 2}}},
		{weight = 5, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "construction-robot", count = {min_count = 5, max_count = 25}}},
		{weight = 4, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "production-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 1, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "stack-filter-inserter", count = {min_count = 4, max_count = 8}}},
		{weight = 2, d_min = 0.4, d_max = 1, scaling = true, loot = {name = "steam-turbine", count = {min_count = 1, max_count = 2}}},
		{weight = 1, d_min = 0.4, d_max = 1, scaling = true, loot = {name = "centrifuge", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0.5, d_max = 1.2, scaling = true, loot = {name = "nuclear-reactor", count = {min_count = 1, max_count = 1}}},
		{weight = 5, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "uranium-rounds-magazine", count = {min_count = 32, max_count = 128}}},
		{weight = 1, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "discharge-defense-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "logistic-robot", count = {min_count = 5, max_count = 25}}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "utility-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "substation", count = {min_count = 2, max_count = 4}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "assembling-machine-3", count = {min_count = 2, max_count = 4}}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "heat-pipe", count = {min_count = 4, max_count = 8}}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "heat-exchanger", count = {min_count = 2, max_count = 4}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-transport-belt", count = {min_count = 25, max_count = 75}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-underground-belt", count = {min_count = 4, max_count = 8}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-splitter", count = {min_count = 1, max_count = 4}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "electric-furnace", count = {min_count = 2, max_count = 4}}},
		{weight = 1, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-loader", count = {min_count = 1, max_count = 2}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "flamethrower-turret", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "laser-turret", count = {min_count = 3, max_count = 6}}},
		{weight = 5, d_min = 0.4, d_max = 1.6, scaling = true, loot = {name = "uranium-cannon-shell", count = {min_count = 16, max_count = 32}}},
		{weight = 5, d_min = 0.4, d_max = 1.6, scaling = true, loot = {name = "explosive-uranium-cannon-shell", count = {min_count = 16, max_count = 32}}},
		--{weight = 2, d_min = 0.7, d_max = 1, scaling = , loot = {name = "battery-mk2-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "personal-laser-defense-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 3, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "processing-unit", count = {min_count = 50, max_count = 150}}},
		{weight = 2, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "nuclear-fuel", count = {min_count = 1, max_count = 1}}},
		{weight = 2, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "beacon", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0.6, d_max = 1.4, scaling = true, loot = {name = "atomic-bomb", count = {min_count = 1, max_count = 1}}},
		--{weight = 2, d_min = 0.8, d_max = 1, scaling = , loot = {name = "energy-shield-mk2-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 1, d_min = 0.6, d_max = 1.4, scaling = true, loot = {name = "fusion-reactor-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 2, d_min = 0.6, d_max = 1.4, scaling = true, loot = {name = "roboport", count = {min_count = 1, max_count = 1}}},
		--{weight = 1, d_min = 0.9, d_max = 1, scaling = , loot = {name = "personal-roboport-mk2-equipment", count = {min_count = 1, max_count = 1}}},
		{weight = 4, d_min = 0.8, d_max = 1.2, scaling = true, loot = {name = "space-science-pack", count = {min_count = 16, max_count = 64}}},
		{weight = 1, d_min = 0.5, d_max = 3, scaling = true, loot = {name = "power-armor-mk2", count = {min_count = 1, max_count = 1}}},
	}

	return loot_data
end

Public.scrap_yield_amounts = {
	--nerfed:
	["iron-plate"] = 8,
	["iron-gear-wheel"] = 4,
	["iron-stick"] = 8,
	["copper-plate"] = 8,
	["copper-cable"] = 12,
	["electronic-circuit"] = 4,
	["steel-plate"] = 4,
	["pipe"] = 4,
	["solid-fuel"] = 2,
	["empty-barrel"] = 2,
	["crude-oil-barrel"] = 2,
	["lubricant-barrel"] = 2,
	["petroleum-gas-barrel"] = 2,
	["sulfuric-acid-barrel"] = 2,
	["heavy-oil-barrel"] = 2,
	["light-oil-barrel"] = 2,
	["water-barrel"] = 2,
	-- not nerfed:
	["grenade"] = 2,
	["battery"] = 1,
	["explosives"] = 2,
	["advanced-circuit"] = 2,
	["nuclear-fuel"] = 0.1,
	["pipe-to-ground"] = 1,
	["plastic-bar"] = 4,
	["processing-unit"] = 1,
	["used-up-uranium-fuel-cell"] = 1,
	["uranium-fuel-cell"] = 0.3,
	["rocket-fuel"] = 0.3,
	["rocket-control-unit"] = 0.3,
	["low-density-structure"] = 0.3,
	["heat-pipe"] = 1,
	["green-wire"] = 8,
	["red-wire"] = 8,
	["engine-unit"] = 2,
	["electric-engine-unit"] = 2,
	["logistic-robot"] = 0.3,
	["construction-robot"] = 0.3,
	["land-mine"] = 1,
	["rocket"] = 2,
	["explosive-rocket"] = 2,
	["cannon-shell"] = 2,
	["explosive-cannon-shell"] = 2,
	["uranium-cannon-shell"] = 2,
	["explosive-uranium-cannon-shell"] = 2,
	["artillery-shell"] = 0.3,
	["cluster-grenade"] = 0.3,
	["defender-capsule"] = 2,
	["destroyer-capsule"] = 0.3,
	["distractor-capsule"] = 0.3
}

Public.scrap_mining_chance_weights = {
	-- chances of cool stuff improved:
	{name = "iron-plate", chance = 400},
	{name = "iron-gear-wheel", chance = 300},	
	{name = "copper-plate", chance = 300},
	{name = "copper-cable", chance = 200},	
	{name = "electronic-circuit", chance = 125},
	{name = "steel-plate", chance = 75},
	{name = "pipe", chance = 50},
	{name = "solid-fuel", chance = 30},
	{name = "iron-stick", chance = 25},
	{name = "battery", chance = 10},
	{name = "crude-oil-barrel", chance = 10},
	{name = "lubricant-barrel", chance = 7},
	{name = "petroleum-gas-barrel", chance = 7},
	{name = "sulfuric-acid-barrel", chance = 7},
	{name = "heavy-oil-barrel", chance = 7},
	{name = "light-oil-barrel", chance = 7},
	{name = "empty-barrel", chance = 5},
	{name = "water-barrel", chance = 5},
	{name = "green-wire", chance = 5},
	{name = "red-wire", chance = 5},
	{name = "grenade", chance = 5},
	{name = "pipe-to-ground", chance = 3},
	{name = "explosives", chance = 3},
	{name = "advanced-circuit", chance = 3},
	{name = "plastic-bar", chance = 3},
	{name = "engine-unit", chance = 2},
	{name = "nuclear-fuel", chance = 1},
	{name = "processing-unit", chance = 1},
	{name = "used-up-uranium-fuel-cell", chance = 1},
	{name = "uranium-fuel-cell", chance = 1},
	{name = "rocket-fuel", chance = 1},
	{name = "rocket-control-unit", chance = 1},	
	{name = "low-density-structure", chance = 1},	
	{name = "heat-pipe", chance = 1},
	{name = "electric-engine-unit", chance = 1},
	{name = "logistic-robot", chance = 1},
	{name = "construction-robot", chance = 1},
	{name = "land-mine", chance = 1},	
	{name = "rocket", chance = 1},
	{name = "explosive-rocket", chance = 1},
	{name = "cannon-shell", chance = 1},
	{name = "explosive-cannon-shell", chance = 1},
	{name = "uranium-cannon-shell", chance = 1},
	{name = "explosive-uranium-cannon-shell", chance = 1},
	{name = "artillery-shell", chance = 1},
	{name = "cluster-grenade", chance = 1},
	{name = "defender-capsule", chance = 1},
	{name = "destroyer-capsule", chance = 1},
	{name = "distractor-capsule", chance = 1}
}



return Public