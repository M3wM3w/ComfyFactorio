-- config tab --

local Tabs = require 'comfy_panel.main'

local spaghett_entity_blacklist = {
	["logistic-chest-requester"] = true,
	["logistic-chest-buffer"] = true,
	["logistic-chest-active-provider"] = true,
}

local function spaghett_deny_building(event)
	local spaghett = global.comfy_panel_config.spaghett
	if not spaghett.enabled then return end
	local entity = event.created_entity
	if not entity.valid then return end
	if not spaghett_entity_blacklist[event.created_entity.name] then return end

	if event.player_index then
		game.players[event.player_index].insert({name = entity.name, count = 1})
	else
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})
	end

	event.created_entity.surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Spaghett Mode Active!",
		color = {r=0.98, g=0.66, b=0.22}
	})

	entity.destroy()
end

local function spaghett()
	local spaghett = global.comfy_panel_config.spaghett
	if spaghett.enabled then
		for _, f in pairs(game.forces) do
			if f.technologies["logistic-system"].researched then
				spaghett.undo[f.index] = true
			end
			f.technologies["logistic-system"].enabled = false
			f.technologies["logistic-system"].researched = false
		end
	else
		for _, f in pairs(game.forces) do
			f.technologies["logistic-system"].enabled = true
			if spaghett.undo[f.index] then
				f.technologies["logistic-system"].researched = true
				spaghett.undo[f.index] = nil
			end
		end
	end
end

local functions = {
 	["comfy_panel_spectator_switch"] = function(event)
		if event.element.switch_state == "left" then
			game.players[event.player_index].spectator = true
		else
			game.players[event.player_index].spectator = false
		end
	end,

	["comfy_panel_auto_hotbar_switch"] = function(event)
		if event.element.switch_state == "left" then
			global.auto_hotbar_enabled[event.player_index] = true
		else
			global.auto_hotbar_enabled[event.player_index] = false
		end
	end,
	["comfy_panel_blueprint_toggle"] = function(event)
		if event.element.switch_state == "left" then
			game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, true)
			game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, true)
			game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, true)
		else
			game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
			game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
			game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)
		end
	end,
	["comfy_panel_spaghett_toggle"] = function(event)
		if event.element.switch_state == "left" then
			global.comfy_panel_config.spaghett.enabled = true
		else
			global.comfy_panel_config.spaghett.enabled = nil
		end
		spaghett()
	end,
}

local poll_function = {
	["comfy_panel_poll_trusted_toggle"] = function(event)
		if event.element.switch_state == "left" then
			global.comfy_panel_config.poll_trusted = true
		else
			global.comfy_panel_config.poll_trusted = false
		end
	end,
	["comfy_panel_poll_no_notify_toggle"] = function(event)
		local poll = package.loaded['comfy_panel.poll']
		local poll_table = poll.get_no_notify_players()
		if event.element.switch_state == "left" then
			poll_table[event.player_index] = false
		else
			poll_table[event.player_index] = true
		end
	end,
}

local function add_switch(element, switch_state, name, description_main, description)
	local t = element.add({type = "table", column_count = 5})
	local label = t.add({type = "label", caption = "ON"})
	label.style.padding = 0
	label.style.left_padding= 10
	label.style.font_color = {0.77, 0.77, 0.77}
	local switch = t.add({type = "switch", name = name})
	switch.switch_state = switch_state
	switch.style.padding = 0
	switch.style.margin = 0
	local label = t.add({type = "label", caption = "OFF"})
	label.style.padding = 0
	label.style.font_color = {0.70, 0.70, 0.70}

	local label = t.add({type = "label", caption = description_main})
	label.style.padding = 2
	label.style.left_padding= 10
	label.style.minimal_width = 120
	label.style.font = "heading-2"
	label.style.font_color = {0.88, 0.88, 0.99}

	local label = t.add({type = "label", caption = description})
	label.style.padding = 2
	label.style.left_padding= 10
	label.style.single_line = false
	label.style.font = "heading-3"
	label.style.font_color = {0.85, 0.85, 0.85}

	return switch
end

local build_config_gui = (function (player, frame)
	frame.clear()

	local admin = player.admin

	local label = frame.add({type = "label", caption = "Player Settings"})
	label.style.font = "default-bold"
	label.style.padding = 0
	label.style.left_padding = 10
	label.style.horizontal_align = "left"
	label.style.vertical_align = "bottom"
	label.style.font_color = {0.55, 0.55, 0.99}

	frame.add({type = "line"})

	local switch_state = "right"
	if player.spectator then switch_state = "left" end
	add_switch(frame, switch_state, "comfy_panel_spectator_switch", "SpectatorMode", "Toggles zoom-to-world view noise effect.\nEnvironmental sounds will be based on map view.")

	frame.add({type = "line"})

	if global.auto_hotbar_enabled then
		local switch_state = "right"
		if global.auto_hotbar_enabled[player.index] then switch_state = "left" end
		add_switch(frame, switch_state, "comfy_panel_auto_hotbar_switch", "AutoHotbar", "Automatically fills your hotbar with placeable items.")
		frame.add({type = "line"})
	end

	if package.loaded['comfy_panel.poll'] then
		local poll = package.loaded['comfy_panel.poll']
		local poll_table = poll.get_no_notify_players()
		local switch_state = "right"
		if not poll_table[player.index] then switch_state = "left" end
		local switch = add_switch(frame, switch_state, "comfy_panel_poll_no_notify_toggle", "Notify on polls", "Receive a message when new polls are created and popup the poll.")
		frame.add({type = "line"})
	end

	local label = frame.add({type = "label", caption = "Admin Settings"})
	label.style.font = "default-bold"
	label.style.padding = 0
	label.style.left_padding = 10
	label.style.top_padding = 10
	label.style.horizontal_align = "left"
	label.style.vertical_align = "bottom"
	label.style.font_color = {0.77, 0.11, 0.11}

	frame.add({type = "line"})

	local switch_state = "right"
	if game.permissions.get_group("Default").allows_action(defines.input_action.import_blueprint) then switch_state = "left" end
	local switch = add_switch(frame, switch_state, "comfy_panel_blueprint_toggle", "Blueprint Library", "Toggles the usage of blueprint strings and the library.")
	if not admin then switch.ignored_by_interaction = true end

	frame.add({type = "line"})

	local switch_state = "right"
	if global.comfy_panel_config.spaghett.enabled then switch_state = "left" end
	local switch = add_switch(frame, switch_state, "comfy_panel_spaghett_toggle", "Spaghett Mode", "Disables the Logistic System research.\nRequester, buffer or active-provider containers can not be built.")
	if not admin then switch.ignored_by_interaction = true end

	if package.loaded['comfy_panel.poll'] then
		frame.add({type = "line"})
		local switch_state = "right"
		if global.comfy_panel_config.poll_trusted then switch_state = "left" end
		local switch = add_switch(frame, switch_state, "comfy_panel_poll_trusted_toggle", "Poll mode", "Disables non-trusted plebs to create polls.")
		if not admin then switch.ignored_by_interaction = true end
	end

	frame.add({type = "line"})

	for _, e in pairs(frame.children) do
		if e.type == "line" then
			e.style.padding = 0
			e.style.margin = 0
		end
	end
end)

local function on_gui_switch_state_changed(event)
	if not event.element then return end
	if not event.element.valid then return end
	if functions[event.element.name] then
		functions[event.element.name](event)
		return
	elseif package.loaded['comfy_panel.poll'] then
		if poll_function[event.element.name] then
			poll_function[event.element.name](event)
			return
		end
	end
end

local function on_force_created(event)
	spaghett()
end

local function on_built_entity(event)
	spaghett_deny_building(event)
end

local function on_robot_built_entity(event)
	spaghett_deny_building(event)
end

local function on_init()
	global.comfy_panel_config = {}
	global.comfy_panel_config.spaghett = {}
	global.comfy_panel_config.spaghett.undo = {}
	global.comfy_panel_config.poll_trusted = false
end

comfy_panel_tabs["Config"] = {gui = build_config_gui, admin = false}


local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)
Event.add(defines.events.on_force_created, on_force_created)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
