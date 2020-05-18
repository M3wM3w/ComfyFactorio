local Public = {}

local tooltip = "Difficulty increases with higher score."

local function create_score_gui(player)
	local frame = player.gui.left.add({type = "frame", name = "pitch_black_score", direction = "vertical"})
	local t = frame.add({type = "table", column_count = 2})
	
	frame.tooltip = tooltip
	t.tooltip = tooltip
	
	local element = t.add({type = "label", caption = "Score: "})
	element.style.font = "heading-1"
	element.style.font_color = {175, 175, 200}
	element.style.horizontal_align = "right"
	element.style.maximal_width = 56
	element.style.minimal_width = 56
	element.tooltip = tooltip
	
	local element = t.add({type = "label", caption = 0})
	element.style.font = "heading-1"
	element.style.font_color = {100, 0, 255}
	element.style.horizontal_align = "left"
	element.style.minimal_width = 32
	element.tooltip = tooltip
	
	return frame
end

local function update_score_gui(player)
	local frame = player.gui.left.pitch_black_score
	if not player.gui.left.pitch_black_score then frame = create_score_gui(player) end
	
	local frame_table = frame.children[1]
	
	local score_value = frame_table.children[2]
	score_value.caption = global.map_score
end

function Public.update()
	for _, player in pairs(game.connected_players) do
		update_score_gui(player)
	end
end

return Public