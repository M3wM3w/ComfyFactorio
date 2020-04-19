-- chronosphere --

global.objective = {}
global.objective.upgrades = {}
require "modules.difficulty_vote"
require "modules.biters_yield_coins"
require "modules.no_deconstruction_of_neutral_entities"
--require "modules.no_solar"
require "modules.shotgun_buff"
require "modules.mineable_wreckage_yields_scrap"
require "maps.chronosphere.comfylatron"
require "maps.chronosphere.terrain"
require "on_tick_schedule"
require "modules.biter_noms_you"
local Server = require 'utils.server'
local Ai = require "maps.chronosphere.ai"
local Planets = require "maps.chronosphere.chronobubles"
local Ores =require "maps.chronosphere.ores"
local Reset = require "functions.soft_reset"
local Map = require "modules.map_info"
local Upgrades = require "maps.chronosphere.upgrades"
local Tick_functions = require "maps.chronosphere.tick_functions"
local Event_functions = require "maps.chronosphere.event_functions"
local Chrono = require "maps.chronosphere.chrono"
local Locomotive = require "maps.chronosphere.locomotive"
local Gui = require "maps.chronosphere.gui"
local math_random = math.random
local math_floor = math.floor
local math_sqrt = math.sqrt
global.objective.config = {}
global.flame_boots = {}
global.comfylatron = nil
global.lab_cells = {}
require "maps.chronosphere.config_tab"

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 32, ['grenade'] = 4, ['raw-fish'] = 4, ['rail'] = 16, ['wood'] = 16}

local function generate_overworld(surface, optplanet)
	Planets.determine_planet(optplanet)
	local planet = global.objective.planet
	local message = {"chronosphere.planet_jump", planet[1].name.name, planet[1].ore_richness.name, planet[1].day_speed.name}
	game.print(message, {r=0.98, g=0.66, b=0.22})
	local discordmessage = "Destination: "..planet[1].name.dname..", Ore Richness: "..planet[1].ore_richness.dname..", Daynight cycle: "..planet[1].day_speed.dname
	Server.to_discord_embed(discordmessage)
	if planet[1].name.id == 12 then
		game.print({"chronosphere.message_choppy"}, {r=0.98, g=0.66, b=0.22})
	elseif planet[1].name.id == 14 then
		game.print({"chronosphere.message_lava"}, {r=0.98, g=0.66, b=0.22})
	elseif planet[1].name.id == 17 then
		game.print({"chronosphere.message_fishmarket1"}, {r=0.98, g=0.66, b=0.22})
		game.print({"chronosphere.message_fishmarket2"}, {r=0.98, g=0.66, b=0.22})
	end
	surface.min_brightness = 0
	surface.brightness_visual_weights = {1, 1, 1}
	global.objective.surface = surface
	surface.daytime = planet[1].time
	local timer = planet[1].day_speed.timer
	if timer == 0 then
		surface.freeze_daytime = true
		timer = timer + 1
	else
		surface.freeze_daytime = false
	end
	surface.ticks_per_day = timer * 250

	local moisture = planet[1].name.moisture
	if moisture ~= 0 then
		local mgs = surface.map_gen_settings
		mgs.property_expression_names["control-setting:moisture:bias"] = moisture
		surface.map_gen_settings = mgs
	end
	if planet[1].name.id == 14 then --lava planet
		local mgs = surface.map_gen_settings
		mgs.water = 0
		surface.map_gen_settings = mgs
	end
	if planet[1].name.id ~= 12 then --choppy planet
		local mgs = surface.map_gen_settings
		mgs.water = 0.2
		surface.map_gen_settings = mgs
	end
	if planet[1].name.id == 17 then --fish market
		local mgs = surface.map_gen_settings
		mgs.width = 2176
		surface.map_gen_settings = mgs
		surface.request_to_generate_chunks({-960,-64}, 3)
		--surface.request_to_generate_chunks({0,0}, 3)
		surface.force_generate_chunk_requests()
	else
		surface.request_to_generate_chunks({0,0}, 3)
		surface.force_generate_chunk_requests()
	end
end

local function render_train_hp()
	local surface = game.surfaces[global.active_surface_index]
	local objective = global.objective
	objective.health_text = rendering.draw_text{
		text = "HP: " .. objective.health .. " / " .. objective.max_health,
		surface = surface,
		target = global.locomotive,
		target_offset = {0, -2.5},
		color = global.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	objective.caption = rendering.draw_text{
		text = "Comfylatron's ChronoTrain",
		surface = surface,
		target = global.locomotive,
		target_offset = {0, -4.25},
		color = global.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end


local function reset_map()
	for _,player in pairs(game.players) do
		if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
	end
	if game.surfaces["chronosphere"] then game.delete_surface(game.surfaces["chronosphere"]) end
	if game.surfaces["cargo_wagon"] then game.delete_surface(game.surfaces["cargo_wagon"]) end
	local objective = global.objective
	for i = 13, 16, 1 do
		objective.upgrades[i] = 0
	end
	objective.computermessage = 0
	objective.chronojumps = 0
	Planets.determine_planet(nil)
	local planet = global.objective.planet
	if not global.active_surface_index then
		global.active_surface_index = game.create_surface("chronosphere", Chrono.get_map_gen_settings()).index
	else
		game.forces.player.set_spawn_position({12, 10}, game.surfaces[global.active_surface_index])
		global.active_surface_index = Reset.soft_reset_map(game.surfaces[global.active_surface_index], Chrono.get_map_gen_settings(), starting_items).index
	end

	local surface = game.surfaces[global.active_surface_index]
	generate_overworld(surface, planet)
	Chrono.restart_settings()

	game.forces.player.set_spawn_position({12, 10}, surface)
	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(true))
	render_train_hp()
	game.reset_time_played()
	Locomotive.create_wagon_room()
	if objective.game_won then
		game.print({"chronosphere.message_game_won_restart"}, {r=0.98, g=0.66, b=0.22})
	end
	objective.game_lost = false
	objective.game_won = false

	--set_difficulty()
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	global.flame_boots[event.player_index] = {fuel = 1}
	if not global.flame_boots[event.player_index].steps then global.flame_boots[event.player_index].steps = {} end

	local surface = game.surfaces[global.active_surface_index]

	if player.online_time == 0 then
		player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	if player.surface.index ~= global.active_surface_index and player.surface.name ~= "cargo_wagon" then
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
	local player = game.players[event.player_index]
	if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
	if player.character then
		global.objective.offline_players[#global.objective.offline_players + 1] = {index = event.player_index, tick = game.tick}
	end
end


local function set_objective_health(final_damage_amount)
	if final_damage_amount == 0 then return end
	local objective = global.objective
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

local function chronojump(choice)
	local objective = global.objective
	if objective.game_lost then return end
	Chrono.process_jump()

	local oldsurface = game.surfaces[global.active_surface_index]

	for _,player in pairs(game.players) do
		if player.surface == oldsurface then
			if player.controller_type == defines.controllers.editor then player.toggle_map_editor() end
			local wagons = {global.locomotive_cargo[1], global.locomotive_cargo[2], global.locomotive_cargo[3]}
			Locomotive.enter_cargo_wagon(player, wagons[math_random(1,3)])
		end
	end
	global.lab_cells = {}
	global.active_surface_index = game.create_surface("chronosphere" .. objective.chronojumps, Chrono.get_map_gen_settings()).index
	local surface = game.surfaces[global.active_surface_index]
	log("seed of new surface: " .. surface.map_gen_settings.seed)
	local planet = nil
	if choice then
		Planets.determine_planet(choice)
		planet = global.objective.planet
	end
	generate_overworld(surface, planet)

	game.forces.player.set_spawn_position({12, 10}, surface)

	Locomotive.locomotive_spawn(surface, {x = 16, y = 10}, Chrono.get_wagons(false))
	render_train_hp()
	game.delete_surface(oldsurface)
	Chrono.post_jump()
	Event_functions.flamer_nerfs()
	surface.pollute(global.locomotive.position, 150 * (4 / (objective.upgrades[2] / 2 + 1)) * (1 + global.objective.chronojumps) * global.difficulty_vote_value)
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

local function tick()
	local objective = global.objective
	local tick = game.tick
	if tick % 60 == 30 and objective.passivetimer < 64 then
		local surface = game.surfaces[global.active_surface_index]
		if objective.planet[1].name.id == 17 then
			surface.request_to_generate_chunks({-800,0}, 3 + math_floor(objective.passivetimer / 5))
		else
			surface.request_to_generate_chunks({0,0}, 3 + math_floor(objective.passivetimer / 5))
		end
		--surface.force_generate_chunk_requests()

	end
	if tick % 10 == 0 and objective.planet[1].name.id == 18 then
		Tick_functions.spawn_poison()
	end
	if tick % 30 == 0 then
		if tick % 600 == 0 then
			Tick_functions.charge_chronosphere()
			Tick_functions.transfer_pollution()
			if objective.poisontimeout > 0 then
				objective.poisontimeout = objective.poisontimeout - 1
			end
		end
		if tick % 1800 == 0 then
			Locomotive.set_player_spawn_and_refill_fish()
			set_objective_health(Tick_functions.repair_train())
			Upgrades.check_upgrades()
			Tick_functions.boost_evolution()
			if objective.config.offline_loot then
				Tick_functions.offline_players()
			end
		end
		local key = tick % 3600
		if tick_minute_functions[key] then tick_minute_functions[key]() end
		if tick % 60 == 0 and objective.planet[1].name.id ~= 17 then
			objective.chronotimer = objective.chronotimer + 1
			objective.passivetimer = objective.passivetimer + 1
			if objective.chronojumps > 0 then
				game.surfaces[global.active_surface_index].pollute(global.locomotive.position, (0.5 * objective.chronojumps) * (4 / (objective.upgrades[2] / 2 + 1)) * global.difficulty_vote_value)
			end
			if objective.planet[1].name.id == 19 then
				Tick_functions.dangertimer()
			end
			if Tick_functions.check_chronoprogress() then chronojump(nil) end
		end
		if tick % 120 == 0 then
			Tick_functions.move_items()
			Tick_functions.output_items()
		end
		if global.game_reset_tick then
			if global.game_reset_tick < tick then
				global.game_reset_tick = nil
				reset_map()
			end
			return
		end
		Locomotive.fish_tag()
	end
	for _, player in pairs(game.connected_players) do Gui.update_gui(player) end
end

local function on_init()
	local T = Map.Pop_info()
	T.localised_category = "chronosphere"
	T.main_caption_color = {r = 150, g = 150, b = 0}
	T.sub_caption_color = {r = 0, g = 150, b = 0}
	global.objective.game_lost = true
	global.objective.game_won = false
	global.objective.offline_players = {}

	global.objective.config.offline_loot = true
	global.objective.config.jumpfailure = true
	game.create_force("scrapyard")
	local mgs = game.surfaces["nauvis"].map_gen_settings
	mgs.width = 16
	mgs.height = 16
	game.surfaces["nauvis"].map_gen_settings = mgs
	game.surfaces["nauvis"].clear()
	reset_map()
	Chrono.init_setup()
	Event_functions.mining_buffs(nil)
	--if game.surfaces["nauvis"] then game.delete_surface(game.surfaces["nauvis"]) end
end

-- local function on_load()
-- 	Chrono.init_setup()
-- end

local function protect_entity(event)
	if event.entity.force.index ~= 1 then return end --Player Force
	if Event_functions.isprotected(event.entity) then
		if event.cause then
			if event.cause == global.comfylatron or event.entity == global.comfylatron then
				return
			end
			if event.cause.force.index == 2 or event.cause.force.name == "scrapyard" then
					set_objective_health(event.final_damage_amount)
			end
		elseif global.objective.planet[1].name.id == 19 then
			set_objective_health(event.final_damage_amount)
		end
		if not event.entity.valid then return end
		event.entity.health = event.entity.health + event.final_damage_amount
	end
end

local function on_entity_damaged(event)
	if not event.entity.valid then	return end
	protect_entity(event)
	if not event.entity.valid then	return end
	if not event.entity.health then return end
	Event_functions.biters_chew_rocks_faster(event)
	if event.entity.force.name == "enemy" then
		Event_functions.biter_immunities(event)
	end
end

local function pre_player_mined_item(event)
	local objective = global.objective
	if objective.planet[1].name.id == 11 then --rocky planet
		if event.entity.name == "rock-huge" or event.entity.name == "rock-big" or event.entity.name == "sand-rock-big" then
			Event_functions.trap(event.entity, false)
			event.entity.destroy()
			Event_functions.rocky_loot(event)
		end
	end
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "tree" and global.objective.planet[1].name.id == 12 then --choppy planet
		Event_functions.trap(entity, false)
		Event_functions.choppy_loot(event)
	end
	if entity.name == "rock-huge" or entity.name == "rock-big" or entity.name == "sand-rock-big" then
		if global.objective.planet[1].name.id ~= 11 and global.objective.planet[1].name.id ~= 16 then --rocky and maze planet
			Ores.prospect_ores(entity, entity.surface, entity.position)
		elseif
			global.objective.planet[1].name.id == 11 then event.buffer.clear() -- rocky planet
		end
	end
end

local function on_entity_died(event)
	if event.entity.type == "tree" and global.objective.planet[1].name.id == 12 then --choppy planet
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
		global.objective.active_biters[entity.unit_number] = nil
	end
	if entity.type == "rocket-silo" and entity.force.name == "enemy" then
		Event_functions.danger_silo(entity)
	end
	if entity.force.name == "scrapyard" and entity.name == "gun-turret" then
		if global.objective.planet[1].name.id == 19 or global.objective.planet[1].name.id == 16 then --danger + hedge maze
			Event_functions.trap(entity, true)
		end
	end
	if entity.force.name == "enemy" then
		if entity.type == "unit-spawner" then
			Event_functions.spawner_loot(entity.surface, entity.position)
			if global.objective.planet[1].name.id == 18 then
				Ores.prospect_ores(entity, entity.surface, entity.position)
			end
		else
			if global.objective.planet[1].name.id == 18 then
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

local function on_research_finished(event)
	Event_functions.flamer_nerfs()
	Event_functions.mining_buffs(event)
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
	if global.objective.planet[1].name.id == 14 then --lava planet
		Event_functions.lava_planet(event)
	end
end

local function on_technology_effects_reset(event)
	Event_functions.on_technology_effects_reset(event)
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
	        chronojump(param)
	end)
end
--Time for the debug code.  If any (not global.) globals are written to at this point, an error will be thrown.
--eg, x = 2 will throw an error because it's not global.x or local x
setmetatable(_G, {
    __newindex = function(_, n, v)
        log("Desync warning: attempt to write to undeclared var " .. n)
        -- game.print("Attempt to write to undeclared var " .. n)
        global[n] = v;
    end,
    __index = function(_, n)
        return global[n];
    end
})
