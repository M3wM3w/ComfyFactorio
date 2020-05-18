local Global = require 'utils.global'
local Tabs = require 'comfy_panel.main'

local map_info = {
	localised_category = false,
	main_caption = "Insert Main Caption",
	main_caption_color = {r=0.6, g=0.3, b=0.99},
	sub_caption = "Insert Sub Caption",
	sub_caption_color = {r=0.2, g=0.9, b=0.2},
	text = [[
	Add info text to map_info.
	]]
}

Global.register(
	map_info,
	function(tbl)
	map_info = tbl
	end
)

local Public = {}

function Public.Pop_info()
	return map_info
end

local create_map_intro = (function (player, frame)
	frame.clear()
	frame.style.padding = 4
	frame.style.margin = 0

	local t = frame.add {type = "table", column_count = 1}

	local line = t.add { type = "line"}
	line.style.top_margin = 4
	line.style.bottom_margin = 4

	local caption
	if map_info.localised_category then
		caption = {map_info.localised_category .. ".map_info_main_caption"}
	else
		caption = map_info.main_caption
	end
	local l = t.add {type = "label", caption = caption}
	l.style.font = "heading-1"
	l.style.font_color = map_info.main_caption_color
	l.style.minimal_width = 780
	l.style.horizontal_align = "center"
	l.style.vertical_align = "center"

	if map_info.localised_category then
		caption = {map_info.localised_category .. ".map_info_sub_caption"}
	else
		caption = map_info.sub_caption
	end
	local l_2 = t.add {type = "label", caption = caption}
	l_2.style.font = "heading-2"
	l_2.style.font_color = map_info.sub_caption_color
	l_2.style.minimal_width = 780
	l_2.style.horizontal_align = "center"
	l_2.style.vertical_align = "center"

	local line_2 = t.add { type = "line"}
	line_2.style.top_margin = 4
	line_2.style.bottom_margin = 4

	local scroll_pane = frame.add { type = "scroll-pane", name = "scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"}
	scroll_pane.style.maximal_height = 320
	scroll_pane.style.minimal_height = 320

	if map_info.localised_category then
		caption = {map_info.localised_category .. ".map_info_text"}
	else
		caption = map_info.text
	end
	local l_3 = scroll_pane.add {type = "label", caption = caption}
	l_3.style.font = "heading-2"
	l_3.style.single_line = false
	l_3.style.font_color = {r=0.85, g=0.85, b=0.88}
	l_3.style.minimal_width = 780
	l_3.style.horizontal_align = "center"
	l_3.style.vertical_align = "center"

	local b = frame.add {type = "button", caption = "CLOSE", name = "close_map_intro"}
	b.style.font = "heading-2"
	b.style.padding = 2
	b.style.top_margin = 3
	b.style.left_margin = 333
	b.style.horizontal_align = "center"
	b.style.vertical_align = "center"
end
)

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time == 0 then	Tabs.comfy_panel_call_tab(player, "Map Info") end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	if event.element.name == "close_map_intro" then game.players[event.player_index].gui.left.comfy_panel.destroy() return end
end

comfy_panel_tabs["Map Info"] = {gui = create_map_intro, admin = false}

local event = require 'utils.event'
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)

return Public