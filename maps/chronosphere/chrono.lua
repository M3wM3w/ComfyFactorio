local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Score = require "comfy_panel.score"
local Difficulty = require 'modules.difficulty_vote'
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
	local get_score = Score.get_table()
	local objective = Chrono_table.get_table()
    objective.max_health = Balance.Chronotrain_max_HP
	objective.health = Balance.Chronotrain_max_HP
	objective.poisontimeout = 0
	objective.chronocharges = 0
	objective.chronochargesneeded = Balance.MJ_needed_for_full_charge(Difficulty.get().difficulty_vote_value, 0)
	objective.passive_chronocharge_rate = Balance.MJ_needed_for_full_charge(Difficulty.get().difficulty_vote_value, 0) / Balance.passive_planet_jumptime(0) --per second rate
	objective.accumulator_energy_history = {}
	objective.passivetimer = 0
	objective.overstaycount = 0
	objective.jump_countdown_start_time = -1
	objective.jump_countdown_length = -1
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
	objective.outchests = {}
	objective.upgradechest = {}
	objective.fishchest = {}
	objective.accumulators = {}
	objective.comfychests = {}
	objective.comfychests2 = {}
	objective.locomotive_cargo = {}
	for _, player in pairs(game.connected_players) do
		objective.flame_boots[player.index] = {fuel = 1, steps = {}}
	end
	global.friendly_fire_history = {}
	global.landfill_history = {}
	global.mining_history = {}
	get_score.score_table = {}
	Difficulty.reset_difficulty_poll()
	Difficulty.set_poll_closing_timeout(game.tick + 35 * 60 * 60)

	game.difficulty_settings.technology_price_multiplier = Balance.Tech_price_multiplier
	game.map_settings.enemy_evolution.destroy_factor = 0.005
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 7e-05
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 8
	game.map_settings.enemy_expansion.settler_group_min_size = 16
    game.map_settings.enemy_expansion.max_expansion_distance = 9
	game.map_settings.pollution.enabled = true
	game.map_settings.pollution.expected_max_per_chunk = 400
	game.map_settings.pollution.min_to_show_per_chunk = 40
	game.map_settings.pollution.pollution_restored_per_tree_damage = 0.02
	game.map_settings.pollution.min_pollution_to_damage_trees = 1
	game.map_settings.pollution.max_pollution_to_restore_trees = 0
	game.map_settings.pollution.pollution_with_max_forest_damage = 10
	game.map_settings.pollution.pollution_per_tree_damage = 0.1
	game.map_settings.pollution.ageing = 0.1
	game.map_settings.pollution.diffusion_ratio = 0.12
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 5
	game.map_settings.unit_group.min_group_gathering_time = 1800
	game.map_settings.unit_group.max_group_gathering_time = 18000
	game.map_settings.unit_group.max_wait_time_for_late_members = 600
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
end

function Public_chrono.objective_died()
	local objective = Chrono_table.get_table()
	if objective.game_lost == true then return end
	objective.health = 0
	local surface = objective.surface
	game.print({"chronosphere.message_game_lost1"})
	game.print({"chronosphere.message_game_lost2"})
	for i = 1, 3, 1 do
		surface.create_entity({name = "big-artillery-explosion", position = objective.locomotive_cargo[i].position})
		objective.locomotive_cargo[i].destroy()
	end
	for i = 1, #objective.comfychests,1 do
		--surface.create_entity({name = "big-artillery-explosion", position = objective.comfychests[i].position})
		objective.comfychests[i].destroy()

		if objective.comfychests2 then objective.comfychests2[i].destroy() end

		--objective.comfychests = {}
	end
	objective.accumulators = {}
	objective.game_lost = true
	objective.game_reset_tick = game.tick + 1800
	game.play_sound{path="utility/game_lost", volume_modifier=0.75}
end

local function check_nuke_silos()
	local objective = Chrono_table.get_table()
	if objective.dangers and #objective.dangers > 1 then
		for i = 1, #objective.dangers, 1 do
		if objective.dangers[i].destroyed == true then
			objective.looted_nukes = objective.looted_nukes + Balance.nukes_looted_per_silo(Difficulty.get().difficulty_vote_value)
		end
		end
	end
end

function Public_chrono.process_jump()
	local objective = Chrono_table.get_table()

	objective.chronojumps = objective.chronojumps + 1
	objective.passivetimer = 0
	objective.chronochargesneeded = Balance.MJ_needed_for_full_charge(Difficulty.get().difficulty_vote_value, objective.chronojumps)
	objective.passive_chronocharge_rate = Balance.MJ_needed_for_full_charge(Difficulty.get().difficulty_vote_value, objective.chronojumps) / Balance.passive_planet_jumptime(objective.chronojumps)
	objective.active_biters = {}
	objective.unit_groups = {}
	objective.biter_raffle = {}
	objective.chronocharges = 0
	objective.jump_countdown_start_time = -1
	objective.jump_countdown_length = -1
  	objective.dangertimer = 1200
	local message = "Comfylatron: Wheeee! Time jump underway! This is Jump number " .. objective.chronojumps
	game.print(message, {r=0.98, g=0.66, b=0.22})
	Server.to_discord_embed(message)

	if objective.chronojumps == Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
		game.print({"chronosphere.message_evolve"}, {r=0.98, g=0.36, b=0.22})
	elseif objective.chronojumps >= 15 and objective.computermessage == 0 then
		game.print({"chronosphere.message_quest1"}, {r=0.98, g=0.36, b=0.22})
    	objective.computermessage = 1
		game.play_sound{path="utility/new_objective", volume_modifier=0.85}
	elseif objective.chronojumps >= 20 and objective.computermessage == 2 then
		game.print({"chronosphere.message_quest3"}, {r=0.98, g=0.36, b=0.22})
    	objective.computermessage = 3
		game.play_sound{path="utility/new_objective", volume_modifier=0.85}
	elseif objective.chronojumps >= 25 and objective.computermessage == 4 then
		game.print({"chronosphere.message_quest5"}, {r=0.98, g=0.36, b=0.22})
    	objective.computermessage = 5
		game.play_sound{path="utility/new_objective", volume_modifier=0.85}
	end
	if (objective.passivetimer - objective.jump_countdown_length) * objective.passive_chronocharge_rate > objective.chronochargesneeded * 0.75 and objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
    	game.print({"chronosphere.message_overstay"}, {r=0.98, g=0.36, b=0.22})
		Server.to_discord_embed("We took so long to get off that planet, our future destinations have evolved a little...")
  	end
  	if objective.planet[1].type.id == 19 then
		check_nuke_silos()
	end
end

function Public_chrono.get_wagons(start)
	local objective = Chrono_table.get_table()
	local wagons = {}
	wagons[1] = {inventory = {}, bar = 0, filters = {}}
	wagons[2] = {inventory = {}, bar = 0, filters = {}}
	wagons[3] = {inventory = {}, bar = 0, filters = {}}
	if start then
		wagons[1].inventory[1] = {name = "raw-fish", count = 100}
		for i = 2, 3, 1 do
			for j = 1,#Balance.wagon_starting_items do
				wagons[i].inventory[j] = Balance.wagon_starting_items[j]
			end
		end
	else
		local inventories = {
	    one = objective.locomotive_cargo[1].get_inventory(defines.inventory.cargo_wagon),
	    two = objective.locomotive_cargo[2].get_inventory(defines.inventory.cargo_wagon),
	    three = objective.locomotive_cargo[3].get_inventory(defines.inventory.cargo_wagon)
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
	local objective = Chrono_table.get_table()
	local difficulty = Difficulty.get().difficulty_vote_value
	  
  	game.forces.enemy.reset_evolution()
	if objective.chronojumps + objective.overstaycount <= 40 and objective.planet[1].type.id ~= 17 then
		game.forces.enemy.evolution_factor = 0 + 0.025 * (objective.chronojumps + objective.overstaycount)
	else
		game.forces.enemy.evolution_factor = 1
	end
	if objective.planet[1].type.id == 17 then
		objective.comfychests[1].insert({name = "space-science-pack", count = 1000})
		if objective.looted_nukes > 0 then
      	objective.comfychests[1].insert({name = "atomic-bomb", count = objective.looted_nukes})
      	game.print({"chronosphere.message_fishmarket3"}, {r=0.98, g=0.66, b=0.22})
    	end
		objective.chronochargesneeded = 200000000
  	elseif objective.planet[1].type.id == 19 then
		objective.chronocharges = objective.chronochargesneeded - 1500
		objective.passive_chronocharge_rate = 1
	end
	for _, player in pairs(game.connected_players) do
		objective.flame_boots[player.index] = {fuel = 1, steps = {}}
	end

	game.map_settings.enemy_evolution.time_factor = 7e-05 + 3e-06 * (objective.chronojumps + objective.overstaycount)

	game.forces.scrapyard.set_ammo_damage_modifier("bullet", difficulty * 0.01 * objective.chronojumps + 0.02 * math_max(0, objective.chronojumps - 20))
	game.forces.scrapyard.set_turret_attack_modifier("gun-turret", difficulty * 0.01 * objective.chronojumps + 0.02 * math_max(0, objective.chronojumps - 20))
	game.forces.enemy.set_ammo_damage_modifier("melee", 0.1 * objective.overstaycount)
	game.forces.enemy.set_ammo_damage_modifier("biological", 0.1 * objective.overstaycount)
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = Balance.defaultai_attack_pollution_consumption_modifier(difficulty)
	game.map_settings.pollution.max_unit_group_size = Balance.max_new_attack_group_size(difficulty)

	if objective.chronojumps == 1 then
		if difficulty < 1 then
		game.forces.player.technologies["fusion-reactor-equipment"].enabled = true
		game.forces.player.technologies["power-armor-mk2"].enabled = true
		end
	end
end

return Public_chrono
