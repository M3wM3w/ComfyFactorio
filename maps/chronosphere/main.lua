-- chronosphere --

require "modules.difficulty_vote"
require "modules.biters_yield_coins"
require "modules.no_deconstruction_of_neutral_entities"
--require "modules.no_solar"
require "maps.chronosphere.comfylatron"
require "maps.chronosphere.terrain"
require "on_tick_schedule"
require "modules.biter_noms_you"
-- require "modules.custom_death_messages"
local Server = require 'utils.server'
local Ai = require "maps.chronosphere.ai"
local Planets = require "maps.chronosphere.chronobubles"
local Ores =require "maps.chronosphere.ores"
local Reset = require "functions.soft_reset"
local Map = require "modules.map_info"
local Upgrades = require "maps.chronosphere.upgrades"
local Tick_functions = require "maps.chronosphere.tick_functions"
local Event_functions = require "maps.chronosphere.event_functions"
local Balance = require "maps.chronosphere.balance"
local Rand = require 'maps.chronosphere.random'
local Chrono = require "maps.chronosphere.chrono"
local Chrono_table = require 'maps.chronosphere.table'
local Locomotive = require "maps.chronosphere.locomotive"
local Gui = require "maps.chronosphere.gui"
local Difficulty = require 'modules.difficulty_vote'
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
require "maps.chronosphere.config_tab"

local Public = {}

--global.difficulty_tooltips = {
--    [1] = "Biters much less aggressive; pollution by train significantly lower; maps significantly more favourable; upgrades coin prices significantly cheaper; MK2 research enabled; flamer nerf more slight",
--    [2] = "Biters less aggressive; pollution by train lower; maps more favourable; upgrades coin prices cheaper; MK2 research enabled; flamer nerf more slight",
--    [3] = "Biters slightly less aggressive; pollution by train slightly lower; maps slightly more favourable; upgrades coin prices slightly cheaper; MK2 research enabled; flamer nerf more slight",
--    [4] = "Normal difficulty.",
--    [5] = "Biters more aggressive; pollution by train higher; maps less favourable; upgrades coin prices more expensive; flamer nerf less slight",
--    [6] = "Biters much more aggressive; pollution by train significantly higher; maps significantly less favourable; upgrades coin prices significantly more expensive; flamer nerf less slight",
--    [7] = "ENTER AT YOUR PERIL",
--}

local function generate_overworld(surface, optplanet)
	local objective = Chrono_table.get_table()
	Planets.determine_planet(optplanet)
	local planet = objective.planet

	local message = {"chronosphere.planet_jump", planet[1].type.name, planet[1].ore_richness.name, planet[1].day_speed.name}
	game.print(message, {r=0.98, g=0.66, b=0.22})

	local discordmessage = "Destination: "..planet[1].type.dname..", Ore Richness: "..planet[1].ore_richness.dname..", Day length: "..planet[1].day_speed.dname
	Server.to_discord_embed(discordmessage)
	if planet[1].type.id == 12 then
		game.print({"chronosphere.message_choppy"}, {r=0.98, g=0.66, b=0.22})
	elseif planet[1].type.id == 14 then
		game.print({"chronosphere.message_lava"}, {r=0.98, g=0.66, b=0.22})
	elseif planet[1].type.id == 17 then
		game.print({"chronosphere.message_fishmarket1"}, {r=0.98, g=0.66, b=0.22})
		game.print({"chronosphere.message_fishmarket2"}, {r=0.98, g=0.66, b=0.22})
	end
	surface.min_brightness = 0
	surface.brightness_visual_weights = {1, 1, 1}
	objective.surface = surface
	surface.daytime = planet[1].time
	local timer = planet[1].day_speed.timer
	if timer == 0 then
		surface.freeze_daytime = true
		timer = timer + 1
	else
		surface.freeze_daytime = false
	end
	surface.ticks_per_day = timer * 250

	local moisture = planet[1].type.moisture
	if moisture ~= 0 then
		local mgs = surface.map_gen_settings
		mgs.property_expression_names["control-setting:moisture:bias"] = moisture
		surface.map_gen_settings = mgs
	end
	if planet[1].type.id == 14 then --lava planet
		local mgs = surface.map_gen_settings
		mgs.water = 0
		surface.map_gen_settings = mgs
	end
	if planet[1].type.id ~= 12 then --choppy planet
		local mgs = surface.map_gen_settings
		mgs.water = 0.2
		surface.map_gen_settings = mgs
	end
	if planet[1].type.id == 17 then --fish market
		local mgs = surface.map_gen_settings
		mgs.width = 2176
		surface.map_gen_settings = mgs
		surface.request_to_generate_chunks({-960,-64}, 0.5)
		surface.force_generate_chunk_requests()
	end
end

local function render_train_hp()
	local objective = Chrono_table.get_table()
	local surface = game.surfaces[objective.active_surface_index]
	objective.health_text = rendering.draw_text{
		text = "HP: " .. objective.health .. " / " .. objective.max_health,
		surface = surface,
		target = objective.locomotive,
		target_offset = {0, -2.5},
		color = objective.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	objective.caption = rendering.draw_text{
		text = "Comfylatron's ChronoTrain",
		surface = surface,
		target = objective.locomotive,
		target_offset = {0, -4.25},
		color = objective.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end


local function reset_map()
	local objective = Chrono_table.get_table()
	for _,player in pairs(game.players) do
		if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
	end

	if game.surfaces["chronosphere"] then game.delete_surface(game.surfaces["chronosphere"]) end
	if game.surfaces["cargo_wagon"] then game.delete_surface(game.surfaces["cargo_wagon"]) end
	for i = 13, 16, 1 do
		objective.upgrades[i] = 0
	end
	objective.computermessage = 0
	objective.chronojumps = 0

	Planets.determine_planet(nil)
	local planet = objective.planet
	if not objective.active_surface_index then
		objective.active_surface_index = game.create_surface("chronosphere", Chrono.get_map_gen_settings()).index
	else
		game.forces.player.set_spawn_position({12, 10}, game.surfaces[objective.active_surface_index])
		objective.active_surface_index = Reset.soft_reset_map(game.surfaces[objective.active_surface_index], Chrono.get_map_gen_settings(), Balance.starting_items).index
	end

	local surface = game.surfaces[objective.active_surface_index]
	generate_overworld(surface, planet)
	Chrono.restart_settings()

	game.forces.player.set_spawn_position({12, 10}, surface)
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(true))
	render_train_hp()
	game.reset_time_played()
	Locomotive.create_wagon_room()
	Event_functions.mining_buffs(nil)
	if objective.game_won then
		game.print({"chronosphere.message_game_won_restart"}, {r=0.98, g=0.66, b=0.22})
	end
	objective.game_lost = false
	objective.game_won = false

	game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
	game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
	game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)
end

local function on_player_joined_game(event)
	local objective = Chrono_table.get_table()
	local player = game.players[event.player_index]
	if not objective.flame_boots[event.player_index] then
		objective.flame_boots[event.player_index] = {}
	end
	objective.flame_boots[event.player_index] = {fuel = 1}
	if not objective.flame_boots[event.player_index].steps then objective.flame_boots[event.player_index].steps = {} end

	local surface = game.surfaces[objective.active_surface_index]

	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(Balance.starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	if player.surface.index ~= objective.active_surface_index and player.surface.name ~= "cargo_wagon" then
		player.character = nil
		player.set_controller({type=defines.controllers.god})
		player.create_character()
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	local tile = surface.get_tile(player.position)
	if tile.valid then
		if tile.name == "out-of-map" then
			player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		end
	end
end

local function on_pre_player_left_game(event)
	local objective = Chrono_table.get_table()
	local player = game.players[event.player_index]
	if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
	if player.character then
		objective.offline_players[#objective.offline_players + 1] = {index = event.player_index, tick = game.tick}
	end
end


local function set_objective_health(final_damage_amount)
	if final_damage_amount == 0 then return end
	local objective = Chrono_table.get_table()
	objective.health = math_floor(objective.health - final_damage_amount)
	if objective.health > objective.max_health then objective.health = objective.max_health end

	if objective.health <= 0 then
		Chrono.objective_died()
	end
	if objective.health < objective.max_health / 2 and final_damage_amount > 0 then
		Upgrades.trigger_poison()
	end
	rendering.set_text(objective.health_text, "HP: " .. objective.health .. " / " .. objective.max_health)
end

local function award_coins(count)
	Locomotive.award_coins(count)
end


function Public.chronojump(choice)
	local objective = Chrono_table.get_table()

	if objective.chronojumps == 0 then
		Difficulty.set_poll_closing_timeout(game.tick)
	end

	if objective.game_lost then goto continue end

	if objective.chronojumps <= 24 then
		award_coins(
			Balance.coin_reward_per_second_jumped_early(objective.chronochargesneeded / objective.passive_chronocharge_rate + objective.jump_countdown_length - objective.passivetimer, Difficulty.get().difficulty_vote_value)
		)
	end

	Chrono.process_jump()

	local oldsurface = game.surfaces[objective.active_surface_index]

	for _,player in pairs(game.players) do
		if player.surface == oldsurface then
			if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
			local wagons = {objective.locomotive_cargo[1], objective.locomotive_cargo[2], objective.locomotive_cargo[3]}
			Locomotive.enter_cargo_wagon(player, wagons[math.random(1,3)])
		end
	end
	objective.lab_cells = {}
	objective.active_surface_index = game.create_surface("chronosphere" .. objective.chronojumps, Chrono.get_map_gen_settings()).index
	local surface = game.surfaces[objective.active_surface_index]
	--log("seed of new surface: " .. surface.map_gen_settings.seed)
	local planet = objective.planet
	if choice then
		Planets.determine_planet(choice)
	end
	generate_overworld(surface, planet)

	game.forces.player.set_spawn_position({12, 10}, surface)

	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(false))
	--if objective.locomotive == nil then Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(false)) end
	render_train_hp()
	game.delete_surface(oldsurface)
	Chrono.post_jump()
	Event_functions.flamer_nerfs()

	--
    local pos = objective.locomotive.position or {x=0,y=0}
    local exterior_pollution = math_floor(Balance.post_jump_initial_pollution(objective.chronojumps, Difficulty.get().difficulty_vote_value))
    game.surfaces[objective.active_surface_index].pollute(pos, exterior_pollution)
    game.pollution_statistics.on_flow("locomotive", exterior_pollution)

	::continue::
end

local tick_minute_functions = {

	[300 * 2] = Ai.destroy_inactive_biters,
	[300 * 3 + 30 * 0] = Ai.pre_main_attack,		-- setup for main_attack
	[300 * 3 + 30 * 1] = Ai.perform_main_attack,
	[300 * 3 + 30 * 2] = Ai.perform_main_attack,
	[300 * 3 + 30 * 3] = Ai.perform_main_attack,
	[300 * 3 + 30 * 4] = Ai.perform_main_attack,
	[300 * 3 + 30 * 5] = Ai.perform_main_attack,	-- call perform_main_attack 7 times on different ticks
	[300 * 4] = Ai.send_near_biters_to_objective,
	[300 * 5] = Ai.wake_up_sleepy_groups,
	--[300] = Ai.rogue_group

}

local function initiate_jump_countdown()
	local objective = Chrono_table.get_table()
	local difficulty = Difficulty.get().difficulty_vote_value
	local length = Balance.generate_jump_countdown_length(difficulty)

	objective.jump_countdown_start_time = objective.passivetimer
	objective.jump_countdown_length = length
	game.print({"chronosphere.message_initiate_jump_countdown", length}, {r=0.98, g=0.66, b=0.22})
end

local function check_if_overstayed()
	local objective = Chrono_table.get_table()

	  if objective.passivetimer * objective.passive_chronocharge_rate > (objective.chronochargesneeded * 0.75) and objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value) then
		  objective.overstaycount = objective.overstaycount + 1
	  end
end

function Public.add_chronocharge()
	local objective = Chrono_table.get_table()
	local difficulty = Difficulty.get().difficulty_vote_value

end

local function drain_accumulators()
	local objective = Chrono_table.get_table()
	local difficulty = Difficulty.get().difficulty_vote_value

	if objective.passivetimer < 10 then return end
	if objective.chronocharges >= objective.chronochargesneeded then return end
	if not objective.accumulators then return end
	if not objective.chronocharges then return end
	if objective.planet[1].type.id == 17 or objective.planet[1].type.id == 19 then return end
	local acus = objective.accumulators
	if #acus < 1 then return end
	for i = 1, #acus, 1 do
		if not acus[i].valid or not objective.locomotive.valid then return end
		local energy = acus[i].energy
		if energy > 1010000 and objective.chronocharges < objective.chronochargesneeded then
			acus[i].energy = acus[i].energy - 1000000
	
			objective.chronocharges = objective.chronocharges + 1

			if objective.locomotive ~= nil and objective.locomotive.valid then
		
				local pos = objective.locomotive.position or {x=0,y=0}
				local exterior_pollution = Balance.pollution_per_MJ_actively_charged(objective.chronojumps, difficulty, objective.upgrades[2])
				game.surfaces[objective.active_surface_index].pollute(pos, exterior_pollution)
				game.pollution_statistics.on_flow("locomotive", exterior_pollution)
			
				if objective.chronocharges == objective.chronochargesneeded then
					check_if_overstayed()
					initiate_jump_countdown()
				end
			end
		end
	end
end

function Public.attempt_to_jump()
	local objective = Chrono_table.get_table()
	local difficulty = Difficulty.get().difficulty_vote_value
	
	if 100 * math_random() <= Balance.misfire_percentage_chance(difficulty) then
		game.print({"chronosphere.message_jump_misfire"}, {r=0.98, g=0.66, b=0.22})
		objective.jump_countdown_length = objective.jump_countdown_length + 15
	else
		Public.chronojump(nil)
	end
end


function Public.get_total_accu_charge()
	local objective = Chrono_table.get_table()
	local acus = objective.accumulators
	local e = 0
	if #acus > 0 then
	  for i = 1,#acus,1 do
		if acus[i].valid then
		  e = e + acus[i].energy
		end
	  end
	end
	return e
end


local function tick() --only even ticks trigger
	local objective = Chrono_table.get_table()
	local tick = game.tick

	if tick % 60 == 30 and objective.passivetimer < 64 then
		local surface = game.surfaces[objective.active_surface_index]
		if objective.planet[1].type.id == 17 then
			surface.request_to_generate_chunks({-800,0}, 3 + math_floor(objective.passivetimer / 5))
		else
			surface.request_to_generate_chunks({0,0}, 3 + math_floor(objective.passivetimer / 5))
		end
		--surface.force_generate_chunk_requests()
	end
	
	if tick % 12 == 0 and objective.planet[1].type.id == 18 then
		Tick_functions.spawn_poison()
	end
	if tick % 60 == 2 then
		objective.accumulator_energy_history[1] = Public.get_total_accu_charge()
	end
	if tick % 60 == 56 then
		objective.accumulator_energy_history[2] = Public.get_total_accu_charge()
	end

	if objective.chronocharges < objective.chronochargesneeded and objective.planet[1].type.id ~= 17 then
		local chronotimer_ticks_between_increase = math_floor(60 / objective.passive_chronocharge_rate / 2) * 2 --make sure it's even because you can't do things on odd ticks
		
		if tick % chronotimer_ticks_between_increase == 0 then
			objective.chronocharges = objective.chronocharges + 1
		end
	end

	if tick % 30 == 0 then
		local difficulty = Difficulty.get().difficulty_vote_value
		
		if tick % 60 == 0 and objective.planet[1].type.id ~= 17 then
			objective.passivetimer = objective.passivetimer + 1

			if objective.planet[1].type.id == 19 then
				Tick_functions.dangertimer()
			end
			
			Tick_functions.realtime_events()

			if objective.locomotive ~= nil and objective.locomotive.valid then
				if objective.jump_countdown_start_time == -1 then
					if objective.chronocharges == objective.chronochargesneeded then
						check_if_overstayed()
						initiate_jump_countdown()
					end

					local pos = objective.locomotive.position or {x=0,y=0}
					local exterior_pollution = Balance.passive_pollution_rate(objective.chronojumps, difficulty, objective.upgrades[2])
					game.surfaces[objective.active_surface_index].pollute(pos, exterior_pollution)
					game.pollution_statistics.on_flow("locomotive", exterior_pollution)
				else
					if objective.passivetimer == objective.jump_countdown_start_time + objective.jump_countdown_length then
						Public.attempt_to_jump()
					else
						local pos = objective.locomotive.position or {x=0,y=0}
						local exterior_pollution = Balance.countdown_pollution_rate(objective.chronojumps, Difficulty.get().difficulty_vote_value)
						game.surfaces[objective.active_surface_index].pollute(pos, exterior_pollution)
						-- game.pollution_statistics.on_flow("locomotive", exterior_pollution)
					end
				end
			end

		end

		if tick % 60 == 0 then
			drain_accumulators()
		end
		
		if tick % 120 == 0 then
			Tick_functions.move_items()
			Tick_functions.output_items()
		end

		if tick % 600 == 0 then
			Tick_functions.ramp_evolution()
			Upgrades.check_upgrades()
			Tick_functions.transfer_pollution()
			if objective.poisontimeout > 0 then
				objective.poisontimeout = objective.poisontimeout - 1
			end
		end

		if tick % 1800 == 0 then
			Locomotive.set_player_spawn_and_refill_fish()
			set_objective_health(Tick_functions.repair_train())
			if objective.config.offline_loot then
				Tick_functions.offline_players()
			end
		end
		
		if tick % 1800 == 900 and objective.jump_countdown_start_time ~= -1 then
			Ai.perform_main_attack()
		end
		
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
		if objective.game_reset_tick then
			if objective.game_reset_tick < tick then
				objective.game_reset_tick = nil
				reset_map()
			end
			return
		end
		Locomotive.fish_tag()
	end
	for _, player in pairs(game.connected_players) do Gui.update_gui(player) end
end

local function on_init()
	local objective = Chrono_table.get_table()
	local T = Map.Pop_info()
	T.localised_category = "chronosphere"
	T.main_caption_color = {r = 150, g = 150, b = 0}
	T.sub_caption_color = {r = 0, g = 150, b = 0}
	objective.game_lost = true
	objective.game_won = false
	objective.offline_players = {}

	objective.config.offline_loot = true
	objective.config.jumpfailure = true
	game.create_force("scrapyard")
	local mgs = game.surfaces["nauvis"].map_gen_settings
	mgs.width = 16
	mgs.height = 16
	game.surfaces["nauvis"].map_gen_settings = mgs
	game.surfaces["nauvis"].clear()
	
    for k, v in pairs(Balance.player_ammo_damage_modifiers()) do
        game.forces['player'].set_ammo_damage_modifier(k, v)
    end

    for k, v in pairs(Balance.player_gun_speed_modifiers()) do
        game.forces['player'].set_gun_speed_modifier(k, v)
    end

	reset_map()
	--if game.surfaces["nauvis"] then game.delete_surface(game.surfaces["nauvis"]) end
end

-- local function on_load()
-- 	Chrono.init_setup()
-- end

local function protect_entity(event)
	local objective = Chrono_table.get_table()
	if event.entity.force.index ~= 1 then return end --Player Force
	if Event_functions.isprotected(event.entity) then
		if event.cause then
			if event.cause == objective.comfylatron or event.entity == objective.comfylatron then
				return
			end
			if event.cause.force.index == 2 or event.cause.force.name == "scrapyard" then
					set_objective_health(event.final_damage_amount)
			end
		elseif objective.planet[1].type.id == 19 then
			set_objective_health(event.final_damage_amount)
		end
		if not event.entity.valid then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end

local function pre_player_mined_item(event)
	local objective = Chrono_table.get_table()
	if objective.planet[1].type.id == 11 then --rocky planet
		if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
			Event_functions.trap(event.entity, false)
			event.entity.destroy()
			Event_functions.rocky_loot(event)
		end
	end
end

local function on_player_mined_entity(event)
	local objective = Chrono_table.get_table()
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "tree" and objective.planet[1].type.id == 12 then --choppy planet
		Event_functions.trap(entity, false)
		Event_functions.choppy_loot(event)
	end
	if entity.name == "rock-huge" or entity.name == "rock-big" or entity.name == "sand-rock-big" then
		if objective.planet[1].type.id ~= 11 and objective.planet[1].type.id ~= 16 then --rocky and maze planet
			Ores.prospect_ores(entity, entity.surface, entity.position)
		elseif
			objective.planet[1].type.id == 11 then event.buffer.clear() -- rocky planet
		end
	end
end

local function on_entity_died(event)
	local objective = Chrono_table.get_table()
	if event.entity.type == "tree" and objective.planet[1].type.id == 12 then --choppy planet
		if event.cause then
			if event.cause.valid then
				if event.cause.force.name ~= "enemy" then
					Event_functions.trap(event.entity, false)
				end
			end
		end
		-- if not event.entity.valid then return end
		-- for _, entity in pairs (event.entity.surface.find_entities_filtered({area = {{event.entity.position.x - 4, event.entity.position.y - 4},{event.entity.position.x + 4, event.entity.position.y + 4}}, name = "fire-flame-on-tree"})) do
		-- 	if entity.valid then entity.destroy() end
		-- end
		--return
	end
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "unit" and entity.force == "enemy" then
		objective.active_biters[entity.unit_number] = nil
	end
	if entity.type == "rocket-silo" and entity.force.name == "enemy" then
		Event_functions.danger_silo(entity)
	end
	if entity.force.name == "scrapyard" and entity.name == "gun-turret" then
		if objective.planet[1].type.id == 19 or objective.planet[1].type.id == 16 then --danger + hedge maze
			Event_functions.trap(entity, true)
		end
	end
	if entity.force.name == "enemy" then
		if entity.type == "unit-spawner" then
			Event_functions.spawner_loot(entity.surface, entity.position)
			if objective.planet[1].type.id == 18 then
				Ores.prospect_ores(entity, entity.surface, entity.position)
			end
		else
			if objective.planet[1].type.id == 18 then
				Event_functions.swamp_loot(event)
			end
		end
	end
	if entity.force.index == 3 then
		if event.cause then
			if event.cause.valid then
				if event.cause.force.index == 2 then
					Event_functions.shred_simple_entities(entity)
				end
			end
		end
	end
end

local function on_player_driving_changed_state(event)
	local player = game.players[event.player_index]
	local vehicle = event.entity
	Locomotive.enter_cargo_wagon(player, vehicle)
end

-- function deny_building(event)
-- 	local entity = event.created_entity
-- 	if not entity.valid then return end
-- 	local surface = event.created_entity.surface
--
-- 	if event.player_index then
-- 		game.players[event.player_index].insert({name = entity.name, count = 1})
-- 	else
-- 		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
-- 		inventory.insert({name = entity.name, count = 1})
-- 	end
--
-- 	surface.create_entity({
-- 		name = "flying-text",
-- 		position = entity.position,
-- 		text = "Private Comfylatron's area!",
-- 		color = {r=0.98, g=0.66, b=0.22}
-- 	})
--
-- 	entity.destroy()
-- end

-- local function on_built_entity(event)
-- 	if event.surface.name == "cargo_wagon" and event.position.y < -190 then
-- 		deny_building(event)
-- 	end
-- end
--
-- local function on_robot_built_entity(event)
-- 	if event.surface.name == "cargo_wagon" and event.position.y < -190 then
-- 		deny_building(event)
-- 	end
-- 	Terrain.deny_construction_bots(event)
-- end
-- local function on_market_item_purchased(event)
-- 	Locomotive.offer_purchased(event)
-- end

local function on_player_changed_position(event)
	local objective = Chrono_table.get_table()
	if objective.planet[1].type.id == 14 then --lava planet
		Event_functions.lava_planet(event)
	end
end

local function on_technology_effects_reset(event)
	Event_functions.on_technology_effects_reset(event)
end

local function on_research_finished(event)
	local difficulty = Difficulty.get().difficulty_vote_value
	
	Event_functions.flamer_nerfs()
	Event_functions.mining_buffs(event)

	local research = event.research
	local p_force = research.force
	
    for _, e in ipairs(research.effects) do
		local t = e.type
        if t == 'ammo-damage' then
            local category = e.ammo_category
            local factor = Balance.player_ammo_damage_modifiers()[category] or 0

            if factor then
                local current_m = p_force.get_ammo_damage_modifier(category)
                local m = e.modifier
                p_force.set_ammo_damage_modifier(category, current_m + factor * m)
            end
		elseif t == 'gun-speed' then
			local category = e.ammo_category
			local factor = Balance.player_gun_speed_modifiers()[category] or 0
	
			if factor then
				local current_m = p_force.get_gun_speed_modifier(category)
				local m = e.modifier
				p_force.set_gun_speed_modifier(category, current_m + factor * m)
			end
		end
	end
	
end

local function on_entity_damaged(event)
    local difficulty = Difficulty.get().difficulty_vote_value
	
	if not event.entity.valid then return end
	protect_entity(event)
	if not event.entity.valid then return end
	if not event.entity.health then return end
	Event_functions.biters_chew_rocks_faster(event)
	if event.entity.force.name == "enemy" then
		Event_functions.biter_immunities(event)
	end

	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.name ~= "character" then return end
	if event.damage_type.name ~= "physical" then return end

	local player = event.cause
	if player.shooting_state.state == defines.shooting.not_shooting then return end
	local weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
	local ammo = player.get_inventory(defines.inventory.character_ammo)[player.selected_gun_index]
  if not weapon.valid_for_read or not ammo.valid_for_read then return end
	if weapon.name ~= "pistol" then return end
	if ammo.name ~= "firearm-magazine" and ammo.name ~= "piercing-rounds-magazine" and ammo.name ~= "uranium-rounds-magazine" then return end
  if not event.entity.valid then return end 
	event.entity.damage(event.final_damage_amount * (Balance.pistol_damage_multiplier(difficulty) - 1), player.force, "impact", player)
end



local event = require 'utils.event'
event.on_init(on_init)
event.on_load(on_load)
event.on_nth_tick(2, tick)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
event.add(defines.events.on_pre_player_mined_item, pre_player_mined_item)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_technology_effects_reset, on_technology_effects_reset)
event.add(defines.events.on_gui_click, Gui.on_gui_click)


if _DEBUG then
	local Session = require 'utils.session_data'
	local Color = require 'utils.color_presets'

	commands.add_command(
	    'chronojump',
	    'Weeeeee!',
	    function(cmd)
	        local player = game.player
	        local trusted = Session.get_trusted_table()
	        local param = tostring(cmd.parameter)
	        local p

	        if player then
	            if player ~= nil then
	                p = player.print
	                if not trusted[player.name] then
	                    if not player.admin then
	                        p("[ERROR] Only admins and trusted weebs are allowed to run this command!", Color.fail)
	                        return
	                    end
	                end
	            else
	                p = log
	            end
	        end
	        Public.chronojump(param)
	end)
end
--Time for the debug code.  If any (not global.) globals are written to at this point, an error will be thrown.
--eg, x = 2 will throw an error because it's not global.x or local x
--setmetatable(_G, {
--    __newindex = function(_, n, v)
--        log("Desync warning: attempt to write to undeclared var " .. n)
--        -- game.print("Attempt to write to undeclared var " .. n)
--        global[n] = v;
--    end,
--    __index = function(_, n)
--        return global[n];
--    end
--})

return Public
