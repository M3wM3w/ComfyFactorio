local Public = {}
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
local math_round = math.round
local table_insert = table.insert
local table_remove = table.remove

local function get_commmands(target, group)
	local commands = {}
	local group_position = {x = group.position.x, y = group.position.y}
	local step_length = 128

	local target_position = target.position
	local distance_to_target = math_floor(math_sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
	local steps = math_floor(distance_to_target / step_length) + 1
	local vector = {math_round((target_position.x - group_position.x) / steps, 3), math_round((target_position.y - group_position.y) / steps, 3)}

	for i = 1, steps, 1 do
		group_position.x = group_position.x + vector[1]
		group_position.y = group_position.y + vector[2]
		local position = group.surface.find_non_colliding_position("small-biter", group_position, step_length, 2)
		if position then
			commands[#commands + 1] = {
				type = defines.command.attack_area,
				destination = {x = position.x, y = position.y},
				radius = 16,
				distraction = defines.distraction.by_anything
			}
		end
	end

	commands[#commands + 1] = {
		type = defines.command.attack_area,
		destination = target.position,
		radius = 12,
		distraction = defines.distraction.by_enemy,
	}
	commands[#commands + 1] = {
		type = defines.command.attack,
		target = target,
		distraction = defines.distraction.by_enemy,
	}

	return commands
end

local function roll_market()
	local r_max = 0
	local town_centers = global.towny.town_centers
	
	--Skip Towns that are too low in reserach for the current biter evolution.
	local research_threshold = game.forces.enemy.evolution_factor * #game.technology_prototypes * 0.175

	for k, town_center in pairs(town_centers) do
		if town_center.research_counter >= research_threshold then
			r_max = r_max + town_center.research_counter
		end
	end
	if r_max == 0 then return end	
	local r = math_random(0, r_max)
	
	local chance = 0
	for k, town_center in pairs(town_centers) do
		if town_center.research_counter >= research_threshold then
			chance = chance + town_center.research_counter
			if r <= chance then return town_center end
		end
	end
end

local function get_random_close_spawner(surface, market)
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})
	if not spawners[1] then return false end
	local size_of_spawners = #spawners
	local center = market.position
	local spawner = spawners[math_random(1, size_of_spawners)]
	for i = 1, 64, 1 do
		local spawner_2 = spawners[math_random(1, size_of_spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then
			spawner = spawner_2
		end
	end
	return spawner
end

local function is_swarm_valid(swarm)
	local group = swarm.group
	if not group then return end
	if not group.valid then return end
	if game.tick >= swarm.timeout then	
		group.destroy()		
		return
	end
	return true
end

function Public.validate_swarms()
	for k, swarm in pairs(global.towny.swarms) do
		if not is_swarm_valid(swarm) then
			table_remove(global.towny.swarms, k)
		end
	end
end

--Destroy biters that are out of the current evolution range.
function Public.wipe_units_out_of_evo_range()
	local units_to_wipe = {}
	local evo = game.forces.enemy.evolution_factor	
	if evo > 0.80 then return end
		units_to_wipe[#units_to_wipe + 1] = "behemoth-biter"
		units_to_wipe[#units_to_wipe + 1] = "behemoth-spitter"
	if evo < 0.40 then 
		units_to_wipe[#units_to_wipe + 1] = "big-biter"
		units_to_wipe[#units_to_wipe + 1] = "big-spitter"
	end
	if evo < 0.10 then 
		units_to_wipe[#units_to_wipe + 1] = "medium-biter"
		units_to_wipe[#units_to_wipe + 1] = "medium-spitter"
	end	
	for k, surface in pairs(game.surfaces) do
		for k2, unit in pairs(surface.find_entities_filtered({name = units_to_wipe, force = "enemy"})) do
			unit.destroy()
		end
	end
end

function Public.clear_spawn_for_player(player)
	local area = {{player.position.x - 64, player.position.y - 64}, {player.position.x + 64, player.position.y + 64}}
	for _, e in pairs(player.surface.find_entities_filtered({force = "enemy", type = {"unit-spawner", "unit", "turret"}, area = area})) do
		e.destroy()
	end
end

function Public.unit_groups_start_moving()
	for k, swarm in pairs(global.towny.swarms) do
		if swarm.group then
			if swarm.group.valid then
				swarm.group.start_moving()
			end
		end
	end
end

function Public.swarm()
	local count = 0
	for k, swarm in pairs(global.towny.swarms) do
		count = count + 1
	end	
	if count > 6 then return end
	
	local town_center = roll_market()
	if not town_center then return end
	local market = town_center.market
	local surface = market.surface
	local spawner = get_random_close_spawner(surface, market)
	if not spawner then return end	
	local units = spawner.surface.find_enemy_units(spawner.position, 160, market.force)
	if not units[1] then return end
	local unit_group_position = surface.find_non_colliding_position("market", units[1].position, 256, 1)
	if not unit_group_position then return end
	local unit_group = surface.create_unit_group({position = unit_group_position, force = units[1].force})
	local count = (town_center.research_counter * 1.5) + 4
	for key, unit in pairs(units) do
		if key > count then break end
		unit_group.add_member(unit) 
	end
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = get_commmands(market, unit_group)
	})
	table_insert(global.towny.swarms, {group = unit_group, timeout = game.tick + 36000})
end

function Public.set_evolution()
	local town_center_count = global.towny.size_of_town_centers
	if town_center_count == 0 then 
		game.forces.enemy.evolution_factor = 0
		return 
	end
		
	local max_research_count = math_floor(#game.technology_prototypes * 0.30)
	
	local evo = 0
	for _, town_center in pairs(global.towny.town_centers) do
		evo = evo + town_center.research_counter
	end
	evo = evo / town_center_count
	evo = evo / max_research_count
	if evo > 1 then evo = 1 end
	
	game.forces.enemy.evolution_factor = evo
end

return Public