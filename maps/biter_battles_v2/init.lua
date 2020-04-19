local Public = {}

function Public.settings()
	global.gui_refresh_delay = 0
	global.game_lobby_active = true
	global.bb_debug = false
	global.combat_balance = {}
	
	global.bb_settings = {
		--TEAM SETTINGS--
		["team_balancing"] = true,			--Should players only be able to join a team that has less or equal members than the opposing team?
		["only_admins_vote"] = false,		--Are only admins able to vote on the global difficulty?
		
		--GENERAL SETTINGS--
		["blueprint_library_importing"] = false,		--Allow the importing of blueprints from the blueprint library?
		["blueprint_string_importing"] = false,		--Allow the importing of blueprints via blueprint strings?
	}
end

function Public.surface()
	local map_gen_settings = {}
	map_gen_settings.water = math.random(15, 65) * 0.01
	map_gen_settings.starting_area = 2.5
	map_gen_settings.terrain_segmentation = math.random(30, 40) * 0.1
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = 2.5, size = 0.65, richness = 0.5},
		["stone"] = {frequency = 2.5, size = 0.65, richness = 0.5},
		["copper-ore"] = {frequency = 3.5, size = 0.65, richness = 0.5},
		["iron-ore"] = {frequency = 3.5, size = 0.65, richness = 0.5},
		["uranium-ore"] = {frequency = 2, size = 1, richness = 1},
		["crude-oil"] = {frequency = 3, size = 1, richness = 0.75},
		["trees"] = {frequency = math.random(8, 24) * 0.1, size = math.random(8, 24) * 0.1, richness = math.random(1, 10) * 0.1},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}
	}
	game.create_surface("biter_battles", map_gen_settings)

	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false
	game.map_settings.enemy_expansion.enabled = false
end

function Public.forces()
	local surface = game.surfaces["biter_battles"]

	game.create_force("north")	
	game.create_force("south")	
	game.create_force("spectator")
	game.create_force("north_biters")
	game.create_force("south_biters")
	
	local f = game.forces["north"]
	f.set_spawn_position({0, -44}, surface)
	f.set_cease_fire('player', true)
	f.set_friend("spectator", true)
	f.set_friend("south_biters", true)
	f.share_chart = true

	local f = game.forces["south"]
	f.set_spawn_position({0, 44}, surface)
	f.set_cease_fire('player', true)
	f.set_friend("spectator", true)
	f.set_friend("north_biters", true)
	f.share_chart = true

	local f = game.forces["north_biters"]
	f.set_friend("south_biters", true)
	f.set_friend("south", true)
	f.set_friend("player", true)
	f.set_friend("spectator", true)
	f.share_chart = false

	local f = game.forces["south_biters"]
	f.set_friend("north_biters", true)
	f.set_friend("north", true)
	f.set_friend("player", true)
	f.set_friend("spectator", true)
	f.share_chart = false

	local f = game.forces["spectator"]
	f.set_spawn_position({0,0},surface)
	f.technologies["toolbelt"].researched=true
	f.set_cease_fire("north_biters", true)
	f.set_cease_fire("south_biters", true)
	f.set_friend("north", true)
	f.set_friend("south", true)
	f.set_cease_fire("player", true)
	f.share_chart = true

	local f = game.forces["player"]
	f.set_spawn_position({0,0},surface)
	f.set_cease_fire('spectator', true)
	f.set_cease_fire("north_biters", true)
	f.set_cease_fire("south_biters", true)
	f.set_cease_fire('north', true)
	f.set_cease_fire('south', true)
	f.share_chart = false

	if not global.bb_settings.blueprint_library_importing then
		game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
	end
	if not global.bb_settings.blueprint_string_importing then
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)
	end

	local p = game.permissions.create_group("spectator")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], false)
	end

	local defs = {
		defines.input_action.activate_copy,
		defines.input_action.activate_cut,
		defines.input_action.activate_paste,
		defines.input_action.clean_cursor_stack,
		defines.input_action.edit_permission_group,
		defines.input_action.gui_click,
		defines.input_action.gui_confirmed,
		defines.input_action.gui_elem_changed,
		defines.input_action.gui_location_changed,
		defines.input_action.gui_selected_tab_changed,
		defines.input_action.gui_selection_state_changed,
		defines.input_action.gui_switch_state_changed,
		defines.input_action.gui_text_changed,
		defines.input_action.gui_value_changed,
		defines.input_action.open_character_gui,
		defines.input_action.open_kills_gui,
		defines.input_action.rotate_entity,
		defines.input_action.start_walking,
		defines.input_action.toggle_show_entity_info,
		defines.input_action.write_to_console,
	}
	
	for _, d in pairs(defs) do p.set_allows_action(d, true) end

	global.rocket_silo = {}
	global.spectator_rejoin_delay = {}
	global.spy_fish_timeout = {}
	global.force_area = {}
	global.unit_spawners = {}
	global.unit_spawners.north_biters = {}
	global.unit_spawners.south_biters = {}
	global.active_biters = {}
	global.unit_groups = {}
	global.biter_raffle = {}
	global.evo_raise_counter = 1
	global.next_attack = "north"
	if math.random(1,2) == 1 then global.next_attack = "south" end
	global.bb_evolution = {}
	global.bb_threat_income = {}
	global.bb_threat = {}
	global.chunks_mirrored = {}
	global.map_pregen_message_counter = {}

	for _, force in pairs(game.forces) do
		game.forces[force.name].technologies["artillery"].enabled = false
		game.forces[force.name].technologies["artillery-shell-range-1"].enabled = false
		game.forces[force.name].technologies["artillery-shell-speed-1"].enabled = false
		game.forces[force.name].technologies["atomic-bomb"].enabled = false
		game.forces[force.name].research_queue_enabled = true
		global.spy_fish_timeout[force.name] = 0
		global.active_biters[force.name] = {}
		global.biter_raffle[force.name] = {}
		global.bb_evolution[force.name] = 0
		global.bb_threat_income[force.name] = 0
		global.bb_threat[force.name] = 0
		global.biter_health_boost_forces[force.index] = 1
	end
end

return Public