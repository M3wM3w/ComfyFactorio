local WD = require "modules.wave_defense.table"
local Public = {}
local side_target_types = {
	["accumulator"] = true,
	["assembling-machine"] = true,
	["boiler"] = true,
	["furnace"] = true,
	["generator"] = true,
	["lab"] = true,
	["lamp"] = true,
	["mining-drill"] = true,
	["power-switch"] = true,
	["radar"] = true,
	["reactor"] = true,
	["roboport"] = true,
	["rocket-silo"] = true,
	["solar-panel"] = true,
}

local function get_random_target(wave_defense_table)	
	local r = math.random(1, wave_defense_table.side_target_count)
	if not wave_defense_table.side_targets[r] then
		table.remove(wave_defense_table.side_targets, r) 
		wave_defense_table.side_target_count = wave_defense_table.side_target_count - 1
		return 
	end
	if not wave_defense_table.side_targets[r].valid then
		table.remove(wave_defense_table.side_targets, r)
		wave_defense_table.side_target_count = wave_defense_table.side_target_count - 1
		return 
	end
	return wave_defense_table.side_targets[r]
end

function Public.get_side_target()
	local wave_defense_table = WD.get_table()	
	for _ = 1, 512, 1 do
		if wave_defense_table.side_target_count == 0 then return end
		local target = get_random_target(wave_defense_table)
		if target then return target end
	end
end

local function add_entity(entity)
	local wave_defense_table = WD.get_table()
	
	--skip entities that are on another surface
	if entity.surface.index ~= wave_defense_table.surface_index then return end
	
	--add entity to the side target list
	table.insert(wave_defense_table.side_targets, entity)
	wave_defense_table.side_target_count = wave_defense_table.side_target_count + 1
end

local function on_built_entity(event)
	if not side_target_types[event.created_entity.type] then return end
	add_entity(event.created_entity)
end

local function on_robot_built_entity(event)
	if not side_target_types[event.created_entity.type] then return end
	add_entity(event.created_entity)
end

local event = require 'utils.event'
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)

return Public