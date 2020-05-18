local event = require 'utils.event'

local main_caption = " --Hunger Games Mode-- "
local sub_caption = "Deep in the meadow, hidden far away."
local info = [[	
	Create / Join a group to play!!
	
	Use the [Group] button!
	
	Use /s yourmessage in chat for global chat.
	
	Anything goes.
	
	No rules.		
]]

local function create_map_intro(player)
	if player.gui.left["map_intro_frame"] then player.gui.left["map_intro_frame"].destroy() end
	local frame = player.gui.left.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	local t = frame.add {type = "table", column_count = 1}	
	
	local tt = t.add {type = "table", column_count = 3}
	local l = tt.add {type = "label", caption = main_caption}
	l.style.font = "heading-1"
	l.style.font_color = {r=35, g=130, b=60}
	l.style.top_padding = 6	
	l.style.bottom_padding = 6
	
	local l = tt.add {type = "label", caption = sub_caption}
	l.style.font = "heading-2"
	l.style.font_color = {r=0.75, g=0.75, b=0.2}
	l.style.minimal_width = 280	
	
	local b = tt.add {type = "button", caption = "X", name = "close_map_intro_frame"}	
	b.style.font = "heading-1"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	
	local frame = frame.add {type = "frame"}
	local l = frame.add {type = "label", caption = info}
	l.style.single_line = false
	l.style.font = "heading-3"	
	l.style.font_color = {r=0.95, g=0.95, b=0.95}	
	l.style.minimal_width = 500
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	create_map_intro(player)
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
	local player = game.players[event.player_index]
	if event.element.name == "close_map_intro_frame" then player.gui.left["map_intro_frame"].destroy() end	
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)