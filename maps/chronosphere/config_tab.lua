-- config tab for chronotrain--

local Chrono_table = require 'maps.chronosphere.table'
local Chrono = require 'maps.chronosphere.chrono'

local functions = {
	["comfy_panel_offline_accidents"] = function(event)
	local objective = Chrono_table.get_table()
    if game.players[event.player_index].admin then
		if event.element.switch_state == "left" then
			objective.config.offline_loot = true
		else
			objective.config.offline_loot = false
		end
    else
      game.players[event.player_index].print("You are not an admin!")
    end
	end,

	["comfy_panel_danger_events"] = function(event)
	local objective = Chrono_table.get_table()
    if game.players[event.player_index].admin then
      if event.element.switch_state == "left" then
				objective.config.jumpfailure = true
			else
				objective.config.jumpfailure = false
			end
    else
      game.players[event.player_index].print("You are not an admin!")
    end
	end,

	["comfy_panel_game_lost"] = function(event)
	local objective = Chrono_table.get_table()
    if game.players[event.player_index].admin then
			local frame = event.element.parent.parent
      if event.element.switch_state == "left" then
				if not objective.game_lost then
					game.auto_save("chronotrain_before_manual_reset" .. math.random(1,1000))
				end
				frame["comfy_panel_game_lost_confirm_table"].visible = true
			else
				frame["comfy_panel_game_lost_confirm_table"].visible = false
			end
    else
      game.players[event.player_index].print("You are not an admin!")
    end
	end,
	["comfy_panel_game_lost_confirm"] = function(event)
	local objective = Chrono_table.get_table()
    if game.players[event.player_index].admin then
      if event.element.switch_state == "left" then
				Chrono.objective_died()
			end
    else
      game.players[event.player_index].print("You are not an admin!")
    end
	end,
}

local function add_switch(element, switch_state, name, description_main, description)
	local t = element.add({type = "table", column_count = 5, name = name .. "_table"})
	local label
	label = t.add({type = "label", caption = "ON"})
	label.style.padding = 0
	label.style.left_padding= 10
	label.style.font_color = {0.77, 0.77, 0.77}
	local switch = t.add({type = "switch", name = name})
	switch.switch_state = switch_state
	switch.style.padding = 0
	switch.style.margin = 0
	label = t.add({type = "label", caption = "OFF"})
	label.style.padding = 0
	label.style.font_color = {0.70, 0.70, 0.70}

	label = t.add({type = "label", caption = description_main})
	label.style.padding = 2
	label.style.left_padding= 10
	label.style.minimal_width = 130
	label.style.font = "heading-2"
	label.style.font_color = {0.88, 0.88, 0.99}

	label = t.add({type = "label", caption = description})
	label.style.padding = 2
	label.style.left_padding= 10
	label.style.single_line = false
	label.style.font = "heading-3"
	label.style.font_color = {0.85, 0.85, 0.85}
end

local build_config_gui = (function (_, frame)
	local objective = Chrono_table.get_table()
	local switch_state
	frame.clear()

	local line_elements = {}

	line_elements[#line_elements + 1] = frame.add({type = "line"})

	switch_state = "right"
	if objective.config.offline_loot then switch_state = "left" end
	add_switch(frame, switch_state, "comfy_panel_offline_accidents", "Offline Accidents", "Disables or enables dropping of inventory when player goes offline.\nTimer is 15 minutes.")

	line_elements[#line_elements + 1] = frame.add({type = "line"})

	switch_state = "right"
	if objective.config.jumpfailure then switch_state = "left" end
	add_switch(frame, switch_state, "comfy_panel_danger_events", "Dangerous Events", "Disables or enables dangerous event maps\n(they require at least 2-4 capable players to survive)")

	line_elements[#line_elements + 1] = frame.add({type = "line"})

	switch_state = "right"
	if objective.game_lost then switch_state = "left" end
	add_switch(frame, switch_state, "comfy_panel_game_lost", "Reset Run", "Marks game as lost and starts countdown for map reset (Use with caution!)")

	switch_state = "right"
	if objective.game_lost then switch_state = "left" end
	add_switch(frame, switch_state, "comfy_panel_game_lost_confirm", "Confirm Reset Run", "But really you want to reset?\n(Previous button triggered autosave)")
	frame["comfy_panel_game_lost_confirm_table"].visible = false

	line_elements[#line_elements + 1] = frame.add({type = "line"})




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
