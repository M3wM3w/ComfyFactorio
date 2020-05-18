local Scrap_table = require "maps.scrapyard.table"

local max_spill = 60
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt

local function create_particles(surface, name, position, amount, cause_position)
	local direction_mod = (-100 + math_random(0,200)) * 0.0004
	local direction_mod_2 = (-100 + math_random(0,200)) * 0.0004

	if cause_position then
		direction_mod = (cause_position.x - position.x) * 0.025
		direction_mod_2 = (cause_position.y - position.y) * 0.025
	end

	for i = 1, amount, 1 do
		local m = math_random(4, 10)
		local m2 = m * 0.005

		surface.create_particle({
			name = name,
			position = position,
			frame_speed = 1,
			vertical_speed = 0.130,
			height = 0,
			movement = {
				(m2 - (math_random(0, m) * 0.01)) + direction_mod,
				(m2 - (math_random(0, m) * 0.01)) + direction_mod_2
			}
		})
	end
end

local function mining_chances_scrap()
	local data = {
		{name = "iron-plate", chance = 400},
		{name = "iron-gear-wheel", chance = 390},
		{name = "copper-plate", chance = 400},
		{name = "copper-cable", chance = 380},
		{name = "electronic-circuit", chance = 150},
		{name = "steel-plate", chance = 120},
		{name = "solid-fuel", chance = 89},
		{name = "pipe", chance = 75},
		{name = "iron-stick", chance = 50},
		{name = "battery", chance = 20},
		{name = "empty-barrel", chance = 10},
		{name = "crude-oil-barrel", chance = 10},
		{name = "lubricant-barrel", chance = 10},
		{name = "petroleum-gas-barrel", chance = 10},
		{name = "sulfuric-acid-barrel", chance = 10},
		{name = "heavy-oil-barrel", chance = 10},
		{name = "light-oil-barrel", chance = 10},
		{name = "water-barrel", chance = 10},
		{name = "green-wire", chance = 10},
		{name = "red-wire", chance = 10},
		{name = "explosives", chance = 5},
		{name = "advanced-circuit", chance = 5},
		{name = "nuclear-fuel", chance = 1},
		{name = "pipe-to-ground", chance = 10},
		{name = "plastic-bar", chance = 5},
		{name = "rocket-fuel", chance = 3},
		{name = "engine-unit", chance = 4},
		{name = "logistic-robot", chance = 1},
		{name = "construction-robot", chance = 1},
		{name = "land-mine", chance = 3},
		{name = "grenade", chance = 10},
		{name = "rocket", chance = 3},
		{name = "explosive-rocket", chance = 3},
		{name = "cannon-shell", chance = 2},
		{name = "explosive-cannon-shell", chance = 2},
		{name = "explosive-uranium-cannon-shell", chance = 1},
		{name = "artillery-shell", chance = 1},
		{name = "cluster-grenade", chance = 2},
		{name = "defender-capsule", chance = 5},
		{name = "destroyer-capsule", chance = 1},
		{name = "distractor-capsule", chance = 2}
	}
	return data
end
local function mining_chances_ores()
	local data = {
		{name = "iron-ore", chance = 570},
		{name = "copper-ore", chance = 570},
		{name = "stone", chance = 550},
		{name = "coal", chance = 545},
		{name = "uranium-ore", chance = 1},
	}
	return data
end

local function ore_yield_amounts()
	local data = {
		["iron-ore"] = 28,
		["copper-ore"] = 28,
		["stone"] = 20,
		["coal"] = 28,
		["uranium-ore"] = 1,
		["mineable-wreckage"] = 1,
	}
	return data
end

local function scrap_yield_amounts()
	local data = {
		["iron-plate"] = 12,
		["iron-gear-wheel"] = 12,
		["iron-stick"] = 12,
		["copper-plate"] = 12,
		["copper-cable"] = 12,
		["electronic-circuit"] = 4,
		["steel-plate"] = 4,
		["pipe"] = 5,
		["solid-fuel"] = 6,
		["empty-barrel"] = 3,
		["crude-oil-barrel"] = 3,
		["lubricant-barrel"] = 3,
		["petroleum-gas-barrel"] = 3,
		["sulfuric-acid-barrel"] = 3,
		["heavy-oil-barrel"] = 3,
		["light-oil-barrel"] = 3,
		["water-barrel"] = 3,
		["battery"] = 2,
		["explosives"] = 4,
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
		["distractor-capsule"] = 0.3,
		["mineable-wreckage"] = 1,
	}
	return data
end

local scrap_raffle_scrap = {}
for _, t in pairs (mining_chances_scrap()) do
	for x = 1, t.chance, 1 do
		table.insert(scrap_raffle_scrap, t.name)
	end
end

local size_of_scrap_raffle = #scrap_raffle_scrap

local scrap_raffle_ores = {}
for _, t in pairs (mining_chances_ores()) do
	for x = 1, t.chance, 1 do
		table.insert(scrap_raffle_ores, t.name)
	end
end

local size_of_ore_raffle = #scrap_raffle_ores

local function get_amount(data)
	local entity = data.entity
	local this = data.this
	local scrap = data.scrap
	local scrap_amount = scrap_yield_amounts()
	local distance_to_center = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))

	local distance_modifier = 0.25
	local base_amount = 35
	local maximum_amount = 100
	if this.rocks_yield_ore_distance_modifier then distance_modifier = this.rocks_yield_ore_distance_modifier end
	if this.rocks_yield_ore_base_amount then base_amount = this.rocks_yield_ore_base_amount end
	if this.rocks_yield_ore_maximum_amount then maximum_amount = this.rocks_yield_ore_maximum_amount end

	local amount = base_amount + (distance_to_center * distance_modifier)
	if amount > maximum_amount then amount = maximum_amount end

	local m = (70 + math_random(0, 60)) * 0.01
	if this.scrap_enabled then
		local amount_bonus = (game.forces.enemy.evolution_factor * 2) + (game.forces.player.mining_drill_productivity_bonus * 2)
		local r1 = math.ceil(scrap_amount[scrap] * (0.3 + (amount_bonus * 0.3)))
		local r2 = math.ceil(scrap_amount[scrap] * (1.7 + (amount_bonus * 1.7)))
		if not r1 or not r2 then return end
		amount = math.random(r1, r2)
	else
		amount = math_floor(amount * ore_yield_amounts()[entity.name] * m)
	end
	if amount < 1 then amount = 1 end

	return amount
end

local function scrap_randomness(data)
	local entity = data.entity
	local this = data.this
	local player = data.player
	local scrap

	--if this.scrap_enabled[player.index] then
	--	scrap = scrap_raffle_scrap[math.random(1, size_of_scrap_raffle)]
	--else
	--	scrap = scrap_raffle_ores[math.random(1, size_of_ore_raffle)]
	--end

	if this.scrap_enabled then
		scrap = scrap_raffle_scrap[math.random(1, size_of_scrap_raffle)]
	else
		scrap = scrap_raffle_ores[math.random(1, size_of_ore_raffle)]
	end

	data.scrap = scrap

	local scrap_amount = get_amount(data)

	local position = {x = entity.position.x, y = entity.position.y}

	entity.destroy()

	--local scrap_amount = math_floor(amount * 0.85) + 1

	if scrap_amount > max_spill then
		player.surface.spill_item_stack(position,{name = scrap, count = max_spill}, true)
		scrap_amount = scrap_amount - max_spill
		local inserted_count = player.insert({name = scrap, count = scrap_amount})
		scrap_amount = scrap_amount - inserted_count
		if scrap_amount > 0 then
			player.surface.spill_item_stack(position,{name = scrap, count = scrap_amount}, true)
		end
	else
		player.surface.spill_item_stack(position,{name = scrap, count = scrap_amount}, true)
	end

	player.surface.create_entity({
		name = "flying-text",
		position = position,
		text = "+" .. scrap_amount .. " [img=item/" .. scrap .. "]", 
		color = {r = 200, g = 160, b = 30}
	})

	create_particles(player.surface, "shell-particle", position, 64, {x = player.position.x, y = player.position.y})
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name ~= "mineable-wreckage" then return end
	local player = game.players[event.player_index]
	local this = Scrap_table.get_table()
	if not player then
		return
	end

	event.buffer.clear()

	local data = {
		this = this,
		entity = entity,
		player = player
	}

	scrap_randomness(data)
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)