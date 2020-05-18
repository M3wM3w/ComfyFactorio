--mineable-wreckage yields scrap -- by mewmew

local mining_chance_weights = {
	{name = "iron-plate", chance = 1000},
	{name = "iron-gear-wheel", chance = 750},
	{name = "copper-plate", chance = 750},
	{name = "copper-cable", chance = 500},
	{name = "electronic-circuit", chance = 300},
	{name = "steel-plate", chance = 200},
	{name = "solid-fuel", chance = 150},
	{name = "pipe", chance = 100},
	{name = "iron-stick", chance = 50},
	{name = "battery", chance = 20},
	{name = "empty-barrel", chance = 10},
	{name = "crude-oil-barrel", chance = 30},
	{name = "lubricant-barrel", chance = 20},
	{name = "petroleum-gas-barrel", chance = 15},
	{name = "sulfuric-acid-barrel", chance = 15},
	{name = "heavy-oil-barrel", chance = 15},
	{name = "light-oil-barrel", chance = 15},
	{name = "water-barrel", chance = 10},
	{name = "green-wire", chance = 10},
	{name = "red-wire", chance = 10},
	{name = "explosives", chance = 5},
	{name = "advanced-circuit", chance = 5},
	{name = "nuclear-fuel", chance = 1},
	{name = "pipe-to-ground", chance = 10},
	{name = "plastic-bar", chance = 5},
	{name = "processing-unit", chance = 2},
	{name = "used-up-uranium-fuel-cell", chance = 1},
	{name = "uranium-fuel-cell", chance = 1},
	{name = "rocket-fuel", chance = 3},
	{name = "rocket-control-unit", chance = 1},
	{name = "low-density-structure", chance = 1},
	{name = "heat-pipe", chance = 1},
	{name = "engine-unit", chance = 4},
	{name = "electric-engine-unit", chance = 2},
	{name = "logistic-robot", chance = 1},
	{name = "construction-robot", chance = 1},

	{name = "land-mine", chance = 3},
	{name = "grenade", chance = 10},
	{name = "rocket", chance = 3},
	{name = "explosive-rocket", chance = 3},
	{name = "cannon-shell", chance = 2},
	{name = "explosive-cannon-shell", chance = 2},
	{name = "uranium-cannon-shell", chance = 1},
	{name = "explosive-uranium-cannon-shell", chance = 1},
	{name = "artillery-shell", chance = 1},
	{name = "cluster-grenade", chance = 2},
	{name = "defender-capsule", chance = 5},
	{name = "destroyer-capsule", chance = 1},
	{name = "distractor-capsule", chance = 2}
}

local scrap_yield_amounts = {
	["iron-plate"] = 16,
	["iron-gear-wheel"] = 8,
	["iron-stick"] = 16,
	["copper-plate"] = 16,
	["copper-cable"] = 24,
	["electronic-circuit"] = 8,
	["steel-plate"] = 4,
	["pipe"] = 8,
	["solid-fuel"] = 4,
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
	["distractor-capsule"] = 0.3
}

local scrap_raffle = {}
for _, t in pairs (mining_chance_weights) do
	for x = 1, t.chance, 1 do
		table.insert(scrap_raffle, t.name)
	end
end

local size_of_scrap_raffle = #scrap_raffle

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name ~= "mineable-wreckage" then return end

	event.buffer.clear()

	local scrap = scrap_raffle[math.random(1, size_of_scrap_raffle)]

	local amount_bonus = (game.forces.enemy.evolution_factor * 2) + (game.forces.player.mining_drill_productivity_bonus * 2)
	local r1 = math.ceil(scrap_yield_amounts[scrap] * (0.3 + (amount_bonus * 0.3)))
	local r2 = math.ceil(scrap_yield_amounts[scrap] * (1.7 + (amount_bonus * 1.7)))
	local amount = math.random(r1, r2)

	local player = game.players[event.player_index]
	local inserted_count = player.insert({name = scrap, count = amount})

	if inserted_count ~= amount then
		local amount_to_spill = amount - inserted_count
		entity.surface.spill_item_stack(entity.position,{name = scrap, count = amount_to_spill}, true)
	end

	entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "+" .. amount .. " [img=item/" .. scrap .. "]",
		color = {r=0.98, g=0.66, b=0.22}
	})
end

local Event = require 'utils.event'
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
