local Public = {}

local function create_map_intro_button(player)
	if player.gui.top["map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "?", name = "map_intro_button", tooltip = "Map Info"})
	b.style.font_color = {r=0.5, g=0.3, b=0.99}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

local function create_map_intro(player)
	if player.gui.center["map_intro_frame"] then player.gui.center["map_intro_frame"].destroy() end
	local frame = player.gui.center.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
	local frame = frame.add {type = "frame"}
	local l = frame.add {type = "label", caption = {"native_war.map_info"}, name = "native_war_map_intro"}
	l.style.single_line = false
	l.style.font = "heading-2"
	l.style.font_color = {r=0.7, g=0.6, b=0.99}
end

function Public.player_joined_game(player)
	create_map_intro_button(player)
  player.print("Check the question mark button \"?\" for basic information", {255,0,0})
	if player.online_time == 0 then
		--create_map_intro(player)
	end
end

function Public.gui_click(player, element)
	if element.name == "close_map_intro_frame" then player.gui.center["map_intro_frame"].destroy() return true end
	if element.name == "native_war_map_intro" then player.gui.center["map_intro_frame"].destroy() return true end
	if element.name == "map_intro_button" then
		if player.gui.center["map_intro_frame"] then
			player.gui.center["map_intro_frame"].destroy()
			return true
		else
			create_map_intro(player)
			return true
		end
	end
end

return Public
