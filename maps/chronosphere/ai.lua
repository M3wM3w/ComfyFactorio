local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Rand = require 'maps.chronosphere.random'
local Public = {}

local math_random = math.random
local math_sqrt = math.sqrt
local math_floor = math.floor
local worm_raffle = {'small-worm-turret', 'medium-worm-turret', 'big-worm-turret', 'behemoth-worm-turret'}
local spawner_raffle = {'biter-spawner', 'biter-spawner', 'biter-spawner', 'spitter-spawner'}
local biter_raffle = {
  'behemoth-biter',
  'behemoth-spitter',
  'big-biter',
  'big-spitter',
  'medium-biter',
  'medium-spitter',
  'small-biter',
  'small-spitter'
}

local vector_radius = 480
local attack_vectors = {}
for x = vector_radius * -1, vector_radius, 1 do
  for y = 0, vector_radius, 1 do
      local r = math_sqrt(x ^ 2 + y ^ 2)
      if r < vector_radius and r > vector_radius - 1 then
          attack_vectors[#attack_vectors + 1] = {x, y}
      end
  end
end

local size_of_vectors = #attack_vectors

local function get_active_biter_count()
  local objective = Chrono_table.get_table()
	local count = 0
	for k, _ in pairs(objective.active_biters) do
		count = count + 1
	end
	return count
end

local function set_biter_raffle_table(surface)
  local objective = Chrono_table.get_table()
	-- It's fine to only sample the middle
	local area = {left_top = {-400,  -400}, right_bottom = {400,  400}}

	local biters = surface.find_entities_filtered({type = "unit", force = "enemy", area = area})
	if not biters[1] then return end
	local raffle = objective.biter_raffle
	local i = 1
	for key, e in pairs(biters) do
		if key % 5 == 0 then
			raffle[i] = e.name
			i = i + 1
		end
	end
end

local function is_biter_inactive(biter)
	if not biter.entity then
		--print("AI: active unit " .. unit_number .. " removed, possibly died.")
		return true
	end
	if not biter.entity.valid then
		--print("AI: active unit " .. unit_number .. " removed, biter invalid.")
		return true
	end
	if not biter.entity.unit_group then
		--print("AI: active unit " .. unit_number .. "  at x" .. biter.entity.position.x .. " y" .. biter.entity.position.y .. " removed, had no unit group.")
		return true
	end
	if not biter.entity.unit_group.valid then
		--print("AI: active unit " .. unit_number .. " removed, unit group invalid.")
		return true
	end
	if game.tick - biter.active_since > 162000 then
		--print("AI: " .. "enemy" .. " unit " .. unit_number .. " timed out at tick age " .. game.tick - biter.active_since .. ".")
		biter.entity.destroy()
		return true
	end
end

local function set_active_biters(group)
  local objective = Chrono_table.get_table()
  if not group.valid then
      return
  end
  local active_biters = objective.active_biters

  for _, unit in pairs(group.members) do
      if not active_biters[unit.unit_number] then
          active_biters[unit.unit_number] = {entity = unit, active_since = game.tick}
      end
  end
end

Public.destroy_inactive_biters = function()
  local objective = Chrono_table.get_table()
  if objective.passivetimer < 60 then
      return
  end
  for _, group in pairs(objective.unit_groups) do
      set_active_biters(group)
  end

  for unit_number, biter in pairs(objective.active_biters) do
      if is_biter_inactive(biter, unit_number) then
          objective.active_biters[unit_number] = nil
      end
  end
end

local function colonize(unit_group)
  local surface = unit_group.surface
  local evo = math_floor(game.forces['enemy'].evolution_factor * 20)
  local nests = math_random(1 + evo, 2 + evo * 2)
  local commands = {}
  local biters =
      surface.find_entities_filtered {
      position = unit_group.position,
      radius = 30,
      name = biter_raffle,
      force = 'enemy'
  }
  local goodbiters = {}
  if #biters > 1 then
      for i = 1, #biters, 1 do
          if biters[i].unit_group == unit_group then
              goodbiters[#goodbiters + 1] = biters[i]
          end
      end
  end
  local eligible_spawns
  if #goodbiters < 10 then
      --game.print("no biters to colonize")
      if #unit_group.members < 10 then
          unit_group.destroy()
      end
      return
  else
      eligible_spawns = 1 + math_floor(#goodbiters / 10)
  end
  local success = false

  for i = 1, nests, 1 do
      if eligible_spawns < i then
          break
      end
      local pos = surface.find_non_colliding_position('rocket-silo', unit_group.position, 20, 1, true)
      if not pos then
          local items =
              surface.find_entities_filtered {
              position = unit_group.position,
              radius = 32,
              type = 'item-entity',
              name = 'item-on-ground'
          }
          if #items > 0 then
              for i = 1, #items, 1 do
                  if items[i].stack.name == 'stone' then
                      items[i].destroy()
                  end
              end
              pos = surface.find_non_colliding_position('rocket-silo', unit_group.position, 20, 1, true)
          end
      end
      if pos then
          --game.print("[gps=" .. e.position.x .. "," .. e.position.y .. "]")
          success = true
          if math_random(1, 5) == 1 then
              surface.create_entity(
                  {
                      name = worm_raffle[1 + math_floor((game.forces['enemy'].evolution_factor - 0.000001) * 4)],
                      position = pos,
                      force = unit_group.force
                  }
              )
          else
              surface.create_entity(
                  {name = spawner_raffle[math_random(1, #spawner_raffle)], position = pos, force = unit_group.force}
              )
          end
      else
          local obstacles =
              surface.find_entities_filtered {
              position = unit_group.position,
              radius = 10,
              type = {'simple-entity', 'tree'},
              limit = 50
          }
          if obstacles then
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
  if success then
      for i = 1, #goodbiters, 1 do
          if goodbiters[i].valid then
              goodbiters[i].destroy()
          end
      end
  end
  if #commands > 0 then
      --game.print("Attacking [gps=" .. commands[1].target.position.x .. "," .. commands[1].target.position.y .. "]")
      unit_group.set_command(
          {
              type = defines.command.compound,
              structure_type = defines.compound_command.return_last,
              commands = commands
          }
      )
  end

  --unit_group.destroy()
end

Public.send_near_biters_to_objective = function()
  local objective = Chrono_table.get_table()
	if objective.chronojumps == 0 then return end
	if not objective.locomotive then return end
	if not objective.locomotive_cargo[1] then return end
  if not objective.locomotive_cargo[2] then return end
  if not objective.locomotive_cargo[3] then return end
  local targets = {objective.locomotive, objective.locomotive, objective.locomotive_cargo[1], objective.locomotive_cargo[2], objective.locomotive_cargo[3]}
  local random_target = targets[math_random(1, #targets)]
  if objective.game_lost then return end
  local surface = random_target.surface
  local pollution = surface.get_pollution(random_target.position)
  local success = false

  local difficulty = Difficulty.get().difficulty_vote_value
  if pollution > 4 * Balance.pollution_spent_per_attack(difficulty) or objective.planet[1].type.id == 17 then
    local pollution_to_eat = Balance.pollution_spent_per_attack(difficulty)
    surface.pollute(random_target.position, -pollution_to_eat)
    game.pollution_statistics.on_flow("biter-spawner", -pollution_to_eat)
    success = true
  else
    if objective.chronojumps < 50 then
      if math_random(1, 50 - objective.chronojumps) == 1 then success = true end
      -- game.print("not enough pollution for objective attack")
    else
      success = true
    end
  end
  if success then
    -- game.print("sending objective wave")
    game.surfaces[objective.active_surface_index].set_multi_command({
      command={
        type=defines.command.attack,
        target=random_target,
        distraction=defines.distraction.none
        },
      unit_count = 16 + math_random(1, math_floor(1 + game.forces["enemy"].evolution_factor * 100)) * Difficulty.get().difficulty_vote_value,
      force = "enemy",
      unit_search_distance=128
    })
  end
end


local function get_random_close_spawner(surface)
	local area = {left_top = {-1100, -500}, right_bottom = {1100, 500}}

	local spawners = surface.find_entities_filtered({type = "unit-spawner", force = "enemy", area = area})
	if not spawners[1] then return false end

	local spawner = spawners[math_random(1,#spawners)]
	for i = 1, 5, 1 do
		local spawner_2 = spawners[math_random(1,#spawners)]
		if spawner_2.position.x ^ 2 + spawner_2.position.y ^ 2 < spawner.position.x ^ 2 + spawner.position.y ^ 2 then spawner = spawner_2 end
	end

	return spawner
end


local function select_units_around_spawner(spawner)
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value

	local biters = spawner.surface.find_enemy_units(spawner.position, 160, "player")
	if not biters[1] then return false end
	local valid_biters = {}

	local unit_count = 0

	for _, biter in pairs(biters) do
		if unit_count >= Balance.max_new_attack_group_size(difficulty) then break end
		if biter.force.name == "enemy" and objective.active_biters[biter.unit_number] == nil then
			valid_biters[#valid_biters + 1] = biter
			objective.active_biters[biter.unit_number] = {entity = biter, active_since = game.tick}
			unit_count = unit_count + 1
		end
	end

	--Manual spawning of additional units
  local size_of_biter_raffle = #objective.biter_raffle
	if size_of_biter_raffle > 0 then
		for _ = 1, Balance.max_new_attack_group_size(difficulty) - unit_count, 1 do
			local biter_name = objective.biter_raffle[math_random(1, size_of_biter_raffle)]
			local position = spawner.surface.find_non_colliding_position(biter_name, spawner.position, 128, 2)
			if not position then break end

			local biter = spawner.surface.create_entity({name = biter_name, force = "enemy", position = position})

			valid_biters[#valid_biters + 1] = biter
			objective.active_biters[biter.unit_number] = {entity = biter, active_since = game.tick}
		end
	end
	return valid_biters
end


local function generate_attack_target(nearest_player_unit)
  local objective = Chrono_table.get_table()

  local target = Rand.raffle(
    {
      nearest_player_unit,
      objective.locomotive,
      objective.locomotive_cargo[1],
      objective.locomotive_cargo[2],
      objective.locomotive_cargo[3],
      "pumpjack",
      "radar"
    },
    {3, 2, 1, 1, 1, 2, 1}
  )

  if target == "pumpjack" or target == "radar" then
    local entities = game.surfaces[objective.active_surface_index].find_entities_filtered({
      name = target
    })
    entities=Rand.shuffle(entities)
    local entity = false
    for _, e in pairs(entities) do
      if e.is_connected_to_electric_network()
      then
        entity = e
      end
    end
    if entity and entity.valid then
      target = entity
    else
      target = objective.locomotive
    end
  end
  
  return target
end


local function send_group(unit_group, nearest_player_unit)
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value

  local target = generate_attack_target(nearest_player_unit)

  if not target.valid then colonize(unit_group) return end
  local surface = target.surface
  local pollution = surface.get_pollution(target.position)

  if pollution > 4 * Balance.pollution_spent_per_attack(difficulty) or objective.planet[1].type.id == 17 then

    local pollution_to_eat = Balance.pollution_spent_per_attack(difficulty)
    surface.pollute(target.position, -pollution_to_eat)
    game.pollution_statistics.on_flow("biter-spawner", -pollution_to_eat)
    
  
    if #unit_group.members > 0 then game.pollution_statistics.on_flow(unit_group.members[1].name or "small-biter", - pollution_to_eat) end

    local commands = {}

    local vector = attack_vectors[math_random(1, size_of_vectors)]
    local position = {target.position.x + vector[1], target.position.y + vector[2]}
    position = unit_group.surface.find_non_colliding_position("stone-furnace", position, 96, 1)
    if position then

      -- game.print("group of " .. #unit_group.members .. " to " .. position.x .. ", " .. position.y)

      commands[#commands + 1] = {
        type = defines.command.attack_area,
        destination = position,
        radius = 24,
        distraction = defines.distraction.by_enemy
    }
    end

    -- game.print("group of " .. #unit_group.members .. " to " .. target.position.x .. ", " .. target.position.y)

    commands[#commands + 1] = {
    type = defines.command.attack_area,
    destination = target.position,
    radius = 32,
    distraction = defines.distraction.by_enemy
    }

    commands[#commands + 1] = {
    type = defines.command.attack,
    target = target,
    distraction = defines.distraction.by_enemy
    }

    unit_group.set_command({
      type = defines.command.compound,
      structure_type = defines.compound_command.return_last,
      commands = commands
    })
  else
    --game.print("not enough pollution for unit attack")
    colonize(unit_group)
  end
  return true
end

local function is_chunk_empty(surface, area)
	if surface.count_entities_filtered({type = {"unit-spawner", "unit"}, area = area}) ~= 0 then return false end
	if surface.count_entities_filtered({force = "player", area = area}) ~= 0 then return false end
	if surface.count_tiles_filtered({name = {"water", "deepwater"}, area = area}) ~= 0 then return false end
	return true
end

local function get_unit_group_position(surface, nearest_player_unit, spawner)
	if math_random(1,3) ~= 1 then
		local spawner_chunk_position = {x = math.floor(spawner.position.x / 32), y = math.floor(spawner.position.y / 32)}
		local valid_chunks = {}
		for x = -2, 2, 1 do
			for y = -2, 2, 1 do
				local chunk = {x = spawner_chunk_position.x + x, y = spawner_chunk_position.y + y}
				local area = {{chunk.x * 32, chunk.y * 32},{chunk.x * 32 + 32, chunk.y * 32 + 32}}
				if is_chunk_empty(surface, area) then
					valid_chunks[#valid_chunks + 1] = chunk
				end
			end
		end

		if #valid_chunks > 0 then
			local chunk = valid_chunks[math_random(1, #valid_chunks)]
			return {x = chunk.x * 32 + 16, y = chunk.y * 32 + 16}
		end
	end

	local unit_group_position = {x = (spawner.position.x + nearest_player_unit.position.x * 0.2) , y = (spawner.position.y + nearest_player_unit.position.y * 0.2)}
	local pos = surface.find_non_colliding_position("rocket-silo", unit_group_position, 256, 1)
	if pos then unit_group_position = pos end

	if not unit_group_position then
		return false
	end
	return unit_group_position
end

local function create_attack_group(surface)
  local objective = Chrono_table.get_table()
	if 256 - get_active_biter_count() < 256 then
		return false
	end
	local spawner = get_random_close_spawner(surface)
	if not spawner then
		return false
	end
	local nearest_player_unit = surface.find_nearest_enemy({position = spawner.position, max_distance = 1024, force = "enemy"})
	if not nearest_player_unit then nearest_player_unit = objective.locomotive end
	local unit_group_position = get_unit_group_position(surface, nearest_player_unit, spawner)
	local units = select_units_around_spawner(spawner)
	if not units then return false end
	local unit_group = surface.create_unit_group({position = unit_group_position, force = "enemy"})
	for _, unit in pairs(units) do unit_group.add_member(unit) end
	send_group(unit_group, nearest_player_unit)
  objective.unit_groups[unit_group.group_number] = unit_group

end

-- Public.rogue_group = function()
--   local objective = Chrono_table.get_table()
--   if objective.passivetimer < 60 then return end
--   if not objective.locomotive then return end
--   local surface = game.surfaces[objective.active_surface_index]
--   local spawner = get_random_close_spawner(surface)
-- 	if not spawner then
-- 		return false
-- 	end
--   local position = {x = ((spawner.position.x + objective.locomotive.position.x) * 0.5) , y = ((spawner.position.y + objective.locomotive.position.y) * 0.5)}
--   local pos = surface.find_non_colliding_position("rocket-silo", position, 30, 1, true)
--   if not pos then return end
--   surface.set_multi_command({
--     command={
--       type=defines.command.build_base,
--       destination=pos,
--       distraction=defines.distraction.none,
--       ignore_planner = true
--       },
--     unit_count = 16,
--     force = "enemy",
--     unit_search_distance=128
--   })
-- end

Public.pre_main_attack = function()
  local objective = Chrono_table.get_table()
  if objective.chronojumps == 0 then return end
	local surface = game.surfaces[objective.active_surface_index]
  set_biter_raffle_table(surface)
end

Public.perform_main_attack = function()
  local objective = Chrono_table.get_table()
  if objective.chronojumps == 0 then return end
	local surface = game.surfaces[objective.active_surface_index]
	create_attack_group(surface)
end

Public.wake_up_sleepy_groups = function()
  local objective = Chrono_table.get_table()
  if objective.chronojumps == 0 then return end
  local entity
	local unit_group
	for _, biter in pairs(objective.active_biters) do
		entity = biter.entity
		if entity then
			if entity.valid then
				unit_group = entity.unit_group
				if unit_group then
					if unit_group.valid then
						if unit_group.state == defines.group_state.finished then
							local nearest_player_unit = entity.surface.find_nearest_enemy({position = entity.position, max_distance = 2048, force = "enemy"})
							if not nearest_player_unit then nearest_player_unit = objective.locomotive end
              local destination = unit_group.surface.find_non_colliding_position("rocket-silo", unit_group.position, 32, 1)
              if not destination then destination = {x = unit_group.position.x + math_random(-10,10), y = unit_group.position.y + math_random(-10,10)} end
              unit_group.set_command({
                type = defines.command.go_to_location,
                destination = destination,
                distraction = defines.distraction.by_enemy
              })
							send_group(unit_group, nearest_player_unit)
							return
            elseif unit_group.state == defines.group_state.gathering and not unit_group.surface.find_non_colliding_position("rocket-silo", unit_group.position, 3, 1) then
              local destination = unit_group.surface.find_non_colliding_position("rocket-silo", unit_group.position, 32, 1)
              if not destination then destination = {x = unit_group.position.x + math_random(-10,10), y = unit_group.position.y + math_random(-10,10)} end
              unit_group.set_command({
                type = defines.command.go_to_location,
                destination = destination,
                distraction = defines.distraction.by_enemy
              })
              -- local nearest_player_unit = entity.surface.find_nearest_enemy({position = entity.position, max_distance = 2048, force = "enemy"})
							-- if not nearest_player_unit then nearest_player_unit = objective.locomotive end
							-- send_group(unit_group, nearest_player_unit)
							return
            end
					end
				end
			end
		end
	end
end

return Public
