local Public = {}
local Rand = require 'maps.chronosphere.random'
local Chrono_table = require 'maps.chronosphere.table'

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

	return 1 + ((difficulty - 1) * slope)
end
-- SLOPE GUIDE
-- slope 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- slope 4/5 -> {0.20, 0.40, 0.60, 0.80, 1.20, 2.40, 4.00}
-- slope 3/5 -> {0.15, 0.30, 0.45, 0.60, 0.90, 1.80, 3.00}
-- slope 2/5 -> {0.10, 0.20, 0.30, 0.40, 0.60, 1.20, 2.00}

local function difficulty_exp(difficulty,exponent)

	return math_pow(difficulty,exponent)
end
-- EXPONENT GUIDE
-- exponent 1 -> {0.25, 0.50, 0.75, 1.00, 1.50, 3.00, 5.00}
-- exponent 1.5 -> {0.13, 0.35, 0.65, 1.00, 1.84, 5.20, 11.18}
-- exponent 2 -> {0.06, 0.25, 0.56, 1.00, 2.25, 9.00, 25.00}
-- exponent -1.2 -> {5.28, 2.30, 1.41, 1.00, 0.61, 0.27, 0.14}



---- CHRONO/POLLUTION BALANCE ----

function Public.pollution_filter_upgrade_factor(upgrades2)
	return 1 / (1 + upgrades2 / 4)
end

function Public.machine_pollution_transfer_from_inside_factor(difficulty, filter_upgrades) return 3 * Public.pollution_filter_upgrade_factor(filter_upgrades) * difficulty_sloped(difficulty, 3/5) end


function Public.passive_planet_jumptime(jumps)
	local mins

	if jumps < 20 then
		mins = 30 + 3 * jumps
	else
		mins = 90
	end

	return mins * 60
end

function Public.passive_pollution_rate(jumps, difficulty, filter_upgrades)
	local baserate = 5 * jumps

	local modifiedrate = baserate * Public.pollution_filter_upgrade_factor(filter_upgrades) * math_max(0, difficulty_sloped(difficulty, 5/4))

	return modifiedrate
end

function Public.pollution_per_MJ_actively_charged(jumps, difficulty, filter_upgrades)

	local baserate = 2 * (10 + jumps)

	local modifiedrate = baserate * Public.pollution_filter_upgrade_factor(filter_upgrades)

	if difficulty < 1 then
		modifiedrate = modifiedrate * difficulty_sloped(difficulty, 1)
	else
		modifiedrate = modifiedrate
	end

	return modifiedrate
end

function Public.countdown_pollution_rate(jumps, difficulty)
	local baserate = 40 * (10 + jumps) * math_max(0, difficulty_sloped(difficulty, 5/4))

	local modifiedrate = baserate -- thesixthroc: Constant, because part of drama of planet progression. Interpret this as hyperwarp portal pollution

	return modifiedrate
end

function Public.post_jump_initial_pollution(jumps, difficulty)
	local baserate = 200 * (1 + jumps) * math_max(0, difficulty_sloped(difficulty, 5/4))

	local modifiedrate = baserate -- thesixthroc: Constant, because part of drama of planet progression. Interpret this as hyperwarp portal pollution

	return modifiedrate
end


function Public.pollution_spent_per_attack(difficulty) return math_ceil(60 * difficulty_exp(difficulty, -1.4)) end

function Public.defaultai_attack_pollution_consumption_modifier(difficulty) return 0.8 * difficulty_exp(difficulty, -1.4) end

function Public.MJ_needed_for_full_charge(difficulty, jumps)
	local baserate = 2000 + 500 * jumps

	local modifiedrate
	if difficulty <= 1 then modifiedrate = baserate end
	if difficulty > 1 and jumps>0 then modifiedrate = baserate + 1000 end
	return modifiedrate
end



----- GENERAL BALANCE ----

Public.Chronotrain_max_HP = 10000
Public.Chronotrain_HP_repaired_per_pack = 150
Public.Tech_price_multiplier = 0.6

Public.starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 4, ['raw-fish'] = 4, ['wood'] = 16}
Public.wagon_starting_items = {{name = 'firearm-magazine', count = 16},{name = 'iron-plate', count = 16},{name = 'wood', count = 16},{name = 'burner-mining-drill', count = 8}}

function Public.jumps_until_overstay_is_on(difficulty) --both overstay penalties, and evoramp
	local objective = Chrono_table.get_table()
	if not objective.config.overstay_penalty then return 999 end
	if not difficulty then return 3 end
	if difficulty > 1 then
		return 2
	elseif difficulty == 1 then
		return 3
	else
		return 5
	end
end

function Public.player_gun_speed_modifiers() -- modifiers are fractional
    local data = {
        ['artillery-shell'] = 0,
        ['biological'] = 0,
        ['bullet'] = 0,
        ['cannon-shell'] = 0,
        ['capsule'] = 0,
        ['combat-robot-beam'] = 0,
        ['combat-robot-laser'] = 0,
        ['electric'] = 0,
        ['flamethrower'] = 0, --these nerfs are elsewhere for finer control
        ['grenade'] = -0.2,
        ['landmine'] = 0,
        ['laser-turret'] = 0,
        ['melee'] = 0, -- doesn't do anything
        ['railgun'] = 0,
        ['rocket'] = 0,
        ['shotgun-shell'] = 0
    }
    return data
end
function Public.player_ammo_damage_modifiers() -- bullet affects gun turrets, but flamethrower does not affect flamer turrets
    local data = {
        ['artillery-shell'] = 0,
        ['biological'] = 0,
        ['bullet'] = 0,
        ['cannon-shell'] = 0,
        ['capsule'] = 0,
        ['combat-robot-beam'] = 0,
        ['combat-robot-laser'] = 0,
        ['electric'] = 0,
        ['flamethrower'] = 0, --these nerfs are elsewhere for finer control
        ['grenade'] = 0,
        ['landmine'] = 0,
        ['laser-turret'] = 0,
        ['melee'] = 0, -- doesn't do anything
        ['railgun'] = 0,
        ['rocket'] = 0,
        ['shotgun-shell'] = 0
    }
    return data
end

function Public.coin_reward_per_second_jumped_early(seconds, difficulty)
	local minutes = seconds / 60
	local amount = minutes * 25 * difficulty_sloped(difficulty, 0) -- No difficulty scaling seems best. (if this is changed, change the code so that coins are not awarded on the first jump)
	return math_max(0,math_floor(amount))
end

function Public.upgrades_coin_cost_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 3/5) end

function Public.flamers_nerfs_size(jumps, difficulty) return 0.02 * jumps * difficulty_sloped(difficulty, 1/2) end

function Public.max_new_attack_group_size(difficulty) return math_min(200,math_floor(120 * difficulty_sloped(difficulty, 1/2))) end

function Public.fish_market_base_modifier(difficulty) return math_floor(500 / difficulty_sloped(difficulty, 1/2)) end

function Public.evoramp50_multiplier_per_10s(difficulty) return (1 + 1/600 * difficulty_sloped(difficulty, 1)) end

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
	cavewrld = 1,
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
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'stone', count = 50}}, -- needed?
    {price = {{"coin", 100}}, offer = {type = 'give-item', item = 'coal', count = 50}},
    {price = {{"coin", 400}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}},
    {price = {{"coin", 50}, {"empty-barrel", 1}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
    {price = {{"coin", 500}, {"steel-plate", 20}, {"electronic-circuit", 20}}, offer = {type = 'give-item', item = 'loader', count = 1}},
    {price = {{"coin", 1000}, {"steel-plate", 40}, {"advanced-circuit", 10}, {"loader", 1}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
    {price = {{"coin", 3000}, {"express-transport-belt", 10}, {"fast-loader", 1}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
    --{price = {{"coin", 5}, {"stone", 100}}, offer = {type = 'give-item', item = 'landfill', count = 1}},
    {price = {{"coin", 2}, {"steel-plate", 1}, {"explosives", 10}}, offer = {type = 'give-item', item = 'land-mine', count = 1}},
    {price = {{"pistol", 1}}, offer = {type = "give-item", item = "iron-plate", count = 100}}
  }
end
function Public.initial_cargo_boxes()
	return {
		{name = "loader", count = 1},
		{name = "coal", count = math_random(32, 64)},
		{name = "coal", count = math_random(32, 64)},
		{name = "iron-ore", count = math_random(32, 128)},
		{name = "copper-ore", count = math_random(32, 128)},
		{name = "empty-barrel", count = math_random(16, 32)},
		{name = "submachine-gun", count = 1},
		{name = "submachine-gun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun", count = 1},
		{name = "shotgun-shell", count = math_random(4, 5)},
		{name = "shotgun-shell", count = math_random(4, 5)},
		{name = "land-mine", count = math_random(6, 18)},
		{name = "grenade", count = math_random(2, 3)},
		{name = "grenade", count = math_random(2, 3)},
		{name = "grenade", count = math_random(2, 3)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-gear-wheel", count = math_random(7, 15)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "iron-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "copper-plate", count = math_random(15, 23)},
		{name = "firearm-magazine", count = math_random(10, 30)},
		{name = "firearm-magazine", count = math_random(10, 30)},
		{name = "firearm-magazine", count = math_random(10, 30)},
		{name = "rail", count = math_random(16, 24)},
		{name = "rail", count = math_random(16, 24)}
	}
end

function Public.treasure_quantity_difficulty_scaling(difficulty) return difficulty_sloped(difficulty, 1) end

function Public.Base_ore_loot_yield(jumps, scrap)
	if scrap then
		return 4 + 0.5 * jumps
	else
		return 15 + 3 * jumps
	end
end

function Public.scrap()
	local main_loot = {
		["iron-plate"] = {amount = 5, chance = 400},
		["iron-gear-wheel"] = {amount = 3, chance = 250},
		["iron-stick"] = {amount = 2, chance = 100},
		["copper-plate"] = {amount = 5, chance = 400},
		["copper-cable"] = {amount = 8, chance = 150},
		["electronic-circuit"] = {amount = 3, chance = 100},
		["steel-plate"] = {amount = 4, chance = 100},
		["pipe"] = {amount = 3, chance = 50},
		["pipe-to-ground"] = {amount = 1, chance = 10},
		["battery"] = {amount = 3, chance = 10},
		["explosives"] = {amount = 3, chance = 5},
		["advanced-circuit"] = {amount = 5, chance = 3},
		["plastic-bar"] = {amount = 5, chance = 5},
		["processing-unit"] = {amount = 2, chance = 1},
		["used-up-uranium-fuel-cell"] = {amount = 1, chance = 4},
		["uranium-fuel-cell"] = {amount = 0.3, chance = 1},
		["rocket-control-unit"] = {amount = 0.3, chance = 1},
		["low-density-structure"] = {amount = 0.5, chance = 2},
		["heat-pipe"] = {amount = 1, chance = 1},
		["engine-unit"] = {amount = 3, chance = 3},
		["electric-engine-unit"] = {amount = 2, chance = 2},
		["flying-robot-frame"] = {amount = 1, chance = 2},
		["logistic-robot"] = {amount = 0.3, chance = 1},
		["construction-robot"] = {amount = 0.3, chance = 1},
		["land-mine"] = {amount = 1, chance = 1},
		["rocket"] = {amount = 2, chance = 1},
		["explosive-rocket"] = {amount = 2, chance = 1},
		["defender-capsule"] = {amount = 2, chance = 1},
		["destroyer-capsule"] = {amount = 0.3, chance = 1},
		["distractor-capsule"] = {amount = 0.3, chance = 1}
	}
	local second_loot = {
		["cannon-shell"] = {amount = 0.1, chance = 5},
		["explosive-cannon-shell"] = {amount = 0.1, chance = 4},
		["uranium-cannon-shell"] = {amount = 0.1, chance = 3},
		["explosive-uranium-cannon-shell"] = {amount = 0.1, chance = 2},
		["artillery-shell"] = {amount = 0.1, chance = 1},
		["cluster-grenade"] = {amount = 0.2, chance = 20},
		["firearm-magazine"] = {amount = 0.4, chance = 70},
		["piercing-rounds-magazine"] = {amount = 0.2, chance = 55},
		["uranium-rounds-magazine"] = {amount = 0.1, chance = 40},
		["nuclear-fuel"] = {amount = 0.1, chance = 3},
		["rocket-fuel"] = {amount = 0.3, chance = 8},
		["grenade"] = {amount = 0.3, chance = 40},
		["solid-fuel"] = {amount = 0.4, chance = 50},
		["empty-barrel"] = {amount = 0.1, chance = 50},
		["crude-oil-barrel"] = {amount = 0.1, chance = 70},
		["lubricant-barrel"] = {amount = 0.1, chance = 40},
		["petroleum-gas-barrel"] = {amount = 0.1, chance = 60},
		["heavy-oil-barrel"] = {amount = 0.1, chance = 70},
		["light-oil-barrel"] = {amount = 0.1, chance = 70},
		["water-barrel"] = {amount = 0.1, chance = 40},
	}

	local scrap_raffle = {}
	for k, t in pairs (main_loot) do
		for x = 1, t.chance, 1 do
			table.insert(scrap_raffle, {name = k, amount = t.amount})
		end
	end

	local second_raffle = {}
	for k, t in pairs (second_loot) do
		for x = 1, t.chance, 1 do
			table.insert(second_raffle, {name = k, amount = t.amount})
		end
	end
	Rand.shuffle(scrap_raffle)
	Rand.shuffle(second_raffle)

	return {main = scrap_raffle, second = second_raffle}
end

return Public
