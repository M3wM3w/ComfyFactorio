local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

local get_noise = require 'utils.get_noise'
local Scrap = require 'modules.scrap_towny_ffa.scrap'
require 'modules.no_deconstruction_of_neutral_entities'

local scrap_entities = {
	-- simple entity
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "small-ship-wreck"},		-- these are not mineable normally
	{name = "medium-ship-wreck"},	-- these are not mineable normally
	{name = "medium-ship-wreck"},	-- these are not mineable normally
	{name = "medium-ship-wreck"},	-- these are not mineable normally
	{name = "medium-ship-wreck"},	-- these are not mineable normally
	-- simple entity with owner
	{name = "crash-site-spaceship-wreck-small-1"},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-small-1"},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-small-2"},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-small-3"},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-small-4"},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-small-5"},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-small-6"}	-- these do not have mining animation
}

local scrap_entities_index = table.size(scrap_entities)

local scrap_containers = {
	-- containers
	{name = "big-ship-wreck-1", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-1", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-1", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-2", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-2", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-2", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-3", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-3", size = 3},		-- these are not mineable normally
	{name = "big-ship-wreck-3", size = 3},		-- these are not mineable normally
	{name = "crash-site-chest-1", size = 8},	-- these do not have mining animation
	{name = "crash-site-chest-2", size = 8},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-1", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-1", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-1", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-1", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-2", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-2", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-2", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-2", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-3", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-3", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-3", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-medium-3", size = 1},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-big-1", size = 2},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-big-1", size = 2},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-big-1", size = 2},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-big-2", size = 2},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-big-2", size = 2},	-- these do not have mining animation
	{name = "crash-site-spaceship-wreck-big-2", size = 2},	-- these do not have mining animation
}
local scrap_containers_index = table.size(scrap_containers)

-- loot chances and amounts for scrap containers

local container_loot_chance = {
	{name = "advanced-circuit", chance = 5},
	{name = "artillery-shell", chance = 1},
	{name = "cannon-shell", chance = 2},
	{name = "cliff-explosives", chance = 5},
	--{name = "cluster-grenade", chance = 2},
	{name = "construction-robot", chance = 1},
	{name = "copper-cable", chance = 250},
	{name = "copper-plate", chance = 500},
	{name = "crude-oil-barrel", chance = 30},
	{name = "defender-capsule", chance = 5},
	{name = "destroyer-capsule", chance = 1},
	{name = "distractor-capsule", chance = 2},
	{name = "electric-engine-unit", chance = 2},
	{name = "electronic-circuit", chance = 200},
	{name = "empty-barrel", chance = 10},
	{name = "engine-unit", chance = 7},
	{name = "explosive-cannon-shell", chance = 2},
	--{name = "explosive-rocket", chance = 3},
	{name = "explosive-uranium-cannon-shell", chance = 1},
	{name = "explosives", chance = 5},
	{name = "green-wire", chance = 10},
	{name = "grenade", chance = 10},
	{name = "heat-pipe", chance = 1},
	{name = "heavy-oil-barrel", chance = 15},
	{name = "iron-gear-wheel", chance = 500},
	{name = "iron-plate", chance = 750},
	{name = "iron-stick", chance = 50},
	{name = "land-mine", chance = 3},
	{name = "light-oil-barrel", chance = 15},
	{name = "logistic-robot", chance = 1},
	{name = "low-density-structure", chance = 1},
	{name = "lubricant-barrel", chance = 20},
	{name = "nuclear-fuel", chance = 1},
	{name = "petroleum-gas-barrel", chance = 15},
	{name = "pipe", chance = 100},
	{name = "pipe-to-ground", chance = 10},
	{name = "plastic-bar", chance = 5},
	{name = "processing-unit", chance = 2},
	{name = "red-wire", chance = 10},
	--{name = "rocket", chance = 3},  {name = "battery", chance = 20},
	{name = "rocket-control-unit", chance = 1},
	{name = "rocket-fuel", chance = 3},
	{name = "solid-fuel", chance = 100},
	{name = "steel-plate", chance = 150},
	{name = "sulfuric-acid-barrel", chance = 15},
	{name = "uranium-cannon-shell", chance = 1},
	{name = "uranium-fuel-cell", chance = 1},
	{name = "used-up-uranium-fuel-cell", chance = 1},
	{name = "water-barrel", chance = 10}
}

local container_loot_amounts = {
	["advanced-circuit"] = 2,
	["artillery-shell"] = 0.3,
	["battery"] = 2,
	["cannon-shell"] = 2,
	["cliff-explosives"] = 2,
	--["cluster-grenade"] = 0.3,
	["construction-robot"] = 0.3,
	["copper-cable"] = 24,
	["copper-plate"] = 16,
	["crude-oil-barrel"] = 3,
	["defender-capsule"] = 2,
	["destroyer-capsule"] = 0.3,
	["distractor-capsule"] = 0.3,
	["electric-engine-unit"] = 2,
	["electronic-circuit"] = 8,
	["empty-barrel"] = 3,
	["engine-unit"] = 2,
	["explosive-cannon-shell"] = 2,
	--["explosive-rocket"] = 2,
	["explosive-uranium-cannon-shell"] = 2,
	["explosives"] = 4,
	["green-wire"] = 8,
	["grenade"] = 2,
	["heat-pipe"] = 1,
	["heavy-oil-barrel"] = 3,
	["iron-gear-wheel"] = 8,
	["iron-plate"] = 16,
	["iron-stick"] = 16,
	["land-mine"] = 1,
	["light-oil-barrel"] = 3,
	["logistic-robot"] = 0.3,
	["low-density-structure"] = 0.3,
	["lubricant-barrel"] = 3,
	["nuclear-fuel"] = 0.1,
	["petroleum-gas-barrel"] = 3,
	["pipe"] = 8,
	["pipe-to-ground"] = 1,
	["plastic-bar"] = 4,
	["processing-unit"] = 1,
	["red-wire"] = 8,
	--["rocket"] = 2,
	["rocket-control-unit"] = 0.3,
	["rocket-fuel"] = 0.3,
	["solid-fuel"] = 4,
	["steel-plate"] = 4,
	["sulfuric-acid-barrel"] = 3,
	["uranium-cannon-shell"] = 2,
	["uranium-fuel-cell"] = 0.3,
	["used-up-uranium-fuel-cell"] = 1,
	["water-barrel"] = 3
}

local scrap_raffle = {}
for _, t in pairs(container_loot_chance) do
	for _ = 1, t.chance, 1 do
		table_insert(scrap_raffle, t.name)
	end
end

local size_of_scrap_raffle = #scrap_raffle

local function place_scrap(surface, position)
	-- place turrets
	if math_random(1, 700) == 1 then
		if position.x ^ 2 + position.x ^ 2 > 4096 then
			local e = surface.create_entity({name = "gun-turret", position = position, force = "enemy"})
			e.minable = false
			e.operable = false
			e.insert({name = "piercing-rounds-magazine", count = 100})
			return
		end
	end

	-- place spaceship with loot
	if math_random(1, 8192) == 1 then
		local e = surface.create_entity({name = 'crash-site-spaceship', position = position, force = "neutral"})
		e.minable = true
		local i = e.get_inventory(defines.inventory.chest)
		if i then
			for _ = 1, math_random(1, 5), 1 do
				local loot = scrap_raffle[math_random(1, size_of_scrap_raffle)]
				local amount = container_loot_amounts[loot]
				local count = math_floor(amount * math_random(5, 35) * 0.1) + 1
				i.insert({name = loot, count = count})
			end
		end
		return
	end

	-- place scrap containers with loot
	if math_random(1, 128) == 1 then
		local scrap = scrap_containers[math_random(1, scrap_containers_index)]
		local e = surface.create_entity({name = scrap.name, position = position, force = "neutral"})
		e.minable = true
		local i = e.get_inventory(defines.inventory.chest)
		if i then
			local size = scrap.size
			for _ = 1, math_random(1, size), 1 do
				local loot = scrap_raffle[math_random(1, size_of_scrap_raffle)]
				local amount = container_loot_amounts[loot]
				local count = math_floor(amount * math_random(5, 35) * 0.1) + 1
				i.insert({name = loot, count = count})
			end
		end
		return
	end

	-- place scrap entities with loot
	local scrap = scrap_entities[math_random(1, scrap_entities_index)]
	local e = surface.create_entity({name = scrap.name, position = position, force = "neutral"})
	e.minable = true
end

local function is_scrap_area(n)
	if n > 0.5 then return true end
	if n < -0.5 then return true end
end

local function move_away_biteys(surface, area)
	for _, e in pairs(surface.find_entities_filtered({type = {"unit-spawner", "turret", "unit"}, area = area})) do
		local position = surface.find_non_colliding_position(e.name, e.position, 96, 4)
		if position then
			surface.create_entity({name = e.name, position = position, force = "enemy"})
			e.destroy()
		end
	end
end

local vectors = {{0,0}, {1,0}, {-1,0}, {0,1}, {0,-1}}

local function landfill_under(entity)
	-- landfill the area under the entity
	local surface = entity.surface
	for _, v in pairs(vectors) do
		local position = {entity.position.x + v[1], entity.position.y + v[2]}
		if not surface.get_tile(position).collides_with("resource-layer") then
			surface.set_tiles({{name = "landfill", position = position}}, true)
		end
	end

end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if Scrap.is_scrap(entity) then landfill_under(entity) end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	if Scrap.is_scrap(entity) then landfill_under(entity) end
end

--local function on_init(event)
--
--end

local function on_chunk_generated(event)
	--log("scrap_towny_ffa::on_chunk_generated")
	local surface = event.surface
	local seed = surface.map_gen_settings.seed
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	--log("  chunk = {" .. left_top_x/32 .. ", " .. left_top_y/32 .. "}")
	local position
	local noise
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			if math_random(1, 3) > 1 then
				position = {x = left_top_x + x, y = left_top_y + y}
				if not surface.get_tile(position).collides_with("resource-layer") then
					noise = get_noise("scrap_towny_ffa", position, seed)
					if is_scrap_area(noise) then
						surface.set_tiles({{name = "dirt-" .. math_floor(math_abs(noise) * 6) % 6 + 2, position = position}}, true)
						place_scrap(surface, position)
					end
				end
			end
		end
	end
	move_away_biteys(surface, event.area)
	--ffatable.chunk_generated[key] = true
end

local function on_chunk_charted(event)
	local force = event.force
	local surface = game.surfaces[event.surface_index]
	if force.valid then
		if force == game.forces["player"] or force == game.forces["rogue"] then
			force.clear_chart(surface)
		end
	end
end

-- local on_init = function ()
-- 	local ffatable = Table.get_table()
--  ffatable.chunk_generated = {}
-- end

local Event = require 'utils.event'
-- Event.on_init(on_init)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_chunk_charted, on_chunk_charted)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)