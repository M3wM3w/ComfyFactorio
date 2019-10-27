local forces = {
	{name = "north", color = {r = 0, g = 0, b = 200}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "south",	color = {r = 200, g = 0, b = 0}},
}

local function get_player_array(force_name)
	local a = {}	
	for _, p in pairs(game.forces[force_name].connected_players) do a[#a + 1] = p.name end
	return a
end

local function freeze_players()
	if not global.freeze_players then return end
	global.team_manager_default_permissions = {}
	local p = game.permissions.get_group("Default")	
	for action_name, _ in pairs(defines.input_action) do
		global.team_manager_default_permissions[action_name] = p.allows_action(defines.input_action[action_name])
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
		defines.input_action.edit_permission_group,
	}	
	for _, d in pairs(defs) do p.set_allows_action(d, true) end
end

local function unfreeze_players()
	local p = game.permissions.get_group("Default") 
	for action_name, _ in pairs(defines.input_action) do
		if global.team_manager_default_permissions[action_name] then
			p.set_allows_action(defines.input_action[action_name], true)
		end
	end
end

local function return_player_body(player)
	if player.character then return end
	local spawn = player.force.get_spawn_position(player.surface)
	player.set_controller({type=defines.controllers.god})
	local pos = player.surface.find_non_colliding_position("character", spawn, 3, 0.5)
	if pos then
		player.teleport(pos, player.surface)
	else
		player.teleport(spawn, player.surface)
	end
	player.create_character()
end

local function toggle_ghost_spectate(player)
	if player.character then
		player.force = "spectator_ghost"
		player.character.destroy() 
		player.character = nil
		player.set_controller({type=defines.controllers.spectator})
		game.print(player.name .. " has turned into a spectator ghost.")
	else
		player.force = "spectator"
		return_player_body(player)	
		game.print(player.name .. " has stopped being a spectator ghost.")
	end	
end


local function leave_corpse(player)
	if not player.character then return end
	
	local inventories = {
		player.get_inventory(defines.inventory.character_main),
		player.get_inventory(defines.inventory.character_guns),
		player.get_inventory(defines.inventory.character_ammo),
		player.get_inventory(defines.inventory.character_armor),
		player.get_inventory(defines.inventory.character_vehicle),
		player.get_inventory(defines.inventory.character_trash),
	}
	
	local corpse = false
	for _, i in pairs(inventories) do
		for index = 1, #i, 1 do
			if not i[index].valid then break end
			corpse = true
			break
		end
		if corpse then
			player.character.die()
			break
		end
	end
	
	if player.character then player.character.destroy() end	
	player.character = nil
	player.set_controller({type=defines.controllers.god})
	player.create_character()	
end

local function switch_force(player_name, force_name)
	if not game.players[player_name] then game.print("Team Manager >> Player " .. player_name .. " does not exist.", {r=0.98, g=0.66, b=0.22}) return end
	if not game.forces[force_name] then game.print("Team Manager >> Force " .. force_name .. " does not exist.", {r=0.98, g=0.66, b=0.22}) return end
	
	local player = game.players[player_name]
	return_player_body(player)
	player.force = game.forces[force_name]
				
	game.print(player_name .. " has been switched into team " .. force_name .. ".", {r=0.98, g=0.66, b=0.22})
	
	leave_corpse(player)
	
	global.chosen_team[player_name] = nil	
	if force_name == "spectator" then	
		spectate(player, true)		
	else
		join_team(player, force_name, true)
	end
end

local function draw_manager_button(player)
	if player.gui.top["team_manager_toggle_button"] then player.gui.top["team_manager_toggle_button"].destroy() end	
	local button = player.gui.top.add({type = "sprite-button", name = "team_manager_toggle_button", caption = "Team Manager", tooltip = tooltip})
	button.style.font = "heading-2"
	button.style.font_color = {r = 0.88, g = 0.55, b = 0.11}
	button.style.minimal_height = 38
	button.style.minimal_width = 120
	button.style.top_padding = 2
	button.style.left_padding = 0
	button.style.right_padding = 0
	button.style.bottom_padding = 2
end

local function draw_manager_gui(player)
	if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() end
	
	local frame = player.gui.center.add({type = "frame", name = "team_manager_gui", caption = "Manage Teams", direction = "vertical"})
	
	local t = frame.add({type = "table", name = "team_manager_root_table", column_count = 5})
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local l = t.add({type = "sprite-button", caption = string.upper(forces[i2].name), name = forces[i2].name})
			l.style.minimal_width = 160
			l.style.maximal_width = 160
			l.style.font_color = forces[i2].color
			l.style.font = "heading-1"
			i2 = i2 + 1
		else
			local tt = t.add({type = "label", caption = " "})
		end		
	end
	
	local i2 = 1
	for i = 1, #forces * 2 - 1, 1 do
		if i % 2 == 1 then
			local player_list = get_player_array(forces[i2].name)
			if forces[i2].name == "spectator" then
				table.add_all(player_list, get_player_array("spectator_ghost"))
			end
			local list_box = t.add({type = "list-box", name = "team_manager_list_box_" .. i2, items = player_list})
			list_box.style.minimal_height = 360
			list_box.style.minimal_width = 160
			list_box.style.maximal_height = 480
			i2 = i2 + 1
		else
			local tt = t.add({type = "table", column_count = 1})
			local b = tt.add({type = "sprite-button", name = i2 - 1, caption = "→"})
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
			local b = tt.add({type = "sprite-button", name = i2, caption = "←"})
			b.style.font = "heading-1"
			b.style.maximal_height = 38
			b.style.maximal_width = 38
		end		
	end
	
	frame.add({type = "label", caption = ""})
	
	local t = frame.add({type = "table", name = "team_manager_bottom_buttons", column_count = 4})	
	local button = t.add({
			type = "button",
			name = "team_manager_close",
			caption = "Close",
			tooltip = "Close this window."
		})
	button.style.font = "heading-2"
	
	if global.tournament_mode then
		button = t.add({
			type = "button",
			name = "team_manager_activate_tournament",
			caption = "Tournament Mode Activated",
			tooltip = "Only admins can move players. Active players can no longer go spectate. New joining players are spectators."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
	else
		button = t.add({
			type = "button",
			name = "team_manager_activate_tournament",
			caption = "Tournament Mode Disabled",
			tooltip = "Only admins can move players. Active players can no longer go spectate. New joining players are spectators."
		})
		button.style.font_color = {r = 55, g = 55, b = 55}
	end
	button.style.font = "heading-2"
	
	if global.freeze_players then
		button = t.add({
			type = "button",
			name = "team_manager_freeze_players",
			caption = "Unfreeze Players",
			tooltip = "Releases all players."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
	else
		button = t.add({
			type = "button",
			name = "team_manager_freeze_players",
			caption = "Freeze Players",
			tooltip = "Freezes all players, unable to perform actions, until released."
		})
		button.style.font_color = {r = 55, g = 55, b = 222}
	end
	button.style.font = "heading-2"
	
	button = t.add({
		type = "button",
		name = "team_manager_turn_ghost",
		caption = "Ghost-Spectate",
		tooltip = "Turn yourself into a spooky spectator ghost."
	})
	button.style.font_color = {r = 88, g = 88, b = 88}
	button.style.font = "heading-2"
end

local function set_custom_team_name(force_name, team_name)
	if team_name == "" then global.tm_custom_name[force_name] = nil return end
	if not team_name then global.tm_custom_name[force_name] = nil return end
	global.tm_custom_name[force_name] = tostring(team_name)
end

local function custom_team_name_gui(player, force_name)
	if player.gui.center["custom_team_name_gui"] then player.gui.center["custom_team_name_gui"].destroy() return end	
	local frame = player.gui.center.add({type = "frame", name = "custom_team_name_gui", caption = "Set custom team name:", direction = "vertical"})
	local text = force_name
	if global.tm_custom_name[force_name] then text = global.tm_custom_name[force_name] end
	
	local textfield = frame.add({ type = "textfield", name = force_name, text = text })	
	local t = frame.add({type = "table", column_count = 2})	
	local button = t.add({
			type = "button",
			name = "custom_team_name_gui_set",
			caption = "Set",
			tooltip = "Set custom team name."
		})
	button.style.font = "heading-2"
	
	local button = t.add({
			type = "button",
			name = "custom_team_name_gui_close",
			caption = "Close",
			tooltip = "Close this window."
		})
	button.style.font = "heading-2"
end

local function team_manager_gui_click(event)
	local player = game.players[event.player_index]
	local name = event.element.name
	
	if game.forces[name] then
		if not player.admin then player.print("Only admins can change team names.", {r = 175, g = 0, b = 0}) return end
		custom_team_name_gui(player, name)
		player.gui.center["team_manager_gui"].destroy()
		return
	end
	
	if name == "team_manager_close" then
		player.gui.center["team_manager_gui"].destroy()	
		return
	end
	
	if name == "team_manager_activate_tournament" then
		if not player.admin then player.print("Only admins can switch tournament mode.", {r = 175, g = 0, b = 0}) return end
		if global.tournament_mode then
			global.tournament_mode = false
			draw_manager_gui(player)
			game.print(">>> Tournament Mode has been disabled.", {r = 111, g = 111, b = 111})
			return
		end
		global.tournament_mode = true
		draw_manager_gui(player)
		game.print(">>> Tournament Mode has been enabled!", {r = 225, g = 0, b = 0})
		return
	end
	
	if name == "team_manager_freeze_players" then
		if global.freeze_players then
			if not player.admin then player.print("Only admins can unfreeze players.", {r = 175, g = 0, b = 0}) return end
			global.freeze_players = false
			draw_manager_gui(player)
			game.print(">>> Players have been unfrozen!", {r = 255, g = 77, b = 77})
			unfreeze_players()
			return
		end
		if not player.admin then player.print("Only admins can freeze players.", {r = 175, g = 0, b = 0}) return end
		global.freeze_players = true
		draw_manager_gui(player)
		game.print(">>> Players have been frozen!", {r = 111, g = 111, b = 255})
		freeze_players()
		return
	end
	
	if name == "team_manager_turn_ghost" then
		if not player.admin then player.print("Only admins can become spooky spectator ghosts.", {r = 175, g = 0, b = 0}) return end
		toggle_ghost_spectate(player)
		return
	end
	
	if not event.element.parent then return end
	local element = event.element.parent
	if not element.parent then return end
	local element = element.parent
	if element.name ~= "team_manager_root_table" then return end		
	if not player.admin then player.print("Only admins can manage teams.", {r = 175, g = 0, b = 0}) return end
	
	local listbox = player.gui.center["team_manager_gui"]["team_manager_root_table"]["team_manager_list_box_" .. tonumber(name)]
	local selected_index = listbox.selected_index
	if selected_index == 0 then player.print("No player selected.", {r = 175, g = 0, b = 0}) return end
	local player_name = listbox.items[selected_index]
	
	local m = -1
	if event.element.caption == "→" then m = 1 end
	local force_name = forces[tonumber(name) + m].name
	
	switch_force(player_name, force_name)
	
	draw_manager_gui(player)
end

local function on_gui_click(event)	
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	
	if name == "team_manager_toggle_button" then
		if player.gui.center["team_manager_gui"] then player.gui.center["team_manager_gui"].destroy() return end
		draw_manager_gui(player)
		return
	end
	
	if player.gui.center["team_manager_gui"] then team_manager_gui_click(event) end
	
	if player.gui.center["custom_team_name_gui"] then
		if name == "custom_team_name_gui_set" then
			local custom_name = player.gui.center["custom_team_name_gui"].children[1].text
			local force_name = player.gui.center["custom_team_name_gui"].children[1].name
			set_custom_team_name(force_name, custom_name)
			player.gui.center["custom_team_name_gui"].destroy()
			draw_manager_gui(player)
			return
		end
		if name == "custom_team_name_gui_close" then
			player.gui.center["custom_team_name_gui"].destroy()
			draw_manager_gui(player)
			return
		end
	end	
end

local function on_player_joined_game(event)
	draw_manager_button(game.players[event.player_index])
end

local function on_init(surface)
	global.tm_custom_name = {}
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)