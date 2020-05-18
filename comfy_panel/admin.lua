--antigrief things made by mewmew

local event = require 'utils.event'
local Tabs = require 'comfy_panel.main'

local function admin_only_message(str)
	for _, player in pairs(game.connected_players) do
		if player.admin == true then
			player.print("Admins-only-message: " .. str, {r=0.88, g=0.88, b=0.88})
		end
	end
end

local jail_messages = {
	"You´re done bud!",
	"Busted!"
}
local function jail(player, source_player)
	local permission_group = game.permissions.get_group("prisoner")		
	if not permission_group then
		permission_group = game.permissions.create_group("prisoner")
		for action_name, _ in pairs(defines.input_action) do
			permission_group.set_allows_action(defines.input_action[action_name], false)
		end
		permission_group.set_allows_action(defines.input_action.write_to_console, true)
		permission_group.set_allows_action(defines.input_action.gui_click, true)
		permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)		
	end
	permission_group.add_player(player.name)
	game.print(player.name .. " has been jailed. " .. jail_messages[math.random(1, #jail_messages)], { r=0.98, g=0.66, b=0.22})
	admin_only_message(player.name .. " was jailed by " .. source_player.name)
end

local freedom_messages = {
	"Yaay!",
	"Welcome back!"
}
local function free(player, source_player)
	local permission_group = game.permissions.get_group("Default")
	permission_group.add_player(player.name)
	game.print(player.name .. " was set free from jail. " .. freedom_messages[math.random(1, #freedom_messages)], { r=0.98, g=0.66, b=0.22})
	admin_only_message(source_player.name .. " set " .. player.name .. " free from jail")
end

local bring_player_messages = {
	"Come here my friend!",
	"Papers, please.",
	"What are you up to?"
}
local function bring_player(player, source_player)
	if player.driving == true then
		source_player.print("Target player is in a vehicle, teleport not available.", { r=0.88, g=0.88, b=0.88})
		return
	end
	local pos = source_player.surface.find_non_colliding_position("character", source_player.position, 50, 1)
	if pos then
		player.teleport(pos, source_player.surface)
		game.print(player.name .. " has been teleported to " .. source_player.name .. ". " .. bring_player_messages[math.random(1, #bring_player_messages)], { r=0.98, g=0.66, b=0.22})
	end
end

local go_to_player_messages = {
	"Papers, please.",
	"What are you up to?"
}
local function go_to_player(player, source_player)
	local pos = player.surface.find_non_colliding_position("character", player.position, 50, 1)
	if pos then
		source_player.teleport(pos, player.surface)
		game.print(source_player.name .. " is visiting " .. player.name .. ". " .. go_to_player_messages[math.random(1, #go_to_player_messages)], { r=0.98, g=0.66, b=0.22})
	end
end

local function spank(player, source_player)
	if player.character then
		if player.character.health > 1 then player.character.damage(1, "player") end
		player.character.health = player.character.health - 5
		player.surface.create_entity({name = "water-splash", position = player.position})
		game.print(source_player.name .. " spanked " .. player.name, { r=0.98, g=0.66, b=0.22})
	end
end

local damage_messages = {
	" recieved a love letter from ",
	" recieved a strange package from "
}
local function damage(player, source_player)
	if player.character then
		if player.character.health > 1 then player.character.damage(1, "player") end
		player.character.health = player.character.health - 125
		player.surface.create_entity({name = "big-explosion", position = player.position})
		game.print(player.name .. damage_messages[math.random(1, #damage_messages)] .. source_player.name, { r=0.98, g=0.66, b=0.22})		
	end
end

local kill_messages = {
	" did not obey the law.",
	" should not have triggered the admins.",
	" did not respect authority.",
	" had a strange accident.",
	" was struck by lightning."
}
local function kill(player, source_player)
	if player.character then
		player.character.die("player")
		game.print(player.name .. kill_messages[math.random(1, #kill_messages)], { r=0.98, g=0.66, b=0.22})
		admin_only_message(source_player.name .. " killed " .. player.name)
	end
end

local enemy_messages = {
	"Shoot on sight!",
	"Wanted dead or alive!"
}
local function enemy(player, source_player)
	if not game.forces.enemy_players then game.create_force("enemy_players") end
	player.force = game.forces.enemy_players
	game.print(player.name .. " is now an enemy! " .. enemy_messages[math.random(1, #enemy_messages)], {r=0.95, g=0.15, b=0.15})
	admin_only_message(source_player.name .. " has turned " .. player.name .. " into an enemy")	
end

local function ally(player, source_player)
	player.force = game.forces.player
	game.print(player.name .. " is our ally again!", {r=0.98, g=0.66, b=0.22})
	admin_only_message(source_player.name .. " made " .. player.name .. " our ally")	
end

local function turn_off_global_speakers(player)
	local counter = 0
	for _, surface in pairs(game.surfaces) do
		local speakers = surface.find_entities_filtered({name = "programmable-speaker"})
		for i, speaker in pairs(speakers) do
			if speaker.parameters.playback_globally == true then
				speaker.surface.create_entity({name = "massive-explosion", position = speaker.position})
				speaker.die("player")
				counter = counter + 1
			end
		end
	end	
	if counter == 0 then return end
	if counter == 1 then
		game.print(player.name .. " has nuked " .. counter .. " global speaker.", { r=0.98, g=0.66, b=0.22})
	else
		game.print(player.name .. " has nuked " .. counter .. " global speakers.", { r=0.98, g=0.66, b=0.22})
	end
end

local function delete_all_blueprints(player)
	local counter = 0
	for _, surface in pairs(game.surfaces) do
		for _, ghost in pairs(surface.find_entities_filtered({type = {"entity-ghost", "tile-ghost"}})) do
			ghost.destroy()
			counter = counter + 1
		end
	end
	if counter == 0 then return end
	if counter == 1 then
		game.print(counter .. " blueprint has been cleared!", { r=0.98, g=0.66, b=0.22})		
	else
		game.print(counter .. " blueprints have been cleared!", { r=0.98, g=0.66, b=0.22})		
	end
	admin_only_message(player.name .. " has cleared all blueprints.")
end

local function create_mini_camera_gui(player, caption, position)
	if player.gui.center["mini_camera"] then player.gui.center["mini_camera"].destroy() end
	local frame = player.gui.center.add({type = "frame", name = "mini_camera", caption = caption})
	local camera = frame.add({type = "camera", name = "mini_cam_element", position = position, zoom = 0.6, surface_index = player.surface.index})
	camera.style.minimal_width = 640
	camera.style.minimal_height = 480
end

local create_admin_panel = (function (player, frame)
	frame.clear()
	
	local player_names = {}	
	for _, p in pairs(game.connected_players) do		
		table.insert(player_names, tostring(p.name))		
	end	
	table.insert(player_names, "Select Player")
		
	local selected_index = #player_names
	if global.admin_panel_selected_player_index then
		if global.admin_panel_selected_player_index[player.name] then
			if player_names[global.admin_panel_selected_player_index[player.name]] then
				selected_index = global.admin_panel_selected_player_index[player.name]
			end
		end
	end
	
	local drop_down = frame.add({type = "drop-down", name = "admin_player_select", items = player_names, selected_index = selected_index})
	drop_down.style.minimal_width = 326
	drop_down.style.right_padding = 12
	drop_down.style.left_padding = 12
			
	local t = frame.add({type = "table", column_count = 3})
	local buttons = {
		t.add({type = "button", caption = "Jail", name = "jail", tooltip = "Jails the player, they will no longer be able to perform any actions except writing in chat."}),
		t.add({type = "button", caption = "Free", name = "free", tooltip = "Frees the player from jail."}),			
		t.add({type = "button", caption = "Bring Player", name = "bring_player", tooltip = "Teleports the selected player to your position."}),
		t.add({type = "button", caption = "Make Enemy", name = "enemy", tooltip = "Sets the selected players force to enemy_players.          DO NOT USE IN PVP MAPS!!"}),
		t.add({type = "button", caption = "Make Ally", name = "ally", tooltip = "Sets the selected players force back to the default player force.           DO NOT USE IN PVP MAPS!!"}),
		t.add({type = "button", caption = "Go to Player", name = "go_to_player", tooltip = "Teleport yourself to the selected player."}),		
		t.add({type = "button", caption = "Spank", name = "spank", tooltip = "Hurts the selected player with minor damage. Can not kill the player."}),
		t.add({type = "button", caption = "Damage", name = "damage", tooltip = "Damages the selected player with greater damage. Can not kill the player."}),
		t.add({type = "button", caption = "Kill", name = "kill", tooltip = "Kills the selected player instantly."})
		
	}
	for _, button in pairs(buttons) do
		button.style.font = "default-bold"
		--button.style.font_color = { r=0.99, g=0.11, b=0.11}
		button.style.font_color = { r=0.99, g=0.99, b=0.99}
		button.style.minimal_width = 106
	end
	
	local line = frame.add { type = "line"}
	line.style.top_margin = 8
	line.style.bottom_margin = 8
	
	local l = frame.add({type = "label", caption = "Global Actions:"})
	local t = frame.add({type = "table", column_count = 2})
	local buttons = {
		t.add({type = "button", caption = "Destroy global speakers", name = "turn_off_global_speakers", tooltip = "Destroys all speakers that are set to play sounds globally."}),
		t.add({type = "button", caption = "Delete blueprints", name = "delete_all_blueprints", tooltip = "Deletes all placed blueprints on the map."})
	---	t.add({type = "button", caption = "Cancel all deconstruction orders", name = "remove_all_deconstruction_orders"})
	}
	for _, button in pairs(buttons) do
		button.style.font = "default-bold"
		button.style.font_color = { r=0.98, g=0.66, b=0.22}
		button.style.minimal_width = 80
	end
	
	local line = frame.add { type = "line"}
	line.style.top_margin = 8
	line.style.bottom_margin = 8
	
	local histories = {}
	if global.bad_fire_history then table.insert(histories, "Bad Fire History") end
	if global.friendly_fire_history then table.insert(histories, "Friendly Fire History") end
	if global.mining_history then table.insert(histories, "Mining History") end
	if global.landfill_history then table.insert(histories, "Landfill History") end
	if global.artillery_history then table.insert(histories, "Artillery History") end
	
	if #histories == 0 then return end
	
	local l = frame.add({type = "label", caption = "----------------------------------------------"})
	
	local selected_index = 1
	if global.admin_panel_selected_history_index then
		if global.admin_panel_selected_history_index[player.name] then		
			selected_index = global.admin_panel_selected_history_index[player.name]			
		end
	end
		
	local drop_down = frame.add({type = "drop-down", name = "admin_history_select", items = histories, selected_index = selected_index})
	drop_down.style.right_padding = 12
	drop_down.style.left_padding = 12
	
	local history = frame["admin_history_select"].items[frame["admin_history_select"].selected_index]
	
	local history_index = {
		["Bad Fire History"] = global.bad_fire_history,
		["Friendly Fire History"] = global.friendly_fire_history,
		["Mining History"] = global.mining_history,
		["Landfill History"] = global.landfill_history,
		["Artillery History"] = global.artillery_history
	}
		
	local t = frame.add({type = "table", column_count = 1})
	l.style.font = "default-listbox"
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	local scroll_pane = t.add({ type = "scroll-pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	scroll_pane.style.maximal_height = 200
	for i = #history_index[history], 1, -1 do
		scroll_pane.add({type = "label", caption = history_index[history][i], tooltip = "Click to open mini camera."})
	end

end)

local admin_functions = {
		["jail"] = jail,
		["free"] = free,
		["bring_player"] = bring_player,
		["spank"] = spank,
		["damage"] = damage,
		["kill"] = kill,
		["enemy"] = enemy,
		["ally"] = ally,
		["go_to_player"] = go_to_player
	}

local admin_global_functions = {
		["turn_off_global_speakers"] = turn_off_global_speakers,
		["delete_all_blueprints"] = delete_all_blueprints,
	}

local function get_position_from_string(str)
	if not str then return end
	if str == "" then return end
	str = string.lower(str)
	local x_pos = string.find(str, "x:")
	local y_pos = string.find(str, "y:")
	if not x_pos then return false end
	if not y_pos then return false end
	x_pos = x_pos + 2
	y_pos = y_pos + 2
	
	local a = 1
	for i = 1, string.len(str), 1 do
		local s = string.sub(str, x_pos + i, x_pos + i)
		if not s then break end
		if string.byte(s) == 32 then break end
		a = a + 1			
	end	
	local x = string.sub(str, x_pos, x_pos + a)
	
	local a = 1
	for i = 1, string.len(str), 1 do
		local s = string.sub(str, y_pos + i, y_pos + i)
		if not s then break end
		if string.byte(s) == 32 then break end
		a = a + 1			
	end	
	
	local y = string.sub(str, y_pos, y_pos + a)	
	x = tonumber(x)
	y = tonumber(y)		
	local position = {x = x, y = y}
	return position
end	
	
local function on_gui_click(event)
	local player = game.players[event.player_index]
	local frame = Tabs.comfy_panel_get_active_frame(player)
	if not frame then return end
	if frame.name ~= "Admin" then return end
	
	local name = event.element.name

	if admin_functions[name] then
		local target_player_name = frame["admin_player_select"].items[frame["admin_player_select"].selected_index]
		if not target_player_name then return end
		if target_player_name == "Select Player" then
			player.print("No target player selected.", {r=0.88, g=0.88, b=0.88})
			return			
		end
		local target_player = game.players[target_player_name]
		if target_player.connected == true then
			admin_functions[name](target_player, player)
		end
		return
	end
	
	if admin_global_functions[name] then		
		admin_global_functions[name](player)		
		return
	end
	
	if name == "mini_camera" or name == "mini_cam_element" then
		player.gui.center["mini_camera"].destroy()
		return
	end		
	
	if not frame then return end
	if not event.element.caption then return end
	local position = get_position_from_string(event.element.caption)	
	if not position then return end
	
	if player.gui.center["mini_camera"] then
		if player.gui.center["mini_camera"].caption == event.element.caption then
			player.gui.center["mini_camera"].destroy()
			return
		end
	end
	
	create_mini_camera_gui(player, event.element.caption, position)	
end

local function on_gui_selection_state_changed(event)
	local player = game.players[event.player_index]	
	local name = event.element.name
	
	if name == "admin_history_select" then	
		if not global.admin_panel_selected_history_index then global.admin_panel_selected_history_index = {} end
		global.admin_panel_selected_history_index[player.name] = event.element.selected_index
		
		local frame = Tabs.comfy_panel_get_active_frame(player)
		if not frame then return end
		if frame.name ~= "Admin" then return end

		create_admin_panel(player, frame)
	end
end

comfy_panel_tabs["Admin"] = {gui = create_admin_panel, admin = true}



event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)