local function init_surface()
	local map_gen_settings = {}
	map_gen_settings.water = "0"
	map_gen_settings.starting_area = "5"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0", size = "0", richness = "0"},
		["stone"] = {frequency = "0", size = "0", richness = "0"},
		["copper-ore"] = {frequency = "0", size = "0", richness = "0"},
		["iron-ore"] = {frequency = "0", size = "0", richness = "0"},
		["uranium-ore"] = {frequency = "0", size = "0", richness = "0"},
		["crude-oil"] = {frequency = "0", size = "0", richness = "0"},
		["trees"] = {frequency = "0", size = "0", richness = "0"},
		["enemy-base"] = {frequency = "0", size = "0", richness = "0"}	
	}
	local surface = game.create_surface("wave_of_death", map_gen_settings)
			
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false	
	game.map_settings.enemy_expansion.enabled = false
	game.difficulty_settings.technology_price_multiplier = 0.8
	
	return surface
end

local function init_forces(surface)
	game.create_force(1)
	game.create_force(2)
	game.create_force(3)
	game.create_force(4)
	
	for _, force in pairs(game.forces) do
		if force.name ~= "enemy" then
			force.technologies["optics"].researched = true
			force.technologies["artillery"].enabled = false
			force.technologies["artillery-shell-range-1"].enabled = false					
			force.technologies["artillery-shell-speed-1"].enabled = false	
			force.technologies["atomic-bomb"].enabled = false			
			force.set_ammo_damage_modifier("shotgun-shell", 1)
			force.research_queue_enabled = true
			force.share_chart = true
			for _, force_2 in pairs(game.forces) do
				if force_2.name ~= "enemy" then
					force.set_cease_fire(force_2.name, true)
				end
			end
		end
	end
	
	for i = 1, 4, 1 do
		game.forces[i].set_friend("player", true)
		game.forces["player"].set_friend(game.forces[i].name, true)
	end
	game.forces["player"].set_spawn_position({x = 32, y = 0}, surface)
	
	local p = game.permissions.create_group("spectator")
	for action_name, _ in pairs(defines.input_action) do
		p.set_allows_action(defines.input_action[action_name], false)
	end	
	local defs = {
		defines.input_action.write_to_console,
		defines.input_action.gui_click,
		defines.input_action.gui_selection_state_changed,
		defines.input_action.gui_checked_state_changed	,
		defines.input_action.gui_elem_changed,
		defines.input_action.gui_text_changed,
		defines.input_action.gui_value_changed,
		defines.input_action.start_walking,
		defines.input_action.open_kills_gui,
		defines.input_action.open_character_gui,
		defines.input_action.edit_permission_group,
		defines.input_action.toggle_show_entity_info,
		defines.input_action.rotate_entity,
		defines.input_action.start_research
	}	
	for _, d in pairs(defs) do p.set_allows_action(d, true) end
end

local function init_globals()
	global.spread_amount_modifier = 0.75 --percentage of a cleared wave to spawn at all other teams
	global.wod_lane = {}
	global.wod_biters = {}
	global.lobby_active = true
	
	for i = 1, 4, 1 do
		global.wod_lane[i] = {}
		global.wod_lane[i].current_wave = 1
		global.wod_lane[i].alive_biters = 0
		global.wod_lane[i].game_lost = false
	end
end

local function init()
	if global.spread_amount_modifier then return end
	local surface = init_surface()	
	init_globals()
	init_forces(surface)
	
	surface.request_to_generate_chunks({x = 0, y = 0}, 8)
	surface.force_generate_chunk_requests()
end

return init