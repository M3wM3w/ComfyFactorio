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



--- DIFFICULTY SCALING CURVES ---

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



---- CHRONO/POLLUTION BALANCE ----

function Public.charging_pollution_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 3/5) end

function Public.pollution_filter_upgrade_factor(upgrades2)
	return 1 / (upgrades2 / 3 + 1) -- 20/05/05: unchanged
end

function Public.machine_pollution_transfer_from_inside_factor(difficulty, filter_upgrades) return 3 * Public.pollution_filter_upgrade_factor(filter_upgrades) * difficulty_sloped(difficulty, 2/5) end


-- 20/05/05: Now that we have a dynamic passive charge rate, we can separate the energy needed to charge from the default length of stay. So we can choose the following however we like:

function Public.passive_planet_jumptime(jumps)
	local mins

	if jumps < 20 then
		mins = 30 + 4 * jumps
	else
		mins = 110
	end

	return mins * 60
end

function Public.passive_pollution_rate(jumps, difficulty, filter_upgrades)
	local baserate = 2 * jumps -- 20/05/05: unchanged

	local modifiedrate = baserate * Public.charging_pollution_difficulty_scaling(difficulty) * Public.pollution_filter_upgrade_factor(filter_upgrades)
  
	return modifiedrate
end

function Public.active_pollution_per_chronocharge(jumps, difficulty, filter_upgrades) -- 20/05/05: 1CC = 1MJ
	--previously 1CC was 3MJ, and 1MJ active charge produced (10 + 2 * jumps) pollution

	local baserate = 0.75 * (10 + 2 * jumps) -- 20/05/05: lowered by 25%. gotta survive new 'countdown' phase afterwards

	local modifiedrate = baserate * Public.charging_pollution_difficulty_scaling(difficulty) * Public.pollution_filter_upgrade_factor(filter_upgrades)
	
	return modifiedrate
end

function Public.countdown_pollution_rate(jumps, difficulty)
	local baserate = 25 * (10 + 2 * jumps)

	local modifiedrate = baserate -- thesixthroc: Constant, because part of drama of planet progression. Interpreting this as hyperwarp portal pollution
	
	return modifiedrate
end

function Public.post_jump_initial_pollution(jumps, difficulty)
	local baserate = 300 * (2 + jumps)

	local modifiedrate = baserate -- thesixthroc: Constant, because part of drama of planet progression. Interpreting this as hyperwarp portal pollution
	
	return modifiedrate
end


function Public.pollution_spent_per_attack(difficulty) return 50 * difficulty_exp(difficulty, -1.2) end -- 20/05/05: now scales as -1.2 rather than -1

function Public.defaultai_attack_pollution_consumption_modifier(difficulty) return 0.8 end -- 20/05/05: unchanged, just exposed here. change?

-- 20/05/05: changing this now affects ONLY how many kWH you need to get to the next level:
function Public.MJ_needed_for_full_charge(difficulty, jumps)
	local baserate = 2000 + 500 * jumps -- thesixthroc: I believe around here is good

	local modifiedrate
	if difficulty <= 1 then modifiedrate = baserate end
	if difficulty > 1 and jumps>0 then modifiedrate = baserate + 2000 + 100 * jumps end
	return modifiedrate
end



----- GENERAL BALANCE ----

Public.Chronotrain_max_HP = 10000
Public.Chronotrain_HP_repaired_per_pack = 150

Public.starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 2, ['raw-fish'] = 4, ['wood'] = 16}
Public.wagon_starting_items = {{name = 'firearm-magazine', count = 16},{name = 'iron-plate', count = 16},{name = 'wood', count = 16},{name = 'burner-mining-drill', count = 8}}

function Public.jumps_until_overstay_is_on(difficulty) --both overstay penalties, and evoramp
	if difficulty > 1 then return 2
	elseif difficulty == 1 then return 3
	else return 5
	end
end

function Public.pistol_damage_multiplier(difficulty) return 2.5 end --3 will one-shot biters
function Public.damage_research_effect_on_shotgun_multipler(difficulty) return 3 end

function Public.generate_jump_countdown_length(difficulty)
	if difficulty <= 1 then
		return Rand.raffle({90,120,150,180,210},{1,8,64,8,1})
	else
		return 150 -- thesixthroc: suppress rng for speedrunners
	end
end

function Public.misfire_percentage_chance(difficulty)
	if difficulty <= 1 and difficulty > 0.25 then
		return 5
	else
		return 0 -- thesixthroc: suppress rng for speedrunners
	end
end

function Public.coin_reward_per_second_jumped_early(seconds, difficulty)
	local minutes = seconds / 60
	local amount = minutes * 20 * difficulty_sloped(difficulty, 0) -- No difficulty scaling seems best. (if this is changed, change the code so that coins are not awarded on the first jump)
	return math_max(0,math_floor(amount))
end

function Public.upgrades_coin_cost_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 3/5) end

function Public.flamers_nerfs_size(jumps, difficulty) return 0.02 * jumps * difficulty_sloped(difficulty, 1/2) end

function Public.max_new_attack_group_size(difficulty) return math_max(188,math_floor(120 * difficulty_sloped(difficulty, 4/5))) end

function Public.evoramp50_multiplier_per_second(difficulty) return (1 + 1/500 * difficulty_sloped(difficulty, 2/5)) end

function Public.nukes_looted_per_silo(difficulty) return math_max(10, 10 * math_ceil(difficulty_sloped(difficulty, 1))) end

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
	cavewrld = 1, -- 20/05/05: reduced from 2 to 1, this map is the most laggy...
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
    {price = {{'coin', 40}}, offer = {type = 'give-item', item = "raw-fish"}},
    {price = {{"coin", 40}}, offer = {type = 'give-item', item = 'wood', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}},
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'stone', count = 50}}, -- 20/05/05: not needed I think
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'coal', count = 50}},
    {price = {{"coin", 400}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
    {price = {{"coin", 50}, {"empty-barrel", 1}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
    {price = {{"coin", 500}, {"steel-plate", 20}, {"electronic-circuit", 20}}, offer = {type = 'give-item', item = 'loader', count = 1}}, -- thesixthroc: balancing loaders for higher difficulties
    {price = {{"coin", 1000}, {"steel-plate", 40}, {"advanced-circuit", 10}, {"loader", 1}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}}, -- thesixthroc: balancing loaders for higher difficulties
    {price = {{"coin", 3000}, {"express-transport-belt", 10}, {"fast-loader", 1}}, offer = {type = 'give-item', item = 'express-loader', count = 1}}, -- thesixthroc: balancing loaders for higher difficulties
    --{price = {{"coin", 5}, {"stone", 100}}, offer = {type = 'give-item', item = 'landfill', count = 1}},
    {price = {{"coin", 2}, {"steel-plate", 1}, {"explosives", 10}}, offer = {type = 'give-item', item = 'land-mine', count = 1}},
    {price = {{"pistol", 1}}, offer = {type = "give-item", item = "iron-plate", count = 100}}
  }
end
function Public.initial_cargo_boxes()
	return {
		-- 20/05/05: early-game grenades turned off to encourage treasure hunting:
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
		-- 20/05/05: shotguns relatively weak until first tech upgrade, so let's avoid disappointment and's make players get these more from treasure hunting:
		-- {name = "shotgun", count = 1},
		-- {name = "shotgun", count = 1},
		-- {name = "shotgun", count = 1},
		{name = "shotgun-shell", count = math_random(4, 5)},
		{name = "shotgun-shell", count = math_random(4, 5)},
		{name = "firearm-magazine", count = math_random(10, 30)},
		{name = "firearm-magazine", count = math_random(10, 30)},
		{name = "firearm-magazine", count = math_random(10, 30)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)},


		-- 20/05/05: compensate for removed items, aiming to slightly mix up the initial play patterns:
		{name = "loader", count = 1},
		{name = "coal", count = math_random(32, 64)},
		{name = "coal", count = math_random(32, 64)},
		{name = "iron-ore", count = math_random(32, 64)},
		{name = "empty-barrel", count = math_random(16, 32)},
	}
end

function Public.treasure_quantity_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 1) end

function Public.treasure_chest_loot(difficulty, planet)
	
	local function loot_data_sensible(loot_data_item)
		return {weight = loot_data_item[1], d_min = loot_data_item[2], d_max = loot_data_item[3], scaling = loot_data_item[4], name = loot_data_item[5], min_count = loot_data_item[6], max_count = loot_data_item[7]}
	end
	
	local loot_data_raw= {
		{5, 0, 1, false, "railgun-dart", 8, 20}, -- thesixthroc: this should not scale with jumps. reward treasure hunting currency the same at all jump numbers

		--always there (or normally always there):
		{4, 0, 1, false, "pistol", 1, 2},
		{1, 0, 1, false, "gun-turret", 2, 4},
		{6, 0, 1, false, "grenade", 16, 32},
		{4, 0, 1, false, "stone-wall", 33, 99},
		{4, 0, 1, false, "gate", 16, 32},
		{2, 0, 1, false, "radar", 1, 2},
		{1, 0, 1, false, "explosives", 10, 50},
		{6, 0, 1, false, "small-lamp", 8, 32},
		{2, 0, 1, false, "electric-mining-drill", 2, 4},
		{3, 0, 1, false, "long-handed-inserter", 4, 16},
		{0.5, 0, 1, false, "filter-inserter", 4, 16},
		{0.2, 0, 1, false, "stack-filter-inserter", 4, 8},
		{0.5, 0, 1, false, "slowdown-capsule", 8, 16},
		{0.5, 0, 1, false, "destroyer-capsule", 4, 8},
		{0.5, 0, 1, false, "defender-capsule", 4, 8},
		{0.5, 0, 1, false, "distractor-capsule", 4, 8},
		{0.25, 0, 1, false, "rail", 50, 100},
		{0.25, 0, 1, false, "uranium-rounds-magazine", 1, 4},
		{2, 0.15, 1, false, "pumpjack", 1, 3},
		{2, 0.15, 1, false, "pump", 1, 2},

		--shotgun meta:
		{12, -0.2, 0.4, true, "shotgun-shell", 16, 32},
		{8, 0, 0.4, true, "shotgun", 1, 1},
		{12, 0, 1.2, true, "piercing-shotgun-shell", 16, 32},
		{8, 0, 1.2, true, "combat-shotgun", 1, 1},

		--modular armor meta:
		{1, -3, 1, true, "modular-armor", 1, 1},
		{1, 0.3, 1, true, "power-armor", 1, 1},
		-- {0.5, -1,3, true, "power-armor-mk2", 1, 1},
		{2, 0, 1, true, "solar-panel-equipment", 1, 2},
		{2, 0, 1, true, "battery-equipment", 1, 1},
		{1.6, 0, 1, true, "energy-shield-equipment", 1, 2},
		{0.8, 0.5, 1.5, true, "personal-laser-defense-equipment", 1, 1},
		{0.8, 0, 1, true, "night-vision-equipment", 1, 1},
		
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
		{3, -0.1, 0.1, true, "wooden-chest", 8, 16},
		{5, -0.1, 0.1, true, "burner-inserter", 8, 16},
		{1, -0.2, 0.2, true, "offshore-pump", 1, 3},
		{3, -0.2, 0.2, true, "boiler", 3, 6},
		{6, -0.2, 0.2, true, "lab", 1, 2},
		{3, -0.2, 0.2, true, "steam-engine", 2, 4},
		{3, -0.2, 0.2, true, "burner-mining-drill", 2, 4},
		{2.7, 0, 0.15, false, "submachine-gun", 1, 3},
		{0.3, 0, 0.15, false, "vehicle-machine-gun", 1, 1},
		{4, 0, 0.3, true, "iron-chest", 8, 16},
		{4, -0.3, 0.3, true, "light-armor", 1, 1},
		{4, -0.3, 0.3, true, "inserter", 8, 16},
		{8, -0.3, 0.3, true, "small-electric-pole", 16, 24},
		{6, -0.4, 0.4, true, "stone-furnace", 8, 16},
		{8, -0.5, 0.5, true, "firearm-magazine", 32, 128},
		{1, -0.3, 0.3, true, "underground-belt", 4, 8},
		{1, -0.3, 0.3, true, "splitter", 1, 4},
		{1, -0.3, 0.3, true, "assembling-machine-1", 2, 4},
		{5, -0.7, 0.7, true, "transport-belt", 25, 75},

		--mid-game:
		{4, -0.2, 0.7, true, "pipe", 30, 50},
		{1, -0.2, 0.7, true, "pipe-to-ground", 4, 8},
		{4, -0.2, 0.7, true, "iron-gear-wheel", 60, 120},
		{4, -0.2, 0.7, true, "copper-cable", 80, 200},
		{4, -0.2, 0.7, true, "electronic-circuit", 50, 150},
		{3, -0.1, 0.8, true, "fast-transport-belt", 25, 75},
		{3, -0.1, 0.8, true, "fast-underground-belt", 4, 8},
		{3, -0.1, 0.8, true, "fast-splitter", 1, 4},
		{1, 0, 0.6, true, "storage-tank", 2, 6},
		{3, 0, 0.6, true, "heavy-armor", 1, 1},
		{2, 0, 0.7, true, "steel-plate", 25, 75},
		{5, 0, 0.9, true, "piercing-rounds-magazine", 32, 128},
		{2, 0.2, 0.6, true, "engine-unit", 16, 32},
		{3, 0, 1, true, "fast-inserter", 8, 16},
		{4, 0, 1, true, "steel-furnace", 4, 8},
		{4, 0, 1, true, "assembling-machine-2", 2, 4},
		{4, 0, 1, true, "medium-electric-pole", 8, 16},
		{4, 0, 1, true, "accumulator", 4, 8},
		{4, 0, 1, true, "solar-panel", 3, 6},
		{7, 0, 1, true, "steel-chest", 8, 16},
		{2, 0.2, 1, true, "chemical-plant", 1, 3},

		--late-game:
		{3, 0, 1.2, true, "rocket-launcher", 1, 1},
		{5, 0, 1.2, true, "rocket", 16, 32},
		{3, 0, 1.2, true, "land-mine", 16, 32},
		{4, 0.2, 1.2, true, "lubricant-barrel", 4, 10},
		{1, 0.2, 1.2, true, "battery", 50, 150},
		{5, 0.2, 1.8, true, "explosive-rocket", 16, 32},
		{4, 0.2, 1.4, true, "advanced-circuit", 50, 150},
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
		{3, 0.25, 1.75, true, "express-transport-belt", 20, 80},
		{3, 0.25, 1.75, true, "express-underground-belt", 4, 8},
		{3, 0.25, 1.75, true, "express-splitter", 1, 4},
		{3, 0.25, 1.75, true, "electric-furnace", 2, 4},
		{3, 0.25, 1.75, true, "laser-turret", 3, 6},
		{4, 0.4, 1.6, true, "processing-unit", 50, 150},
		{2, 0.6, 1.4, true, "roboport", 1, 1},

		-- super late-game:
		{1, 0.9, 1.1, true, "power-armor-mk2", 1, 1},

		--{2, 0, 1, , "computer", 1, 1},
		--{1, 0.2, 1, , "railgun", 1, 1},
		--{2, 0.3, 1, , "oil-refinery", 2, 4},
		--{1, 0.9, 1, , "personal-roboport-mk2-equipment", 1, 1},
	}
	local specialised_loot_raw = {}

	if planet.type.id == 3 then --stonewrld
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

			{4, 0, 1, false, "stone-wall", 33, 99},
		}
	end

	if planet.type.id == 5 then --uraniumwrld
		specialised_loot_raw = {
			{3, -0.5, 1, true, "steam-turbine", 1, 2},
			{3, -0.5, 1, true, "heat-exchanger", 2, 4},
			{3, -0.5, 1, true, "heat-pipe", 4, 8},
			{2, 0, 2, true, "uranium-rounds-magazine", 8, 64},
			{2, 0.2, 1, false, "nuclear-reactor", 1, 1},
			{2, 0.2, 1, false, "centrifuge", 1, 1},
			{3, 0.3, 1, false, "nuclear-fuel", 1, 1},
			{2, 0.3, 1, false, "fusion-reactor-equipment", 1, 1},
			{1, 0.5, 1, false, "atomic-bomb", 1, 1},
			{2, 0, 1, true, "uranium-cannon-shell", 16, 32},
			{5, 0.4, 1.6, true, "explosive-uranium-cannon-shell", 16, 32},
		}
	end

	if planet.type.id == 14 then --ancient battlefield
		specialised_loot_raw = {
			{5, -0.7, 0.7, true, "light-armor", 1, 1},
			{5, -0.3, 0.9, true, "heavy-armor", 1, 1},
			{8, -0.7, 0.7, true, "firearm-magazine", 32, 128},
			{5, 0.4, 0.7, true, "cannon-shell", 16, 32},
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
			{6, -1, 2, true, "flamethrower", 1, 1},
			{12, -1, 2, true, "flamethrower-ammo", 16, 32},
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

			{12, 0, 0.6, true, "modular-armor", 1, 1},
			{8, -0.2,1, true, "power-armor", 1, 1},
			{4, 0,2, true, "power-armor-mk2", 1, 1},

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

			{3, -0, 1, true, "copper-cable", 20, 80},
			{3, -0.3, 0.6, true, "electronic-circuit", 50, 100},
			{3, 0.2, 1.4, true, "advanced-circuit", 50, 100},
			{3, 0.5, 1.5, true, "processing-unit", 50, 100},
		}
	end

	if planet.type.id == 18 then --swampwrld
		specialised_loot_raw = {
			{24, 0, 1, false, "poison-capsule", 8, 16},
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

function Public.scrap_quantity_multiplier(evolution_factor, mining_drill_productivity_bonus)
	return 1 + 4 * evolution_factor --removed dependence on mining drill tech bonus to nerf tech slightly and make the map more distinctive
end

Public.scrap_yield_amounts = {
	["iron-plate"] = 8,
	["iron-gear-wheel"] = 4,
	["iron-stick"] = 8,
	["copper-plate"] = 8,
	["copper-cable"] = 12,
	["electronic-circuit"] = 4,
	["steel-plate"] = 4,
	["pipe"] = 4,
	["solid-fuel"] = 4,
	["empty-barrel"] = 3,
	["crude-oil-barrel"] = 3,
	["lubricant-barrel"] = 3,
	["petroleum-gas-barrel"] = 3,
	["sulfuric-acid-barrel"] = 3,
	["heavy-oil-barrel"] = 3,
	["light-oil-barrel"] = 3,
	["water-barrel"] = 3,
	["grenade"] = 3,
	["battery"] = 3,
	["explosives"] = 3,
	["advanced-circuit"] = 3,
	["nuclear-fuel"] = 0.1,
	["pipe-to-ground"] = 1,
	["plastic-bar"] = 3,
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
	{name = "iron-plate", chance = 600},
	{name = "iron-gear-wheel", chance = 400},	
	{name = "copper-plate", chance = 400},
	{name = "copper-cable", chance = 200},	
	{name = "electronic-circuit", chance = 150},
	{name = "steel-plate", chance = 100},
	{name = "pipe", chance = 75},
	{name = "iron-stick", chance = 30},
	{name = "solid-fuel", chance = 20},
	{name = "battery", chance = 10},
	{name = "crude-oil-barrel", chance = 10},
	{name = "petroleum-gas-barrel", chance = 7},
	{name = "sulfuric-acid-barrel", chance = 7},
	{name = "heavy-oil-barrel", chance = 7},
	{name = "light-oil-barrel", chance = 7},
	{name = "lubricant-barrel", chance = 4},
	{name = "empty-barrel", chance = 4},
	{name = "water-barrel", chance = 4},
	{name = "green-wire", chance = 4},
	{name = "red-wire", chance = 4},
	{name = "grenade", chance = 3},
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