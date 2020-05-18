local Event = require 'utils.event'
local max_spill = 40
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
local insert = table.insert

local scrap_yeild = {
	["mineable-wreckage"] = 1
}

local weights = {
	{"iron-ore", 25},
	{"copper-ore",17},
	{"coal",13},
	{"stone",10},
	{"uranium-ore",2}
}

local texts = {
	["iron-ore"] = {"Iron ore", {r = 200, g = 200, b = 180}},
	["copper-ore"] = {"Copper ore", {r = 221, g = 133, b = 6}},
	["uranium-ore"] = {"Uranium ore", {r= 50, g= 250, b= 50}},
	["coal"] = {"Coal", {r = 0, g = 0, b = 0}},
	["stone"] = {"Stone", {r = 200, g = 160, b = 30}},
}

local particles = {
	["iron-ore"] = "iron-ore-particle",
	["copper-ore"] = "copper-ore-particle",
	["uranium-ore"] = "coal-particle",
	["coal"] = "coal-particle",
	["stone"] = "stone-particle"
}

local ore_raffle = {}
for _, t in pairs (weights) do
	for x = 1, t[2], 1 do
		insert(ore_raffle, t[1])
	end
end

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

		surface.create_entity({
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

local function get_amount(entity)
	local distance_to_center = math_floor(math_sqrt(entity.position.x ^ 2 + entity.position.y ^ 2))

	local distance_modifier = 0.25
	local base_amount = 35
	local maximum_amount = 100
	if global.rocks_yield_ore_distance_modifier then distance_modifier = global.rocks_yield_ore_distance_modifier end
	if global.rocks_yield_ore_base_amount then base_amount = global.rocks_yield_ore_base_amount end
	if global.rocks_yield_ore_maximum_amount then maximum_amount = global.rocks_yield_ore_maximum_amount end

	local amount = base_amount + (distance_to_center * distance_modifier)
	if amount > maximum_amount then amount = maximum_amount end

	local m = (70 + math_random(0, 60)) * 0.01

	amount = math_floor(amount * scrap_yeild[entity.name] * m)
	if amount < 1 then amount = 1 end

	return amount
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if not scrap_yeild[entity.name] then return end

	event.buffer.clear()

	local ore = ore_raffle[math_random(1, #ore_raffle)]
	local player = game.players[event.player_index]
	local count = get_amount(entity)
	local position = {x = entity.position.x, y = entity.position.y}

	player.surface.create_entity({name = "flying-text", position = position, text = "+" .. count .. " [img=item/" .. ore .. "]", color = {r = 200, g = 160, b = 30}})
	create_particles(player.surface, particles[ore], position, 64, {x = player.position.x, y = player.position.y})

	--entity.destroy()

	if count > max_spill then
		player.surface.spill_item_stack(position,{name = ore, count = max_spill}, true)
		count = count - max_spill
		local inserted_count = player.insert({name = ore, count = count})
		count = count - inserted_count
		if count > 0 then
			player.surface.spill_item_stack(position,{name = ore, count = count}, true)
		end
	else
		player.surface.spill_item_stack(position,{name = ore, count = count}, true)
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if not scrap_yeild[entity.name] then return end

	local surface = entity.surface
	local ore = ore_raffle[math_random(1, #ore_raffle)]
	local pos = {entity.position.x, entity.position.y}
	create_particles(surface, particles[ore], pos, 16, false)

	if event.cause then
		if event.cause.valid then
			if event.cause.force.index == 2 or event.cause.force.index == 3 then
				entity.destroy()
				return
			end
		end
	end
	entity.destroy()
	surface.spill_item_stack(pos,{name = ore, count = math_random(8,12)}, true)
end

Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)