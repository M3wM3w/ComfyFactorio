require "modules.mineable_wreckage_yields_scrap"
require "modules.no_deconstruction_of_neutral_entities"

local get_noise = require "utils.get_noise"
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

local scrap_entities = {"crash-site-assembling-machine-1-broken", "crash-site-assembling-machine-2-broken", "crash-site-lab-broken",
 "medium-ship-wreck", "small-ship-wreck",
 "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2", "crash-site-chest-1", "crash-site-chest-2",
 "big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3", "big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3", "big-ship-wreck-1", "big-ship-wreck-2", "big-ship-wreck-3",
 }
local scrap_entities_index = #scrap_entities

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

local function place_scrap(surface, position)
	if math_random(1, 700) == 1 then
		if position.x ^ 2 + position.x ^ 2 > 4096 then
			local e = surface.create_entity({name = "gun-turret", position = position, force = "enemy"})			
			e.insert({name = "piercing-rounds-magazine", count = 100})		
			return
		end
	end

	if math_random(1, 128) == 1 then
		local e = surface.create_entity({name = scrap_entities[math_random(1, scrap_entities_index)], position = position, force = "neutral"})
		local i = e.get_inventory(defines.inventory.chest)
		if i then
			for x = 1, math_random(6,18), 1 do
				local loot = scrap_raffle[math_random(1, size_of_scrap_raffle)]
				
				i.insert({name = loot, count = math_floor(scrap_yield_amounts[loot] * math_random(5, 35) * 0.1) + 1})
			end
		end
		return
	end		
	surface.create_entity({name = "mineable-wreckage", position = position, force = "neutral"})
end

local function is_scrap_area(noise)
	if noise > 0.25 then return true end	
	if noise < -0.25 then return true end
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

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.name ~= "mineable-wreckage" then return end
	local surface = entity.surface
	for _, v in pairs(vectors) do
		local position = {entity.position.x + v[1], entity.position.y + v[2]}
		if not surface.get_tile(position).collides_with("resource-layer") then 
			surface.set_tiles({{name = "landfill", position = position}}, true)
		end
	end
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	on_player_mined_entity(event)
end

local function on_chunk_generated(event)	
	local surface = event.surface
	local seed = surface.map_gen_settings.seed
	local left_top_x = event.area.left_top.x
	local left_top_y = event.area.left_top.y
	local position
	local noise
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			if math_random(1, 3) > 1 then
				position = {x = left_top_x + x, y = left_top_y + y}				
				if not surface.get_tile(position).collides_with("resource-layer") then 
					noise = get_noise("scrapyard", position, seed)
					if is_scrap_area(noise) then
						surface.set_tiles({{name = "dirt-" .. math_floor(math_abs(noise) * 6) % 6 + 2, position = position}}, true)
						place_scrap(surface, position)
					end
				end		
			end
		end
	end
	
	move_away_biteys(surface, event.area)
end

local Event = require 'utils.event'
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_entity_died, on_entity_died)