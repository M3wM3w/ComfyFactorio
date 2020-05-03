local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Public_tick = {}

local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil
local math_min = math.min

function Public_tick.check_chronoprogress()
  local objective = Chrono_table.get_table()
  if objective.planet[1].type.id == 19 then
    if objective.passivetimer == 10 then
      game.print({"chronosphere.message_danger1"}, {r=0.98, g=0.66, b=0.22})
      game.print({"chronosphere.message_danger2"}, {r=0.98, g=0.66, b=0.22})
    elseif objective.passivetimer == 25 then
      game.print({"chronosphere.message_danger3"}, {r=0.98, g=0, b=0})
    elseif objective.passivetimer == 30 then
      game.print({"chronosphere.message_danger4"}, {r=0.98, g=0, b=0})
    end
  end

  if objective.passivetimer == math_floor(objective.chrononeeds * 0.50 / objective.passive_charge_rate) and objective.chronojumps > 3 then
		game.print({"chronosphere.message_rampup50"}, {r=0.98, g=0.66, b=0.22})
	end

	if objective.chronotimer == objective.chrononeeds - 180  then
		game.print({"chronosphere.message_jump180"}, {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 60  then
		game.print({"chronosphere.message_jump60"}, {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer == objective.chrononeeds - 30 then
		game.print({"chronosphere.message_jump30"}, {r=0.98, g=0.66, b=0.22})
	elseif objective.chronotimer >= objective.chrononeeds - 10 and objective.chrononeeds - objective.chronotimer > 0 then
		game.print("Comfylatron: Jump in " .. objective.chrononeeds - objective.chronotimer .. " seconds!", {r=0.98, g=0.66, b=0.22})
	end
	if objective.chronotimer >= objective.chrononeeds then
		return true
	end
  return false
end

function Public_tick.record_energy_historyA()
  local objective = Chrono_table.get_table()
  local acus = objective.acumulators
  if #objective.accumulator_energy_history == 0 and #acus > 0 then
    e = 0
    for i = 1,#acus,1 do
      if acus[i].valid then
        e = e + acus[i].energy
      end
    end
    objective.accumulator_energy_history[1] = e
  end
end

function Public_tick.record_energy_historyB()
  local objective = Chrono_table.get_table()
  local acus = objective.acumulators
  if #objective.accumulator_energy_history == 1 and #acus > 0 then
    e = 0
    for i = 1,#acus,1 do
      if acus[i].valid then
        e = e + acus[i].energy
      end
    end
    objective.accumulator_energy_history[2] = e
  end
end

function Public_tick.charge_chronosphere()
  local objective = Chrono_table.get_table()
	if not objective.acumulators then return end
	if not objective.chronotimer then return end
	if objective.passivetimer < 10 then return end
	if objective.planet[1].type.id == 17 or objective.planet[1].type.id == 19 then return end
	local acus = objective.acumulators
	if #acus < 1 then return end
	for i = 1, #acus, 1 do
		if not acus[i].valid then return end
		local energy = acus[i].energy
		if energy > 3010000 and objective.chronotimer < objective.chrononeeds - 182 then
			acus[i].energy = acus[i].energy - 3000000
      objective.chronotimer = objective.chronotimer + 1
<<<<<<< Updated upstream

      local exterior_pollution = Balance.train_base_pollution_due_to_charging(objective.jumps) * Balance.train_pollution_difficulty_scaling() * (3 / (objective.upgrades[2] / 3 + 1))

      game.surfaces[objective.active_surface_index].pollute(objective.locomotive.position, exterior_pollution)
      game.pollution_statistics.set_input_count(game.pollution_statistics.get_input_count("locomotive") + "locomotive",exterior_pollution)
=======
      local pollution = (10 + 2 * objective.chronojumps) * (3 / (objective.upgrades[2] / 3 + 1)) * (((global.difficulty_vote_value - 1) * 3 / 5) + 1)
			game.surfaces[objective.active_surface_index].pollute(objective.locomotive.position, pollution)
      game.pollution_statistics.set_input_count("locomotive",pollution + game.pollution_statistics.get_input_count("locomotive"))
>>>>>>> Stashed changes
    end
	end
end

function Public_tick.transfer_pollution()
  local objective = Chrono_table.get_table()
	local surface = game.surfaces["cargo_wagon"]
<<<<<<< Updated upstream
  if not surface then return end

  local total_interior_pollution = surface.get_total_pollution()

  local exterior_pollution = total_interior_pollution * (3 / (objective.upgrades[2] / 3 + 1)) * Balance.train_pollution_difficulty_scaling()
  
  game.surfaces[objective.active_surface_index].pollute(objective.locomotive.position, exterior_pollution)
  -- attribute the difference to the locomotive in the stats:
  game.pollution_statistics.set_input_count("locomotive",game.pollution_statistics.get_input_count("locomotive") + exterior_pollution - total_interior_pollution)
  surface.clear_pollution()
=======
	if not surface then return end
	local pollution = surface.get_total_pollution() * (3 / (objective.upgrades[2] / 3 + 1)) * (((global.difficulty_vote_value - 1) * 3 / 5) + 1)
  game.surfaces[objective.active_surface_index].pollute(objective.locomotive.position, pollution)
  game.pollution_statistics.set_input_count("locomotive",pollution + game.pollution_statistics.get_input_count("locomotive"))
	surface.clear_pollution()
>>>>>>> Stashed changes
end

function Public_tick.boost_evolution()
	local objective = Chrono_table.get_table()
	if objective.passivetimer > objective.chrononeeds * 0.50 and objective.chronojumps > 3 then
		local evolution = game.forces.enemy.evolution_factor
		evolution = evolution + (evolution / 500) * Balance.evo_50ramp_difficulty_scaling()
		if evolution > 1 then evolution = 1 end
		game.forces.enemy.evolution_factor = evolution
	end
end

function Public_tick.move_items()
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

function Public_tick.output_items()
  local objective = Chrono_table.get_table()
	if objective.game_lost == true then return end
	if not objective.outchests then return end
	if not objective.locomotive_cargo[2] then return end
	if not objective.locomotive_cargo[3] then return end
	if objective.upgrades[8] ~= 1 then return end
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
	end
end

function Public_tick.repair_train()
	local objective = Chrono_table.get_table()
	if not game.surfaces["cargo_wagon"] then return 0 end
	if objective.game_lost == true then return 0 end
	local count = 0
	local inv = objective.upgradechest[0].get_inventory(defines.inventory.chest)
	if objective.health < objective.max_health then
		count = inv.get_item_count("repair-pack")
		count = math_min(count, objective.upgrades[6] + 1, math_ceil((objective.max_health - objective.health) / Balance.Chronotrain_HP_repaired_per_pack))
		if count > 0 then inv.remove({name = "repair-pack", count = count}) end
	end
  return count * -Balance.Chronotrain_HP_repaired_per_pack
end

function Public_tick.spawn_poison()
  local objective = Chrono_table.get_table()
  local surface = game.surfaces[objective.active_surface_index]
  local random_x = math_random(-460,460)
  local random_y = math_random(-460,460)
  local tile = surface.get_tile(random_x, random_y)
  if not tile.valid then return end
  if tile.name == "water-shallow" or tile.name == "water-mud" then
    surface.create_entity({name = "poison-cloud", position = {x = random_x, y = random_y}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x + 2, y = random_y + 2}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x - 2, y = random_y - 2}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x + 2, y = random_y - 2}})
    surface.create_entity({name = "poison-cloud", position = {x = random_x - 2, y = random_y + 2}})
  end
end

local function launch_nukes()
  local objective = Chrono_table.get_table()
  local surface = game.surfaces[objective.active_surface_index]
  if objective.dangers and #objective.dangers > 1 then
    for i = 1, #objective.dangers, 1 do
      if objective.dangers[i].destroyed == false then
        local fake_shooter = surface.create_entity({name = "character", position = objective.dangers[i].silo.position, force = "enemy"})
        surface.create_entity({name = "atomic-rocket", position = objective.dangers[i].silo.position, force = "enemy", speed = 1, max_range = 800, target = objective.locomotive, source = fake_shooter})
        game.print({"chronosphere.message_nuke"}, {r=0.98, g=0, b=0})
      end
    end
  end
end

function Public_tick.dangertimer()
  local objective = Chrono_table.get_table()
  local timer = objective.dangertimer
  if timer == 0 then return end
  if objective.planet[1].type.id == 19 then
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

function Public_tick.offline_players()
  local objective = Chrono_table.get_table()
  if objective.chronotimer > objective.chrononeeds - 182 or objective.passivetimer < 30 then return end
  --local current_tick = game.tick
  local players = objective.offline_players
  local surface = game.surfaces[objective.active_surface_index]
  if #players > 0 then
    --log("nonzero offline players")
    local later = {}
    for i = 1, #players, 1 do
      if players[i] and game.players[players[i].index] and game.players[players[i].index].connected then
        --game.print("deleting already online character from list")
        players[i] = nil
      else
        if players[i] and players[i].tick < game.tick - 54000 then
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
            -- also want to mark the player as offline for purposes of 'time played?'
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
		objective.offline_players = players
  end
end


return Public_tick
