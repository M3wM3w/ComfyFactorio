-- chronosphere, or also called chronotrain --

require "modules.biter_noms_you"
require "modules.biters_yield_coins"
require "modules.no_deconstruction_of_neutral_entities"
require "maps.chronosphere.comfylatron"
local Ai = require "maps.chronosphere.ai"
local Balance = require "maps.chronosphere.balance"
local Difficulty = require "modules.difficulty_vote"
local Event_functions = require "maps.chronosphere.event_functions"
local Factories = require 'maps.chronosphere.production'
local Gui = require "maps.chronosphere.gui"
local Chrono = require "maps.chronosphere.chrono"
local Chrono_table = require "maps.chronosphere.table"
local Locomotive = require "maps.chronosphere.locomotive"
local Map = require "modules.map_info"
local Minimap = require "maps.chronosphere.minimap"
local On_Event = require "maps.chronosphere.on_event"
local Reset = require "functions.soft_reset"
local Tick_functions = require "maps.chronosphere.tick_functions"
local Upgrades = require "maps.chronosphere.upgrades"
local World_functions = require "maps.chronosphere.world_functions"
local Worlds = require "maps.chronosphere.world_list"
require "maps.chronosphere.config_tab"

local function generate_overworld(surface, optworld)
	local objective = Chrono_table.get_table()
	Worlds.determine_world(optworld)
	Chrono.message_on_arrival()
	Chrono.setup_world(surface)
end

local function reset_map()
	local objective = Chrono_table.get_table()
	Chrono.reset_surfaces()
	Worlds.determine_world(nil)
	local world = objective.world
	if not objective.active_surface_index then
		objective.active_surface_index = game.create_surface("chronosphere", Chrono.get_map_gen_settings()).index
	else
		game.forces.player.set_spawn_position({12, 10}, game.surfaces[objective.active_surface_index])
		objective.active_surface_index = Reset.soft_reset_map(game.surfaces[objective.active_surface_index], Chrono.get_map_gen_settings(), Balance.starting_items).index
	end

	local surface = game.surfaces[objective.active_surface_index]
	generate_overworld(surface, world)
	Chrono.restart_settings()
	Chrono.reset_chests()

	for _,player in pairs(game.players) do
		Minimap.minimap(player, true)
	end

	game.forces.player.set_spawn_position({12, 10}, surface)
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(true))
	Event_functions.render_train_hp()
	game.reset_time_played()
	Locomotive.create_wagon_room()
	Event_functions.mining_buffs(nil)
	if objective.game_won then
		game.print({"chronosphere.message_game_won_restart"}, {r=0.98, g=0.66, b=0.22})
	end
	Minimap.update_surface()
	objective.game_lost = false
	objective.game_won = false

	-- game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
	-- game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
	-- game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)
	--game.permissions.get_group("Default").set_allows_action(defines.input_action.set_linked_container_link_i_d, false)
end

local function chronojump(choice)
	local objective = Chrono_table.get_table()
	local scheduletable = Chrono_table.get_schedule_table()
	if objective.chronojumps == 0 then
		Difficulty.set_poll_closing_timeout(game.tick)
	end

	if objective.game_lost then goto continue end

	if objective.chronojumps <= 24 then
		Locomotive.award_coins(
			Balance.coin_reward_per_second_jumped_early(objective.chronochargesneeded / objective.passive_chronocharge_rate + 180 - objective.passivetimer, Difficulty.get().difficulty_vote_value)
		)
	end

	Chrono.process_jump()
	Factories.jump_procedure()

	local oldsurface = game.surfaces[objective.active_surface_index]

	for _,player in pairs(game.players) do
		if player.surface == oldsurface then
			if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
			local wagons = {objective.locomotive_cargo[1], objective.locomotive_cargo[2], objective.locomotive_cargo[3]}
			Locomotive.enter_cargo_wagon(player, wagons[math.random(1,3)])
		end
	end
	scheduletable.lab_cells = {}
	objective.active_surface_index = game.create_surface("chronosphere" .. objective.chronojumps, Chrono.get_map_gen_settings()).index
	local surface = game.surfaces[objective.active_surface_index]

	generate_overworld(surface, choice)
	game.forces.player.set_spawn_position({12, 10}, surface)
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(false))
	Event_functions.render_train_hp()
	Tick_functions.change_to_neutral(oldsurface)
	Tick_functions.add_schedule(oldsurface)
	Chrono.post_jump()
	Event_functions.flamer_nerfs()
	Minimap.update_surface()
	Tick_functions.train_pollution("postjump")

	::continue::
end

local function drain_accumulators()
	local objective = Chrono_table.get_table()
	if objective.passivetimer < 10 then return end
	if not objective.chronocharges then return end
	if objective.chronocharges >= objective.chronochargesneeded then return end
	if not objective.accumulators then return end
	if (objective.world.id == 2 and objective.world.variant.id == 2) or objective.world.id == 7 then return end
	local acus = objective.accumulators
	if #acus < 1 then return end
	for i = 1, #acus, 1 do
		if not acus[i].valid or not objective.locomotive.valid then return end
		local energy = acus[i].energy
		if energy > 1010000 and objective.chronocharges < objective.chronochargesneeded then
			acus[i].energy = acus[i].energy - 1000000
			objective.chronocharges = objective.chronocharges + 1
			if objective.locomotive ~= nil and objective.locomotive.valid then
				Tick_functions.train_pollution("accumulators")
				if objective.chronocharges >= objective.chronochargesneeded then
					Event_functions.check_if_overstayed()
					Event_functions.initiate_jump_countdown()
					return
				end
			end
		end
	end
end

local function tick()
	local objective = Chrono_table.get_table()
	local tick = game.tick
	Ai.Tick_actions(tick)

	if tick % 60 == 10 and objective.passivetimer > 64 then
		Tick_functions.scheduled_surface_clearing()
	end
	if tick % 60 == 30 and objective.passivetimer < 64 then
		Tick_functions.request_chunks()
	end
	if tick % 30 == 20 then
		Tick_functions.laser_defense()
	end
	if tick % 20 == 0 and objective.world.id == 8 then
		Tick_functions.spawn_poison()
	end
	if tick % 60 == 0 then
		objective.passivetimer = objective.passivetimer + 1
		if objective.world.id ~= 7 then
			Tick_functions.update_charges(tick)
			drain_accumulators()
		end
		Factories.produce_assemblers()
		Tick_functions.dangertimer()
		Tick_functions.realtime_events()
		if objective.jump_countdown_start_time == -1 then
			if objective.chronocharges >= objective.chronochargesneeded then
				Event_functions.check_if_overstayed()
				Event_functions.initiate_jump_countdown()
			end
			Tick_functions.train_pollution("passive")
		else
			if objective.passivetimer == objective.jump_countdown_start_time + 180 then
				chronojump(nil)
			else
				Tick_functions.train_pollution("countdown")
			end
		end
	end
	if tick % 120 == 0 then
		Tick_functions.move_items()
		Tick_functions.output_items()
	end
	if tick % 600 == 0 then
		Tick_functions.ramp_evolution()
		Factories.check_activity()
		Upgrades.check_upgrades()
		Tick_functions.transfer_pollution()
		if objective.poisontimeout > 0 then
			objective.poisontimeout = objective.poisontimeout - 1
		end
		if tick % 1800 == 0 then
			Locomotive.set_player_spawn_and_refill_fish()
			Event_functions.set_objective_health(Tick_functions.repair_train())
			if objective.config.offline_loot then
				Tick_functions.offline_players()
			end
		end
		if tick % 1800 == 900 and objective.jump_countdown_start_time ~= -1 then
			Ai.perform_main_attack()
		end

		if objective.game_reset_tick then
			if objective.game_reset_tick < tick then
				objective.game_reset_tick = nil
				if objective.game_won then
					Tick_functions.message_game_won()
				end
				reset_map()
			end
			return
		end
		Locomotive.fish_tag()
	end
	for _, player in pairs(game.connected_players) do
		Minimap.toggle_button(player)
		Gui.update_gui(player)
	end
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
	objective.config.overstay_penalty = true
	objective.config.lock_difficulties = true
	objective.config.lock_hard_difficulties = true
	Chrono.set_difficulty_settings()
	game.create_force("scrapyard")
	local mgs = game.surfaces["nauvis"].map_gen_settings
	mgs.width = 16
	mgs.height = 16
	game.surfaces["nauvis"].map_gen_settings = mgs
	game.surfaces["nauvis"].clear()
	reset_map()
end

local function on_player_driving_changed_state(event)
	local player = game.players[event.player_index]
	local vehicle = event.entity
	Locomotive.enter_cargo_wagon(player, vehicle)
	Minimap.minimap(player, true)
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(10, tick)
Event.add(defines.events.on_entity_damaged, On_Event.on_entity_damaged)
Event.add(defines.events.on_entity_died, On_Event.on_entity_died)
Event.add(defines.events.on_player_joined_game, On_Event.on_player_joined_game)
Event.add(defines.events.on_pre_player_left_game, On_Event.on_pre_player_left_game)
Event.add(defines.events.on_pre_player_mined_item, On_Event.pre_player_mined_item)
Event.add(defines.events.on_player_mined_entity, On_Event.on_player_mined_entity)
Event.add(defines.events.on_research_finished, On_Event.on_research_finished)
Event.add(defines.events.on_built_entity, On_Event.on_built_entity)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_player_changed_position, On_Event.on_player_changed_position)
Event.add(defines.events.on_technology_effects_reset, Event_functions.on_technology_effects_reset)
Event.add(defines.events.on_gui_click, Gui.on_gui_click)
Event.add(defines.events.on_pre_player_died, On_Event.on_pre_player_died)

if _DEBUG then
	local Session = require 'utils.datastore.session_data'
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
	        chronojump(param)
	end)
end
