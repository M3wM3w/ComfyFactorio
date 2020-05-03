local Public = {}

local math_floor = math.floor
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_ceil = math.ceil
local math_pow = math.ceil

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

----

Public.starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 2, ['raw-fish'] = 4, ['wood'] = 16}

Public.Chronotrain_max_HP = 10000
Public.Chronotrain_HP_repaired_per_pack = 150
Public.grenade_crafting_time_multiplier = 2 --grenades take twice as long to make, such that you want to find them

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

----

function Public.ore_richness_weightings()
  local difficulty = global.difficulty_vote_value
  
  local weightings = {4,8,12,8,4,0}
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
  return weightings
end
function Public.dayspeed_weightings()
  return {2,4,3,1,3,1}
end

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

return Public

----

--mineable-wreckage yields scrap -- by mewmew

--module adapted to chronotrain

-- everything halved for performance
local Public.scrap_mining_chance_weights = {
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
local Public.scrap_yield_amounts = {
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