local Public = {}

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_ceil = math.ceil
local math_pow = math.ceil
local math_random = math.random

-- SLOPE GUIDE
-- slope 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- slope 4/5 -> {0.20, 0.40, 0.60, 0.80, 1.20, 2.40, 4.00}
-- slope 3/5 -> {0.15, 0.30, 0.45, 0.60, 0.90, 1.80, 3.00}
-- slope 2/5 -> {0.10, 0.20, 0.30, 0.40, 0.60, 1.20, 2.00}
local function difficulty_sloped(slope)
  local difficulty = global.difficulty_vote_value

  return 1 + ((difficulty - 1) * slope)
end

-- EXPONENT GUIDE
-- exponent 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- exponent 1.5 -> {0.13, 0.35, 0.65, 1.00, 1.84, 5.20, 11.18}
-- exponent 2 -> {0.06, 0.25, 0.56, 1.00, 2.25, 9.00, 25.00}
-- exponent -1.2 -> {5.28, 2.30, 1.41, 1.00, 0.61, 0.27, 0.14}
local function difficulty_exp(exponent)
  local difficulty = global.difficulty_vote_value

  return math_floor(math_pow(difficulty,exponent))
end

----

local function desired_passive_planet_jumptime_fn(jumps)--in seconds
  -- scaling function: https://imgur.com/a/0jpLvCL
  local fn
  if jumps<=3 then fn = 32 + 5 * jumps
  elseif jumps <=16 then fn = 90 - 42 * math_pow(1.15, -(jumps - 3))
  else fn = 44 + 39 * math_pow(1.04, -(jumps-16))
  end

  return fn*60
end

--------

Public.Chronotrain_max_HP = 10000
Public.Chronotrain_HP_repaired_per_pack = 150
Public.starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 2, ['raw-fish'] = 4, ['wood'] = 16}

-- Public.initial_chrononeeds = 2000
-- function Public.additional_chrononeeds() return 300 * Chrono_table.get_table().chronojumps end
-- function Public.dynamic_passive_charge_rate() return 1 end
-- previously, I think the amount of Joules required to jump was too high to begin with, and too low later. Now due to dynamic_passive_charge_rate we have control over that independent of what the 'Timer' displays, so let's do:
function Public.dynamic_chrononeeds(jumps) return math_floor(desired_passive_planet_jumptime_fn(jumps))/60/32*500 end --scaled to be 500 at jumps=0
function Public.dynamic_passive_charge_rate(jumps) return Public.dynamic_chrononeeds(jumps)/desired_passive_planet_jumptime_fn(jumps) end --per second rate
function Public.pollution_spent_per_attack() return 50 * difficulty_exp(-1.2) end
function Public.upgrades_coin_cost_difficulty_scaling() return difficulty_sloped(3/5) end
function Public.train_base_pollution_due_to_charging(chronojumps) return (10 + 2 * chronojumps) end
function Public.train_pollution_difficulty_scaling() return difficulty_sloped(3/5) end
function Public.max_new_attack_group_size() return math_floor(128 * difficulty_sloped(4/5)) end
function Public.evo_50ramp_difficulty_scaling() return difficulty_sloped(2/5) end

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

function Public.ore_richness_weights()
  local difficulty = global.difficulty_vote_value
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
	[1] = ores_weights[1],
	[2] = ores_weights[2],
	[3] = ores_weights[3],
	[4] = ores_weights[4],
	[5] = ores_weights[5],
	[6] = ores_weights[6]
  }
end

Public.dayspeed_weights = {
  [1] = 2,
  [2] = 4,
  [3] = 3,
  [4] = 1,
  [5] = 3,
  [6] = 1
}

function Public.market_offers()
	return {
    {price = {{'coin', 10}}, offer = {type = 'give-item', item = "raw-fish"}},
    {price = {{"coin", 20}}, offer = {type = 'give-item', item = 'wood', count = 50}},
    {price = {{"coin", 50}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
    {price = {{"coin", 50}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
    {price = {{"coin", 50}}, offer = {type = 'give-item', item = 'stone', count = 50}},
    {price = {{"coin", 50}}, offer = {type = 'give-item', item = 'coal', count = 50}},
    {price = {{"coin", 200}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
    {price = {{"coin", 25}, {"empty-barrel", 1}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
    {price = {{"coin", 200}, {"steel-plate", 20}, {"electronic-circuit", 20}}, offer = {type = 'give-item', item = 'loader', count = 1}},
    {price = {{"coin", 400}, {"steel-plate", 40}, {"advanced-circuit", 10}, {"loader", 1}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
    {price = {{"coin", 600}, {"express-transport-belt", 10}, {"fast-loader", 1}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
    --{price = {{"coin", 5}, {"stone", 100}}, offer = {type = 'give-item', item = 'landfill', count = 1}},
    {price = {{"coin", 1}, {"steel-plate", 1}, {"explosives", 10}}, offer = {type = 'give-item', item = 'land-mine', count = 1}},
    {price = {{"pistol", 1}}, offer = {type = "give-item", item = "iron-plate", count = 100}}
  }
end

function Public.treasure_chest_loot()
	return {
		-- no scaling:
		{weight = 3, d_min = 0, d_max = 0.2, scaling = false, loot = {name = "submachine-gun", count = math_random(1,3)}},
		{weight = 3, d_min = 0, d_max = 0.3, scaling = false, loot = {name = "iron-chest", count = math_random(8,16)}},
		{weight = 3, d_min = 0, d_max = 0.5, scaling = false, loot = {name = "long-handed-inserter", count = math_random(8,16)}},
		{weight = 2, d_min = 0, d_max = 0.6, scaling = false, loot = {name = "pistol", count = math_random(1,2)}},
		{weight = 1, d_min = 0, d_max = 0.8, scaling = false, loot = {name = "gun-turret", count = math_random(2,4)}},
		{weight = 5, d_min = 0, d_max = 1, scaling = false, loot = {name = "railgun-dart", count = math_random(4,20)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "explosives", count = math_random(20,50)}},
		{weight = 5, d_min = 0, d_max = 1, scaling = false, loot = {name = "grenade", count = math_random(16,32)}},
		{weight = 4, d_min = 0, d_max = 1, scaling = false, loot = {name = "stone-wall", count = math_random(33,99)}},
		{weight = 4, d_min = 0, d_max = 1, scaling = false, loot = {name = "gate", count = math_random(16,32)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "radar", count = math_random(1,2)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "effectivity-module", count = math_random(1,4)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "productivity-module", count = math_random(1,4)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "speed-module", count = math_random(1,4)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = false, loot = {name = "slowdown-capsule", count = math_random(16,32)}},
		{weight = 1, d_min = 0.1, d_max = 1, scaling = false, loot = {name = "pumpjack", count = math_random(1,3)}},
		{weight = 1, d_min = 0.2, d_max = 1, scaling = false, loot = {name = "night-vision-equipment", count = 1}},
		{weight = 1, d_min = 0.2, d_max = 1, scaling = false, loot = {name = "pump", count = math_random(1,2)}},

		-- scaling:
		{weight = 3, d_min = -0.1, d_max = 0.1, scaling = true, loot = {name = "wooden-chest", count = math_random(8,16)}},
		{weight = 3, d_min = -0.1, d_max = 0.1, scaling = true, loot = {name = "burner-inserter", count = math_random(8,16)}},
		{weight = 3, d_min = -0.1, d_max = 0.1, scaling = true, loot = {name = "light-armor", count = 1}},
		{weight = 8, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "shotgun-shell", count = math_random(16,32)}},
		{weight = 2, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "offshore-pump", count = math_random(1,3)}},
		{weight = 3, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "boiler", count = math_random(3,6)}},
		{weight = 3, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "steam-engine", count = math_random(2,4)}},
		{weight = 3, d_min = -0.2, d_max = 0.2, scaling = true, loot = {name = "burner-mining-drill", count = math_random(2,4)}},
		{weight = 2, d_min = -0.3, d_max = 0.3, scaling = true, loot = {name = "shotgun", count = 1}},
		{weight = 2, d_min = -0.3, d_max = 0.3, scaling = true, loot = {name = "lab", count = math_random(1,2)}},
		{weight = 3, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "stone-furnace", count = math_random(8,16)}},
		{weight = 5, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "firearm-magazine", count = math_random(32,128)}},
		{weight = 4, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "automation-science-pack", count = math_random(16,64)}},
		{weight = 3, d_min = -0.4, d_max = 0.4, scaling = true, loot = {name = "small-electric-pole", count = math_random(16,24)}},
		{weight = 3, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "assembling-machine-1", count = math_random(2,4)}},
		{weight = 3, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "underground-belt", count = math_random(4,8)}},
		{weight = 3, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "splitter", count = math_random(1,4)}},
		{weight = 4, d_min = -0.5, d_max = 0.5, scaling = true, loot = {name = "logistic-science-pack", count = math_random(16,64)}},
		{weight = 3, d_min = -0.6, d_max = 0.6, scaling = true, loot = {name = "copper-cable", count = math_random(100,200)}},
		{weight = 3, d_min = -0.7, d_max = 0.7, scaling = true, loot = {name = "pipe", count = math_random(30,50)}},
		{weight = 3, d_min = -0.7, d_max = 0.7, scaling = true, loot = {name = "iron-gear-wheel", count = math_random(80,100)}},
		{weight = 3, d_min = -0.7, d_max = 0.7, scaling = true, loot = {name = "transport-belt", count = math_random(25,75)}},
		{weight = 3, d_min = -0.2, d_max = 0.4, scaling = true, loot = {name = "inserter", count = math_random(8,16)}},
		{weight = 10, d_min = -0.2, d_max = 0.6, scaling = true, loot = {name = "piercing-shotgun-shell", count = math_random(16,32)}},
		{weight = 4, d_min = -0.3, d_max = 0.6, scaling = true, loot = {name = "electronic-circuit", count = math_random(50,150)}},
		{weight = 4, d_min = -0.4, d_max = 0.8, scaling = true, loot = {name = "military-science-pack", count = math_random(16,64)}},
		{weight = 2, d_min = -0.2, d_max = 0.7, scaling = true, loot = {name = "defender-capsule", count = math_random(8,16)}},
		{weight = 1, d_min = -0.2, d_max = 0.6, scaling = true, loot = {name = "loader", count = math_random(1,2)}},
		{weight = 3, d_min = -0.2, d_max = 0.8, scaling = true, loot = {name = "fast-transport-belt", count = math_random(25,75)}},
		{weight = 3, d_min = -0.2, d_max = 0.8, scaling = true, loot = {name = "fast-underground-belt", count = math_random(4,8)}},
		{weight = 3, d_min = -0.2, d_max = 0.8, scaling = true, loot = {name = "fast-splitter", count = math_random(1,4)}},
		{weight = 3, d_min = 0, d_max = 0.5, scaling = true, loot = {name = "heavy-armor", count = 1}},
		{weight = 1, d_min = 0, d_max = 0.6, scaling = false, loot = {name = "filter-inserter", count = math_random(8,16)}},
		{weight = 2, d_min = 0, d_max = 0.7, scaling = true, loot = {name = "steel-plate", count = math_random(25,75)}},
		{weight = 3, d_min = 0, d_max = 0.7, scaling = true, loot = {name = "small-lamp", count = math_random(16,32)}},
		{weight = 2, d_min = 0, d_max = 0.7, scaling = true, loot = {name = "engine-unit", count = math_random(16,32)}},
		{weight = 1, d_min = 0.1, d_max = 0.6, scaling = true, loot = {name = "lubricant-barrel", count = math_random(4,10)}},
		{weight = 1, d_min = 0, d_max = 0.8, scaling = true, loot = {name = "fast-loader", count = math_random(1,2)}},
		{weight = 2, d_min = 0, d_max = 0.8, scaling = true, loot = {name = "modular-armor", count = 1}},
		{weight = 5, d_min = 0, d_max = 0.9, scaling = true, loot = {name = "piercing-rounds-magazine", count = math_random(32,128)}},
		{weight = 3, d_min = 0.2, d_max = 0.8, scaling = true, loot = {name = "flamethrower", count = 1}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "rail", count = math_random(25,75)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "fast-inserter", count = math_random(8,16)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "arithmetic-combinator", count = math_random(4,8)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "constant-combinator", count = math_random(4,8)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "decider-combinator", count = math_random(4,8)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "power-switch", count = 1}},
		{weight = 1, d_min = 0, d_max = 1, scaling = true, loot = {name = "programmable-speaker", count = math_random(2,4)}},
		{weight = 4, d_min = 0, d_max = 1, scaling = true, loot = {name = "green-wire", count = math_random(10,29)}},
		{weight = 4, d_min = 0, d_max = 1, scaling = true, loot = {name = "red-wire", count = math_random(10,29)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "pipe-to-ground", count = math_random(4,8)}},
		{weight = 3, d_min = 0, d_max = 1.2, scaling = true, loot = {name = "rocket-launcher", count = 1}},
		{weight = 5, d_min = 0, d_max = 1.2, scaling = true, loot = {name = "rocket", count = math_random(16,32)}},
		{weight = 5, d_min = 0, d_max = 1.2, scaling = true, loot = {name = "land-mine", count = math_random(16,32)}},
		--{weight = 2, d_min = 0, d_max = 1, scaling = , loot = {name = "computer", count = 1}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "steel-furnace", count = math_random(4,8)}},
		{weight = 1, d_min = 0, d_max = 1, scaling = true, loot = {name = "train-stop", count = math_random(1,2)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "assembling-machine-2", count = math_random(2,4)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "rail-signal", count = math_random(8,16)}},
		{weight = 2, d_min = 0, d_max = 1, scaling = true, loot = {name = "rail-chain-signal", count = math_random(8,16)}},
		--{weight = 1, d_min = 0.2, d_max = 1, scaling = , loot = {name = "railgun", count = 1}},
		{weight = 2, d_min = 0, d_max = 1, scaling = false, loot = {name = "distractor-capsule", count = math_random(8,16)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "medium-electric-pole", count = math_random(8,16)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = false, loot = {name = "electric-mining-drill", count = math_random(2,4)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "accumulator", count = math_random(4,8)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "storage-tank", count = math_random(2,6)}},
		{weight = 3, d_min = 0, d_max = 1, scaling = true, loot = {name = "solar-panel", count = math_random(3,6)}},
		{weight = 3, d_min = 0.2, d_max = 1, scaling = true, loot = {name = "combat-shotgun", count = 1}},
		{weight = 1, d_min = 0.2, d_max = 1.2, scaling = true, loot = {name = "battery", count = math_random(50,150)}},
		{weight = 3, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "poison-capsule", count = math_random(8,16)}},
		{weight = 5, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "flamethrower-ammo", count = math_random(16,32)}},
		{weight = 5, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "explosive-rocket", count = math_random(16,32)}},
		{weight = 2, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "destroyer-capsule", count = math_random(8,16)}},
		{weight = 1, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "exoskeleton-equipment", count = 1}},
		{weight = 3, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "advanced-circuit", count = math_random(50,150)}},
		{weight = 4, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "chemical-science-pack", count = math_random(16,64)}},
		{weight = 3, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "stack-inserter", count = math_random(4,8)}},
		{weight = 3, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "big-electric-pole", count = math_random(4,8)}},
		{weight = 3, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "steel-chest", count = math_random(8,16)}},
		{weight = 3, d_min = 0.2, d_max = 1, scaling = true, loot = {name = "chemical-plant", count = math_random(1,3)}},
		{weight = 1, d_min = 0.2, d_max = 1, scaling = true, loot = {name = "belt-immunity-equipment", count = 1}},
		{weight = 2, d_min = 0.3, d_max = 1, scaling = true, loot = {name = "energy-shield-equipment", count = math_random(1,2)}},
		{weight = 2, d_min = 0.3, d_max = 1, scaling = true, loot = {name = "battery-equipment", count = 1}},
		{weight = 2, d_min = 0.3, d_max = 1, scaling = true, loot = {name = "rocket-fuel", count = math_random(4,10)}},
		--{weight = 2, d_min = 0.3, d_max = 1, scaling = , loot = {name = "oil-refinery", count = math_random(2,4)}},
		{weight = 5, d_min = 0.4, d_max = 0.7, scaling = true, loot = {name = "cannon-shell", count = math_random(16,32)}},
		{weight = 5, d_min = 0.4, d_max = 0.8, scaling = true, loot = {name = "explosive-cannon-shell", count = math_random(16,32)}},
		{weight = 5, d_min = 0.4, d_max = 0.8, scaling = true, loot = {name = "solar-panel-equipment", count = math_random(1,4)}},
		{weight = 2, d_min = 0.4, d_max = 1, scaling = true, loot = {name = "electric-engine-unit", count = math_random(16,32)}},
		{weight = 5, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "cluster-grenade", count = math_random(8,16)}},
		{weight = 1, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "power-armor", count = 1}},
		{weight = 3, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "personal-roboport-equipment", count = math_random(1,2)}},
		{weight = 5, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "construction-robot", count = math_random(5,25)}},
		{weight = 4, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "production-science-pack", count = math_random(16,64)}},
		{weight = 1, d_min = 0.2, d_max = 1.4, scaling = true, loot = {name = "stack-filter-inserter", count = math_random(4,8)}},
		{weight = 2, d_min = 0.4, d_max = 1, scaling = true, loot = {name = "steam-turbine", count = math_random(1,2)}},
		{weight = 1, d_min = 0.4, d_max = 1, scaling = true, loot = {name = "centrifuge", count = 1}},
		{weight = 1, d_min = 0.5, d_max = 1.2, scaling = true, loot = {name = "nuclear-reactor", count = 1}},
		{weight = 5, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "uranium-rounds-magazine", count = math_random(32,128)}},
		{weight = 1, d_min = 0.2, d_max = 1.8, scaling = true, loot = {name = "discharge-defense-equipment", count = 1}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "logistic-robot", count = math_random(5,25)}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "utility-science-pack", count = math_random(16,64)}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "substation", count = math_random(2,4)}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "assembling-machine-3", count = math_random(2,4)}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "heat-pipe", count = math_random(4,8)}},
		{weight = 2, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "heat-exchanger", count = math_random(2,4)}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-transport-belt", count = math_random(25,75)}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-underground-belt", count = math_random(4,8)}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-splitter", count = math_random(1,4)}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "electric-furnace", count = math_random(2,4)}},
		{weight = 1, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "express-loader", count = math_random(1,2)}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "flamethrower-turret", count = 1}},
		{weight = 3, d_min = 0.25, d_max = 1.75, scaling = true, loot = {name = "laser-turret", count = math_random(3,6)}},
		{weight = 5, d_min = 0.4, d_max = 1.6, scaling = true, loot = {name = "uranium-cannon-shell", count = math_random(16,32)}},
		{weight = 5, d_min = 0.4, d_max = 1.6, scaling = true, loot = {name = "explosive-uranium-cannon-shell", count = math_random(16,32)}},
		--{weight = 2, d_min = 0.7, d_max = 1, scaling = , loot = {name = "battery-mk2-equipment", count = 1}},
		{weight = 1, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "personal-laser-defense-equipment", count = 1}},
		{weight = 3, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "processing-unit", count = math_random(50,150)}},
		{weight = 2, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "nuclear-fuel", count = 1}},
		{weight = 2, d_min = 0.5, d_max = 1.5, scaling = true, loot = {name = "beacon", count = 1}},
		{weight = 1, d_min = 0.6, d_max = 1.4, scaling = true, loot = {name = "atomic-bomb", count = 1}},
		--{weight = 2, d_min = 0.8, d_max = 1, scaling = , loot = {name = "energy-shield-mk2-equipment", count = 1}},
		{weight = 1, d_min = 0.6, d_max = 1.4, scaling = true, loot = {name = "fusion-reactor-equipment", count = 1}},
		{weight = 2, d_min = 0.6, d_max = 1.4, scaling = true, loot = {name = "roboport", count = 1}},
		--{weight = 1, d_min = 0.9, d_max = 1, scaling = , loot = {name = "personal-roboport-mk2-equipment", count = 1}},
		{weight = 4, d_min = 0.8, d_max = 1.2, scaling = true, loot = {name = "space-science-pack", count = math_random(16,64)}},
		{weight = 1, d_min = 0.5, d_max = 3, scaling = true, loot = {name = "power-armor-mk2", count = 1}},
	}
end

Public.scrap_mining_chance_weights = {
	{name = "iron-plate", chance = 500},
	{name = "iron-gear-wheel", chance = 325},	
	{name = "copper-plate", chance = 325},
	{name = "copper-cable", chance = 250},	
	{name = "electronic-circuit", chance = 150},
	{name = "steel-plate", chance = 100},
	{name = "solid-fuel", chance = 75},
	{name = "pipe", chance = 50},
	{name = "iron-stick", chance = 25},
	{name = "battery", chance = 10},
	{name = "empty-barrel", chance = 5},
	{name = "crude-oil-barrel", chance = 15},
	{name = "lubricant-barrel", chance = 10},
	{name = "petroleum-gas-barrel", chance = 7},
	{name = "sulfuric-acid-barrel", chance = 7},
	{name = "heavy-oil-barrel", chance = 7},
	{name = "light-oil-barrel", chance = 7},
	{name = "water-barrel", chance = 5},
	{name = "green-wire", chance = 5},
	{name = "red-wire", chance = 5},
	{name = "explosives", chance = 3},
	{name = "advanced-circuit", chance = 3},
	{name = "nuclear-fuel", chance = 1},
	{name = "pipe-to-ground", chance = 5},
	{name = "plastic-bar", chance = 3},
	{name = "processing-unit", chance = 1},
	{name = "used-up-uranium-fuel-cell", chance = 1},
	{name = "uranium-fuel-cell", chance = 1},
	{name = "rocket-fuel", chance = 1},
	{name = "rocket-control-unit", chance = 1},	
	{name = "low-density-structure", chance = 1},	
	{name = "heat-pipe", chance = 1},
	{name = "engine-unit", chance = 2},
	{name = "electric-engine-unit", chance = 1},
	{name = "logistic-robot", chance = 1},
	{name = "construction-robot", chance = 1},
	
	{name = "land-mine", chance = 1},	
	{name = "grenade", chance = 4},
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

-- first few materials halved for balance
Public.scrap_yield_amounts = {
	["iron-plate"] = 8,
	["iron-gear-wheel"] = 4,
	["iron-stick"] = 8,
	["copper-plate"] = 8,
	["copper-cable"] = 12,
	["electronic-circuit"] = 4,
	["steel-plate"] = 2,
	["pipe"] = 4,
	["solid-fuel"] = 2,
	["empty-barrel"] = 3,
	["crude-oil-barrel"] = 3,
	["lubricant-barrel"] = 3,
	["petroleum-gas-barrel"] = 3,
	["sulfuric-acid-barrel"] = 3,
	["heavy-oil-barrel"] = 3,
	["light-oil-barrel"] = 3,
	["water-barrel"] = 3,
	["battery"] = 2,
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
	["grenade"] = 2,
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




return Public