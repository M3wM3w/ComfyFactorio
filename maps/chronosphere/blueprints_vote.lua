-- modification of difficulty_vote.lua
-- still uses difficulty_poll_closing_timeout

local event = require 'utils.event' 
local Server = require 'utils.server'

local options = {
	[1] = {name = "Imports On", value = true, color = {r=0, g=0, b=0.66}, button_text_color = {r=0, g=0, b=0.8}, print_color = {r=0.16, g=0.5, b=1}},
	[2] = {name = "Imports Off", value = false, color = {r=0.5, g=0.5, b=0}, button_text_color = {r=0.55, g=0.55, b=0}, print_color = {r=1, g=1, b=0.5}}
}

local function blueprints_permissions_gui()
		
	for _, player in pairs(game.connected_players) do
		if player.gui.top["blueprint_permissions_gui"] then
			player.gui.top["blueprint_permissions_gui"].caption = options[global.blueprints_vote_index].name
			player.gui.top["blueprint_permissions_gui"].style.font_color = options[global.blueprints_vote_index].button_text_color
		else
			local b = player.gui.top.add { type = "button", caption = options[global.blueprints_vote_index].name, name = "blueprint_permissions_gui" }
			b.style.font = "heading-2"
			b.style.font_color = options[global.blueprints_vote_index].button_text_color
			b.style.minimal_height = 38
		end
	end
end

local function poll_blueprints(player)
	if player.gui.center["blueprints_poll"] then player.gui.center["blueprints_poll"].destroy() return end
	if not global.difficulty_poll_closing_timeout then global.difficulty_poll_closing_timeout = game.tick + 35 * 60 * 60 end
	if game.tick > global.difficulty_poll_closing_timeout then
		if player.online_time ~= 0 then
			local t = math.abs(math.floor((global.difficulty_poll_closing_timeout - game.tick) / 3600))
			local str = "Votes have closed " .. t
			str = str .. " minute"
			if t > 1 then str = str .. "s" end
			str = str .. " ago."
			player.print(str)
		end
		return 
	end
	
	local frame = player.gui.center.add { type = "frame", caption = "Vote on importing blueprints:", name = "blueprints_poll", direction = "vertical" }
	for i = 1, 2, 1 do
		local b
		b = frame.add({type = "button", name = tostring(i), caption = options[i].name})
		b.style.font_color = options[i].color
		b.style.font = "heading-2"
		b.style.minimal_width = 160
	end
	local b = frame.add({type = "label", caption = "- - - - - - - - - - - - - - - - - -"})
	local b = frame.add({type = "button", name = "close", caption = "Close (" .. math.floor((global.difficulty_poll_closing_timeout - game.tick) / 3600) .. " minutes left)"})
	b.style.font_color = {r=0.66, g=0.0, b=0.66}
	b.style.font = "heading-3"
	b.style.minimal_width = 96
end

local function set_blueprints_permissions()
	local a = 0
	local vote_count = 0
	for _, d in pairs(global.blueprints_player_votes) do
		a = a + d
		vote_count = vote_count + 1
	end
	if vote_count == 0 then return end
	a = a / vote_count
	local new_index = math.round(a, 0)
	if global.blueprints_vote_index ~= new_index then
		local message
		if options[new_index].value then
			message = table.concat({"Permissions: Importing blueprints on!"})
		else
			message = table.concat({"Permissions: Importing blueprints off!"})
		end
		game.print(message, options[new_index].print_color)
		Server.to_discord_embed(message)	
	end
	 global.blueprints_vote_index = new_index
	 global.blueprints_vote_allowed = options[new_index].value

	if global.blueprints_vote_allowed == true then
		game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, true)
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, true)
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, true)
	else
		game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
		game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)
	end
end

function reset_blueprints_poll()
	global.blueprints_vote_allowed = true
	global.blueprints_vote_index = 1
	global.blueprints_player_votes = {}
	global.difficulty_poll_closing_timeout = game.tick + 35 * 60 * 60
	for _, p in pairs(game.connected_players) do
		if p.gui.center["blueprints_poll"] then p.gui.center["blueprints_poll"].destroy() end
		poll_difficulty(p)
	end
	blueprints_permissions_gui()
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.blueprints_vote_allowed then global.blueprints_vote_allowed = true end
	if not global.blueprints_vote_index then global.blueprints_vote_index = 1 end
	if not global.blueprints_player_votes then global.blueprints_player_votes = {} end
	if not global.difficulty_poll_closing_timeout then global.difficulty_poll_closing_timeout = 35 * 60 * 60 end
	--if game.tick < global.difficulty_poll_closing_timeout then
	--	if not global.blueprints_player_votes[player.name] then
	--		poll_blueprints(player)
	--	end
	--else
		if player.gui.center["blueprints_poll"] then player.gui.center["blueprints_poll"].destroy() end
	--end
	blueprints_permissions_gui()
end

local function on_player_left_game(event)
	if game.tick > global.difficulty_poll_closing_timeout then return end
	local player = game.players[event.player_index]
	if not global.blueprints_player_votes[player.name] then return end
	global.blueprints_player_votes[player.name] = nil
	set_blueprints_permissions()
	blueprints_permissions_gui()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "blueprint_permissions_gui" then
		poll_blueprints(player)
		return
	end
	if event.element.type ~= "button" then return end
	if event.element.parent.name ~= "blueprints_poll" then return end
	if event.element.name == "close" then event.element.parent.destroy() return end
	if game.tick > global.difficulty_poll_closing_timeout then event.element.parent.destroy() return end
	local i = tonumber(event.element.name)
	game.print(player.name .. " has voted for Blueprint " .. options[i].name .. "!", options[i].print_color)
	global.blueprints_player_votes[player.name] = i
	set_blueprints_permissions()
	blueprints_permissions_gui()
	event.element.parent.destroy()
end
	
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_gui_click, on_gui_click)