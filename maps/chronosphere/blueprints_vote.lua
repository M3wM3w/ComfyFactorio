-- modification of difficulty_vote.lua
-- still uses difficulty_poll_closing_timeout

local event = require 'utils.event' 
local Server = require 'utils.server'

local options = {
	[1] = {name = "Blueprints On", value = true, color = {r=0.0, g=0.0, b=0.90}, print_color = {r=0.00, g=0, b=0.70}},
	[2] = {name = "Blueprints Off", value = false, color = {r=0.90, g=0.0, b=0.0}, print_color = {r=0.70, g=0, b=0.00}}
}

local function blueprints_permissions_gui()
		
	for _, player in pairs(game.connected_players) do
		if player.gui.top["blueprint_permissions_gui"] then
			player.gui.top["blueprint_permissions_gui"].caption = options[global.blueprints_vote_index].name
			player.gui.top["blueprint_permissions_gui"].style.font_color = options[global.blueprints_vote_index].print_color
		else
			local b = player.gui.top.add { type = "button", caption = options[global.blueprints_vote_index].name, name = "blueprint_permissions_gui" }
			b.style.font = "heading-2"
			b.style.font_color = options[global.blueprints_vote_index].print_color
			b.style.minimal_height = 38
		end
	end
end

local function poll_blueprints(player)
	if player.gui.center["blueprints_poll"] then player.gui.center["blueprints_poll"].destroy() return end
	if not global.difficulty_poll_closing_timeout then global.difficulty_poll_closing_timeout = 54000 end
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
	
	local frame = player.gui.center.add { type = "frame", caption = "Vote on blueprints:", name = "blueprints_poll", direction = "vertical" }
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
			message = table.concat({"Permissions: Blueprints on!"})
		else
			message = table.concat({"Permissions: Blueprints off!"})
		end
		game.print(message, options[new_index].print_color)
		Server.to_discord_embed(message)	
	end
	 global.blueprints_vote_index = new_index
	 global.blueprints_vote_allowed = options[new_index].value
end

function reset_blueprints_poll()
	global.blueprints_vote_allowed = true
	global.blueprints_vote_index = 1
	global.blueprints_player_votes = {}
	global.difficulty_poll_closing_timeout = game.tick + 54000
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
	if not global.difficulty_poll_closing_timeout then global.difficulty_poll_closing_timeout = 54000 end
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
	game.print(player.name .. " has voted for " .. options[i].name .. "!", options[i].print_color)
	global.blueprints_player_votes[player.name] = i
	set_blueprints_permissions()
	blueprints_permissions_gui()
	event.element.parent.destroy()
end
	
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_gui_click, on_gui_click)