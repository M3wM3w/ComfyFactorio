local event = require 'utils.event'

local info = [[
Hello Players,

on this map you battle with your team against up to 3 other teams.

Each team can call its own wave of biters and spitters at any time and they get stronger with each wave.
Each wave, when defeated, sends a percentage of their enemys to all other teams.

To call a wave, you have to rotate the loader.
But remember that you must also be able to defeat the enemy.

Your task is to defend your loader. If it is destroyed, you have lost!

A round is over when only one team has it's loader left.

Credits:
Map made by MewMew and Kyte
]]

local function create_map_intro_button(player)
	if player.gui.top["map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "?", name = "map_intro_button", tooltip = "Map Info"})
	b.style.font_color = {r = 0.1, g = 0.8, b = 0.1}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2
end

local function create_map_intro(player)
	if player.gui.left["map_intro_frame"] then player.gui.left["map_intro_frame"].destroy() end
	local frame = player.gui.left.add {type = "frame", name = "map_intro_frame", direction = "vertical"}

	local t = frame.add {type = "table", column_count = 1}

	local b = frame.add {type = "button", caption = "Close", name = "close_map_intro_frame", align = "right"}
	b.style.font = "default"
	b.style.minimal_height = 30
	b.style.minimal_width = 30
	b.style.top_padding = 2
	b.style.left_padding = 4
	b.style.right_padding = 4
	b.style.bottom_padding = 2

	local frame = t.add {type = "frame"}
	local l = frame.add {type = "label", caption = info}
	l.style.single_line = false
	l.style.font = "heading-2"
	l.style.font_color = {r=0.60, g=0.8, b=0.60}
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	create_map_intro_button(player)
	if player.online_time == 0 then
		create_map_intro(player)
	end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "close_map_intro_frame" then player.gui.left["map_intro_frame"].destroy() return end
	if event.element.name == "map_intro_button" then
		if player.gui.left["map_intro_frame"] then
			player.gui.left["map_intro_frame"].destroy()
		else
			create_map_intro(player)
		end
		return
	end
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)
