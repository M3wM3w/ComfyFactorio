-- config tab -- 

local Tabs = require 'comfy_panel.main'

local functions = {
	["map_settings_team_balancing_toggle"] = function(event) 
		if event.element.switch_state == "left" then
			global.bb_settings.team_balancing = true
			game.print("Team balancing has been enabled!")
		else
			global.bb_settings.team_balancing = false
			game.print("Team balancing has been disabled!")
		end
	end,
	
	["map_settings_only_admins_vote"] = function(event) 
		if event.element.switch_state == "left" then
			global.bb_settings.only_admins_vote = true
			global.difficulty_player_votes = {}
			game.print("Admin-only difficulty voting has been enabled!")
		else
			global.bb_settings.only_admins_vote = false
			game.print("Admin-only difficulty voting has been disabled!")
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
	local line_elements = {}
	local switch_label_elements = {}
	local label_elements = {}
	
	line_elements[#line_elements + 1] = frame.add({type = "line"})
		
	local switch_state = "right"
	if global.bb_settings.team_balancing then switch_state = "left" end
	local switch = add_switch(frame, switch_state, "map_settings_team_balancing_toggle", "Team Balancing", "Players can only join a team that has less or equal players than the opposing.")
	if not admin then switch.ignored_by_interaction = true end
	
	line_elements[#line_elements + 1] = frame.add({type = "line"})
		
	local switch_state = "right"
	if global.bb_settings.only_admins_vote then switch_state = "left" end
	local switch = add_switch(frame, switch_state, "map_settings_only_admins_vote", "Admin Vote", "Only admins can vote for map difficulty. Clears all currently existing votes.")
	if not admin then switch.ignored_by_interaction = true end
	
	line_elements[#line_elements + 1] = frame.add({type = "line"})
	
end)

local function on_gui_switch_state_changed(event)
	if not event.element then return end
	if not event.element.valid then return end
	if functions[event.element.name] then
		functions[event.element.name](event)
		return
	end
end

comfy_panel_tabs["MapSettings"] = {gui = build_config_gui, admin = true}


local event = require 'utils.event'
event.add(defines.events.on_gui_switch_state_changed, on_gui_switch_state_changed)