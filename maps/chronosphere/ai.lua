local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Rand = require 'maps.chronosphere.random'
local Raffle = require "maps.chronosphere.raffles"
local Public = {}

local random = math.random
local floor = math.floor

local normal_area = {left_top = {-480, -480}, right_bottom = {480, 480}}
local fish_area = {left_top = {-1100, -400}, right_bottom = {1100, 400}}


-----------commands-----------

local function move_to(position)
  local command = {
    type = defines.command.go_to_location,
    destination = position,
    distraction = defines.distraction.by_anything
  }
  return command
end

local function attack_target(target)
  if not target.valid then return end
  local command = {
		type = defines.command.attack,
		target = target,
		distraction = defines.distraction.by_anything,
	}
  return command
end

local function attack_area(position, radius)
  local command = {
    type = defines.command.attack_area,
    destination = position,
    radius = radius or 25,
    distraction = defines.distraction.by_anything
   }
   return command
end

local function attack_obstacles(surface, position)
  local commands = {}
  local obstacles = surface.find_entities_filtered{position = position, radius = 25, type = {"simple-entity", "tree", "simple-entity-with-owner"}, limit = 100}
  if obstacles then
    Rand.shuffle(obstacles)
    Rand.shuffle_distance(obstacles, position)
    for i = 1, #obstacles, 1 do
      if obstacles[i].valid then
        commands[#commands + 1] = {
          type = defines.command.attack,
          target = obstacles[i],
          distraction = defines.distraction.by_anything
        }
      end
    end
  end
  commands[#commands + 1] = move_to(position)
  local command = {
    type = defines.command.compound,
    structure_type = defines.compound_command.return_last,
    commands = commands
  }
  return command
end

local function multicommand(group, commands)
  if #commands > 0 then
    local command = {
      type = defines.command.compound,
      structure_type = defines.compound_command.return_last,
      commands = commands
    }
    group.set_command(command)
  end
end

local function multi_attack(surface, target)
  surface.set_multi_command({
    command = attack_target(target),
    unit_count = 16 + random(1, floor(1 + game.forces["enemy"].evolution_factor * 100)) * Difficulty.get().difficulty_vote_value,
    force = "enemy",
    unit_search_distance = 1024
  })
end

------------------------misc functions----------------------

local function generate_side_attack_target(surface, position)
  local targets = {
    "character",
    "pumpjack",
    "radar",
    "burner-mining-drill",
    "electric-mining-drill",
    "nuclear-reactor",
    "boiler",
    "assembling-machine-1",
    "assembling-machine-2",
    "assembling-machine-3",
    "oil-refinery",
    "centrifuge",
    "burner-inserter"
  }
  local entities = surface.find_entities_filtered{name = targets}
  if #entities < 1 then return false end
  entities = Rand.shuffle(entities)
  entities = Rand.shuffle_distance(entities, position)
  local weights = {}
  for index, _ in pairs(entities) do
    weights[#weights + 1] = 1 + floor((#entities - index) / 2)
  end
  return Rand.raffle(entities, weights)
end

local function generate_main_attack_target()
  local objective = Chrono_table.get_table()
  local targets = {objective.locomotive, objective.locomotive, objective.locomotive_cargo[1], objective.locomotive_cargo[2], objective.locomotive_cargo[3]}
  return targets[random(1, #targets)]
end

local function generate_expansion_position(start_pos)
  local objective = Chrono_table.get_table()
  local target_pos = objective.locomotive.position
  return {x = (start_pos.x * 0.90 + target_pos.x * 0.10) , y = (start_pos.y * 0.90 + target_pos.y * 0.10)}
end

local function get_random_close_spawner(surface)
  local objective = Chrono_table.get_table()
	local area = normal_area
  if objective.world.id == 7 then area = fish_area end

	local spawners = surface.find_entities_filtered({type = "unit-spawner", force = "enemy", area = area})
	if not spawners[1] then return false end
  spawners = Rand.shuffle(spawners)
  spawners = Rand.shuffle_distance(spawners, objective.locomotive.position)
  local weights = {}
  for index, _ in pairs(spawners) do
    weights[#weights + 1] = 1 + floor((#spawners - index) / 2)
  end
  return Rand.raffle(spawners, weights)
end

local function is_biter_inactive(biter)
	if not biter.entity then
		return true
	end
	if not biter.entity.valid then
		return true
	end
	if not biter.entity.unit_group then
		return true
	end
	if not biter.entity.unit_group.valid then
		return true
	end
	if game.tick - biter.active_since > 162000 then
		biter.entity.destroy()
		return true
	end
  return false
end

local function get_active_biter_count()
  local bitertable = Chrono_table.get_biter_table()
	local count = 0
	for k, biter in pairs(bitertable.active_biters) do
    if biter.entity.valid then
		  count = count + 1
    else
      bitertable[k] = nil
    end
	end
	return count
end

local function select_units_around_spawner(spawner, size)
  local bitertable = Chrono_table.get_biter_table()
  local difficulty = Difficulty.get().difficulty_vote_value
  if not size then size = 1 end

	local biters = spawner.surface.find_enemy_units(spawner.position, 50, "player")
	if not biters[1] then return nil end
	local valid_biters = {}

	local unit_count = 0

	for _, biter in pairs(biters) do
		if unit_count >= floor(Balance.max_new_attack_group_size(difficulty) * size) then break end
		if biter.force.name == "enemy" and bitertable.active_biters[biter.unit_number] == nil then
			valid_biters[#valid_biters + 1] = biter
			bitertable.active_biters[biter.unit_number] = {entity = biter, active_since = game.tick}
			unit_count = unit_count + 1
		end
	end
	--Manual spawning of additional units
  local size_of_biter_raffle = #bitertable.biter_raffle
	if size_of_biter_raffle > 0 then
		for _ = 1, floor(Balance.max_new_attack_group_size(difficulty) * size - unit_count), 1 do
			local biter_name = bitertable.biter_raffle[random(1, size_of_biter_raffle)]
			local position = spawner.surface.find_non_colliding_position(biter_name, spawner.position, 50, 2)
			if not position then break end

			local biter = spawner.surface.create_entity({name = biter_name, force = "enemy", position = position})
      if bitertable.free_biters > 0 then
        bitertable.free_biters = bitertable.free_biters - 1
      else
        local local_pollution = math.min(spawner.surface.get_pollution(spawner.position), 400 * game.map_settings.pollution.enemy_attack_pollution_consumption_modifier * game.forces.enemy.evolution_factor)
        spawner.surface.pollute(spawner.position, -local_pollution)
        game.pollution_statistics.on_flow("biter-spawner", -local_pollution)
        if local_pollution < 1 then break end
      end
			valid_biters[#valid_biters + 1] = biter
			bitertable.active_biters[biter.unit_number] = {entity = biter, active_since = game.tick}
		end
	end
	return valid_biters
end

local function pollution_requirement(surface, position, main)
  local objective = Chrono_table.get_table()
  if not position then
    position = objective.locomotive.position
    main = true
  end
  if objective.world.id == 7 then return true end
  local pollution = surface.get_pollution(position)
  local pollution_to_eat = Balance.pollution_spent_per_attack(Difficulty.get().difficulty_vote_value)
  local multiplier = 0.5
  if main then multiplier = 4 end
  if pollution > multiplier * pollution_to_eat then
    surface.pollute(position, -pollution_to_eat)
    game.pollution_statistics.on_flow("small-biter", -pollution_to_eat)
    return true
  end
  return false
end

local function set_biter_raffle_table(surface)
  local objective = Chrono_table.get_table()
  local bitertable = Chrono_table.get_biter_table()
	local area = normal_area
  if objective.world.id == 7 then area = fish_area end
	local biters = surface.find_entities_filtered({type = "unit", force = "enemy", area = area, limit = 100})
	if not biters[1] then return end
	local i = 1
	for key, e in pairs(biters) do
		if key % 5 == 0 then
			bitertable.biter_raffle[i] = e.name
			i = i + 1
		end
	end
end

local function create_attack_group(surface, size)
  local objective = Chrono_table.get_table()
  local bitertable = Chrono_table.get_biter_table()
	if get_active_biter_count() > 512 * Difficulty.get().difficulty_vote_value then
		return nil
	end
	local spawner = get_random_close_spawner(surface)
	if not spawner then
		return nil
	end
	local position = surface.find_non_colliding_position("rocket-silo", spawner.position, 256, 1)
	local units = select_units_around_spawner(spawner, size)
	if not units then return nil end
	local unit_group = surface.create_unit_group({position = position, force = "enemy"})
	for _, unit in pairs(units) do unit_group.add_member(unit) end
  bitertable.unit_groups[unit_group.group_number] = unit_group
  return unit_group
end

--------------------------command functions-------------------------------

local function colonize(group)
  --if _DEBUG then game.print(game.tick ..": colonizing") end
  local surface = group.surface
  local evo = floor(game.forces['enemy'].evolution_factor * 20)
  local nests = random(1 + evo, 2 + evo * 2)
  local commands = {}
  local biters = surface.find_entities_filtered {position = group.position, radius = 30, name = Raffle.biters, force = 'enemy'}
  local goodbiters = {}
  if #biters > 1 then
    for i = 1, #biters, 1 do
      if biters[i].unit_group == group then
        goodbiters[#goodbiters + 1] = biters[i]
      end
    end
  end
  local eligible_spawns
  if #goodbiters < 10 then
    if #group.members < 10 then
      group.destroy()
    end
    return
  else
    eligible_spawns = 1 + floor(#goodbiters / 10)
  end
  local success = false

  for i = 1, nests, 1 do
    if eligible_spawns < i then break end
    local pos = surface.find_non_colliding_position('biter-spawner', group.position, 20, 1, true)
    if pos then
      --game.print("[gps=" .. pos.x .. "," .. pos.y .."," .. surface.name .. "]")
      success = true
      if random(1, 5) == 1 then
        local evo = group.force.evolution_factor
        surface.create_entity({name = Raffle.worms[random(1 + floor(evo * 8), floor(1 + evo * 16))], position = pos, force = group.force})
      else
        surface.create_entity({name = Raffle.spawners[random(1, #Raffle.spawners)], position = pos, force = group.force})
      end
    else
      commands = {
        attack_obstacles(surface, group.position)
      }
    end
  end
  if success then
    for i = 1, #goodbiters, 1 do
      if goodbiters[i].valid then
        goodbiters[i].destroy()
      end
    end
    return
  end
  if #commands > 0 then
    --game.print("Attacking [gps=" .. commands[1].target.position.x .. "," .. commands[1].target.position.y .. "]")
    multicommand(group, commands)
  end
end

local function send_near_biters_to_objective()
  local objective = Chrono_table.get_table()
  if objective.game_lost then return end
  local target = generate_main_attack_target()
  if not target or not target.valid then return end
  if pollution_requirement(target.surface, target.position, true) or random(1, math.max(1, 40 - objective.chronojumps)) == 1 then
    if _DEBUG then game.print(game.tick .. ": sending objective wave") end
    multi_attack(target.surface, target)
  end
end

local function attack_check(group, target, main)
  local commands = {}
  if pollution_requirement(group.surface, target.position, main) then
    commands = {
      attack_target(target),
      attack_area(target.position, 32)
    }
  else
    local position = generate_expansion_position(group.position)
    commands = {
      attack_obstacles(group.surface, position)
    }
  end
  multicommand(group, commands)
end

local function give_new_orders(group)
  local target = generate_side_attack_target(group.surface, group.position)
  if not target or not target.valid or not pollution_requirement(group.surface, target.position, false) then
    colonize(group)
    return
  end
  if not group or not group.valid or not target or not target.valid then return end
  local commands = {
    attack_target(target),
    attack_area(target.position, 32)
  }
  multicommand(group, commands)
end

------------------------- tick minute functions--------------------

local function destroy_inactive_biters()
  local bitertable = Chrono_table.get_biter_table()
  for unit_number, biter in pairs(bitertable.active_biters) do
      if is_biter_inactive(biter, unit_number) then
          bitertable.active_biters[unit_number] = nil
          bitertable.free_biters = bitertable.free_biters + 1
      end
  end
end

local function prepare_biters()
  local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
  set_biter_raffle_table(surface)
  --if _DEBUG then game.print(game.tick .. ": biters prepared") end
end

function Public.perform_rogue_attack()
  local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	local group = create_attack_group(surface, 0.2)
  if not group or not group.valid then return end
  local target = generate_side_attack_target(surface, group.position)
  if not target or not target.valid then return end
  attack_check(group, target, false)
  --if _DEBUG then game.print(game.tick ..": sending rogue attack") end
end

function Public.perform_main_attack()
  local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	local group = create_attack_group(surface, 1)
  local target = generate_main_attack_target()
  if not group or not group.valid or not target or not target.valid then return end
  attack_check(group, target, true)
  --if _DEBUG then game.print(game.tick ..": sending main attack") end
end

local function check_groups()
  local objective = Chrono_table.get_table()
  local bitertable = Chrono_table.get_biter_table()
  for index, group in pairs(bitertable.unit_groups) do
    if not group.valid or group.surface.index ~= objective.active_surface_index or #group.members < 1 then
      bitertable.unit_groups[index] = nil
    else
      if group.state == defines.group_state.finished then
        give_new_orders(group)
      elseif group.state == defines.group_state.gathering then
        group.start_moving()
      end
    end
  end
end

function Public.Tick_actions(tick)
  local objective = Chrono_table.get_table()
  if objective.chronojumps == 0 then return end
  if objective.passivetimer < 60 then return end
  local tick_minute_functions = {

  	[100] = destroy_inactive_biters,
  	[200] = prepare_biters,		-- setup for main_attack
  	[400] = Public.perform_rogue_attack,
  	[700] = Public.perform_main_attack,
  	[1000] = Public.perform_main_attack,
  	[1300] = Public.perform_main_attack,
  	[1500] = Public.perform_main_attack,	-- call perform_main_attack 7 times on different ticks
  	[3200] = send_near_biters_to_objective,
  	[3500] = check_groups,
  }
  local key = tick % 3600
  if tick_minute_functions[key] then tick_minute_functions[key]() end
end

return Public
