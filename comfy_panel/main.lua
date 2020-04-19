--[[
Comfy Panel

To add a tab, insert into the "comfy_panel_tabs" table.

Example: comfy_panel_tabs["mapscores"] = {gui = draw_map_scores, admin = false}
if admin = true, then tab is visible only for admins (usable for map-specific settings)

draw_map_scores would be a function with the player and the frame as arguments

]]

local event = require 'utils.event'

comfy_panel_tabs = {}


local Public = {}

function Public.get_tabs(data)
	return comfy_panel_tabs
end

function Public.comfy_panel_clear_left_gui(player)
	for _, child in pairs(player.gui.left.children) do
		child.visible = false
	end
end

function Public.comfy_panel_restore_left_gui(player)
	for _, child in pairs(player.gui.left.children) do
		child.visible = true
	end
end

function Public.comfy_panel_get_active_frame(player)
	if not player.gui.left.comfy_panel then return false end
	if not player.gui.left.comfy_panel.tabbed_pane.selected_tab_index then return player.gui.left.comfy_panel.tabbed_pane.tabs[1].content end
	return player.gui.left.comfy_panel.tabbed_pane.tabs[player.gui.left.comfy_panel.tabbed_pane.selected_tab_index].content
end

function Public.comfy_panel_refresh_active_tab(player)
	local frame = Public.comfy_panel_get_active_frame(player)
	if not frame then return end
	comfy_panel_tabs[frame.name].gui(player, frame)
end

local function top_button(player)
	if player.gui.top["comfy_panel_top_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "comfy_panel_top_button", sprite = "item/raw-fish"})
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.padding = -2
end

local function main_frame(player)
	local tabs = comfy_panel_tabs
	Public.comfy_panel_clear_left_gui(player)

	local frame = player.gui.left.add({type = "frame", name = "comfy_panel"})
	frame.style.margin = 6

	local tabbed_pane = frame.add({type = "tabbed-pane", name = "tabbed_pane"})

	for name, func in pairs(tabs) do
		if func.admin == true then
			if player.admin then
				local tab = tabbed_pane.add({type = "tab", caption = name})
				local frame = tabbed_pane.add({type = "frame", name = name, direction = "vertical"})
				frame.style.minimal_height = 480
				frame.style.maximal_height = 480
				frame.style.minimal_width = 800
				frame.style.maximal_width = 800
				tabbed_pane.add_tab(tab, frame)
			end
		else
			local tab = tabbed_pane.add({type = "tab", caption = name})
			local frame = tabbed_pane.add({type = "frame", name = name, direction = "vertical"})
			frame.style.minimal_height = 480
			frame.style.maximal_height = 480
			frame.style.minimal_width = 800
			frame.style.maximal_width = 800
			tabbed_pane.add_tab(tab, frame)
		end
	end

	local tab = tabbed_pane.add({type = "tab", name = "comfy_panel_close", caption = "X"})
	tab.style.maximal_width = 32
	local frame = tabbed_pane.add({type = "frame", name = name, direction = "vertical"})
	tabbed_pane.add_tab(tab, frame)

	for _, child in pairs(tabbed_pane.children) do
		child.style.padding = 8
		child.style.left_padding = 2
		child.style.right_padding = 2
	end

	Public.comfy_panel_refresh_active_tab(player)
end

function Public.comfy_panel_call_tab(player, name)
	main_frame(player)
	local tabbed_pane = player.gui.left.comfy_panel.tabbed_pane
	for key, v in pairs(tabbed_pane.tabs) do
		if v.tab.caption == name then
			tabbed_pane.selected_tab_index = key
			Public.comfy_panel_refresh_active_tab(player)
		end
	end
end

local function on_player_joined_game(event)
	top_button(game.players[event.player_index])
end

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]

	if event.element.name == "comfy_panel_top_button" then
		if player.gui.left.comfy_panel then
			player.gui.left.comfy_panel.destroy()
			Public.comfy_panel_restore_left_gui(player)
			return
		else
			main_frame(player)
			return
		end
	end

	if event.element.caption == "X" and event.element.name == "comfy_panel_close" then
		player.gui.left.comfy_panel.destroy()
		Public.comfy_panel_restore_left_gui(player)
		return
	end

	if not event.element.caption then return end
	if event.element.type ~= "tab" then return end
	Public.comfy_panel_refresh_active_tab(player)
end

event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)

return Public
