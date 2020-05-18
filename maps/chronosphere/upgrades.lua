local Chrono_table = require 'maps.chronosphere.table'
local Public = {}
local Server = require 'utils.server'
local Upgrades = require "maps.chronosphere.upgrade_list"

local function check_win()
  local objective = Chrono_table.get_table()
  if objective.fishchest then
    if objective.fishchest.valid then
      local inv = objective.fishchest.get_inventory(defines.inventory.chest)
      local countfish = inv.get_item_count("raw-fish")
      local enemies = game.surfaces[objective.active_surface_index].count_entities_filtered{force = "enemy"}
      if countfish > 0 then
        inv.remove({name = "raw-fish", count = countfish})
        objective.mainscore = objective.mainscore + countfish
        if enemies > 0 then
          game.print("Comfylatron: You delivered fish, but there is still " .. enemies .. " enemies left. Kill them all so fish are safe!", {r=0.98, g=0.66, b=0.22})
        else
          if not objective.game_reset_tick then
            objective.game_reset_tick = game.tick + 18000
            objective.game_won = true
            objective.game_lost = true
            objective.chronocharges = 200000000 - 300
			game.play_sound{path="utility/game_won", volume_modifier=0.85}
            local message = {"chronosphere.message_game_won1"}
						local message2 = "Number of delivered fish: " .. objective.mainscore
            game.print(message, {r=0.98, g=0.66, b=0.22})
						game.print(message2, {r=0.98, g=0.66, b=0.22})
            Server.to_discord_embed(message)
						Server.to_discord_embed(message2)
          end
        end
      end
    end
  end
end

local function upgrade_hp()
	local objective = Chrono_table.get_table()
	objective.max_health = 10000 + 2500 * objective.upgrades[1]
	rendering.set_text(objective.health_text, "HP: " .. objective.health .. " / " .. objective.max_health)
end

local function spawn_accumulators()
	local objective = Chrono_table.get_table()
	local x = -28
	local y = -252
	local yy = objective.upgrades[3] * 2
	local surface = game.surfaces["cargo_wagon"]
	if yy > 8 then yy = yy + 2 end
	if yy > 26 then yy = yy + 2 end
	if yy > 44 then yy = yy + 2 end
	for i = 1, 27, 1 do
		local acumulator = surface.create_entity({name = "accumulator", position = {x + 2 * i, y + yy}, force="player", create_build_effect_smoke = false})
		acumulator.minable = false
		acumulator.destructible = false
		table.insert(objective.accumulators, acumulator)
	end
end

local function upgrade_pickup()
	game.forces.player.character_loot_pickup_distance_bonus = game.forces.player.character_loot_pickup_distance_bonus + 1
end

local function upgrade_inv()
	game.forces.player.character_inventory_slots_bonus = game.forces.player.character_inventory_slots_bonus + 10
end

local function upgrade_water()
	if not game.surfaces["cargo_wagon"] then return end
  local positions = {{28,66},{28,-62},{-29,66},{-29,-62}}
  for i = 1, 4, 1 do
    local e = game.surfaces["cargo_wagon"].create_entity({name = "offshore-pump", position = positions[i], force="player"})
    e.destructible = false
    e.minable = false
  end
end

local function upgrade_out()
	local objective = Chrono_table.get_table()
	if not game.surfaces["cargo_wagon"] then return end
	local positions = {{-16,-62},{15,-62},{-16,66},{15,66}}
	local out = {}
	for i = 1, 4, 1 do
    local e = game.surfaces["cargo_wagon"].create_entity({name = "steel-chest", position = positions[i], force = "player"})
		e.destructible = false
		e.minable = false
		objective.outchests[i] = e
		out[i] = rendering.draw_text{
			text = "Output",
			surface = e.surface,
			target = e,
			target_offset = {0, -1.5},
			color = objective.locomotive.color,
			scale = 0.80,
			font = "default-game",
			alignment = "center",
			scale_with_zoom = false
		}
	end
	return out
end

local function upgrade_storage()
  local objective = Chrono_table.get_table()
  if not game.surfaces["cargo_wagon"] then return end
	local chests = {}
  local positions = {x = {-33, 32}, y = {-189, -127, -61, 1, 67, 129}}
  for i = 1, 58, 1 do
    for ii = 1, 6, 1 do
      if objective.upgrades[9] == 1 then
        chests[#chests + 1] = {entity = {name = "wooden-chest", position = {x = positions.x[1] ,y = positions.y[ii] + i}, force = "player"}, old = "none"}
        chests[#chests + 1] = {entity = {name = "wooden-chest", position = {x = positions.x[2] ,y = positions.y[ii] + i}, force = "player"}, old = "none"}
      elseif objective.upgrades[9] == 2 then
        chests[#chests + 1] = {entity = {name = "iron-chest", position = {x = positions.x[1] ,y = positions.y[ii] + i}, force = "player", fast_replace = true, spill = false}, old = "wood"}
        chests[#chests + 1] = {entity = {name = "iron-chest", position = {x = positions.x[2] ,y = positions.y[ii] + i}, force = "player", fast_replace = true, spill = false}, old = "wood"}
      elseif objective.upgrades[9] == 3 then
        chests[#chests + 1] = {entity = {name = "steel-chest", position = {x = positions.x[1] ,y = positions.y[ii] + i}, force = "player", fast_replace = true, spill = false}, old = "iron"}
        chests[#chests + 1] = {entity = {name = "steel-chest", position = {x = positions.x[2] ,y = positions.y[ii] + i}, force = "player", fast_replace = true, spill = false}, old = "iron"}
      elseif objective.upgrades[9] == 4 then
        chests[#chests + 1] = {entity = {name = "logistic-chest-storage", position = {x = positions.x[1] ,y = positions.y[ii] + i}, force = "player", fast_replace = true, spill = false}, old = "steel"}
        chests[#chests + 1] = {entity = {name = "logistic-chest-storage", position = {x = positions.x[2] ,y = positions.y[ii] + i}, force = "player", fast_replace = true, spill = false}, old = "steel"}
      end
    end
  end
	local surface = game.surfaces["cargo_wagon"]
	for i = 1, #chests, 1 do
    if objective.upgrades[9] == 1 then
      surface.set_tiles({{name = "tutorial-grid", position = chests[i].entity.position}})
    end
		local old = nil
    local oldpos = {x = chests[i].entity.position.x + 0.5, y = chests[i].entity.position.y + 0.5}
		if chests[i].old == "wood" then old = surface.find_entity("wooden-chest", oldpos)
		elseif chests[i].old == "iron" then old = surface.find_entity("iron-chest", oldpos)
		elseif chests[i].old == "steel" then old = surface.find_entity("steel-chest", oldpos)
		end
		if old then
      old.minable = true
      old.destructible = true
		end
    local e = surface.create_entity(chests[i].entity)
		e.destructible = false
		e.minable = false
	end
end

local function fusion_buy()
  local objective = Chrono_table.get_table()
  if objective.upgradechest[11] and objective.upgradechest[11].valid then
    local inv = objective.upgradechest[11].get_inventory(defines.inventory.chest)
    inv.insert({name = "fusion-reactor-equipment", count = 1})
  end
end

local function mk2_buy()
  local objective = Chrono_table.get_table()
  if objective.upgradechest[12] and objective.upgradechest[12].valid then
	local inv = objective.upgradechest[12].get_inventory(defines.inventory.chest)
    inv.insert({name = "power-armor-mk2", count = 1})
  end
end

local function process_upgrade(index)
	local objective = Chrono_table.get_table()
	if index == 1 then
		upgrade_hp()
	elseif index == 3 then
		spawn_accumulators()
	elseif index == 4 then
		upgrade_pickup()
	elseif index == 5 then
		upgrade_inv()
	elseif index == 7 then
		upgrade_water()
	elseif index == 8 then
		upgrade_out()
	elseif index == 9 then
		upgrade_storage()
	elseif index == 11 then
		fusion_buy()
	elseif index == 12 then
		mk2_buy()
	elseif index == 13 then
		objective.computermessage = 2
	elseif index == 14 then
		objective.computermessage = 4
	elseif index == 15 then
		if objective.upgrades[15] == 10 then
			game.print({"chronosphere.message_quest6"}, {r=0.98, g=0.66, b=0.22})
		end
	end
end

local function check_single_upgrade(index)
	local objective = Chrono_table.get_table()
	local upgrades = Upgrades.upgrades()
	if objective.upgradechest[index] and objective.upgradechest[index].valid then
		if index == 14 and (objective.upgrades[13] ~= 1 or objective.computermessage ~= 3) then
			return
		elseif index == 15 and (objective.upgrades[14] ~= 1 or objective.computermessage ~= 5) then
			return
		elseif index == 16 and objective.upgrades[15] ~= 10 then
			return
		end
		local inv = objective.upgradechest[index].get_inventory(defines.inventory.chest)
		if objective.upgrades[index] < upgrades[index].max_level and objective.chronojumps >= upgrades[index].jump_limit then
			for _, item in pairs(upgrades[index].cost) do
				if inv.get_item_count(item.name) < item.count then return end
			end
		else
			return
		end

		for _, item in pairs(upgrades[index].cost) do
			if item.count > 0 then
				inv.remove({name = item.name, count = item.count})
			end
		end
		objective.upgrades[index] = objective.upgrades[index] + 1
		game.print(upgrades[index].message, {r=0.98, g=0.66, b=0.22})
		process_upgrade(index)
	end
end

local function check_all_upgrades()
	local upgrades = Upgrades.upgrades()
	for i = 1, #upgrades, 1 do
		check_single_upgrade(i)
	end
end

function Public.check_upgrades()
  local objective = Chrono_table.get_table()
  if not objective.upgradechest then return end
	if objective.game_lost == true then return end
	check_all_upgrades()
  if objective.planet[1].type.id == 17 then
    if objective.fishchest then
      check_win()
    end
  end
end

function Public.trigger_poison()
  local objective = Chrono_table.get_table()
  if objective.game_lost then return end
  if objective.upgrades[10] > 0 and objective.poisontimeout == 0 then
    objective.upgrades[10] = objective.upgrades[10] - 1
    objective.poisontimeout = 120
    local objs = {objective.locomotive, objective.locomotive_cargo[1], objective.locomotive_cargo[2], objective.locomotive_cargo[3]}
    local surface = objective.surface
	game.print({"chronosphere.message_poison_defense"}, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed("Triggering poison defense. Let's kill everything!")
    for i = 1, 4, 1 do
      surface.create_entity({name = "poison-capsule", position = objs[i].position, force = "player", target = objs[i], speed = 1 })
    end
    for i = 1 , #objective.comfychests, 1 do
      surface.create_entity({name = "poison-capsule", position = objective.comfychests[i].position, force = "player", target = objective.comfychests[i], speed = 1 })
    end
  end
end

return Public
