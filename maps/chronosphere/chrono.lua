local Public_chrono = {}

local Server = require 'utils.server'
local math_random = math.random
local math_max = math.max

function Public_chrono.get_map_gen_settings()
	local seed = math_random(1, 1000000)
	local map_gen_settings = {
		["seed"] = seed,
		["width"] = 960,
		["height"] = 960,
		["water"] = 0.1,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = true,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = true},
			["decorative"] = {treat_missing_as_default = true},
		},
	}
	return map_gen_settings
end

function Public_chrono.restart_settings()
  local objective = global.objective
  objective.max_health = 10000
	objective.health = 10000
	objective.poisontimeout = 0
	objective.chronotimer = 0
	objective.passivetimer = 0
	objective.passivejumps = 0
	objective.chrononeeds = 2000
	objective.mainscore = 0
	objective.active_biters = {}
	objective.unit_groups = {}
	objective.biter_raffle = {}
	objective.dangertimer = 1200
	objective.dangers = {}
	objective.looted_nukes = 0
	objective.offline_players = {}
  objective.nextsurface = nil
	for i = 1, 16, 1 do
		objective.upgrades[i] = 0
	end
	objective.upgrades[10] = 2 --poison
	global.outchests = {}
	global.upgradechest = {}
	global.fishchest = {}
	global.acumulators = {}
	global.comfychests = {}
	global.comfychests2 = {}
	global.locomotive_cargo = {}
	for _, player in pairs(game.connected_players) do
		global.flame_boots[player.index] = {fuel = 1, steps = {}}
	end
	global.friendly_fire_history = {}
	global.landfill_history = {}
	global.mining_history = {}
	global.score = {}
  global.difficulty_poll_closing_timeout = game.tick + 90000
  global.difficulty_player_votes = {}

	game.difficulty_settings.technology_price_multiplier = 0.6
	game.map_settings.enemy_evolution.destroy_factor = 0.005
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 7e-05
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 8
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.pollution.enabled = true
	game.map_settings.pollution.pollution_restored_per_tree_damage = 0.02
	game.map_settings.pollution.min_pollution_to_damage_trees = 1
	game.map_settings.pollution.max_pollution_to_restore_trees = 0
	game.map_settings.pollution.pollution_with_max_forest_damage = 10
	game.map_settings.pollution.pollution_per_tree_damage = 0.1
	game.map_settings.pollution.ageing = 0.1
	game.map_settings.pollution.diffusion_ratio = 0.1
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 5
	game.forces.neutral.character_inventory_slots_bonus = 500
	game.forces.enemy.evolution_factor = 0.0001
	game.forces.scrapyard.set_friend('enemy', true)
	game.forces.enemy.set_friend('scrapyard', true)

	game.forces.player.technologies["land-mine"].enabled = false
	game.forces.player.technologies["landfill"].enabled = false
	game.forces.player.technologies["cliff-explosives"].enabled = false
	game.forces.player.technologies["fusion-reactor-equipment"].enabled = false
	game.forces.player.technologies["power-armor-mk2"].enabled = false
	game.forces.player.technologies["railway"].researched = true
	game.forces.player.recipes["pistol"].enabled = false

	global.objective = objective
end

function Public_chrono.init_setup()
	game.forces.player.recipes["pistol"].enabled = false
end

function Public_chrono.objective_died()
  local objective = global.objective
  if objective.game_lost == true then return end
  objective.health = 0
  local surface = objective.surface
  game.print({"chronosphere.message_game_lost1"})
  game.print({"chronosphere.message_game_lost2"})
  for i = 1, 3, 1 do
    surface.create_entity({name = "big-artillery-explosion", position = global.locomotive_cargo[i].position})
    global.locomotive_cargo[i].destroy()
  end
  for i = 1, #global.comfychests,1 do
    --surface.create_entity({name = "big-artillery-explosion", position = global.comfychests[i].position})
    global.comfychests[i].destroy()

    if global.comfychests2 then global.comfychests2[i].destroy() end

    --global.comfychests = {}
  end
  global.acumulators = {}
  objective.game_lost = true
  global.game_reset_tick = game.tick + 1800
  for _, player in pairs(game.connected_players) do
    player.play_sound{path="utility/game_lost", volume_modifier=0.75}
  end
end

local function overstayed()
  local objective = global.objective
	if objective.passivetimer > objective.chrononeeds * 0.75 and objective.chronojumps > 5 then
		objective.passivejumps = objective.passivejumps + 1
    return true
	end
  return false
end

local function check_nuke_silos()
  local objective = global.objective
  if objective.dangers and #objective.dangers > 1 then
    for i = 1, #objective.dangers, 1 do
      if objective.dangers[i].destroyed == true then
        objective.looted_nukes = objective.looted_nukes + 5
      end
    end
  end
end

function Public_chrono.process_jump(choice)
	local objective = global.objective
	local overstayed = overstayed()
	objective.chronojumps = objective.chronojumps + 1
	objective.chrononeeds = 2000 + 300 * objective.chronojumps
	objective.passivetimer = 0
	objective.chronotimer = 0
  objective.dangertimer = 1200
	local message = "Comfylatron: Wheeee! Time Jump Active! This is Jump number " .. objective.chronojumps
	game.print(message, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed(message)

	if objective.chronojumps == 6 then
		game.print({"chronosphere.message_evolve"}, {r=0.98, g=0.36, b=0.22})
	elseif objective.chronojumps >= 15 and objective.computermessage == 0 then
		game.print({"chronosphere.message_quest1"}, {r=0.98, g=0.36, b=0.22})
    objective.computermessage = 1
	elseif objective.chronojumps >= 20 and objective.computermessage == 2 then
		game.print({"chronosphere.message_quest3"}, {r=0.98, g=0.36, b=0.22})
    objective.computermessage = 3
	elseif objective.chronojumps >= 25 and objective.computermessage == 4 then
		game.print({"chronosphere.message_quest5"}, {r=0.98, g=0.36, b=0.22})
    objective.computermessage = 5
	end
	if overstayed then
    game.print({"chronosphere.message_overstay"}, {r=0.98, g=0.36, b=0.22})
  end
  if objective.planet[1].name.id == 19 then
    check_nuke_silos()
  end
	global.objective = objective
end

function Public_chrono.get_wagons(start)
	local wagons = {}
	wagons[1] = {inventory = {}, bar = 0, filters = {}}
	wagons[2] = {inventory = {}, bar = 0, filters = {}}
	wagons[3] = {inventory = {}, bar = 0, filters = {}}
	if start then
		wagons[1].inventory[1] = {name = "raw-fish", count = 100}
		for i = 2, 3, 1 do
			wagons[i].inventory[1] = {name = 'firearm-magazine', count = 16}
			wagons[i].inventory[2] = {name = 'iron-plate', count = 16}
			wagons[i].inventory[3] = {name = 'wood', count = 16}
			wagons[i].inventory[4] = {name = 'burner-mining-drill', count = 8}
		end
	else
		local inventories = {
	    one = global.locomotive_cargo[1].get_inventory(defines.inventory.cargo_wagon),
	    two = global.locomotive_cargo[2].get_inventory(defines.inventory.cargo_wagon),
	    three = global.locomotive_cargo[3].get_inventory(defines.inventory.cargo_wagon)
	  }
		inventories.one.sort_and_merge()
		--inventories.two.sort_and_merge()

		wagons[1].bar = inventories.one.get_bar()
		wagons[2].bar = inventories.two.get_bar()
	  wagons[3].bar = inventories.three.get_bar()
		for i = 1, 40, 1 do
			wagons[1].filters[i] = inventories.one.get_filter(i)
			wagons[1].inventory[i] = inventories.one[i]
			wagons[2].filters[i] = inventories.two.get_filter(i)
			wagons[2].inventory[i] = inventories.two[i]
	    wagons[3].filters[i] = inventories.three.get_filter(i)
			wagons[3].inventory[i] = inventories.three[i]
		end
	end
  return wagons
end

function Public_chrono.post_jump()
  local objective = global.objective
  game.forces.enemy.reset_evolution()
	if objective.chronojumps + objective.passivejumps <= 40 and objective.planet[1].name.id ~= 17 then
		game.forces.enemy.evolution_factor = 0 + 0.025 * (objective.chronojumps + objective.passivejumps)
	else
		game.forces.enemy.evolution_factor = 1
	end
	if objective.planet[1].name.id == 17 then
		global.comfychests[1].insert({name = "space-science-pack", count = 1000})
    if objective.looted_nukes > 0 then
      global.comfychests[1].insert({name = "atomic-bomb", count = objective.looted_nukes})
      game.print({"chronosphere.message_fishmarket3"}, {r=0.98, g=0.66, b=0.22})
    end
		objective.chrononeeds = 200000000
  elseif objective.planet[1].name.id == 19 then
    objective.chronotimer = objective.chrononeeds - 1500
	end
	for _, player in pairs(game.connected_players) do
		global.flame_boots[player.index] = {fuel = 1, steps = {}}
	end

	game.map_settings.enemy_evolution.time_factor = 7e-05 + 3e-06 * (objective.chronojumps + objective.passivejumps)
	game.forces.scrapyard.set_ammo_damage_modifier("bullet", 0.01 * objective.chronojumps + 0.02 * math_max(0, objective.chronojumps - 20))
	game.forces.scrapyard.set_turret_attack_modifier("gun-turret", 0.01 * objective.chronojumps + 0.02 * math_max(0, objective.chronojumps - 20))
	game.forces.enemy.set_ammo_damage_modifier("melee", 0.1 * objective.passivejumps)
	game.forces.enemy.set_ammo_damage_modifier("biological", 0.1 * objective.passivejumps)
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.8
  if objective.chronojumps == 1 then
    if global.difficulty_vote_value < 1 then
      game.forces.player.technologies["fusion-reactor-equipment"].enabled = true
      game.forces.player.technologies["power-armor-mk2"].enabled = true
    end
  end
	global.objective = objective
end

return Public_chrono
