local WD = require "modules.wave_defense.table"

local function create_gui(player)
	local frame = player.gui.top.add({ type = "frame", name = "wave_defense"})
	frame.style.maximal_height = 38

	local label = frame.add({ type = "label", caption = " ", name = "label"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local label = frame.add({ type = "label", caption = " ", name = "wave_number"})
	label.style.font_color = {r=0.88, g=0.88, b=0.88}
	label.style.font = "default-bold"
	label.style.right_padding = 4
	label.style.font_color = {r=0.33, g=0.66, b=0.9}

	local progressbar = frame.add({ type = "progressbar", name = "progressbar", value = 0})
	progressbar.style.minimal_width = 96
	progressbar.style.maximal_width = 96
	progressbar.style.top_padding = 10

	local line = frame.add({type = "line", direction = "vertical"})
	line.style.left_padding = 4
	line.style.right_padding = 4

	local label = frame.add({ type = "label", caption = " ", name = "threat", tooltip = {"wave_defense.tooltip_1"}})
	label.style.font = "default-bold"
	label.style.left_padding = 4
	label.style.font_color = {r = 150, g = 0, b = 255}

	local label = frame.add({ type = "label", caption = " ", name = "threat_value", tooltip = {"wave_defense.tooltip_1"}})
	label.style.font = "default-bold"
	label.style.right_padding = 1
	label.style.minimal_width = 10
	label.style.font_color = {r = 150, g = 0, b = 255}

	local label = frame.add({ type = "label", caption = " ", name = "threat_gains", tooltip = {"wave_defense.tooltip_2"}})
	label.style.font = "default"
	label.style.left_padding = 1
	label.style.right_padding = 1
end

--display threat gain/loss per minute during last 15 minutes
local function get_threat_gain()
	local wave_defense_table = WD.get_table()
	local past_index = wave_defense_table.threat_log_index - 900
	if past_index < 1 then past_index = 1 end
	local gain = math.floor((wave_defense_table.threat_log[wave_defense_table.threat_log_index] - wave_defense_table.threat_log[past_index]) / 15)
	return gain
end

local function update_gui(player)
	local wave_defense_table = WD.get_table()
	if not player.gui.top.wave_defense then create_gui(player) end
	local gui = player.gui.top.wave_defense
	local biter_health_boost = 1
	if global.biter_health_boost then biter_health_boost = global.biter_health_boost end

	gui.label.caption = {"wave_defense.gui_2"}
	gui.wave_number.caption = wave_defense_table.wave_number
	if wave_defense_table.wave_number == 0 then
		gui.label.caption = {"wave_defense.gui_1"}
		gui.wave_number.caption = math.floor((wave_defense_table.next_wave - game.tick) / 60) + 1
	end
	local interval = wave_defense_table.next_wave - wave_defense_table.last_wave
	gui.progressbar.value = 1 - (wave_defense_table.next_wave - game.tick) / interval

	gui.threat.caption = {"wave_defense.gui_3"}
	gui.threat.tooltip = {"wave_defense.tooltip_1", biter_health_boost * 100}
	gui.threat_value.caption = math.floor(wave_defense_table.threat)
	gui.threat_value.tooltip = {"wave_defense.tooltip_1", biter_health_boost * 100}	

	if wave_defense_table.wave_number == 0 then
		gui.threat_gains.caption = ""
		return
	end

	local gain = get_threat_gain()
	local d = wave_defense_table.wave_number / 75

	if gain >= 0 then
		gui.threat_gains.caption = " (+" .. gain .. ")"
		local g = 255 - math.floor(gain / d)
		if g < 0 then g = 0 end
		gui.threat_gains.style.font_color = {255, g, 0}
	else
		gui.threat_gains.caption = " (" .. gain .. ")"
		local r = 255 - math.floor(math.abs(gain) / d)
		if r < 0 then r = 0 end
		gui.threat_gains.style.font_color = {r, 255, 0}
	end
end

return update_gui
