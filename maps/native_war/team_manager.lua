local Public = {}

local wait_messages = {
	"please get comfy.",
	"get comfy!!",
	"go and grab a drink.",
	"take a short healthy break.",
	"go and stretch your legs.",
	"please pet the cat.",
	"time to get a bowl of snacks :3",
	"send love to Mewmew",
}
local forces = {
	{name = "west",	color = {r = 1, g = 1, b = 255}},
	{name = "spectator", color = {r = 111, g = 111, b = 111}},
	{name = "east", color = {r = 255, g = 1, b = 1}},
}
local gui_values = {
		["west"] = {force = "west", c1 = "west", c2 = "JOIN ", n1 = "join_west_button",
		color1 = {r = 1, g = 1, b = 255}, color2 = {r = 0.66, g = 0.66, b = 0.99}}, --tech_spy = "spy-north-tech", prod_spy = "spy-north-prod"
		["east"] = {force = "east", c1 = "east", c2 = "JOIN ", n1 = "join_east_button",
		color1 = {r = 255, g = 1, b = 1}, color2 = {r = 0.99, g = 0.44, b = 0.44}} --tech_spy = "spy-north-tech", prod_spy = "spy-north-prod"
}

starting_items = {['iron-plate'] = 32, ['iron-gear-wheel'] = 16, ['stone'] = 25}


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

local function create_first_join_gui(player)
	if not global.game_lobby_timeout then global.game_lobby_timeout = 10 end --[[5999940]]
	if global.game_lobby_timeout - game.tick < 0 then global.game_lobby_active = false end
	local frame = player.gui.left.add { type = "frame", name = "nv_main_gui", direction = "vertical" }
	local b = frame.add{ type = "label", caption = "Defend your Market!" }
	b.style.font = "heading-1"
	b.style.font_color = {r=0.98, g=0.66, b=0.22}
	local b = frame.add  { type = "label", caption = "Feed the market with science to send native waves!" }
	b.style.font = "heading-2"
	b.style.font_color = {r=0.98, g=0.66, b=0.22}
	frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	for _, gui_value in pairs(gui_values) do
		local t = frame.add { type = "table", column_count = 3 }
		local c = gui_value.c1
		--if global.tm_custom_name[gui_value.force] then c = global.tm_custom_name[gui_value.force] end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "heading-2"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		l.style.maximal_width = 290
		local l = t.add  { type = "label", caption = "  -  "}
		local c = #game.forces[gui_value.force].connected_players .. " Player"
		if #game.forces[gui_value.force].connected_players >= 1 then c = c .. "s" end
		local l = t.add  { type = "label", caption = c}
		l.style.font_color = { r=0.22, g=0.88, b=0.22}
		local c = gui_value.c2
		local font_color =  gui_value.color1
		if global.game_lobby_active then
			font_color = {r=0.7, g=0.7, b=0.7}
			c = c .. " (waiting for players...  "
			c = c .. math.ceil((global.game_lobby_timeout - game.tick)/60)
			c = c .. ")"
		end
		local t = frame.add  { type = "table", column_count = 4 }
		for _, p in pairs(game.forces[gui_value.force].connected_players) do
			local l = t.add({type = "label", caption = p.name})
			l.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
			l.style.font = "heading-2"
		end
		local b = frame.add  { type = "sprite-button", name = gui_value.n1, caption = c }
		b.style.font = "default-large-bold"
		b.style.font_color = font_color
		b.style.minimal_width = 350
		frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	end
end

local function create_main_gui(player)
	local is_spec = player.force.name == "spectator"
	if player.gui.left["nv_main_gui"] then player.gui.left["nv_main_gui"].destroy() end
		--if global.bb_game_won_by_team then return end
	if not global.chosen_team[player.name] then
		if not global.tournament_mode then
			create_first_join_gui(player)
			return
		end
	end
	local frame = player.gui.left.add { type = "frame", name = "nv_main_gui", direction = "vertical" }
		-- Science sending GUI
	local first_team = true
	for _, gui_value in pairs(gui_values) do
		-- Line separator
		if not first_team then
			frame.add { type = "line", caption = "this line", direction = "horizontal" }
		else
			first_team = false
		end
			-- Team name & Player count
		local t = frame.add { type = "table", column_count = 3 }
			-- Team name
		local c = gui_value.c1
		--if global.tm_custom_name[gui_value.force] then c = global.tm_custom_name[gui_value.force] end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default-bold"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		--l.style.minimal_width = 100
		l.style.maximal_width = 102
			-- Number of players
		local l = t.add  { type = "label", caption = " - "}
		local c = #game.forces[gui_value.force].connected_players .. " Player"
		if #game.forces[gui_value.force].connected_players >= 1 then c = c .. "s" end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default"
		l.style.font_color = { r=0.22, g=0.88, b=0.22}
			-- Player list
		local t = frame.add  { type = "table", column_count = 4 }
		for _, p in pairs(game.forces[gui_value.force].connected_players) do
			local l = t.add  { type = "label", caption = p.name }
			l.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
		end

		-- Statistics
		--local t = frame.add { type = "table", name = "stats_" .. gui_value.force, column_count = 6 }
		-- Tech button
	--	if is_spec then
		--	add_tech_button(t, gui_value)
			-- add_prod_button(t, gui_value)
		--end
	end
		-- Action frame
	local t = frame.add  { type = "table", column_count = 2 }
		-- Spectate / Rejoin team
	if is_spec then
		local b = t.add  { type = "sprite-button", name = "nv_leave_spectate", caption = "Join Team" }
	else
		local b = t.add  { type = "sprite-button", name = "nv_spectate", caption = "Spectate" }
	end
		-- Playerlist button
		local b_width = is_spec and 97 or 86
	-- 111 when prod_spy button will be there
	for _, b in pairs(t.children) do
		b.style.font = "default-bold"
		b.style.font_color = { r=0.98, g=0.66, b=0.22}
		b.style.top_padding = 1
		b.style.left_padding = 1
		b.style.right_padding = 1
		b.style.bottom_padding = 1
		b.style.maximal_height = 30
		b.style.width = b_width
	end
end

function Public.refresh()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["nv_main_gui"] then
			create_main_gui(player)
		end
	end
end

function join_team(player, force_name, forced_join)
	if not player.character then return end
	if not forced_join then
		if global.tournament_mode then player.print("The game is set to tournament mode. Teams can only be changed via team manager.", {r = 0.98, g = 0.66, b = 0.22}) return end
	end
	if not force_name then return end
	local surface = player.surface

	local enemy_team = "west"
	if force_name == "west" then enemy_team = "east" end

	if not global.training_mode and global.nv_settings.team_balancing then
		if not forced_join then
			if #game.forces[force_name].connected_players > #game.forces[enemy_team].connected_players then
				if not global.chosen_team[player.name] then
					player.print("Team " .. force_name .. " has too many players currently.", {r = 0.98, g = 0.66, b = 0.22})
					return
				end
			end
		end
	end

	if global.chosen_team[player.name] then
		if not forced_join then
			if game.tick - global.spectator_rejoin_delay[player.name] < 7200 then
				player.print(
					"Not ready to return to your team yet. Please wait " .. 120-(math.floor((game.tick - global.spectator_rejoin_delay[player.name])/60)) .. " seconds.",
					{r = 0.98, g = 0.66, b = 0.22}
				)
				return
			end
		end
		local p = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 8, 1)
		player.teleport(p, surface)
		player.force = game.forces[force_name]
		player.character.destructible = true
		Public.refresh()
		game.permissions.get_group("Default").add_player(player)
		local msg = table.concat({"Team ", player.force.name, " player ", player.name, " is no longer spectating."})
		game.print(msg, {r = 0.98, g = 0.66, b = 0.22})
		--Server.to_discord_bold(msg)
		player.spectator = false
		return
	end
	local pos = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 8, 1)
	if not pos then pos = game.forces[force_name].get_spawn_position(surface) end
	player.teleport(pos)
	player.force = game.forces[force_name]
	player.character.destructible = true
	game.permissions.get_group("Default").add_player(player)
	if not forced_join then
		local c = player.force.name
		--if global.tm_custom_name[player.force.name] then c = global.tm_custom_name[player.force.name] end
		local message = table.concat({player.name, " has joined team ", c, "!"})
		game.print(message, {r = 0.98, g = 0.66, b = 0.22})
		--Server.to_discord_bold(message)
	end
	local i = player.get_inventory(defines.inventory.character_main)
	i.clear()
	for item, amount in pairs(starting_items) do
		player.insert({name = item, count = amount})
	end
	global.chosen_team[player.name] = force_name
	player.spectator = false
	Public.refresh()
end

function spectate(player, forced_join)
	if not player.character then return end
	if not forced_join then
		if global.tournament_mode then player.print("The game is set to tournament mode. Teams can only be changed via team manager.", {r = 0.98, g = 0.66, b = 0.22}) return end
	end
	player.teleport(player.surface.find_non_colliding_position("character", {0,-190}, 4, 1))
	player.force = game.forces.spectator
	player.character.destructible = false
	if not forced_join then
		local msg = player.name .. " is spectating."
		game.print(msg, {r = 0.98, g = 0.66, b = 0.22})
		--Server.to_discord_bold(msg)
	end
	game.permissions.get_group("spectator").add_player(player)
	global.spectator_rejoin_delay[player.name] = game.tick
	create_main_gui(player)
	player.spectator = true
end

function Public.draw_top_toggle_button(player)
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
			local list_box = t.add({type = "list-box", name = "team_manager_list_box_" .. i2, items = get_player_array(forces[i2].name)})
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
			caption = "Tournament Mode Enabled",
			tooltip = "Only admins can move players and vote for difficulty.\nActive players can no longer go spectate.\nNew joining players are spectators."
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

	if global.training_mode then
		button = t.add({
			type = "button",
			name = "team_manager_activate_training",
			caption = "Training Mode Activated",
			tooltip = "Feed your own team's biters and only teams with players gain threat & evo."
		})
		button.style.font_color = {r = 222, g = 22, b = 22}
	else
		button = t.add({
			type = "button",
			name = "team_manager_activate_training",
			caption = "Training Mode Disabled",
			tooltip = "Feed your own team's biters and only teams with players gain threat & evo."
		})
		button.style.font_color = {r = 55, g = 55, b = 55}
	end
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

	if name == "team_manager_activate_training" then
		if not player.admin then player.print("Only admins can switch training mode.", {r = 175, g = 0, b = 0}) return end
		if global.training_mode then
			global.training_mode = false
			global.game_lobby_active = true
			draw_manager_gui(player)
			game.print(">>> Training Mode has been disabled.", {r = 111, g = 111, b = 111})
			return
		end
		global.training_mode = true
		global.game_lobby_active = false
		draw_manager_gui(player)
		game.print(">>> Training Mode has been enabled!", {r = 225, g = 0, b = 0})
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

local function create_sprite_button(player)
	if player.gui.top["nv_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "nv_toggle_button", sprite = "item/splitter"})
	button.style.font = "default-bold"
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2
end

local function join_gui_click(name, player)
	local team = {
		["join_west_button"] = "west",
		["join_east_button"] = "east"
	}

	if not team[name] then return end

	if global.game_lobby_active then
		if player.admin then
			join_team(player, team[name])
			game.print("Lobby disabled, admin override.", { r=0.98, g=0.66, b=0.22})
			global.game_lobby_active = false
			return
		end
		player.print("Waiting for more players, " .. wait_messages[math_random(1, #wait_messages)], { r=0.98, g=0.66, b=0.22})
		return
	end
	join_team(player, team[name])
end

function Public.gui_click(event)
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

	--[[if player.gui.center["custom_team_name_gui"] then
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
	end]]
end

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	if name == "nv_toggle_button" then
		if player.gui.left["nv_main_gui"] then
			player.gui.left["nv_main_gui"].destroy()
		else
			create_main_gui(player)
		end
		return
	end
	if name == "join_west_button" then join_gui_click(name, player) return end
	if name == "join_east_button" then join_gui_click(name, player) return end
	if name == "nv_leave_spectate" then join_team(player, global.chosen_team[player.name])	end
	if name == "nv_spectate" then	spectate(player) return	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	--if not global.bb_view_players then global.bb_view_players = {} end
	if not global.chosen_team then global.chosen_team = {} end

	--global.bb_view_players[player.name] = false

	if #game.connected_players > 1 then
		global.game_lobby_timeout = math.ceil(1 / #game.connected_players) --EVL
		--global.game_lobby_timeout = math.ceil(36000 / #game.connected_players)
	else
		global.game_lobby_timeout = 1 --EVL
		--global.game_lobby_timeout = 599940
	end

	if not global.chosen_team[player.name] then
		if global.tournament_mode then
			player.force = game.forces.spectator
		else
			player.force = game.forces.player
		end
	end
	create_sprite_button(player)

	create_main_gui(player)
end

function Public.init()
	global.tm_custom_name = {}
end

local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
return Public
