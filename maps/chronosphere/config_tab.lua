-- config tab for chronotrain--

local Tabs = require 'comfy_panel.main'

local functions = {
 	["comfy_panel_offline_accidents"] = function(event)
    if game.players[event.player_index].admin then
  		if event.element.switch_state == "left" then
  			global.objective.config.offline_loot = true
  		else
  			global.objective.config.offline_loot = false
  		end
    else
      game.players[event.player_index].print("You are not admin!")
    end
	end,

	["comfy_panel_danger_events"] = function(event)
    if game.players[event.player_index].admin then
      if event.element.switch_state == "left" then
  			global.objective.config.jumpfailure = true
  		else
  			global.objective.config.jumpfailure = false
  		end
    else
      game.players[event.player_index].print("You are not admin!")
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
end

local build_config_gui = (function (player, frame)
	frame.clear()

	local line_elements = {}
	local switch_label_elements = {}
	local label_elements = {}

	line_elements[#line_elements + 1] = frame.add({type = "line"})

	local switch_state = "right"
	if global.objective.config.offline_loot then switch_state = "left" end
	add_switch(frame, switch_state, "comfy_panel_offline_accidents", "Offline Accidents", "Disablesr enables dropping of inventory when player goes offline.\nTimer is 15 minutes.")

	line_elements[#line_elements + 1] = frame.add({type = "line"})

	if global.auto_hotbar_enabled then
		local switch_state = "right"
		if global.objective.config.jumpfailure then switch_state = "left" end
		add_switch(frame, switch_state, "comfy_panel_danger_events", "Dangerous Events", "Disables or enables dangerous event maps\n(they require at least 2-4 capable players to survive)")
		line_elements[#line_elements + 1] = frame.add({type = "line"})
	end

end)

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	if functions[event.element.name] then
		functions[event.element.name](event)
		return
	end
end

comfy_panel_tabs["ChronoTrain"] = {gui = build_config_gui, admin = true}


local event = require 'utils.event'
event.add(defines.events.on_gui_click, on_gui_click)
