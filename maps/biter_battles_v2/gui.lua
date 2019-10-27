local event = require 'utils.event' 
local spy_fish = require "maps.biter_battles_v2.spy_fish"
local feed_the_biters = require "maps.biter_battles_v2.feeding"

local food_names = {
	["automation-science-pack"] = true,
	["logistic-science-pack"] = true,
	["military-science-pack"] = true,
	["chemical-science-pack"] = true,
	["production-science-pack"] = true,
	["utility-science-pack"] = true,
	["space-science-pack"] = true
}

local gui_values = {
		["north"] = {force = "north", biter_force = "north_biters", c1 = bb_config.north_side_team_name, c2 = "JOIN ", n1 = "join_north_button",
		t1 = "Evolution of the North side biters. Can go beyond 100% for endgame modifiers.",
		t2 = "Threat causes biters to attack. Reduces when biters are slain.", color1 = {r = 0.55, g = 0.55, b = 0.99}, color2 = {r = 0.66, g = 0.66, b = 0.99}},
		["south"] = {force = "south", biter_force = "south_biters", c1 = bb_config.south_side_team_name, c2 = "JOIN ", n1 = "join_south_button",
		t1 = "Evolution of the South side biters. Can go beyond 100% for endgame modifiers.",
		t2 = "Threat causes biters to attack. Reduces when biters are slain.", color1 = {r = 0.99, g = 0.33, b = 0.33}, color2 = {r = 0.99, g = 0.44, b = 0.44}}
	}		

local map_gen_messages = {
	"Map is still generating, please get comfy.",
	"Map is still generating, get comfy!!",
	"Map is still generating, go and grab a drink.",
	"Map is still generating, take a short healthy break.",
	"Map is still generating, go and stretch your legs.",
	"Map is still generating, please pet the cat.",
	"Map is still generating, time to get a bowl of snacks :3"
}
	
local function create_sprite_button(player)
	if player.gui.top["bb_toggle_button"] then return end
	local button = player.gui.top.add({type = "sprite-button", name = "bb_toggle_button", sprite = "entity/big-spitter"})
	button.style.font = "default-bold"
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2	
end

local function create_first_join_gui(player)
	if not global.game_lobby_timeout then global.game_lobby_timeout = 5999940 end
	if global.game_lobby_timeout - game.tick < 0 then global.game_lobby_active = false end
	local frame = player.gui.left.add { type = "frame", name = "bb_main_gui", direction = "vertical" }
	local b = frame.add{ type = "label", caption = "Defend your Rocket Silo!" }
	b.style.font = "heading-1"
	b.style.font_color = {r=0.98, g=0.66, b=0.22}
	local b = frame.add  { type = "label", caption = "Feed the enemy team's biters to gain advantage!" }
	b.style.font = "heading-2"
	b.style.font_color = {r=0.98, g=0.66, b=0.22}
	
	frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	
	for _, gui_value in pairs(gui_values) do
		local t = frame.add { type = "table", column_count = 3 }
		local c = gui_value.c1
		if global.tm_custom_name[gui_value.force] then c = global.tm_custom_name[gui_value.force] end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "heading-2"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		l.style.maximal_width = 290
		local l = t.add  { type = "label", caption = "  -  "}
		local l = t.add  { type = "label", caption = #game.forces[gui_value.force].connected_players .. " Players "}
		l.style.font_color = { r=0.22, g=0.88, b=0.22}
		
		local c = gui_value.c2	
		local font_color =  gui_value.color1
		if global.game_lobby_active then
			font_color = {r=0.7, g=0.7, b=0.7}
			c = c .. " (waiting for players...  "
			c = c .. math.ceil((global.game_lobby_timeout - game.tick)/60)
			c = c .. ")"										
		end		
		local t = frame.add  { type = "table", column_count = 4 }	
		for _, p in pairs(game.forces[gui_value.force].connected_players) do
			local l = t.add({type = "label", caption = p.name})
			l.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
			l.style.font = "heading-2"
		end		
		local b = frame.add  { type = "sprite-button", name = gui_value.n1, caption = c }
		b.style.font = "default-large-bold"
		b.style.font_color = font_color
		b.style.minimal_width = 350
		frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	end	
end

local function create_main_gui(player)
	if player.gui.left["bb_main_gui"] then player.gui.left["bb_main_gui"].destroy() end
	
	if global.bb_game_won_by_team then return end
	if not global.chosen_team[player.name] then
		if not global.tournament_mode then
			create_first_join_gui(player) 
			return
		end
	end
		
	local frame = player.gui.left.add { type = "frame", name = "bb_main_gui", direction = "vertical" }

	if player.force.name ~= "spectator" and player.force.name ~= "spectator_ghost" then			
		frame.add { type = "table", name = "biter_battle_table", column_count = 4 }
		local t = frame.biter_battle_table
		local foods = {"automation-science-pack","logistic-science-pack","military-science-pack","chemical-science-pack","production-science-pack","utility-science-pack","space-science-pack","raw-fish"}
		local food_tooltips = {"10 Mutagen strength","25 Mutagen strength", "96 Mutagen strength", "264 Mutagen strength", "887 Mutagen strength", "994 Mutagen strength", "2895 Mutagen strength", "Send spy"}
		local x = 1
		for _, f in pairs(foods) do
			local s = t.add { type = "sprite-button", name = f, sprite = "item/" .. f }
			s.tooltip = {"",food_tooltips[x]}
			s.style.minimal_height = 41
			s.style.minimal_width = 41
			s.style.top_padding = 0
			s.style.left_padding = 0
			s.style.right_padding = 0
			s.style.bottom_padding = 0
			x = x + 1
		end
	end	
	
	for _, gui_value in pairs(gui_values) do			
		local t = frame.add { type = "table", column_count = 3 }
		local c = gui_value.c1
		if global.tm_custom_name[gui_value.force] then c = global.tm_custom_name[gui_value.force] end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default-bold"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		--l.style.minimal_width = 100
		l.style.maximal_width = 102
		
		local l = t.add  { type = "label", caption = " - "}
		local c = #game.forces[gui_value.force].connected_players .. " Player"
		if #game.forces[gui_value.force].connected_players ~= 1 then c = c .. "s" end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default"
		l.style.font_color = { r=0.22, g=0.88, b=0.22}		
				
		if global.bb_view_players[player.name] == true then		
			local t = frame.add  { type = "table", column_count = 4 }	
			for _, p in pairs(game.forces[gui_value.force].connected_players) do
				local l = t.add  { type = "label", caption = p.name }
				l.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
			end
		end

		local t = frame.add { type = "table", name = "stats_" .. gui_value.force, column_count = 4 }			
		local l = t.add  { type = "label", caption = "Evo:"}
		--l.style.minimal_width = 25
		l.tooltip = gui_value.t1
		local evo = math.floor(1000 * global.bb_evolution[gui_value.biter_force]) * 0.1
		local l = t.add  {type = "label", caption = evo .. "%"}
		l.style.minimal_width = 38
		l.style.font_color = gui_value.color2
		l.style.font = "default-bold"
		l.tooltip = gui_value.t1
		
		local l = t.add  {type = "label", caption = "Threat: "}
		l.style.minimal_width = 25
		l.tooltip = gui_value.t2
		local l = t.add  {type = "label", name = "threat_" .. gui_value.force, caption = math.floor(global.bb_threat[gui_value.biter_force])}	
		l.style.font_color = gui_value.color2
		l.style.font = "default-bold"
		l.style.minimal_width = 25
		l.tooltip = gui_value.t2
		
		frame.add  { type = "label", caption = string.rep("-", 29)}						
	end
	
	local t = frame.add  { type = "table", column_count = 2 }
	if player.force.name == "spectator" or player.force.name == "spectator_ghost" then
		local b = t.add  { type = "sprite-button", name = "bb_leave_spectate", caption = "Join Team" }
	else
		local b = t.add  { type = "sprite-button", name = "bb_spectate", caption = "Spectate" }
	end
	
	if global.bb_view_players[player.name] == true then
		local b = t.add  { type = "sprite-button", name = "bb_hide_players", caption = "Playerlist" }
	else
		local b = t.add  { type = "sprite-button", name = "bb_view_players", caption = "Playerlist" }						
	end		
	for _, b in pairs(t.children) do
		b.style.font = "default-bold"
		b.style.font_color = { r=0.98, g=0.66, b=0.22}
		b.style.top_padding = 1
		b.style.left_padding = 1
		b.style.right_padding = 1
		b.style.bottom_padding = 1
		b.style.maximal_height = 30
		b.style.minimal_width = 86
	end
end

local function refresh_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["bb_main_gui"] then
			create_main_gui(player)					
		end
	end
	global.gui_refresh_delay = game.tick + 5
end

function refresh_gui_threat()
	if global.gui_refresh_delay > game.tick then return end
	for _, player in pairs(game.connected_players) do
		if player.gui.left["bb_main_gui"] then
			if player.gui.left["bb_main_gui"].stats_north then
				player.gui.left["bb_main_gui"].stats_north.threat_north.caption = math.floor(global.bb_threat["north_biters"])
				player.gui.left["bb_main_gui"].stats_south.threat_south.caption = math.floor(global.bb_threat["south_biters"])
			end
		end
	end
	global.gui_refresh_delay = game.tick + 5
end

function join_team(player, force_name, forced_join)
	if not player.character then return end
	if not forced_join then
		if global.tournament_mode then player.print("The game is set to tournament mode. Teams can only be changed via team manager.", {r = 0.98, g = 0.66, b = 0.22}) return end		
	end
	if not force_name then return end
	local surface = player.surface
	
	local enemy_team = "south"
	if force_name == "south" then enemy_team = "north" end
	
	if bb_config.team_balancing then
		if not forced_join then
			if #game.forces[force_name].connected_players > #game.forces[enemy_team].connected_players then
				if not global.chosen_team[player.name] then
					player.print("Team " .. force_name .. " has too many players currently.", {r = 0.98, g = 0.66, b = 0.22})
					return
				end
			end
		end
	end
	
	if global.chosen_team[player.name] then
		if not forced_join then
			if game.tick - global.spectator_rejoin_delay[player.name] < 3600 then
				player.print(
					"Not ready to return to your team yet. Please wait " .. 60-(math.floor((game.tick - global.spectator_rejoin_delay[player.name])/60)) .. " seconds.",
					{r = 0.98, g = 0.66, b = 0.22}
				)
				return
			end
		end
		local p = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 8, 0.5)
		player.teleport(p, surface)	
		player.force = game.forces[force_name]
		player.character.destructible = true
		refresh_gui()
		game.permissions.get_group("Default").add_player(player)
		game.print("Team " .. player.force.name .. " player " .. player.name .. " is no longer spectating.", {r = 0.98, g = 0.66, b = 0.22})
		player.spectator = false
		return
	end
	local pos = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 3, 1)
	if not pos then pos = game.forces[force_name].get_spawn_position(surface) end
	player.teleport(pos)
	player.force = game.forces[force_name]
	player.character.destructible = true
	game.permissions.get_group("Default").add_player(player)
	if not forced_join then
		local c = player.force.name
		if global.tm_custom_name[player.force.name] then c = global.tm_custom_name[player.force.name] end
		game.print(player.name .. " has joined team " .. c .. "!", {r = 0.98, g = 0.66, b = 0.22})
	end
	local i = player.get_inventory(defines.inventory.character_main)
	i.clear()
	player.insert {name = 'pistol', count = 1}
	player.insert {name = 'raw-fish', count = 3}
	player.insert {name = 'firearm-magazine', count = 32}		
	player.insert {name = 'iron-gear-wheel', count = 8}
	player.insert {name = 'iron-plate', count = 16}
	global.chosen_team[player.name] = force_name
	player.spectator = false
	refresh_gui()
end

function spectate(player, forced_join)
	if not player.character then return end
	if not forced_join then
		if global.tournament_mode then player.print("The game is set to tournament mode. Teams can only be changed via team manager.", {r = 0.98, g = 0.66, b = 0.22}) return end		
	end
	player.teleport(player.surface.find_non_colliding_position("character", {0,0}, 4, 1))	
	player.force = game.forces.spectator
	player.character.destructible = false
	if not forced_join then
		game.print(player.name .. " is spectating.", {r = 0.98, g = 0.66, b = 0.22})
	end		
	game.permissions.get_group("spectator").add_player(player)	
	global.spectator_rejoin_delay[player.name] = game.tick
	create_main_gui(player)
	player.spectator = true
end

local function join_gui_click(name, player)	
	local team = {
		["join_north_button"] = "north",
		["join_south_button"] = "south"
	}

	if not team[name] then return end
	
	-- JOIN PREVENTION IF MAP IS STILL GENERATING
	if not global.map_generation_complete then
		if not global.map_pregen_message_counter[player.name] then global.map_pregen_message_counter[player.name] = 1 end
		player.print(map_gen_messages[global.map_pregen_message_counter[player.name]], {r = 0.98, g = 0.66, b = 0.22})
		global.map_pregen_message_counter[player.name] = global.map_pregen_message_counter[player.name] + 1
		if global.map_pregen_message_counter[player.name] > #map_gen_messages then global.map_pregen_message_counter[player.name] = 1 end
		return 
	end
	
	if global.game_lobby_active then
		if player.admin then
			join_team(player, team[name])
			game.print("Lobby disabled, admin override.", { r=0.98, g=0.66, b=0.22})
			global.game_lobby_active = false
			return
		end
		player.print("Waiting for more players to join the game.", { r=0.98, g=0.66, b=0.22}) 
		return
	end
	join_team(player, team[name])
end

local function on_gui_click(event)
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.player_index]
	local name = event.element.name
	if name == "bb_toggle_button" then
		if player.gui.left["bb_main_gui"] then
			player.gui.left["bb_main_gui"].destroy()
		else
			create_main_gui(player)
		end
		return
	end
	
	if name == "join_north_button" then join_gui_click(name, player) return end
	if name == "join_south_button" then join_gui_click(name, player) return end
	
	if name == "raw-fish" then spy_fish(player) return end
	
	if food_names[name] then feed_the_biters(player, name) return end
	
	if name == "bb_leave_spectate" then join_team(player, global.chosen_team[player.name])	end
	
	if name == "bb_spectate" then
		if player.position.y ^ 2 + player.position.x ^ 2 < 12000 then
			spectate(player)
		else
			player.print("You are too far away from spawn to spectate.",{ r=0.98, g=0.66, b=0.22})
		end
		return
	end

	if name == "bb_hide_players" then
		global.bb_view_players[player.name] = false
		create_main_gui(player)
	end
	if name == "bb_view_players" then
		global.bb_view_players[player.name] = true 
		create_main_gui(player)
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	
	if not global.bb_view_players then global.bb_view_players = {} end
	if not global.chosen_team then global.chosen_team = {} end
	
	global.bb_view_players[player.name] = false
	
	if #game.connected_players > 1 then
		global.game_lobby_timeout = math.ceil(36000 / #game.connected_players)
	else
		global.game_lobby_timeout = 599940
	end
	
	--if not global.chosen_team[player.name] then
	--	if global.tournament_mode then
	--		player.force = game.forces.spectator
	--	else
	--		player.force = game.forces.player
	--	end
	--end
	
	create_sprite_button(player)
	create_main_gui(player)
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

return refresh_gui