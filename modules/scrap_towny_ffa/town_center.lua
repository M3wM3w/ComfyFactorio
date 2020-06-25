local Team = require "modules.scrap_towny_ffa.team"
local Building = require "modules.scrap_towny_ffa.building"

local Public = {}

local math_random = math.random
local table_insert = table.insert
local math_floor = math.floor
local table_shuffle = table.shuffle_table

local town_radius = 27
local radius_between_towns = 160
local ore_amount = 250

local colors = {}
local c1 = 250
local c2 = 210
local c3 = -40
for v = c1, c2, c3 do
	table_insert(colors, {0, 0, v})
end
for v = c1, c2, c3 do
	table_insert(colors, {0, v, 0})
end
for v = c1, c2, c3 do
	table_insert(colors, {v, 0, 0})
end
for v = c1, c2, c3 do
	table_insert(colors, {0, v, v})
end
for v = c1, c2, c3 do
	table_insert(colors, {v, v, 0})
end
for v = c1, c2, c3 do
	table_insert(colors, {v, 0, v})
end

local town_wall_vectors = {}
for x = 2, town_radius, 1 do
	table_insert(town_wall_vectors, {x, town_radius})
	table_insert(town_wall_vectors, {x * -1, town_radius})
	table_insert(town_wall_vectors, {x, town_radius * -1})
	table_insert(town_wall_vectors, {x * -1, town_radius * -1})
end
for y = 2, town_radius - 1, 1 do
	table_insert(town_wall_vectors, {town_radius, y})
	table_insert(town_wall_vectors, {town_radius, y * -1})
	table_insert(town_wall_vectors, {town_radius * -1, y})
	table_insert(town_wall_vectors, {town_radius * -1, y * -1})
end

local gate_vectors_horizontal = {}
for x = -1, 1, 1 do
	table_insert(gate_vectors_horizontal, {x, town_radius})
	table_insert(gate_vectors_horizontal, {x, town_radius * -1})
end
local gate_vectors_vertical = {}
for y = -1, 1, 1 do
	table_insert(gate_vectors_vertical, {town_radius, y})
	table_insert(gate_vectors_vertical, {town_radius * -1, y})
end

local resource_vectors = {}
resource_vectors[1] = {}
for x = 7, 24, 1 do
	for y = 7, 24, 1 do	
		table_insert(resource_vectors[1], {x, y})
	end
end
resource_vectors[2] = {}
for _, vector in pairs(resource_vectors[1]) do table_insert(resource_vectors[2], {vector[1] * -1, vector[2]}) end
resource_vectors[3] = {}
for _, vector in pairs(resource_vectors[1]) do table_insert(resource_vectors[3], {vector[1] * -1, vector[2] * -1}) end
resource_vectors[4] = {}
for _, vector in pairs(resource_vectors[1]) do table_insert(resource_vectors[4], {vector[1], vector[2] * -1}) end

local additional_resource_vectors = {}
additional_resource_vectors[1] = {}
for x = 10, 22, 1 do
	for y = -4, 4, 1 do	
		table_insert(additional_resource_vectors[1], {x, y})
	end
end
additional_resource_vectors[2] = {}
for _, vector in pairs(additional_resource_vectors[1]) do table_insert(additional_resource_vectors[2], {vector[1] * -1, vector[2]}) end
additional_resource_vectors[3] = {}
for y = 10, 22, 1 do
	for x = -4, 4, 1 do	
		table_insert(additional_resource_vectors[3], {x, y})
	end
end
additional_resource_vectors[4] = {}
for _, vector in pairs(additional_resource_vectors[3]) do table_insert(additional_resource_vectors[4], {vector[1], vector[2] * -1}) end

local market_collide_vectors = {{-1, 1},{0, 1},{1, 1},{1, 0},{1, -1}}

local clear_whitelist_types = {
	["simple-entity"] = true,
	["resource"] = true,
	["cliff"] = true,
	["tree"] = true,
}

local starter_supplies = {
	{name = "raw-fish", count = 3},
	{name = "grenade", count = 3},
	{name = "stone", count = 32},
	{name = "land-mine", count = 4},
	{name = "iron-gear-wheel", count = 16},
	{name = "iron-plate", count = 32},
	{name = "copper-plate", count = 16},
	{name = "shotgun", count = 1},
	{name = "shotgun-shell", count = 8},
	{name = "firearm-magazine", count = 16},
	{name = "firearm-magazine", count = 16},
	{name = "gun-turret", count = 2},	
}

local function count_nearby_ore(surface, position, ore_name)
	local count = 0
	local r = town_radius + 8
	for _, e in pairs(surface.find_entities_filtered({area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}, force = "neutral", name = ore_name})) do
		count = count + e.amount
	end
	return count
end

local function draw_town_spawn(player_name)
	local market = global.towny.town_centers[player_name].market
	local position = market.position
	local surface = market.surface

	local area = {{position.x - (town_radius + 1), position.y - (town_radius + 1)}, {position.x + (town_radius + 1), position.y + (town_radius + 1)}}

	-- remove other than cliffs, rocks and ores and trees
	for _, e in pairs(surface.find_entities_filtered({area = area, force = "neutral"})) do
		if not clear_whitelist_types[e.type] then
			e.destroy()
		end
	end

	-- create walls
	for _, vector in pairs(gate_vectors_horizontal) do
		local p = {position.x + vector[1], position.y + vector[2]}
		--p = surface.find_non_colliding_position("gate", p, 64, 1)
		if p then
			surface.create_entity({name = "gate", position = p, force = player_name, direction = 2})
		end
	end
	for _, vector in pairs(gate_vectors_vertical) do
		local p = {position.x + vector[1], position.y + vector[2]}	
		--p = surface.find_non_colliding_position("gate", p, 64, 1)
		if p then
			surface.create_entity({name = "gate", position = p, force = player_name, direction = 0})
		end
	end

	for _, vector in pairs(town_wall_vectors) do
		local p = {position.x + vector[1], position.y + vector[2]}
		--p = surface.find_non_colliding_position("stone-wall", p, 64, 1)
		if p then
			surface.create_entity({name = "stone-wall", position = p, force = player_name})
		end
	end

	-- ore patches
	local ores = {"iron-ore", "copper-ore", "stone", "coal"}
	table_shuffle(ores)
	
	for i = 1, 4, 1 do
		if count_nearby_ore(surface, position, ores[i]) < 200000 then
			for _, vector in pairs(resource_vectors[i]) do
				local p = {position.x + vector[1], position.y + vector[2]} 
				p = surface.find_non_colliding_position(ores[i], p, 64, 1)
				if p then 
					surface.create_entity({name = ores[i], position = p, amount = ore_amount})
				end
			end
		end
	end

	-- starter chests
	for _, item_stack in pairs(starter_supplies) do
		local m1 = -8 + math_random(0, 16)
		local m2 = -8 + math_random(0, 16)		
		local p = {position.x + m1, position.y + m2}
		p = surface.find_non_colliding_position("wooden-chest", p, 64, 1)
		if p then 
			local e = surface.create_entity({name = "wooden-chest", position = p, force = player_name})
			local inventory = e.get_inventory(defines.inventory.chest)
			inventory.insert(item_stack)
		end
	end

	local vector_indexes = {1,2,3,4}
	table_shuffle(vector_indexes)

	-- trees
	--local tree = "tree-0" .. math_random(1, 9)
	--for _, vector in pairs(additional_resource_vectors[vector_indexes[1]]) do
	--	if math_random(1, 6) == 1 then
	--		local p = {position.x + vector[1], position.y + vector[2]}
	--		p = surface.find_non_colliding_position(tree, p, 64, 1)
	--		if p then
	--			surface.create_entity({name = tree, position = p})
	--		end
	--	end
	--end

	--local area = {{position.x - town_radius * 1.5, position.y - town_radius * 1.5}, {position.x + town_radius * 1.5, position.y + town_radius * 1.5}}

	-- pond
	for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
		local x = position.x + vector[1]
		local y = position.y + vector[2]
		local p = {x = x, y = y}
		if surface.get_tile(p).name ~= "out-of-map" then
			surface.set_tiles({{name = "water-green", position = p}})
		end
	end

	-- fish
	for _, vector in pairs(additional_resource_vectors[vector_indexes[2]]) do
		local x = position.x + vector[1] + 0.5
		local y = position.y + vector[2] + 0.5
		local p = {x = x, y = y}
		if math_random(1, 5) == 1 then
			if surface.can_place_entity({name = "fish", position = p}) then
				surface.create_entity({name = "water-splash", position = p})
				surface.create_entity({name = "fish", position = p})
			end
		end
	end

	-- uranium ore
	--if count_nearby_ore(surface, position, "uranium-ore") < 100000 then
	--	for _, vector in pairs(additional_resource_vectors[vector_indexes[3]]) do
	--		local p = {position.x + vector[1], position.y + vector[2]}
	--		p = surface.find_non_colliding_position("uranium-ore", p, 64, 1)
	--		if p then
	--			surface.create_entity({name = "uranium-ore", position = p, amount = ore_amount * 2})
	--		end
	--	end
	--end

	-- oil patches
	--local vectors = additional_resource_vectors[vector_indexes[4]]
	--for _ = 1, 3, 1 do
	--	local vector = vectors[math_random(1, #vectors)]
	--	local p = {position.x + vector[1], position.y + vector[2]}
	--	p = surface.find_non_colliding_position("crude-oil", p, 64, 1)
	--	if p then
	--		surface.create_entity({name = "crude-oil", position = p, amount = 500000})
	--	end
	--end
end

local function is_valid_location(surface, entity)

	for _, vector in pairs(market_collide_vectors) do
		local p = {entity.position.x + vector[1], entity.position.y + vector[2]} 
		if not surface.can_place_entity({name = "iron-chest", position = p}) then
			surface.create_entity({
				name = "flying-text",
				position = entity.position,
				text = "Position is obstructed!",
				color = {r=0.77, g=0.0, b=0.0}
			})
			return false
		end
	end

	if global.towny.size_of_town_centers > 48 then
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Too many town centers on the map!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return false
	end

	if Building.near_town(entity.position, entity.surface, radius_between_towns) then
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "Town location is too close to another town center!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return false
	end
	
	local area = {{entity.position.x - town_radius, entity.position.y - town_radius}, {entity.position.x + town_radius, entity.position.y + town_radius}}
	local count = 0
	for _, e in pairs(surface.find_entities_filtered({area = area})) do
		if e.force.name == "enemy" then
			count = count + 1
		end
	end

	if count > 1 then
		surface.create_entity({
			name = "flying-text",
			position = entity.position,
			text = "I got a bad feeling about this!",
			color = {r=0.77, g=0.0, b=0.0}
		})
		return false
	end
	
	return true
end

function Public.set_market_health(entity, final_damage_amount)
	local town_center = global.towny.town_centers[entity.force.name]
	town_center.health = math_floor(town_center.health - final_damage_amount)
	if town_center.health > town_center.max_health then town_center.health = town_center.max_health end
	local m = town_center.health / town_center.max_health
	entity.health = 150 * m
	rendering.set_text(town_center.health_text, "HP: " .. town_center.health .. " / " .. town_center.max_health)	
end

function Public.update_coin_balance(force)
	local town_center = global.towny.town_centers[force.name]
	rendering.set_text(town_center.coins_text, "Coins: " .. town_center.coin_balance)
end


local function is_color_used(color, town_centers)
	for _, center in pairs(town_centers) do
		if center.color then
			if center.color.r == color.r and center.color.g == color.g and center.color.b == color.b then return true end
		end
	end
end

local function get_color()
	local town_centers = global.towny.town_centers
	local c
	
	local shuffle_index = {}
	for i = 1, #colors, 1 do shuffle_index[i] = i end
	table_shuffle(shuffle_index)
	
	for i = 1, #colors, 1 do
		c = {r = colors[shuffle_index[i]][1], g = colors[shuffle_index[i]][2], b = colors[shuffle_index[i]][3],}
		if not is_color_used(c, town_centers) then return c end	
	end
	
	return c
end

local function found_town(event)
	local entity = event.created_entity
	if entity == nil or not entity.valid then return true end	-- end checks, do nothing
	if entity.name ~= "stone-furnace" then return false end		-- continue building checks
	local player = game.players[event.player_index]
	if player.force ~= game.forces["player"] and player.force ~= game.forces["rogue"] then return false end		-- return false means to continue checks
	local force_name = tostring(player.name)
	if game.forces[force_name] then return end

	local inventory = player.get_main_inventory()
	if inventory.get_item_count("small-plane") < 1 then return false end	-- no plane, continue building checks

	local surface = entity.surface

	if global.towny.cooldowns.town_placement[player.index] then
		if game.tick < global.towny.cooldowns.town_placement[player.index] then
			surface.create_entity({
				name = "flying-text",
				position = entity.position,
				text = "Town founding is on cooldown for " .. math.ceil((global.towny.cooldowns.town_placement[player.index] - game.tick) / 3600) .. " minutes.",
				color = {r=0.77, g=0.0, b=0.0}
			})
			player.insert({name = "stone-furnace", count = 1})
			entity.destroy()
			return true
		end
	end

	if not is_valid_location(surface, entity) then
		player.insert({name = "stone-furnace", count = 1})
		entity.destroy()
		return true
	end

	Team.add_new_force(force_name)

	global.towny.town_centers[force_name] = {}
	local town_center = global.towny.town_centers[force_name]
	town_center.market = surface.create_entity({name = "market", position = entity.position, force = force_name})
	town_center.chunk_position = {math.floor(town_center.market.position.x / 32), math.floor(town_center.market.position.y / 32)}
	town_center.max_health = 1000
	town_center.coin_balance = 0
	town_center.input_buffer = {}
	town_center.output_buffer = {}
	town_center.health = town_center.max_health
	town_center.color = get_color()
	town_center.research_counter = 1
	town_center.upgrades = {}
	town_center.upgrades.mining_prod = 0
	town_center.upgrades.laser_turret = {}
	town_center.upgrades.laser_turret.slots = 0
	town_center.upgrades.laser_turret.locations = {}
	town_center.evolution = {}
	town_center.evolution.biters = 0
	town_center.evolution.spitters = 0
	town_center.evolution.worms = 0

	town_center.coins_text = rendering.draw_text{
		text = "Coins: " .. town_center.coin_balance,
		surface = surface,
		target = town_center.market,
		target_offset = {0, -2.75},
		color = {200, 200, 200},
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}

	town_center.health_text = rendering.draw_text{
		text = "HP: " .. town_center.health .. " / " .. town_center.max_health,
		surface = surface,
		target = town_center.market,
		target_offset = {0, -3.25},
		color = {200, 200, 200},
		scale = 1.00,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}

	town_center.town_caption = rendering.draw_text{
		text = player.name .. "'s Town",
		surface = surface,
		target = town_center.market,
		target_offset = {0, -4.25},
		color = town_center.color,
		scale = 1.30,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}

	global.towny.size_of_town_centers = global.towny.size_of_town_centers + 1

	entity.destroy()

	draw_town_spawn(force_name)

	Team.add_player_to_town(player, town_center)
	Team.add_chart_tag(game.forces.player, town_center.market)

	local force = player.force

	-- set the spawn point
	local pos = {x = town_center.market.position.x, y = town_center.market.position.y + 4}
	--log("setting spawn point = {" .. spawn_point.x .. "," .. spawn_point.y .. "}")
	force.set_spawn_position(pos, surface)
	global.towny.spawn_point[player.name] = pos

	global.towny.cooldowns.town_placement[player.index] = game.tick + 3600 * 15

	if inventory.valid then inventory.remove({name = "small-plane", count = 1}) end

	game.print(">> " .. player.name .. " has founded a new town!", {255, 255, 0})
	return true
end

local function on_built_entity(event)
	found_town(event)
end

local function on_player_repaired_entity(event)
	local entity = event.entity
	if entity.name == "market" then
		Public.set_market_health(entity, -4)
	end
end

--local function on_robot_repaired_entity(event)
--	local entity = event.entity
--	if entity.name == "market" then
--		Public.set_market_health(entity, -4)
--	end
--end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name == "market" then
		Public.set_market_health(entity, event.final_damage_amount)
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)
--Event.add(defines.events.on_robot_repaired_entity, on_robot_repaired_entity)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)

return Public