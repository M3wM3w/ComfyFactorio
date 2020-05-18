local WD = require "modules.wave_defense.table"
local threat_values = require "modules.wave_defense.threat_values"
local BiterRolls = require 'modules.wave_defense.biter_rolls'
local math_random = math.random

local Public = {}

local function remove_unit(entity)
	local wave_defense_table = WD.get_table()
	local unit_number = entity.unit_number
	if not wave_defense_table.active_biters[unit_number] then return end
	local m = 1
	if global.biter_health_boost_units[unit_number] then
		m = 1 / global.biter_health_boost_units[unit_number][2]
	end
	local active_threat_loss = math.round(threat_values[entity.name] * m, 2)
	wave_defense_table.active_biter_threat = wave_defense_table.active_biter_threat - active_threat_loss
	wave_defense_table.active_biter_count = wave_defense_table.active_biter_count - 1
	wave_defense_table.active_biters[unit_number] = nil
end

local function place_nest_near_unit_group(wave_defense_table)
	local group = wave_defense_table.unit_groups[math_random(1, #wave_defense_table.unit_groups)]
	if not group then return end
	if not group.valid then return end
	if not group.members then return end
	if not group.members[1] then return end
	local unit = group.members[math_random(1, #group.members)]
	if not unit.valid then return end
	local name = "biter-spawner"
	if math_random(1, 3) == 1 then name = "spitter-spawner" end
	local position = unit.surface.find_non_colliding_position(name, unit.position, 12, 1)
	if not position then return end
	local r = wave_defense_table.nest_building_density	
	if unit.surface.count_entities_filtered({type = "unit-spawner", area = {{position.x - r, position.y - r},{position.x + r, position.y + r}}}) > 0 then return end
	unit.surface.create_entity({name = name, position = position, force = unit.force})
	unit.surface.create_entity({name = "blood-explosion-huge", position = position})
	unit.surface.create_entity({name = "blood-explosion-huge", position = unit.position})
	remove_unit(unit)
	unit.destroy()
	wave_defense_table.threat = wave_defense_table.threat - threat_values[name]
	return true	
end

function Public.build_nest()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.threat < 1024 then return end
	if #wave_defense_table.unit_groups == 0 then return end
	for _ = 1, 2, 1 do 
		if place_nest_near_unit_group(wave_defense_table) then return end 
	end
end

function Public.build_worm()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.threat < 512 then return end
	if math_random(1, wave_defense_table.worm_building_chance) ~= 1 then return end
	if #wave_defense_table.unit_groups == 0 then return end
	local group = wave_defense_table.unit_groups[math_random(1, #wave_defense_table.unit_groups)]
	if not group then return end
	if not group.valid then return end
	if not group.members then return end
	if not group.members[1] then return end
	local unit = group.members[math_random(1, #group.members)]
	if not unit.valid then return end
	local position = unit.surface.find_non_colliding_position("assembling-machine-1", unit.position, 8, 1)
	BiterRolls.wave_defense_set_worm_raffle(wave_defense_table.wave_number)
	local worm = BiterRolls.wave_defense_roll_worm_name()
	if not position then return end
	local r = wave_defense_table.worm_building_density
	if unit.surface.count_entities_filtered({type = "turret", area = {{position.x - r, position.y - r},{position.x + r, position.y + r}}}) > 0 then return end
	unit.surface.create_entity({name = worm, position = position, force = unit.force})
	unit.surface.create_entity({name = "blood-explosion-huge", position = position})
	unit.surface.create_entity({name = "blood-explosion-huge", position = unit.position})
	remove_unit(unit)
	unit.destroy()
	wave_defense_table.threat = wave_defense_table.threat - threat_values[worm]
end
--[[
local function get_circle_vectors(radius)
	local vectors = {}
	for x = radius * -1, radius, 1 do
		for y = radius * -1, radius, 1 do
			if math.sqrt(x^2 + y^2) <= radius then
				vectors[#vectors + 1] = {x, y}
			end
		end
	end
	return vectors
end

local acid_nova_entities = {
	["small-biter"] = {projectile = "acid-stream-worm-small", vectors = get_circle_vectors(3), threat_cost = 32},
	["medium-biter"] = {projectile = "acid-stream-worm-medium", vectors = get_circle_vectors(4), threat_cost = 64},
	["big-biter"] = {projectile = "acid-stream-worm-big", vectors = get_circle_vectors(5), threat_cost = 96},
	["behemoth-biter"] = {projectile = "acid-stream-worm-behemoth", vectors = get_circle_vectors(6), threat_cost = 128},
}

local function acid_nova(entity)
	local wave_defense_table = WD.get_table()
	if not acid_nova_entities[entity.name] then return end
	if wave_defense_table.threat < 100000 then return end
	if math.random(1, 32) ~= 1 then return end
	for _ = 1, 8, 1 do
		local i = math_random(1, #acid_nova_entities[entity.name].vectors)		
		entity.surface.create_entity({	
			name = acid_nova_entities[entity.name].projectile,
			position = entity.position,
			force = entity.force.name,
			source = entity.position,
			target = {x = entity.position.x + acid_nova_entities[entity.name].vectors[i][1], y = entity.position.y + acid_nova_entities[entity.name].vectors[i][2]},
			max_range = 10, 
			speed = 0.001
		})
	end	
	wave_defense_table.threat = wave_defense_table.threat - acid_nova_entities[entity.name].threat_cost	
	return true
end
]]
local function shred_simple_entities(entity)
	local wave_defense_table = WD.get_table()
	if wave_defense_table.threat < 25000 then return end
	local simple_entities = entity.surface.find_entities_filtered({type = "simple-entity", area = {{entity.position.x - 3, entity.position.y - 3},{entity.position.x + 3, entity.position.y + 3}}})
	if #simple_entities == 0 then return end
	if #simple_entities > 1 then table.shuffle_table(simple_entities) end	
	local r = math.floor(wave_defense_table.threat * 0.00004)
	if r < 1 then r = 1 end
	local count = math.random(1, r)
	--local count = 1
	local damage_dealt = 0
	for i = 1, count, 1 do
		if not simple_entities[i] then break end
		if simple_entities[i].valid then
			if simple_entities[i].health then
				damage_dealt = damage_dealt + simple_entities[i].health
				simple_entities[i].die("neutral", simple_entities[i])
			end
		end
	end
	if damage_dealt == 0 then return end
	local threat_cost = math.floor(damage_dealt * wave_defense_table.simple_entity_shredding_cost_modifier)
	if threat_cost < 1 then threat_cost = 1 end
	wave_defense_table.threat = wave_defense_table.threat - threat_cost
end

local function spawn_unit_spawner_inhabitants(wave_defense_table, entity)
	if entity.type ~= "unit-spawner" then return end
	local count = 8 + math.floor(wave_defense_table.wave_number * 0.02)
	if count > 128 then count = 128 end
	BiterRolls.wave_defense_set_unit_raffle(wave_defense_table.wave_number)
	for _ = 1, count, 1 do
		local position = {entity.position.x + (-4 + math.random(0, 8)), entity.position.y + (-4 + math.random(0, 8))}		
		if math.random(1,4) == 1 then
			entity.surface.create_entity({name = BiterRolls.wave_defense_roll_spitter_name(), position = position, force = "enemy"})
		else
			entity.surface.create_entity({name = BiterRolls.wave_defense_roll_biter_name(), position = position, force = "enemy"})
		end
	end
end

local function on_entity_died(event)
	local wave_defense_table = WD.get_table()
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.type == "unit" then
		if not threat_values[entity.name] then return end
		wave_defense_table.threat = math.round(wave_defense_table.threat - threat_values[entity.name] * global.biter_health_boost, 2)
		remove_unit(entity)
		--acid_nova(entity)
	else
		if entity.force.index == 2 then	
			if entity.health then
				if threat_values[entity.name] then
					wave_defense_table.threat = math.round(wave_defense_table.threat - threat_values[entity.name] * global.biter_health_boost, 2)
				end				
				spawn_unit_spawner_inhabitants(wave_defense_table, entity)
			end
		end
	end

	if entity.force.index == 3 then
		if event.cause then
			if event.cause.valid then
				if event.cause.force.index == 2 then
					shred_simple_entities(entity)
				end
			end
		end
	end
end

local event = require 'utils.event'
event.add(defines.events.on_entity_died, on_entity_died)

return Public