local BiterHealthBooster = require "modules.biter_health_booster"
local BiterRolls = require "modules.wave_defense.biter_rolls"
local SideTargets = require "modules.wave_defense.side_targets"
local ThreatEvent = require "modules.wave_defense.threat_events"
local update_gui = require "modules.wave_defense.gui"
local threat_values = require "modules.wave_defense.threat_values"
local WD = require "modules.wave_defense.table"
local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert
local math_sqrt = math.sqrt
local math_round = math.round
local event = require 'utils.event'
local Public = {}

local group_size_modifier_raffle = {}
local group_size_chances = {{4, 0.4}, {5, 0.5}, {6, 0.6}, {7, 0.7}, {8, 0.8}, {9, 0.9}, {10, 1}, {9, 1.1}, {8, 1.2}, {7, 1.3}, {6, 1.4}, {5, 1.5}, {4, 1.6}, {3, 1.7}, {2, 1.8}}
for _, v in pairs(group_size_chances) do
	for c = 1, v[1], 1 do
		table_insert(group_size_modifier_raffle, v[2])
	end
end
local group_size_modifier_raffle_size = #group_size_modifier_raffle

local function debug_print(msg)
	local wave_defense_table = WD.get_table()
	if not wave_defense_table.debug then return end
	print("WaveDefense: " .. msg)
end

local function is_closer(pos1, pos2, pos)
  return ((pos1.x - pos.x)^2 + (pos1.y - pos.y)^2) < ((pos2.x - pos.x)^2 + (pos2.y - pos.y)^2)
end

local function shuffle_distance(tbl, position)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
      if is_closer(tbl[i].position, tbl[rand].position, position) and i > rand then
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
      end
		end
	return tbl
end

local function is_unit_valid(biter)
	local wave_defense_table = WD.get_table()
	if not biter.entity then debug_print("is_unit_valid - unit destroyed - does no longer exist") return false end
	if not biter.entity.valid then debug_print("is_unit_valid - unit destroyed - invalid") return false end
	if not biter.entity.unit_group then debug_print("is_unit_valid - unit destroyed - no unitgroup") return false end
	if biter.spawn_tick + wave_defense_table.max_biter_age < game.tick then debug_print("is_unit_valid - unit destroyed - timed out") return false end
	return true
end

local function refresh_active_unit_threat()
	local wave_defense_table = WD.get_table()
	debug_print("refresh_active_unit_threat - current value " .. wave_defense_table.active_biter_threat)
	local active_biter_threat = 0
	for k, biter in pairs(wave_defense_table.active_biters) do
		if biter.entity then
			if biter.entity.valid then
				active_biter_threat = active_biter_threat + threat_values[biter.entity.name]
			end
		end
	end
	wave_defense_table.active_biter_threat = math_round(active_biter_threat * global.biter_health_boost, 2)
	debug_print("refresh_active_unit_threat - new value " .. wave_defense_table.active_biter_threat)
end

local function time_out_biters()
	local wave_defense_table = WD.get_table()
	for k, biter in pairs(wave_defense_table.active_biters) do
		if not is_unit_valid(biter) then
			wave_defense_table.active_biter_count = wave_defense_table.active_biter_count - 1
			if biter.entity then
				if biter.entity.valid then
					wave_defense_table.active_biter_threat = wave_defense_table.active_biter_threat - math_round(threat_values[biter.entity.name] * global.biter_health_boost, 2)
					if biter.entity.force.index == 2 then
						biter.entity.destroy()
					end
				end
			end
			wave_defense_table.active_biters[k] = nil
		end
	end
end

local function get_random_close_spawner(surface)
	local wave_defense_table = WD.get_table()
	local spawners = surface.find_entities_filtered({type = "unit-spawner"})
	if not spawners[1] then return false end
	local center = wave_defense_table.target.position
	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, wave_defense_table.get_random_close_spawner_attempts, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if (center.x - spawner_2.position.x) ^ 2 + (center.y - spawner_2.position.y) ^ 2 < (center.x - spawner.position.x) ^ 2 + (center.y - spawner.position.y) ^ 2 then spawner = spawner_2 end
	end
	debug_print("get_random_close_spawner - Found at x" .. spawner.position.x .. " y" .. spawner.position.y)
	return spawner
end

local function get_random_character(wave_defense_table)
	local characters = {}
	for _, player in pairs(game.connected_players) do
		if player.character then
			if player.character.valid then
				if player.character.surface.index == wave_defense_table.surface_index then
					characters[#characters + 1] = player.character
				end
			end
		end
	end
	if not characters[1] then return end
	return characters[math_random(1, #characters)]
end

local function set_main_target()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.target then
		if wave_defense_table.target.valid then return end
	end

	local target = SideTargets.get_side_target()
	if not target then target = get_random_character(wave_defense_table) end
	if not target then return end

	wave_defense_table.target = target
	debug_print("set_main_target -- New main target " .. target.name .. " at position x" .. target.position.x .. " y" .. target.position.y .. " selected.")
end

local function set_group_spawn_position(surface)
	local wave_defense_table = WD.get_table()
	local spawner = get_random_close_spawner(surface)
	if not spawner then return end
	local position = surface.find_non_colliding_position("behemoth-biter", spawner.position, 64, 1)
	if not position then return end
	wave_defense_table.spawn_position = {x = position.x, y = position.y}
	debug_print("set_group_spawn_position -- Changed position to x" .. wave_defense_table.spawn_position.x .. " y" .. wave_defense_table.spawn_position.y .. ".")
end

local function set_enemy_evolution()
	local wave_defense_table = WD.get_table()
	local evolution_factor = wave_defense_table.wave_number * 0.001
	local biter_health_boost = 1
	--local damage_increase = 0

	if evolution_factor > 1 then
		--damage_increase = damage_increase + (evolution_factor - 1)
		--biter_health_boost = biter_health_boost + (evolution_factor - 1) * 2
		evolution_factor = 1
	end

	if wave_defense_table.threat > 50000 then
		biter_health_boost = math_round(biter_health_boost + (wave_defense_table.threat - 50000) * 0.000033, 3)
		--damage_increase = math_round(damage_increase + wave_defense_table.threat * 0.0000025, 3)
	end

	global.biter_health_boost = biter_health_boost
	--game.forces.enemy.set_ammo_damage_modifier("melee", damage_increase)
	--game.forces.enemy.set_ammo_damage_modifier("biological", damage_increase)
	game.forces.enemy.evolution_factor = evolution_factor
end

local function can_units_spawn()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.threat <= 0 then
		debug_print("can_units_spawn - threat too low")
		return false
	end
	if wave_defense_table.active_biter_count >= wave_defense_table.max_active_biters then
		debug_print("can_units_spawn - active biter count too high")
		return false
	end
	if wave_defense_table.active_biter_threat >= wave_defense_table.threat then
		debug_print("can_units_spawn - active biter threat too high (" .. wave_defense_table.active_biter_threat .. ")")
		return false
	end
	return true
end

local function get_active_unit_groups_count()
	local wave_defense_table = WD.get_table()
	local count = 0
	for _, g in pairs(wave_defense_table.unit_groups) do
		if g.valid then
			if #g.members > 0 then
				count = count + 1
			else
				g.destroy()
			end
		end
	end
	debug_print("Active unit group count: " .. count)
	return count
end

local function spawn_biter(surface, is_boss_biter)
	local wave_defense_table = WD.get_table()
	if not is_boss_biter then
		if not can_units_spawn() then return end
	end

	local name
	if math_random(1,100) > 73 then
		name = BiterRolls.wave_defense_roll_spitter_name()
	else
		name = BiterRolls.wave_defense_roll_biter_name()
	end
	--local position = surface.find_non_colliding_position(name, wave_defense_table.spawn_position, 48, 2)
	--if not position then return false end
	local biter = surface.create_entity({name = name, position = wave_defense_table.spawn_position, force = "enemy"})
	biter.ai_settings.allow_destroy_when_commands_fail = false
	biter.ai_settings.allow_try_return_to_spawner = false
	if is_boss_biter then BiterHealthBooster.add_boss_unit(biter, global.biter_health_boost * 5, 0.35) end
	wave_defense_table.active_biters[biter.unit_number] = {entity = biter, spawn_tick = game.tick}
	wave_defense_table.active_biter_count = wave_defense_table.active_biter_count + 1
	wave_defense_table.active_biter_threat = wave_defense_table.active_biter_threat + math_round(threat_values[name] * global.biter_health_boost, 2)
	return biter
end

local function set_next_wave()
	local wave_defense_table = WD.get_table()
	wave_defense_table.wave_number = wave_defense_table.wave_number + 1

	local threat_gain = wave_defense_table.wave_number * wave_defense_table.threat_gain_multiplier
	if wave_defense_table.wave_number > 1000 then
		threat_gain = threat_gain * (wave_defense_table.wave_number * 0.001)
	end
	if wave_defense_table.wave_number % 25 == 0 then
		wave_defense_table.boss_wave = true
		threat_gain = threat_gain * 2
	end

	wave_defense_table.threat = wave_defense_table.threat + math_floor(threat_gain)
	wave_defense_table.last_wave = wave_defense_table.next_wave
	wave_defense_table.next_wave = game.tick + wave_defense_table.wave_interval
end

local function reform_group(group)
	local wave_defense_table = WD.get_table()
	local group_position = {x = group.position.x, y = group.position.y}
	local step_length = wave_defense_table.unit_group_command_step_length
	local position = group.surface.find_non_colliding_position("biter-spawner", group_position, step_length, 4)
	if position then
		local new_group = group.surface.create_unit_group{position = position, force = group.force}
		for key, biter in pairs(group.members) do
			new_group.add_member(biter)
		end
		debug_print("Creating new unit group, because old one was stuck.")
		table_insert(wave_defense_table.unit_groups, new_group)
		return new_group
	else
		debug_print("Destroying stuck group.")
		--table.remove(wave_defense_table.unit_groups, group) --need group id instead to work, so as of now, groups are removed only by regular remove checks :( !
		group.destroy()
	end
	return nil
end

local function get_commmands(group)
	local wave_defense_table = WD.get_table()
	local commands = {}
	local group_position = {x = group.position.x, y = group.position.y}
	local step_length = wave_defense_table.unit_group_command_step_length

	if math_random(1,2) == 1 then
		local side_target = SideTargets.get_side_target()
		if side_target then
			local target_position = side_target.position
			local distance_to_target = math_floor(math_sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
			local steps = math_floor(distance_to_target / step_length) + 1
			local vector = {math_round((target_position.x - group_position.x) / steps, 3), math_round((target_position.y - group_position.y) / steps, 3)}

			if wave_defense_table.debug then
				debug_print("get_commmands - to side_target x" .. side_target.position.x .. " y" .. side_target.position.y)
				debug_print("get_commmands - distance_to_target:" .. distance_to_target .. " steps:" .. steps)
				debug_print("get_commmands - vector " .. vector[1] .. "_" .. vector[2])
			end

			for i = 1, steps, 1 do
				local old_position = group_position
				group_position.x = group_position.x + vector[1]
				group_position.y = group_position.y + vector[2]
				local obstacles = group.surface.find_entities_filtered{position = old_position, radius = step_length, type = {"simple-entity", "tree"}, limit = 50}
				if obstacles then
					shuffle_distance(obstacles, old_position)
					for i = 1, #obstacles, 1 do
						if obstacles[i].valid then
							commands[#commands + 1] = {
								type = defines.command.attack,
								target = obstacles[i],
								distraction = defines.distraction.by_enemy
							 }
						end
					end
				end
				local position = group.surface.find_non_colliding_position("rocket-silo", group_position, step_length, 4)
				if position then
					-- commands[#commands + 1] = {
					-- 	type = defines.command.go_to_location,
					-- 	destination = {x = position.x, y = position.y},
					-- 	distraction = defines.distraction.by_anything
					-- }
					commands[#commands + 1] = {
						type = defines.command.attack_area,
						destination = {x = position.x, y = position.y},
						radius = 16,
						distraction = defines.distraction.by_anything
					}
				else
					local obstacles = group.surface.find_entities_filtered{position = group_position, radius = step_length, type = {"simple-entity", "tree"}, limit = 50}
					if obstacles then
						shuffle_distance(obstacles, old_position)
		        for i = 1, #obstacles, 1 do
		          if obstacles[i].valid then
		            commands[#commands + 1] = {
				          type = defines.command.attack,
				          target = obstacles[i],
			            distraction = defines.distraction.by_enemy
		    	       }
		          end
		        end
		      end
				end
			end

			commands[#commands + 1] = {
				type = defines.command.attack,
				target = side_target,
				distraction = defines.distraction.by_enemy,
			}
		end
	end

	local target_position = wave_defense_table.target.position
	local distance_to_target = math_floor(math_sqrt((target_position.x - group_position.x) ^ 2 + (target_position.y - group_position.y) ^ 2))
	local steps = math_floor(distance_to_target / step_length) + 1
	local vector = {math_round((target_position.x - group_position.x) / steps, 3), math_round((target_position.y - group_position.y) / steps, 3)}

	if wave_defense_table.debug then
		debug_print("get_commmands - to main target x" .. target_position.x .. " y" .. target_position.y)
		debug_print("get_commmands - distance_to_target:" .. distance_to_target .. " steps:" .. steps)
		debug_print("get_commmands - vector " .. vector[1] .. "_" .. vector[2])
	end

	for i = 1, steps, 1 do
		local old_position = group_position
		group_position.x = group_position.x + vector[1]
		group_position.y = group_position.y + vector[2]
		local obstacles = group.surface.find_entities_filtered{position = old_position, radius = step_length / 2, type = {"simple-entity", "tree"}, limit = 50}
		if obstacles then
			shuffle_distance(obstacles, old_position)
			for i = 1, #obstacles, 1 do
				if obstacles[i].valid then
					commands[#commands + 1] = {
						type = defines.command.attack,
						target = obstacles[i],
						distraction = defines.distraction.by_enemy
					 }
				end
			end
		end
		local position = group.surface.find_non_colliding_position("rocket-silo", group_position, step_length, 1)
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
		destination = {x = target_position.x, y = target_position.y},
		radius = 8,
		distraction = defines.distraction.by_enemy
	}

	commands[#commands + 1] = {
		type = defines.command.attack,
		target = wave_defense_table.target,
		distraction = defines.distraction.by_enemy,
	}

	return commands
end

local function command_unit_group(group)
	local wave_defense_table = WD.get_table()
	if not wave_defense_table.unit_group_last_command[group.group_number] then
		wave_defense_table.unit_group_last_command[group.group_number] = game.tick - (wave_defense_table.unit_group_command_delay + 1)
	end
	if wave_defense_table.unit_group_last_command[group.group_number] then
		if wave_defense_table.unit_group_last_command[group.group_number] + wave_defense_table.unit_group_command_delay > game.tick then return end
	end
	local tile = group.surface.get_tile(group.position)
	if tile.valid and tile.collides_with("player-layer") then
		group = reform_group(group)
	end
	if not group then return end

	group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = get_commmands(group)
	})

	wave_defense_table.unit_group_last_command[group.group_number] = game.tick
end

local function give_commands_to_unit_groups()
	local wave_defense_table = WD.get_table()
	if #wave_defense_table.unit_groups == 0 then return end
	if not wave_defense_table.target then return end
	if not wave_defense_table.target.valid then return end
	for k, group in pairs(wave_defense_table.unit_groups) do
		if group.valid then
			command_unit_group(group)
		else
			table.remove(wave_defense_table.unit_groups, k)
		end
	end
end

local function spawn_unit_group()
	local wave_defense_table = WD.get_table()
	if not can_units_spawn() then return end
	if not wave_defense_table.target then return end
	if not wave_defense_table.target.valid then return end
	if get_active_unit_groups_count() >= wave_defense_table.max_active_unit_groups then return end
	local surface = game.surfaces[wave_defense_table.surface_index]
	set_group_spawn_position(surface)
	local pos = wave_defense_table.spawn_position
	if not surface.can_place_entity({name = "small-biter", position = pos}) then return end

	local radius = 10
	local area = {left_top = {pos.x - radius, pos.y - radius}, right_bottom = {pos.x + radius, pos.y + radius}}
	for k,v in pairs(surface.find_entities_filtered{area = area, name = "land-mine"}) do if v and v.valid then v.die() end end

	BiterRolls.wave_defense_set_unit_raffle(wave_defense_table.wave_number)

	debug_print("Spawning unit group at x" .. wave_defense_table.spawn_position.x .." y" .. wave_defense_table.spawn_position.y)
	local unit_group = surface.create_unit_group({position = wave_defense_table.spawn_position, force = "enemy"})
	local group_size = math_floor(wave_defense_table.average_unit_group_size * group_size_modifier_raffle[math_random(1, group_size_modifier_raffle_size)])
	for _ = 1, group_size, 1 do
		local biter = spawn_biter(surface)
		if not biter then break end
		unit_group.add_member(biter)
	end

	if wave_defense_table.boss_wave then
		local count = math_random(1, math_floor(wave_defense_table.wave_number * 0.01) + 2)
		if count > 8 then count = 8 end
		for _ = 1, count, 1 do
			local biter = spawn_biter(surface, true)
			if not biter then break end
			unit_group.add_member(biter)
		end
		wave_defense_table.boss_wave = false
	end

	table_insert(wave_defense_table.unit_groups, unit_group)
	return true
end

local function log_threat()
	local wave_defense_table = WD.get_table()
	wave_defense_table.threat_log_index = wave_defense_table.threat_log_index + 1
	wave_defense_table.threat_log[wave_defense_table.threat_log_index] = wave_defense_table.threat
	if wave_defense_table.threat_log_index > 900 then wave_defense_table.threat_log[wave_defense_table.threat_log_index - 901] = nil end
end

local tick_tasks = {
	[30] = set_main_target,
	[60] = set_enemy_evolution,
	[90] = spawn_unit_group,
	[120] = give_commands_to_unit_groups,
	[150] = ThreatEvent.build_nest,
	[180] = ThreatEvent.build_worm,
	[3600] = time_out_biters,
	[7200] = refresh_active_unit_threat,
}

local function on_tick()
	local wave_defense_table = WD.get_table()
	if wave_defense_table.game_lost then return end

	if game.tick > wave_defense_table.next_wave then	set_next_wave() end

	local t = game.tick % 300
	local t2 = game.tick % 18000

	if tick_tasks[t] then tick_tasks[t]() end
	if tick_tasks[t2] then tick_tasks[t2]() end

	if game.tick % 60 == 0 then log_threat() end
	for _, player in pairs(game.connected_players) do update_gui(player) end
end

local function on_init()
	local wave_defense_table = WD.get_table()
	wave_defense_table.reset_wave_defense()
end

event.on_nth_tick(30, on_tick)
return Public
