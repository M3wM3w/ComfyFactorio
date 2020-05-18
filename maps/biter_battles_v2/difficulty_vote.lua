local bb_config = require "maps.biter_battles_v2.config"
local event = require 'utils.event'
local Server = require 'utils.server'

local difficulties = {
	[1] = {name = "Peaceful", str = "25%", value = 0.25, color = {r=0.00, g=0.45, b=0.00}, print_color = {r=0.00, g=0.9, b=0.00}},
	[2] = {name = "Piece of cake", str = "50%", value = 0.5, color = {r=0.00, g=0.35, b=0.00}, print_color = {r=0.00, g=0.7, b=0.00}},
	[3] = {name = "Easy", str = "75%", value = 0.75, color = {r=0.00, g=0.25, b=0.00}, print_color = {r=0.00, g=0.5, b=0.00}},
	[4] = {name = "Normal", str = "100%", value = 1, color = {r=0.00, g=0.00, b=0.25}, print_color = {r=0.0, g=0.0, b=0.7}},
	[5] = {name = "Hard", str = "150%", value = 1.5, color = {r=0.25, g=0.00, b=0.00}, print_color = {r=0.5, g=0.0, b=0.00}},
	[6] = {name = "Nightmare", str = "250%", value = 2.5, color = {r=0.35, g=0.00, b=0.00}, print_color = {r=0.7, g=0.0, b=0.00}},
	[7] = {name = "Insane", str = "500%", value = 5, color = {r=0.45, g=0.00, b=0.00}, print_color = {r=0.9, g=0.0, b=0.00}}
}

local timeout = 18000

local function difficulty_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top["difficulty_gui"] then player.gui.top["difficulty_gui"].destroy() end
		local str = table.concat({"Global map difficulty is ", difficulties[global.difficulty_vote_index].name, ". Mutagen has ", difficulties[global.difficulty_vote_index].str, " effectiveness."})
		local b = player.gui.top.add { type = "sprite-button", caption = difficulties[global.difficulty_vote_index].name, tooltip = str, name = "difficulty_gui" }
		b.style.font = "heading-2"
		b.style.font_color = difficulties[global.difficulty_vote_index].print_color
		b.style.minimal_height = 38
		b.style.minimal_width = 96
	end
end

local function poll_difficulty(player)
	if player.gui.center["difficulty_poll"] then player.gui.center["difficulty_poll"].destroy() return end
	
	if global.bb_settings.only_admins_vote or global.tournament_mode then
		if not player.admin then return end
	end
	
	local tick = game.ticks_played
	if tick > timeout then
		if player.online_time ~= 0 then
			local t = math.abs(math.floor((timeout - tick) / 3600))
			local str = "Votes have closed " .. t
			str = str .. " minute"
			if t > 1 then str = str .. "s" end
			str = str .. " ago."
			player.print(str)
		end
		return 
	end
	
	local frame = player.gui.center.add { type = "frame", caption = "Vote global difficulty:", name = "difficulty_poll", direction = "vertical" }
	for i = 1, 7, 1 do
		local b = frame.add({type = "button", name = tostring(i), caption = difficulties[i].name .. " (" .. difficulties[i].str .. ")"})
		b.style.font_color = difficulties[i].color
		b.style.font = "heading-2"
		b.style.minimal_width = 180
	end
	local b = frame.add({type = "label", caption = "- - - - - - - - - - - - - - - - - - - -"})
	local b = frame.add({type = "button", name = "close", caption = "Close (" .. math.floor((timeout - tick) / 3600) .. " minutes left)"})
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

local function on_player_joined_game(event)
	if not global.difficulty_vote_value then global.difficulty_vote_value = 1 end
	if not global.difficulty_vote_index then global.difficulty_vote_index = 4 end
	if not global.difficulty_player_votes then global.difficulty_player_votes = {} end
	
	local player = game.players[event.player_index]
	if game.ticks_played < timeout then
		if not global.difficulty_player_votes[player.name] then
			if global.bb_settings.only_admins_vote or global.tournament_mode then
				if player.admin then poll_difficulty(player) end
			else
				poll_difficulty(player)
			end
		end
	else
		if player.gui.center["difficulty_poll"] then player.gui.center["difficulty_poll"].destroy() end
	end
	
	difficulty_gui()
end

local function on_player_left_game(event)
	if game.ticks_played > timeout then return end
	local player = game.players[event.player_index]
	if not global.difficulty_player_votes[player.name] then return end
	global.difficulty_player_votes[player.name] = nil
	set_difficulty()
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
	if game.ticks_played > timeout then event.element.parent.destroy() return end
	local i = tonumber(event.element.name)
	
	if global.bb_settings.only_admins_vote or global.tournament_mode then
		if player.admin then
			game.print(player.name .. " has voted for " .. difficulties[i].name .. " difficulty!", difficulties[i].print_color)
			global.difficulty_player_votes[player.name] = i
			set_difficulty()
			difficulty_gui()				
		end
		event.element.parent.destroy()
		return
	end
	
	game.print(player.name .. " has voted for " .. difficulties[i].name .. " difficulty!", difficulties[i].print_color)
	global.difficulty_player_votes[player.name] = i
	set_difficulty()
	difficulty_gui()	
	event.element.parent.destroy()
end
	
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_player_joined_game, on_player_joined_game)