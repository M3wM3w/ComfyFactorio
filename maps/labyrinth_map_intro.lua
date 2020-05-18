local event = require 'utils.event'

local main_caption = " --Labyrinth-- "
local sub_caption = " *...where am i* "
local info = [[
How did i end up in this strange place?

You can barely remember that your ship must have crashed.
To make things worse, you can´t make out any of your supplies.
They must have sunken with it.
At least i am still alive.. i hope..

It seems to be an island of some sort.
There is nothing but water as far as your eyes can see.

There seems to be an opening to the north.
Maybe i should inspect...
]]

local function create_map_intro(player)	
	local frame = player.gui.left.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	local t = frame.add {type = "table", column_count = 1}	
	
	local tt = t.add {type = "table", column_count = 3}
	local l = tt.add {type = "label", caption = main_caption}
	l.style.font = "default-listbox"
	l.style.font_color = {r=0.6, g=0.3, b=0.99}
	l.style.top_padding = 6	
	l.style.bottom_padding = 6
	
	local l = tt.add {type = "label", caption = sub_caption}
	l.style.font = "default"
	l.style.font_color = {r=0.2, g=0.9, b=0.2}
	l.style.minimal_width = 280	
	
	local b = tt.add {type = "button", caption = "X", name = "close_map_intro_frame", align = "right"}	
	b.style.font = "default"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
	
	local tt = t.add {type = "table", column_count = 1}
	local frame = t.add {type = "frame"}
	local l = frame.add {type = "label", caption = info}
	l.style.single_line = false	
	l.style.font_color = {r=0.95, g=0.95, b=0.95}	
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	create_map_intro(player)
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end	
	local player = game.players[event.element.player_index]
	if event.element.name == "close_map_intro_frame" then player.gui.left["map_intro_frame"].destroy() end	
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)