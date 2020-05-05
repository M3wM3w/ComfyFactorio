local event = require 'utils.event' 
local Server = require 'utils.server'

local difficulties = {
	[1] = {name = "Peaceful", value = 0.25, color = {r=0.00, g=0.45, b=0.00}, print_color = {r=0.00, g=0.8, b=0.00}},
	[2] = {name = "Piece of cake", value = 0.5, color = {r=0.00, g=0.35, b=0.00}, print_color = {r=0.00, g=0.6, b=0.00}},
	[3] = {name = "Easy", value = 0.75, color = {r=0.00, g=0.25, b=0.00}, print_color = {r=0.00, g=0.4, b=0.00}},
	[4] = {name = "Normal", value = 1, color = {r=0.00, g=0.00, b=0.25}, print_color = {r=0.0, g=0.0, b=0.5}},
	[5] = {name = "Hard", value = 1.5, color = {r=0.25, g=0.00, b=0.00}, print_color = {r=0.4, g=0.0, b=0.00}},
	[6] = {name = "Nightmare", value = 3, color = {r=0.35, g=0.00, b=0.00}, print_color = {r=0.6, g=0.0, b=0.00}},
	[7] = {name = "Impossible", value = 5, color = {r=0.45, g=0.00, b=0.00}, print_color = {r=0.8, g=0.0, b=0.00}}
} 

local function difficulty_gui()
	local tooltip = "Current difficulty of the map is " .. difficulties[global.difficulty_vote_index].name
	tooltip = tooltip .. "."
		
	for _, player in pairs(game.connected_players) do
		if player.gui.top["difficulty_gui"] then
			player.gui.top["difficulty_gui"].caption = difficulties[global.difficulty_vote_index].name
			player.gui.top["difficulty_gui"].tooltip = tooltip
			player.gui.top["difficulty_gui"].style.font_color = difficulties[global.difficulty_vote_index].print_color
		else
			local b = player.gui.top.add { type = "button", caption = difficulties[global.difficulty_vote_index].name, tooltip = tooltip, name = "difficulty_gui" }
			b.style.font = "heading-2"
			b.style.font_color = difficulties[global.difficulty_vote_index].print_color
			b.style.minimal_height = 38
		end
	end
end

local function poll_difficulty(player)
	if player.gui.center["difficulty_poll"] then player.gui.center["difficulty_poll"].destroy() return end
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
	
	local frame = player.gui.center.add { type = "frame", caption = "Vote difficulty:", name = "difficulty_poll", direction = "vertical" }
	for i = 1, 7, 1 do
		local b = frame.add({type = "button", name = tostring(i), caption = difficulties[i].name})
		b.style.font_color = difficulties[i].color
		b.style.font = "heading-2"
		b.style.minimal_width = 160
	end
	local b = frame.add({type = "label", caption = "- - - - - - - - - - - - - - - - - -"})
	local b = frame.add({type = "button", name = "close", caption = "Close (" .. math.floor((global.difficulty_poll_closing_timeout - game.tick) / 3600) .. " minutes left)"})
	b.style.font_color = {r=0.66, g=0.0, b=0.66}
	b.style.font = "heading-3"
	b.style.minimal_width = 96
end

local function set_difficulty()
	local a = 0
	local vote_count = 0
	for _, d in pairs(global.difficulty_player_votes) do
		a = a + d
		vote_count = vote_count + 1
	end
	if vote_count == 0 then return end
	a = a / vote_count
	local new_index = math.round(a, 0)
	if global.difficulty_vote_index ~= new_index then
		local message = table.concat({">> Map difficulty has changed to ", difficulties[new_index].name, " difficulty!"})
		game.print(message, difficulties[new_index].print_color)
		Server.to_discord_embed(message)	
	end
	 global.difficulty_vote_index = new_index
	 global.difficulty_vote_value = difficulties[new_index].value
end

function reset_difficulty_poll()
	global.difficulty_vote_value = 1
	global.difficulty_vote_index = 4
	global.difficulty_player_votes = {}
	global.difficulty_poll_closing_timeout = game.tick + 54000
	for _, p in pairs(game.connected_players) do
		if p.gui.center["difficulty_poll"] then p.gui.center["difficulty_poll"].destroy() end
		poll_difficulty(p)
	end
	difficulty_gui()
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.difficulty_vote_value then global.difficulty_vote_value = 1 end
	if not global.difficulty_vote_index then global.difficulty_vote_index = 4 end
	if not global.difficulty_player_votes then global.difficulty_player_votes = {} end
	if not global.difficulty_poll_closing_timeout then global.difficulty_poll_closing_timeout = 54000 end
	if game.tick < global.difficulty_poll_closing_timeout then
		if not global.difficulty_player_votes[player.name] then
			poll_difficulty(player)
		end
	else
		if player.gui.center["difficulty_poll"] then player.gui.center["difficulty_poll"].destroy() end
	end
	difficulty_gui()
end

local function on_player_left_game(event)
	if game.tick > global.difficulty_poll_closing_timeout then return end
	local player = game.players[event.player_index]
	if not global.difficulty_player_votes[player.name] then return end
	global.difficulty_player_votes[player.name] = nil
	set_difficulty()
	difficulty_gui()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "difficulty_gui" then
		poll_difficulty(player)
		return
	end
	if event.element.type ~= "button" then return end
	if event.element.parent.name ~= "difficulty_poll" then return end
	if event.element.name == "close" then event.element.parent.destroy() return end
	if game.tick > global.difficulty_poll_closing_timeout then event.element.parent.destroy() return end
	local i = tonumber(event.element.name)
	game.print(player.name .. " has voted for " .. difficulties[i].name .. " difficulty!", difficulties[i].print_color)
	global.difficulty_player_votes[player.name] = i
	set_difficulty()
	difficulty_gui()
	event.element.parent.destroy()
end
	
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_gui_click, on_gui_click)