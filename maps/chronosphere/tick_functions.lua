local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local Server = require 'utils.server'
local Public = {}

local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil
local math_min = math.min
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad
local math_exp = math.exp

function Public.realtime_events()
  local objective = Chrono_table.get_table()

  if objective.world.id == 2 and objective.world.variant.id == 2 then
    if objective.passivetimer == 10 then
      game.print({"chronosphere.message_danger1"}, {r=0.98, g=0.66, b=0.22})
      game.print({"chronosphere.message_danger2"}, {r=0.98, g=0.66, b=0.22})
    elseif objective.passivetimer == 25 then
      game.print({"chronosphere.message_danger3"}, {r=0.98, g=0, b=0})
    elseif objective.passivetimer == 30 then
      game.print({"chronosphere.message_danger4"}, {r=0.98, g=0, b=0})
      game.print({"chronosphere.message_danger5"}, {r=0.98, g=0.66, b=0.22})
    end
  end

  if objective.jump_countdown_start_time == -1 and objective.passivetimer == math_floor(objective.chronochargesneeded * 0.50 / objective.passive_chronocharge_rate) and objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
		game.print({"chronosphere.message_rampup50"}, {r=0.98, g=0.66, b=0.22})
  end

  if objective.game_lost then return end
  if objective.jump_countdown_start_time ~= -1 then
    if objective.passivetimer == objective.jump_countdown_start_time + 180 - 60 then
      game.print({"chronosphere.message_jump60"}, {r=0.98, g=0.66, b=0.22})
    elseif objective.passivetimer == objective.jump_countdown_start_time + 180 - 30 then
      game.print({"chronosphere.message_jump30"}, {r=0.98, g=0.66, b=0.22})
    elseif objective.passivetimer >= objective.jump_countdown_start_time + 180 - 10 and objective.jump_countdown_start_time + 180 - objective.passivetimer > 0 then
      game.print({"chronosphere.message_jump10", objective.jump_countdown_start_time + 180 - objective.passivetimer}, {r=0.98, g=0.66, b=0.22})
    end
  end
end


function Public.train_pollution(source, interior_pollution)
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value
  local pos = objective.locomotive.position or {x=0,y=0}
  local pollution = 0
  local stat_target = "locomotive"
  if not interior_pollution then interior_pollution = 0 end
  if source == "passive" then
    stat_target = "heat-pipe"
    pollution = Balance.passive_pollution_rate(objective.chronojumps, difficulty, objective.upgrades[2])
  elseif source == "countdown" then
    stat_target = "electric-energy-interface"
    pollution = Balance.countdown_pollution_rate(objective.chronojumps, difficulty)
  elseif source == "postjump" then
    stat_target = "heat-interface"
    pollution = math_floor(Balance.post_jump_initial_pollution(objective.chronojumps, difficulty))
  elseif source == "accumulators" then
    stat_target = "accumulator"
    pollution = Balance.pollution_per_MJ_actively_charged(objective.chronojumps, difficulty, objective.upgrades[2])
  elseif source == "lasers" then
    stat_target = "laser-turret"
    pollution = Balance.pollution_per_MJ_actively_charged(objective.chronojumps, difficulty, objective.upgrades[2]) / 10
  elseif source == "wagons" then
    pollution =  interior_pollution * Balance.machine_pollution_transfer_from_inside_factor(difficulty, objective.upgrades[2])
  end
  game.surfaces[objective.active_surface_index].pollute(pos, pollution)
  game.pollution_statistics.on_flow(stat_target, pollution - interior_pollution)
end

function Public.transfer_pollution()
  local objective = Chrono_table.get_table()
	local surface = game.surfaces["cargo_wagon"]
  if not surface or not objective.locomotive.valid then return end
  Public.train_pollution("wagons", surface.get_total_pollution())
  surface.clear_pollution()
end

function Public.ramp_evolution()
  local objective = Chrono_table.get_table()
  local difficulty = Difficulty.get().difficulty_vote_value

	if objective.passivetimer * objective.passive_chronocharge_rate > objective.chronochargesneeded * 0.50 and objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
		local evolution = game.forces.enemy.evolution_factor
		evolution = evolution * Balance.evoramp50_multiplier_per_10s(difficulty)
		if evolution > 1 then evolution = 1 end
		game.forces.enemy.evolution_factor = evolution
	end
end

function Public.move_items()
  local objective = Chrono_table.get_table()
	if not objective.comfychests then return end
	if not objective.comfychests2 then return end
	if objective.game_lost == true then return end
  local input = objective.comfychests
  local output = objective.comfychests2
	for i = 1, 24, 1 do
		if not input[i].valid then return end
		if not output[i].valid then  return end

		local input_inventory = input[i].get_inventory(defines.inventory.chest)
		local output_inventory = output[i].get_inventory(defines.inventory.chest)
		input_inventory.sort_and_merge()
		output_inventory.sort_and_merge()
		for ii = 1, #input_inventory, 1 do
			if input_inventory[ii].valid_for_read then
				local count = output_inventory.insert(input_inventory[ii])
				input_inventory[ii].count = input_inventory[ii].count - count
			end
		end
	end
end

local function transfer_signals(index, inventory)
  local objective = Chrono_table.get_table()
  local counts = inventory.get_contents()
  if not objective.outcombinators then return end
  local combi = objective.outcombinators[index].get_or_create_control_behavior()
  local i = 1
  for name, count in pairs(counts) do
    if i > 20 then break end
    combi.set_signal(i, {signal = {type = "item", name = name}, count = count})
    i = i + 1
  end
  if i < 20 then
    for j = i, 20, 1 do
      combi.set_signal(j, nil)
    end
  end
end

function Public.output_items()
  local objective = Chrono_table.get_table()
	if objective.game_lost == true then return end
	if not objective.outchests then return end
	if not objective.locomotive_cargo[2] then return end
	if not objective.locomotive_cargo[3] then return end
	if objective.upgrades[8] < 1 then return end
	local wagon = {
		[1] = objective.locomotive_cargo[2].get_inventory(defines.inventory.cargo_wagon),
		[2] = objective.locomotive_cargo[3].get_inventory(defines.inventory.cargo_wagon)
	}
	for i = 1, 4, 1 do
		if not objective.outchests[i].valid then return end
		local inv = objective.outchests[i].get_inventory(defines.inventory.chest)
		inv.sort_and_merge()
		for ii = 1, #inv, 1 do
			if inv[ii].valid_for_read then
				local count = wagon[math_ceil(i/2)].insert(inv[ii])
				inv[ii].count = inv[ii].count - count
			end
		end
    if objective.upgrades[8] == 2 then transfer_signals(i, wagon[math_ceil(i/2)]) end
	end
end

function Public.repair_train()
	local objective = Chrono_table.get_table()
	if not game.surfaces["cargo_wagon"] then return 0 end
	if objective.game_lost == true then return 0 end
	local count = 0
  local chest = objective.upgradechest[0]
  if not chest or not chest.valid then return end
	local inv = chest.get_inventory(defines.inventory.chest)
	if objective.health < objective.max_health then
		count = inv.get_item_count("repair-pack")
		count = math_min(count, objective.upgrades[6] + 1, math_ceil((objective.max_health - objective.health) / Balance.Chronotrain_HP_repaired_per_pack))
		if count > 0 then inv.remove({name = "repair-pack", count = count}) end
	end
  return count * -Balance.Chronotrain_HP_repaired_per_pack
end

local function create_poison_cloud(position)
  local objective = Chrono_table.get_table()
  local surface = game.surfaces[objective.active_surface_index]

  local tile = surface.get_tile(position.x, position.y)
  if not tile then return end
  if not tile.valid then return end
  if tile.name == "water-shallow" or tile.name == "water-mud" then
    local random_angles = {math_rad(math_random(359)),math_rad(math_random(359)),math_rad(math_random(359)),math_rad(math_random(359))}

    surface.create_entity({name = "poison-cloud", position = {x = position.x, y = position.y}})
    surface.create_entity({name = "poison-cloud", position = {x = position.x + 12 * math_cos(random_angles[1]), y = position.y + 12 * math_sin(random_angles[1])}})
    surface.create_entity({name = "poison-cloud", position = {x = position.x + 12 * math_cos(random_angles[2]), y = position.y + 12 * math_sin(random_angles[2])}})
    surface.create_entity({name = "poison-cloud", position = {x = position.x + 12 * math_cos(random_angles[3]), y = position.y + 12 * math_sin(random_angles[3])}})
    surface.create_entity({name = "poison-cloud", position = {x = position.x + 12 * math_cos(random_angles[4]), y = position.y + 12 * math_sin(random_angles[4])}})
  end
end

function Public.spawn_poison()
  local random_x = math_random(-460,460)
  local random_y = math_random(-460,460)
  create_poison_cloud{x = random_x, y = random_y}
  if math_random(1,3) == 1 then
    local random_angles = {math_rad(math_random(359))}
    create_poison_cloud{x = random_x + 24 * math_cos(random_angles[1]), y = random_y + 24 * math_sin(random_angles[1])}
  end
end

local function launch_nukes()
  local objective = Chrono_table.get_table()
  local surface = game.surfaces[objective.active_surface_index]
  if objective.dangers and #objective.dangers > 1 then
    for i = 1, #objective.dangers, 1 do
      if objective.dangers[i].destroyed == false then
        if objective.upgrades[17] == 1 then
          game.print({"chronosphere.message_nuke_intercepted"}, {r=0, g=0.98, b=0})
          objective.upgrades[17] = 0
        else
          local fake_shooter = surface.create_entity({name = "character", position = objective.dangers[i].silo.position, force = "enemy"})
          surface.create_entity({name = "atomic-rocket", position = objective.dangers[i].silo.position, force = "enemy", speed = 1, max_range = 800, target = objective.locomotive, source = fake_shooter})
          game.print({"chronosphere.message_nuke"}, {r=0.98, g=0, b=0})
        end
      end
    end
  end
end

function Public.dangertimer()
  local objective = Chrono_table.get_table()
  local timer = objective.dangertimer
  if timer == 0 then return end
  if objective.world.id == 2 and objective.world.variant.id == 2 then
    timer = timer - 1
    if objective.dangers and #objective.dangers > 0 then
      for i = 1, #objective.dangers, 1 do
        if objective.dangers[i].destroyed == false then
          if timer == 15 then
            objective.dangers[i].silo.launch_rocket()
            objective.dangers[i].silo.rocket_parts = 100
          end
          rendering.set_text(objective.dangers[i].timer, math_floor(timer / 60) .. " min, " .. timer % 60 .. " s")
        end
      end
    end
  else
    timer = 1200
  end
  if timer < 0 then timer = 0 end
  if timer == 0 then
    launch_nukes()
    timer = 90
  end

  objective.dangertimer = timer
end

function Public.offline_players()
  local objective = Chrono_table.get_table()
  local playertable = Chrono_table.get_player_table()
  if objective.chronocharges >= objective.chronochargesneeded or objective.passivetimer < 30 then return end
  --local current_tick = game.tick
  local players = playertable.offline_players
  local surface = game.surfaces[objective.active_surface_index]
  if #players > 0 then
    --log("nonzero offline players")
    local later = {}
    for i = 1, #players, 1 do
      if players[i] and game.players[players[i].index] and game.players[players[i].index].connected then
        --game.print("deleting already online character from list")
        players[i] = nil
      else
        if players[i] and players[i].tick < game.tick - 72000 then
          --log("spawning corpse")
          local player_inv = {}
          local items = {}
          player_inv[1] = game.players[players[i].index].get_inventory(defines.inventory.character_main)
          player_inv[2] = game.players[players[i].index].get_inventory(defines.inventory.character_armor)
          player_inv[3] = game.players[players[i].index].get_inventory(defines.inventory.character_guns)
          player_inv[4] = game.players[players[i].index].get_inventory(defines.inventory.character_ammo)
          player_inv[5] = game.players[players[i].index].get_inventory(defines.inventory.character_trash)
          local e = surface.create_entity({name = "character", position = game.forces.player.get_spawn_position(surface), force = "neutral"})
          local inv = e.get_inventory(defines.inventory.character_main)
          for ii = 1, 5, 1 do
            if player_inv[ii].valid then
              for iii = 1, #player_inv[ii], 1 do
                if player_inv[ii][iii].valid then
                  items[#items + 1] = player_inv[ii][iii]
                end
              end
            end
          end
          if #items > 0 then
            for item = 1, #items, 1 do
              if items[item].valid then
                  inv.insert(items[item])
              end
            end
						game.print({"chronosphere.message_accident"}, {r=0.98, g=0.66, b=0.22})
            e.die("neutral")
					else
						e.destroy()
          end

          for ii = 1, 5, 1 do
            if player_inv[ii].valid then
              player_inv[ii].clear()
            end
          end
          players[i] = nil
        else
          later[#later + 1] = players[i]
        end
      end
    end
    players = {}
    if #later > 0 then
      for i = 1, #later, 1 do
        players[#players + 1] = later[i]
      end
    end
		playertable.offline_players = players
  end
end

function Public.request_chunks()
  local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	if objective.world.id == 7 then
		surface.request_to_generate_chunks({-800,0}, 1 + math_floor(objective.passivetimer / 5))
	else
		surface.request_to_generate_chunks({0,0}, 1 + math_floor(objective.passivetimer / 5))
	end
	--surface.force_generate_chunk_requests()
end

function Public.update_charges(tick)
  local objective = Chrono_table.get_table()
  if objective.chronocharges < objective.chronochargesneeded and objective.world.id ~= 7 then  -- < 2000
    objective.chronocharges = objective.chronocharges + objective.passive_chronocharge_rate
		-- local chronotimer_ticks_between_increase = math_floor(objective.passive_chronocharge_rate / 10) * 10 --- 60 / (1800 / 2000)
		-- if tick % chronotimer_ticks_between_increase == 0 then
		-- 	objective.chronocharges = objective.chronocharges + 1
		-- end
	end
end

local function add_step()
  local scheduletable = Chrono_table.get_schedule_table()
  if scheduletable.schedule_step ~= scheduletable.schedule_max_step then
    scheduletable.schedule_step = scheduletable.schedule_step + 1
  end
end

function Public.scheduled_surface_clearing()
  local scheduletable = Chrono_table.get_schedule_table()
  local step = scheduletable.schedule_step
  local schedule = scheduletable.schedule
  if schedule[step] then
    local surface = schedule[step].surface
    if not surface.valid then
      schedule[step] = nil
      add_step()
      return
    end
    if schedule[step].operation == "biter_clearing" then
      local biters = surface.find_entities_filtered{type = "unit", force = "enemy", limit = 10000}
      for _,biter in pairs(biters) do
        if biter.valid then biter.destroy() end
      end
      schedule[step] = nil
      add_step()
    elseif schedule[step].operation == "nest_clearing" then
      local nests = surface.find_entities_filtered{type = "unit-spawner", force = "enemy"}
      for _, nest in pairs(nests) do
        if nest.valid then nest.destroy() end
      end
      schedule[step] = nil
      add_step()
    elseif schedule[step].operation == "scrap_clearing" then
      local scrap = surface.find_entities_filtered{force = "neutral", limit = 5000}
      for _, e in pairs(scrap) do
        if e.valid then e.destroy() end
      end
      schedule[step] = nil
      add_step()
    elseif schedule[step].operation == "clear" then
      surface.clear()
      schedule[step] = nil
      add_step()
    elseif schedule[step].operation == "delete" then
      game.delete_surface(surface)
      schedule[step] = nil
      add_step()
    end
  end
end

function Public.add_schedule(surface)
  local scheduletable = Chrono_table.get_schedule_table()
  local step = scheduletable.schedule_max_step
  local add = 1
  scheduletable.schedule[step + add] = {operation = "nest_clearing", surface = surface}
  add = add + 1
  local count_biters = surface.count_entities_filtered{type = "unit", force = "enemy"}
  for i = 1, count_biters, 10000 do
    scheduletable.schedule[step + add] = {operation = "biter_clearing", surface = surface}
    add = add + 1
  end
  local count_scrap = surface.count_entities_filtered{force = "neutral"}
  for i = 1, count_scrap, 5000 do
    scheduletable.schedule[step + add] = {operation = "scrap_clearing", surface = surface}
    add = add + 1
  end
  scheduletable.schedule[step + add] = {operation = "clear", surface = surface}
  add = add + 1
  scheduletable.schedule[step + add] = {operation = "delete", surface = surface}
  scheduletable.schedule_max_step = scheduletable.schedule_max_step + add
  if scheduletable.schedule_step == step then
    scheduletable.schedule_step = scheduletable.schedule_step + 1
  end
end

function Public.change_to_neutral(surface)
  local entities = surface.find_entities_filtered{force = "player"}
  for _, entity in pairs(entities) do
    if entity.valid then
      entity.force = "neutral"
      entity.active = false
    end
  end
  local pollution = surface.get_total_pollution()
  surface.clear_pollution()
  game.pollution_statistics.on_flow("power-switch", -pollution)
end

local function shoot_laser(surface, source, enemy)
  local force = source.force
  surface.create_entity{name = "laser-beam", position = source.position, force = "player", target = enemy, source = source, max_length = 32, duration = 60 }
  local damage = enemy.damage(20 * (1 + force.get_ammo_damage_modifier("laser") + force.get_gun_speed_modifier("laser")), force, "laser", source)
end

local function shoot_acid(surface, source, enemy)
  local force = source.force
  surface.create_entity({name = 'acid-stream-spitter-behemoth', position = source.position, target = enemy, source = source, force = force})
  --local damage = enemy.damage(20 * (1 + force.get_ammo_damage_modifier("biological") + force.get_gun_speed_modifier("laser")), force, "laser", source)
end

function Public.laser_defense()
  local objective = Chrono_table.get_table()
  if objective.upgrades[22] == 0 then return end
  local surface = game.surfaces[objective.active_surface_index]
  if surface ~= objective.locomotive.surface then return end
  if not objective.laser_battery.valid then return end
  local enemies = surface.find_entities_filtered{radius = 32, limit = objective.upgrades[22], force = {"enemy", "scrapyard"}, position = objective.locomotive.position}
  if #enemies < 1 then return end
  for i = 1, math.min(objective.upgrades[22], #enemies), 1 do
    if objective.laser_battery.energy < 110000 then
      surface.create_entity({
        name = "flying-text",
        position = objective.locomotive.position,
        text = "Low Power",
        color = {r = 0.98, g = 0, b = 0}
      })
      break
    end
    local enemy = enemies[i]
    if enemy and enemy.valid and enemy.health and enemy.health > 0 then
      shoot_laser(surface, objective.locomotive, enemy)
      objective.laser_battery.energy = objective.laser_battery.energy - 100000
      Public.train_pollution("lasers")
    end
  end
end

function Public.message_game_won()
  local objective = Chrono_table.get_table()
  objective.game_lost = true
  game.print({"chronosphere.message_game_won2", objective.mainscore}, {r=0.98, g=0.66, b=0.22})
  Server.to_discord_embed({"chronosphere.message_game_won2", objective.mainscore}, true)
end

-- function Public.player_spit()
--   for _, player in pairs(game.connected_players) do
--     if not player.character or not player.character.valid then return end
--     local enemies = player.surface.find_entities_filtered{radius = 32, limit = 10, force = {"enemy", "scrapyard"}, position = player.character.position}
--     if #enemies < 1 then return end
--     for i = 1, #enemies, 1 do
--       local enemy = enemies[i]
--       if enemy and enemy.valid and enemy.health and enemy.health > 0 then
--         shoot_acid(player.surface, player.character, enemy)
--       end
--     end
--   end
-- end

return Public
