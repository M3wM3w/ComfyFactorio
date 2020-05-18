local event = require 'utils.event'

local main_caption = " --Fish Defender-- "
local sub_caption = " *blb blubby blub* "
local info = [[
	The biters have caught the scent of fish in the market.
	Fend them off as long as possible!
	This however will not be an easy task,
	since their strength and resistance increases constantly over time.
	
	Your ultimate goal is to evacuate all the fish to cat planet!
	Put them in your rocket's cargo and launch them into space.
	Don't worry, you will still get space science.
	
	The Market will gladly take any coin you might find.
	Additional turret slots can be bought at the market.
	Several unique upgrades are available too.
	
	Researching tanks will unlock the artillery technology early.
	
	Any container bearing dangerous goods, like ammo, grenades or barrels,
	causes heavy explosions when it breaks.
	Maybe this can be used to our advantage.
]]

local function create_map_intro_button(player)
	if player.gui.top["map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "?", name = "map_intro_button", tooltip = "Map Info"})
	b.style.font_color = {r=0.11, g=0.8, b=0.44}
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
	
	local tt = t.add {type = "table", column_count = 3}
	local l = tt.add {type = "label", caption = main_caption}
	l.style.font = "heading-1"
	l.style.font_color = {r=0.11, g=0.8, b=0.44}
	
	local l = tt.add {type = "label", caption = sub_caption}
	l.style.font = "heading-2"
	l.style.font_color = {r=0.33, g=0.66, b=0.9}
	l.style.minimal_width = 320	
	
	local b = tt.add {type = "button", caption = "X", name = "close_map_intro_frame", align = "right"}	
	b.style.font = "heading-2"
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
	l.style.font = "heading-2"
	l.style.font_color = {r=0.75, g=0.8, b=0.8}
	l.style.minimal_width = 480
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

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	create_map_intro_button(player)
	if player.online_time == 0 then
		create_map_intro(player)
	end
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)
