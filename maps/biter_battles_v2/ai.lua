local Public = {}
local BiterRaffle = require "functions.biter_raffle"
local Functions = require "maps.biter_battles_v2.functions"
local bb_config = require "maps.biter_battles_v2.config"
local math_random = math.random
local math_abs = math.abs

local vector_radius = 512
local attack_vectors = {}
attack_vectors.north = {}
attack_vectors.south = {}
for x = vector_radius * -1, vector_radius, 1 do
	for y = 0, vector_radius, 1 do
		local r = math.sqrt(x ^ 2 + y ^ 2)
		if r < vector_radius and r > vector_radius - 1 then
			attack_vectors.north[#attack_vectors.north + 1] = {x, y * -1}
			attack_vectors.south[#attack_vectors.south + 1] = {x, y}
		end
	end
end
local size_of_vectors = #attack_vectors.north

local unit_type_raffle = {"biter", "biter", "biter", "mixed", "mixed", "spitter"}
local size_of_unit_type_raffle = #unit_type_raffle

local threat_values = {
	["small-spitter"] = 1.5,
	["small-biter"] = 1.5,
	["medium-spitter"] = 4,
	["medium-biter"] = 4,
	["big-spitter"] = 12,
	["big-biter"] = 12,
	["behemoth-spitter"] = 32,
	["behemoth-biter"] = 32,
	["small-worm-turret"] = 8,
	["medium-worm-turret"] = 12,
	["big-worm-turret"] = 16,
	["behemoth-worm-turret"] = 16,
	["biter-spawner"] = 16,
	["spitter-spawner"] = 16
}

local function get_active_biter_count(biter_force_name)
	local count = 0
	for _, biter in pairs(global.active_biters[biter_force_name]) do
		count = count + 1
	end
	return count
end

local function get_target_entity(force_name)
	local force_index = game.forces[force_name].index	
	local target_entity = Functions.get_random_target_entity(force_index)
	if not target_entity then print("Unable to get target entity for " .. force_name .. ".") return end	
	for _ = 1, 2, 1 do
		local e = Functions.get_random_target_entity(force_index)
		if math_abs(e.position.x) < math_abs(target_entity.position.x) then
			target_entity = e
		end
	end	
	if not target_entity then print("Unable to get target entity for " .. force_name .. ".") return end	
	--print("Target entity for " .. force_name .. ": " .. target_entity.name .. " at x=" .. target_entity.position.x .. " y=" .. target_entity.position.y)
	return target_entity
end

local function get_threat_ratio(biter_force_name)
	if global.bb_threat[biter_force_name] <= 0 then return 0 end
	local t1 = global.bb_threat["north_biters"]
	local t2 = global.bb_threat["south_biters"]
	if t1 == 0 and t2 == 0 then return 0.5 end
	if t1 < 0 then t1 = 0 end
	if t2 < 0 then t2 = 0 end
	local total_threat = t1 + t2
	local ratio = global.bb_threat[biter_force_name] / total_threat
	return ratio
end

local function is_biter_inactive(biter, unit_number, biter_force_name)
	if not biter.entity then 
		if global.bb_debug then print("BiterBattles: active unit " .. unit_number .. " removed, possibly died.") end
		return true 
	end	
	if not biter.entity.valid then 
		if global.bb_debug then print("BiterBattles: active unit " .. unit_number .. " removed, biter invalid.") end
		return true 
	end	
	if not biter.entity.unit_group then
		if global.bb_debug then print("BiterBattles: active unit " .. unit_number .. "  at x" .. biter.entity.position.x .. " y" .. biter.entity.position.y .. " removed, had no unit group.") end
		return true 
	end	
	if not biter.entity.unit_group.valid then
		if global.bb_debug then print("BiterBattles: active unit " .. unit_number .. " removed, unit group invalid.") end
		return true 
	end
	if game.tick - biter.active_since > bb_config.biter_timeout then
		if global.bb_debug then print("BiterBattles: " .. biter_force_name .. " unit " .. unit_number .. " timed out at tick age " .. game.tick - biter.active_since .. ".") end
		biter.entity.destroy()
		return true 
	end
end

local function set_active_biters(group)
	if not group.valid then return end
	local active_biters = global.active_biters[group.force.name]
	
	for _, unit in pairs(group.members) do
		if not active_biters[unit.unit_number] then
			active_biters[unit.unit_number] = {entity = unit, active_since = game.tick}
		end
	end
end

Public.destroy_inactive_biters = function()
	local biter_force_name = global.next_attack .. "_biters"
	
	for _, group in pairs(global.unit_groups) do
		set_active_biters(group)
	end
	
	for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
		if is_biter_inactive(biter, unit_number, biter_force_name) then
			global.active_biters[biter_force_name][unit_number] = nil
		end
	end
end

Public.send_near_biters_to_silo = function()
	if game.tick < 108000 then return end
	if not global.rocket_silo["north"] then return end
	if not global.rocket_silo["south"] then return end
	
	game.surfaces["biter_battles"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["north"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "north_biters",
		unit_search_distance = 64
		})
		
	game.surfaces["biter_battles"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["south"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "south_biters",
		unit_search_distance = 64
		})
end

local function get_random_spawner(biter_force_name)
	local spawners = global.unit_spawners[biter_force_name]
	local size_of_spawners = #spawners
	
	for _ = 1, 256, 1 do
		if size_of_spawners == 0 then return end
		local index = math_random(1, size_of_spawners)
		local spawner = spawners[index]	
		if spawner and spawner.valid then
			return spawner
		else	
			table.remove(spawners, index)
			size_of_spawners = size_of_spawners - 1
		end	
	end	
end

local function select_units_around_spawner(spawner, force_name, side_target)
	local biter_force_name = spawner.force.name
	
	local valid_biters = {}
	local i = 0
	
	local threat = global.bb_threat[biter_force_name] * math_random(8, 32) * 0.01
	
	--threat modifier for outposts
	local m = math_abs(side_target.position.x) - 512
	if m < 0 then m = 0 end
	m = 1 - m * 0.001
	if m < 0.5 then m = 0.5 end	
	threat = threat * m
	
	local unit_count = 0
	local max_unit_count = math.floor(global.bb_threat[biter_force_name] * 0.25) + math_random(6,12)
	if max_unit_count > bb_config.max_group_size then max_unit_count = bb_config.max_group_size end
	
	--Collect biters around spawners
	if math_random(1, 2) == 1 then
		local biters = spawner.surface.find_enemy_units(spawner.position, 160, force_name)
		if biters[1] then 	
			for _, biter in pairs(biters) do
				if unit_count >= max_unit_count then break end
				if biter.force.name == biter_force_name and global.active_biters[biter.force.name][biter.unit_number] == nil then
					i = i + 1
					valid_biters[i] = biter
					global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
					unit_count = unit_count + 1
					threat = threat - threat_values[biter.name]
				end	
				if threat < 0 then break end
			end
		end
	end
	
	--Manual spawning of units	
	local roll_type = unit_type_raffle[math_random(1, size_of_unit_type_raffle)]
	for c = 1, max_unit_count - unit_count, 1 do
		if threat < 0 then break end
		local unit_name = BiterRaffle.roll(roll_type, global.bb_evolution[biter_force_name])
		local position = spawner.surface.find_non_colliding_position(unit_name, spawner.position, 128, 2)
		if not position then break end		
		local biter = spawner.surface.create_entity({name = unit_name, force = biter_force_name, position = position})
		threat = threat - threat_values[biter.name]	
		i = i + 1
		valid_biters[i] = biter
		global.active_biters[biter.force.name][biter.unit_number] = {entity = biter, active_since = game.tick}
	end
		
	if global.bb_debug then game.print(get_active_biter_count(biter_force_name) .. " active units for " .. biter_force_name) end
	
	return valid_biters
end

local function send_group(unit_group, force_name, side_target)
	local target
	if side_target then
		target = side_target
	else
		target = get_target_entity(force_name) 
	end
	if not target then print("No target for " .. force_name .. " biters.") return end
	
	target = target.position
	
	local commands = {}	
	local vector = attack_vectors[force_name][math_random(1, size_of_vectors)]
	local distance_modifier = math_random(25, 100) * 0.01
	
	local position = {target.x + (vector[1] * distance_modifier), target.y + (vector[2] * distance_modifier)}
	position = unit_group.surface.find_non_colliding_position("stone-furnace", position, 96, 1)
	if position then
		if math.abs(position.y) < math.abs(unit_group.position.y) then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = position,
				radius = 16,
				distraction = defines.distraction.by_enemy
			}
		end
	end
	
	commands[#commands + 1] = {
		type = defines.command.attack_area,
		destination = target,
		radius = 32,
		distraction = defines.distraction.by_enemy
	}
	
	commands[#commands + 1] = {
		type = defines.command.attack,
		target = global.rocket_silo[force_name],
		distraction = defines.distraction.by_enemy
	}
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.logical_and,
		commands = commands
	})
	return true
end

local function get_unit_group_position(spawner)
	local p	
	if spawner.force.name == "north_biters" then
		p = {x = spawner.position.x, y = spawner.position.y + 4}
	else
		p = {x = spawner.position.x, y = spawner.position.y - 4}
	end
	p = spawner.surface.find_non_colliding_position("electric-furnace", p, 512, 1)
	if not p then
		if global.bb_debug then game.print("No unit_group_position found for team " .. spawner.force.name) end
		return 
	end
	return p
end

local function get_active_threat(biter_force_name)
	local active_threat = 0	
	for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
		if biter.entity then 
			if biter.entity.valid then
				active_threat = active_threat + threat_values[biter.entity.name]
			end
		end
	end
	return active_threat
end

local function get_nearby_biter_nest(target_entity)
	local center = target_entity.position
	local biter_force_name = target_entity.force.name .. "_biters"
	local spawner = get_random_spawner(biter_force_name)	
	if not spawner then return end
	local best_distance = (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2
	
	for i = 1, 16, 1 do
		local new_spawner = get_random_spawner(biter_force_name)
		local new_distance = (center.x - new_spawner.position.x) ^ 2 + (center.y - new_spawner.position.y) ^ 2	
		if new_distance < best_distance then
			spawner = new_spawner
			best_distance = new_distance
		end
	end
	
	if not spawner then return end
	--print("Nearby biter nest found at x=" .. spawner.position.x .. " y=" .. spawner.position.y .. ".")
	return spawner
end

local function create_attack_group(surface, force_name, biter_force_name)
	local threat = global.bb_threat[biter_force_name]	
	if get_active_threat(biter_force_name) > threat * 1.20 then return end
	if threat <= 0 then return false end
	
	if bb_config.max_active_biters - get_active_biter_count(biter_force_name) < bb_config.max_group_size then
		if global.bb_debug then game.print("Not enough slots for biters for team " .. force_name .. ". Available slots: " .. bb_config.max_active_biters - get_active_biter_count(biter_force_name)) end
		return false 
	end	
	
	local side_target = get_target_entity(force_name)
	if not side_target then
		print("No side target found for " .. force_name .. ".")
		return
	end
	
	local spawner = get_nearby_biter_nest(side_target)
	if not spawner then
		print("No spawner found for " .. force_name .. ".")
		return
	end
	
	local unit_group_position = get_unit_group_position(spawner)
	if not unit_group_position then return end
	
	local units = select_units_around_spawner(spawner, force_name, side_target)
	if not units then return end
	
	local unit_group = surface.create_unit_group({position = unit_group_position, force = biter_force_name})
	for _, unit in pairs(units) do unit_group.add_member(unit) end
	
	send_group(unit_group, force_name, side_target)
	
	global.unit_groups[unit_group.group_number] = unit_group
end

Public.pre_main_attack = function()
	local surface = game.surfaces["biter_battles"]
	local force_name = global.next_attack

	if not global.training_mode or (global.training_mode and #game.forces[force_name].connected_players > 0) then
		local biter_force_name = force_name .. "_biters"
		global.main_attack_wave_amount = math.ceil(get_threat_ratio(biter_force_name) * 7)

		if global.bb_debug then game.print(global.main_attack_wave_amount .. " unit groups designated for " .. force_name .. " biters.") end
	else
		global.main_attack_wave_amount = 0
	end
end


Public.perform_main_attack = function()
	if global.main_attack_wave_amount > 0 then
		local surface = game.surfaces["biter_battles"]
		local force_name = global.next_attack
		local biter_force_name = force_name .. "_biters"

		create_attack_group(surface, force_name, biter_force_name)
		global.main_attack_wave_amount = global.main_attack_wave_amount - 1	
	end
end

Public.post_main_attack = function()
	global.main_attack_wave_amount = 0
	if global.next_attack == "north" then
		global.next_attack = "south"
	else
		global.next_attack = "north"
	end	
end

Public.wake_up_sleepy_groups = function()
	local force_name = global.next_attack
	local biter_force_name = force_name .. "_biters"
	local entity
	local unit_group	
	for unit_number, biter in pairs(global.active_biters[biter_force_name]) do
		entity = biter.entity
		if entity then 
			if entity.valid then
				unit_group = entity.unit_group
				if unit_group then
					if unit_group.valid then
						if unit_group.state == defines.group_state.finished then
							send_group(unit_group, force_name)
							--print("BiterBattles: Woke up Unit Group at x" .. unit_group.position.x .. " y" .. unit_group.position.y .. ".")
							return
						end
					end
				end
			end
		end
	end
end

Public.raise_evo = function()
	if global.freeze_players then return end
	if not global.training_mode and (#game.forces.north.connected_players == 0 or #game.forces.south.connected_players == 0) then return end
	if not global.total_passive_feed_redpotion then global.total_passive_feed_redpotion = 0 end
	local amount = math.ceil(global.difficulty_vote_value * global.evo_raise_counter)
	global.total_passive_feed_redpotion = global.total_passive_feed_redpotion + amount
	local biter_teams = {["north_biters"] = "north", ["south_biters"] = "south"}
	local a_team_has_players = false
	for bf, pf in pairs(biter_teams) do
		if #game.forces[pf].connected_players > 0 then
			set_evo_and_threat(amount, "automation-science-pack", bf)
			a_team_has_players = true
		end
	end
	if not a_team_has_players then return end
	global.evo_raise_counter = global.evo_raise_counter + (1 * 0.50)
end

--Biter Threat Value Substraction
function Public.subtract_threat(entity)
	if not threat_values[entity.name] then return end
	if entity.type == "unit" then
		global.active_biters[entity.force.name][entity.unit_number] = nil
	end
	
	global.bb_threat[entity.force.name] = global.bb_threat[entity.force.name] - threat_values[entity.name]
	
	return true
end

return Public
