local Public = {}

function Public.settings()
	global.gui_refresh_delay = 0
	global.game_lobby_active = true
	global.bb_debug = false
	global.combat_balance = {}
	global.nv_settings = {
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
  map_gen_settings.seed = math.random(1, 99999999)
  map_gen_settings.water = math.random(5, 10) * 0.025
  map_gen_settings.starting_area = 1
  map_gen_settings.terrain_segmentation = 8
  map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}
  map_gen_settings.autoplace_controls = {

    ["coal"] = {frequency = 2.5, size = 0.65, richness = 0.5},
    ["stone"] = {frequency = 2.5, size = 0.65, richness = 0.5},
    ["copper-ore"] = {frequency = 2.5, size = 0.65, richness = 0.5},
    ["iron-ore"] = {frequency = 2.5, size = 0.65, richness = 0.5},
    ["uranium-ore"] = {frequency = 2, size = 1, richness = 1},
    ["crude-oil"] = {frequency = 3, size = 1, richness = 0.75},
    ["trees"] = {frequency = math.random(5, 12) * 0.1, size = math.random(5, 12) * 0.1, richness = math.random(1, 10) * 0.1},
    ["enemy-base"] = {frequency = 0, size = 0, richness = 0}
  }
  local surface = game.create_surface("mirror_terrain", map_gen_settings)
  local hatchery_position = {x = 200, y = 0}
  local x = hatchery_position.x - 16
	local offset = 38

	surface.request_to_generate_chunks({x, 0}, 5)
	surface.force_generate_chunk_requests()

	local positions = {{x = x, y = offset}, {x = x, y = offset * -1}, {x = x, y = offset * -2}, {x = x, y = offset * 2}}
	table.shuffle_table(positions)

	local r = 32
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			local p = {x = hatchery_position.x + x, y = hatchery_position.y + y}
			if math.sqrt(x ^ 2 + y ^ 2) < r then
				local tile = surface.get_tile(p)
				if tile.name == "water" or tile.name == "deepwater" then
					surface.set_tiles({{name = "landfill", position = p}}, true)
				end
			end
		end
	end
  local map_gen_settings2 = {
  		["seed"] = 1,
  		["water"] = 1,
  		["starting_area"] = 1,
  		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
  		["default_enable_all_autoplace_controls"] = false,
  		["autoplace_settings"] = {
  			["entity"] = {treat_missing_as_default = false},
  			["tile"] = {treat_missing_as_default = false},
  			["decorative"] = {treat_missing_as_default = false},
  		},
  	}
  	global.active_surface_index = game.create_surface("native_war", map_gen_settings2)
  	local surface = game.surfaces["native_war"]
  	surface.request_to_generate_chunks({0,0}, 8)
  	surface.force_generate_chunk_requests()
end

function Public.forces()
	local surface = game.surfaces["native_war"]
	game.create_force("west")
	game.create_force("east")
	game.create_force("spectator")
  game.forces.west.set_friend("spectator", true)
  game.forces.west.set_spawn_position({-205, 0}, surface)
  game.forces.west.share_chart = true
  game.forces.east.set_friend("spectator", true)
  game.forces.east.set_spawn_position({205, 0}, surface)
  game.forces.east.share_chart = true
  game.forces.spectator.set_friend("west", true)
  game.forces.spectator.set_friend("east", true)
  game.forces.spectator.set_spawn_position({0,-190},surface)
  game.forces.spectator.share_chart = false

  if not global.nv_settings.blueprint_library_importing then
		game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
	end
	if not global.nv_settings.blueprint_string_importing then
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
	global.biter_raffle = {}
	global.evo_raise_counter = 1
	global.next_attack = "north"
	if math.random(1,2) == 1 then global.next_attack = "south" end
	global.bb_evolution = {}
	global.bb_threat_income = {}
	global.bb_threat = {}
	global.chunks_to_mirror = {}
	global.map_pregen_message_counter = {}

	for _, force_name in pairs({"west", "east"}) do
		game.forces[force_name].share_chart = true
		game.forces[force_name].research_queue_enabled = true
		game.forces[force_name].technologies["artillery"].enabled = false
		game.forces[force_name].technologies["artillery-shell-range-1"].enabled = false
		game.forces[force_name].technologies["artillery-shell-speed-1"].enabled = false
		game.forces[force_name].technologies["land-mine"].enabled = false
		game.forces[force_name].technologies["atomic-bomb"].enabled = false
		game.forces[force_name].research_queue_enabled = true
    game.forces[force_name].share_chart = true
		local force_index = game.forces[force_name].index
		global.map_forces[force_name].unit_health_boost = 1
		global.map_forces[force_name].unit_count = 0
		global.map_forces[force_name].units = {}
		global.map_forces[force_name].radar = {}
		global.map_forces[force_name].max_unit_count = 768
		global.map_forces[force_name].player_count = 0
		global.biter_reanimator.forces[force_index] = 0
		global.map_forces[force_name].energy = 0
		global.map_forces[force_name].modifier ={damage = 1, resistance = 1, splash = 1}
		global.map_forces[force_name].ate_buffer_potion = {
			["automation-science-pack"] = 0,
			["logistic-science-pack"]= 0,
			["military-science-pack"]= 0,
			["chemical-science-pack"]= 0,
			["production-science-pack"]= 0,
			["utility-science-pack"]= 0
		}
		if force_name == "west" then
			global.map_forces[force_name].worm_turrets_positions = {
				[1] = {x=-127,y=-38},
				[2] = {x=-112,y=-38},
				[3] = {x=-127,y=-70},
				[4] = {x=-112,y=-70},
				[5] = {x=-127,y=-102},
				[6] = {x=-112,y=-102},
				[7] = {x=-90,y=-119},
				[8] = {x=-90,y=-136},
				[9] = {x=-70,y=-90},
				[10] = {x=-50,y=-90},
				[11] = {x=-70,y=-58},
				[12] = {x=-50,y=-58},
				[13] = {x=-70,y=-26},
				[14] = {x=-50,y=-26},
				[15] = {x=-70,y=0},
				[16] = {x=-50,y=0},
				[17] = {x=-70,y=36},
				[18] = {x=-50,y=36},
				[19] = {x=-70,y=68},
				[20] = {x=-50,y=68},
				[21] = {x=-70,y=100},
				[22] = {x=-50,y=100},
				[23] = {x=-30,y=119},
				[24] = {x=-30,y=136},
				[25] = {x=-9,y=90},
				[26] = {x=9,y=90},
				[27] = {x=-9,y=59},
				[28] = {x=9,y=59},
				[29] = {x=-9,y=27},
				[30] = {x=9,y=27}
			}
			global.map_forces[force_name].spawn = {x=-137,y=0}
			global.map_forces[force_name].eei = {x=-200,y=0}
		else
			global.map_forces[force_name].worm_turrets_positions ={
				[1] = {x=127,y=38},
				[2] = {x=112,y=38},
				[3] = {x=127,y=70},
				[4] = {x=112,y=70},
				[5] = {x=127,y=102},
				[6] = {x=112,y=102},
				[7] = {x=90,y=119},
				[8] = {x=90,y=136},
				[9] = {x=70,y=90},
				[10] = {x=50,y=90},
				[11] = {x=70,y=58},
				[12] = {x=50,y=58},
				[13] = {x=70,y=26},
				[14] = {x=50,y=26},
				[15] = {x=70,y=0},
				[16] = {x=50,y=0},
				[17] = {x=70,y=-36},
				[18] = {x=50,y=-36},
				[19] = {x=70,y=-68},
				[20] = {x=50,y=-68},
				[21] = {x=70,y=-100},
				[22] = {x=50,y=-100},
				[23] = {x=30,y=-119},
				[24] = {x=30,y=-136},
				[25] = {x=-9,y=-90},
				[26] = {x=9,y=-90},
				[27] = {x=9,y=-59},
				[28] = {x=-9,y=-59},
				[29] = {x=9,y=-27},
				[30] = {x=-9,y=-27}
			}
			global.map_forces[force_name].spawn = {x=137,y=0}
			global.map_forces[force_name].eei = {x=201,y=0}
		end
		global.active_biters[force_name] = {}
		global.biter_raffle[force_name] = {}
	end
end

return Public
