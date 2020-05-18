-- Biter Battles -- mewmew made this --

local Server = require 'utils.server'
local Score = require "comfy_panel.score"
require "on_tick_schedule"
require "modules.splice_double"
require "modules.explosive_biters"
require "modules.spawners_contain_biters"
require "modules.custom_death_messages"

local biter_battles_terrain = require 'maps.biter_battles.biter_battles_terrain'
local event = require 'utils.event'
local math_random = math.random
local insert = table.insert

local food_names = {
	["automation-science-pack"] = 	"automation science",
	["logistic-science-pack"] = 	"logistic science",
	["military-science-pack"] =		"military science",
	["chemical-science-pack"] = 	"chemical science",
	["production-science-pack"] =	"production science",
	["utility-science-pack"] =		"utility science",
	["space-science-pack"] = 		"space science"
}
	
local food_values = {
	["automation-science-pack"] = 	0.00000100,
	["logistic-science-pack"] = 	0.00000292,
	["military-science-pack"] =		0.00001225,
	["chemical-science-pack"] = 	0.00002392,
	["production-science-pack"] =	0.00008000,
	["utility-science-pack"] =		0.00013875,
	["space-science-pack"] = 		0.00042000
}

local function get_border_cords(f)
	local a = {{-1000,-1000},{1000,-10}}
	if f == "south" then a = {{-1000,10},{1000,1000}} end
	local entities = game.surfaces["surface"].find_entities_filtered{area=a,force=f}
	if not entities then return end
	local x_top = entities[1].position.x; local y_top = entities[1].position.y; local x_bot = entities[1].position.x; local y_bot = entities[1].position.y	
	for _, e in pairs(entities) do		
		if e.position.x < x_top then x_top = e.position.x end
		if e.position.y < y_top then y_top = e.position.y end
		if e.position.x > x_bot then x_bot = e.position.x end
		if e.position.y > y_bot then y_bot = e.position.y end
	end
	global.force_area[f] = {}
	global.force_area[f].x_top	= x_top
	global.force_area[f].y_top	= y_top
	global.force_area[f].x_bot	= x_bot
	global.force_area[f].y_bot	= y_bot	
	--game.print(x_top .. " "  .. y_top .. " , ".. x_bot .. " " .. y_bot)	
end

local function create_biter_battle_sprite_button(player)
	if player.gui.top.biter_battle_toggle_menu_button == nil then
		local button = player.gui.top.add { name = "biter_battle_toggle_menu_button", type = "sprite-button", sprite = "entity/behemoth-spitter" }
		button.style.font = "default-bold"
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function get_sorted_list(column_name, score_list)		
	for x = 1, #score_list, 1 do
		for y = 1, #score_list, 1 do			
			if not score_list[y + 1] then break end
			if score_list[y][column_name] < score_list[y + 1][column_name] then
				local key = score_list[y]
				score_list[y] = score_list[y + 1]
				score_list[y + 1] = key
			end
		end		
	end	
	return score_list
end

local function get_mvps(force)
	local get_score = Score.get_table().score_table
	if not get_score[force] then return false end
	local score = get_score[force]
	local score_list = {}
	for _, p in pairs(game.players) do
		if score.players[p.name] then
			local killscore = 0
			if score.players[p.name].killscore then killscore = score.players[p.name].killscore end
			local deaths = 0
			if score.players[p.name].deaths then deaths = score.players[p.name].deaths end
			local built_entities = 0
			if score.players[p.name].built_entities then built_entities = score.players[p.name].built_entities end
			local mined_entities = 0
			if score.players[p.name].mined_entities then mined_entities = score.players[p.name].mined_entities end
			table.insert(score_list, {name = p.name, killscore = killscore, deaths = deaths, built_entities = built_entities, mined_entities = mined_entities})	
		end
	end
	local mvp = {}
	score_list = get_sorted_list("killscore", score_list)
	mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
	score_list = get_sorted_list("deaths", score_list)
	mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
	score_list = get_sorted_list("built_entities", score_list)
	mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
	return mvp
end

local function show_mvps(player)
	local get_score = Score.get_table().score_table
	if not get_score then return end
	if player.gui.left["mvps"] then return end
	local frame = player.gui.left.add({type = "frame", name = "mvps", direction = "vertical"})
	local l = frame.add({type = "label", caption = "MVPs - North:"})
	l.style.font = "default-listbox"
	l.style.font_color = {r = 0.55, g = 0.55, b = 0.99}
		
	local t = frame.add({type = "table", column_count = 2})
	local mvp = get_mvps("north")		
	if mvp then
		
		local l = t.add({type = "label", caption = "Defender >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.killscore.name .. " with a score of " .. mvp.killscore.score})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Builder >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things"})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Deaths >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.deaths.name .. " died " .. mvp.deaths.score .. " times"})						
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		if not global.results_sent_north then
			local result = {}
			insert(result, 'NORTH: \\n')
			insert(result, 'MVP Defender: \\n')
			insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Builder: \\n')
			insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Deaths: \\n')
			insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
			local message = table.concat(result)
			Server.to_discord_embed(message)
			global.results_sent_north = true
		end
	end
	
	local l = frame.add({type = "label", caption = "MVPs - South:"})
	l.style.font = "default-listbox"
	l.style.font_color = {r = 0.99, g = 0.33, b = 0.33}
	
	local t = frame.add({type = "table", column_count = 2})
	local mvp = get_mvps("south")		
	if mvp then			
		local l = t.add({type = "label", caption = "Defender >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.killscore.name .. " with a score of " .. mvp.killscore.score})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Builder >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things"})
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		local l = t.add({type = "label", caption = "Deaths >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
		local l = t.add({type = "label", caption = mvp.deaths.name .. " died " .. mvp.deaths.score .. " times"})						
		l.style.font = "default-bold"
		l.style.font_color = {r=0.33, g=0.66, b=0.9}
		
		if not global.results_sent_south then
			local result = {}
			insert(result, 'SOUTH: \\n')
			insert(result, 'MVP Defender: \\n')
			insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Builder: \\n')
			insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			insert(result, '\\n')
			insert(result, 'MVP Deaths: \\n')
			insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
			local message = table.concat(result)
			Server.to_discord_embed(message)
			global.results_sent_south = true
		end
	end
end

local function create_biter_battle_menu(player)
	if global.rocket_silo_destroyed then 
		local frame = player.gui.left.add { type = "frame", name = "victory_popup", direction = "vertical" }			
		local l = frame.add { type = "label", caption = global.rocket_silo_destroyed , single_line = false, name = "victory_caption" }
		l.style.font = "default-listbox"
		l.style.font_color = { r=0.98, g=0.66, b=0.22}
		l.style.top_padding = 10
		l.style.left_padding = 20
		l.style.right_padding = 20
		l.style.bottom_padding = 10
		show_mvps(player)
		return
	end
	
	if player.gui.left["biter_battle_menu"] then player.gui.left["biter_battle_menu"].destroy() end
	
	local frame = player.gui.left.add { type = "frame", name = "biter_battle_menu", direction = "vertical" }

	if player.force.name == "north" or player.force.name == "south" then			
		frame.add { type = "table", name = "biter_battle_table", column_count = 4 }
		local t = frame.biter_battle_table
		local foods = {"automation-science-pack","logistic-science-pack","military-science-pack","chemical-science-pack","production-science-pack","utility-science-pack","space-science-pack","raw-fish"}
		local food_tooltips = {"1 Calorie","3 Calories", "12 Calories", "24 Calories", "80 Calories", "138 Calories", "420 Calories", "Send spy"}
		local x = 1
		for _, f in pairs(foods) do
			local s = t.add { type = "sprite-button", name = f, sprite = "item/" .. f }
			s.tooltip = {"",food_tooltips[x]}
			x = x + 1
		end
	end
	if player.force.name == "player"	then
		local b = frame.add  { type = "label", caption = "Defend your team´s rocket silo!" }
		b.style.font = "default-bold"
		b.style.font_color = { r=0.98, g=0.66, b=0.22}
		local b = frame.add  { type = "label", caption = "Feed the enemy team´s biters to gain advantage!" }
		b.style.font = "default-bold"
		b.style.font_color = { r=0.98, g=0.66, b=0.22}
		frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	end		
	
	local t = frame.add { type = "table", column_count = 3 }	
	local l = t.add  { type = "label", caption = "Team North"}
	l.style.font = "default-bold"
	l.style.font_color = {r = 0.55, g = 0.55, b = 0.99}
	local l = t.add  { type = "label", caption = "  -  "}
	local l = t.add  { type = "label", caption = #game.forces["north"].connected_players .. " Players "}
	l.style.font_color = { r=0.22, g=0.88, b=0.22}
	
	if player.force.name ~= "player" then	
		
		if global.biter_battle_view_players[player.name] == true then
			local t = frame.add  { type = "table", column_count = 4 }	
			for _, p in pairs(game.forces.north.connected_players) do
				local color = {}
				color = p.color
				color.r = color.r * 0.6 + 0.4
				color.g = color.g * 0.6 + 0.4
				color.b = color.b * 0.6 + 0.4
				color.a = 1
				local l = t.add  { type = "label", caption = p.name }
				l.style.font_color = color
			end
		end
	
		local t = frame.add { type = "table", column_count = 4 }			
		local l = t.add  { type = "label", caption = "Nerf: "}
		l.style.minimal_width = 25
		l.tooltip = "Damage nerf of the team."
		local l = t.add  { type = "label", caption = math.round(global.team_nerf["north"]*100,1) .. " "}
		l.style.minimal_width = 40
		l.style.font_color = {r = 0.66, g = 0.66, b = 0.99}
		l.style.font = "default-bold"		
		local l = t.add  { type = "label", caption = " Biter Rage: "}
		l.style.minimal_width = 25
		l.tooltip = "Increases damage and the amount of angry biters."
		local l = t.add  { type = "label", caption = math.round(global.biter_rage["north"],0)}	
		l.style.font_color = {r = 0.66, g = 0.66, b = 0.99}
		l.style.font = "default-bold"
		l.style.minimal_width = 25
	end
	
	if player.force.name == "player" then
		local c = "JOIN NORTH"		
		local font_color =  {r = 0.55, g = 0.55, b = 0.99}
		if global.game_lobby_active then
			font_color = { r=0.7, g=0.7, b=0.7}
			c = c .. " (waiting for players...  "
			c = c .. math.round((global.game_lobby_timeout - game.tick)/60,0)
			c = c .. ")"										
		end		
		local t = frame.add  { type = "table", column_count = 4 }	
		for _, p in pairs(game.forces.north.connected_players) do			
			local color = {}
			color = p.color
			color.r = color.r * 0.6 + 0.4
			color.g = color.g * 0.6 + 0.4
			color.b = color.b * 0.6 + 0.4
			color.a = 1
			local l = t.add  { type = "label", caption = p.name }
			l.style.font_color = color
		end		
		local b = frame.add  { type = "sprite-button", name = "join_north_button", caption = c }
		b.style.font = "default-large-bold"
		b.style.font_color = font_color
		b.style.minimal_width = 350	
		frame.add  { type = "label", caption = "-----------------------------------------------------------"}
	else 
		frame.add  { type = "label", caption = "--------------------------"}
	end		
			
	local t = frame.add { type = "table", column_count = 3 }	
	local l = t.add  { type = "label", caption = "Team South"}
	l.style.font = "default-bold"
	l.style.font_color = {r = 0.99, g = 0.33, b = 0.33}
	local l = t.add  { type = "label", caption = "  -  "}
	local l = t.add  { type = "label", caption = #game.forces["south"].connected_players .. " Players "}
	l.style.font_color = { r=0.22, g=0.88, b=0.22}
	
	if player.force.name ~= "player" then
		
		if global.biter_battle_view_players[player.name] == true then
			local t = frame.add  { type = "table", column_count = 4 }	
			for _, p in pairs(game.forces.south.connected_players) do
				local color = {}
				color = p.color
				color.r = color.r * 0.6 + 0.4
				color.g = color.g * 0.6 + 0.4
				color.b = color.b * 0.6 + 0.4
				color.a = 1
				local l = t.add  { type = "label", caption = p.name }
				l.style.font_color = color
			end		
		end
		
		local t = frame.add { type = "table", column_count = 4 }			
		local l = t.add  { type = "label", caption = "Nerf: "}
		l.tooltip = "Damage nerf of the team."
		l.style.minimal_width = 25
		local l = t.add  { type = "label", caption = math.round(global.team_nerf["south"]*100,1) .. " "}
		l.style.minimal_width = 40
		l.style.font_color = {r = 0.99, g = 0.44, b = 0.44}
		l.style.font = "default-bold"		
		local l = t.add  { type = "label", caption = " Biter Rage: "}
		l.style.minimal_width = 25
		l.tooltip = "Increases damage and the amount of angry biters."
		local l = t.add  { type = "label", caption = math.round(global.biter_rage["south"],0)}	
		l.style.font_color = {r = 0.99, g = 0.44, b = 0.44}
		l.style.font = "default-bold"
		l.style.minimal_width = 25
	end
	
	if player.force.name == "player" then
		local c = "JOIN SOUTH"		
		local font_color = {r = 0.99, g = 0.33, b = 0.33}
		if global.game_lobby_active then
			font_color = { r=0.7, g=0.7, b=0.7}
			c = c .. " (waiting for players...  "
			c = c .. math.round((global.game_lobby_timeout - game.tick)/60,0)
			c = c .. ")"										
		end		
		local t = frame.add  { type = "table", column_count = 4 }	
		for _, p in pairs(game.forces.south.connected_players) do
			local color = {}
			color = p.color
			color.r = color.r * 0.6 + 0.4
			color.g = color.g * 0.6 + 0.4
			color.b = color.b * 0.6 + 0.4
			color.a = 1
			local l = t.add  { type = "label", caption = p.name }
			l.style.font_color = color
		end		
		local b = frame.add  { type = "sprite-button", name = "join_south_button", caption = c }
		b.style.font = "default-large-bold"
		b.style.font_color = font_color
		b.style.minimal_width = 350			
	end	
	
	if global.team_chosen[player.name] then
		local t = frame.add  { type = "table", column_count = 2 }
		if player.force.name == "spectator" then
			local b = t.add  { type = "sprite-button", name = "biter_battle_leave_spectate", caption = "Join Team" }
		else
			local b = t.add  { type = "sprite-button", name = "biter_battle_spectate", caption = "Spectate" }
		end
		
		if global.biter_battle_view_players[player.name] == true then
			local b = t.add  { type = "sprite-button", name = "biter_battle_hide_players", caption = "Playerlist" }
		else
			local b = t.add  { type = "sprite-button", name = "biter_battle_view_players", caption = "Playerlist" }						
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
end

local function refresh_gui()
	for _, player in pairs(game.connected_players) do
		local frame = player.gui.left["biter_battle_menu"]
		if (frame) then
			frame.destroy()
			create_biter_battle_menu(player)					
		end
	end
end

local function join_team(player, team)
	local surface = game.surfaces["surface"]
	local enemy_team = "south"
	if team == "south" then enemy_team = "north" end
	
	if team == "north" or team == "south" then
		if #game.forces[team].connected_players > #game.forces[enemy_team].connected_players and global.team_chosen[player.name] == nil then
			player.print("Team " .. team .. " has too many players currently.", { r=0.98, g=0.66, b=0.22})
		else						 
			player.teleport(surface.find_non_colliding_position("character", game.forces[team].get_spawn_position(surface), 3, 1))	
			player.force=game.forces[team]			
			if global.team_chosen[player.name] then
				local p = game.permissions.get_group("Default")	
				p.add_player(player.name)
				game.print("Team " .. player.force.name .. " player " .. player.name .. " is no longer spectating.", { r=0.98, g=0.66, b=0.22})
			else
				game.print(player.name .. " has joined team " .. player.force.name .. "!", { r=0.98, g=0.66, b=0.22})
				local i = player.get_inventory(defines.inventory.character_main)
				player.insert {name = 'pistol', count = 1}
				player.insert {name = 'raw-fish', count = 3}
				player.insert {name = 'firearm-magazine', count = 16}		
				player.insert {name = 'iron-gear-wheel', count = 4}
				player.insert {name = 'iron-plate', count = 8}
				global.team_chosen[player.name] = team
			end			
		end				
	end		
			
	if team == "spectator" then
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 2, 1))	
		player.force=game.forces[team]
		game.print(player.name .. " is spectating.", { r=0.98, g=0.66, b=0.22})		
		local permission_group = game.permissions.get_group("spectator")		
		if not permission_group then
			permission_group = game.permissions.create_group("spectator")
			for action_name, _ in pairs(defines.input_action) do
				permission_group.set_allows_action(defines.input_action[action_name], false)
			end
			permission_group.set_allows_action(defines.input_action.write_to_console, true)
			permission_group.set_allows_action(defines.input_action.gui_click, true)
			permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
			permission_group.set_allows_action(defines.input_action.start_walking, true)
			permission_group.set_allows_action(defines.input_action.open_kills_gui, true)
			permission_group.set_allows_action(defines.input_action.open_character_gui, true)
			--permission_group.set_allows_action(defines.input_action.open_equipment_gui, true)
			permission_group.set_allows_action(defines.input_action.edit_permission_group, true)	
			permission_group.set_allows_action(defines.input_action.toggle_show_entity_info, true)				
		end
		permission_group.add_player(player.name)
		global.spectator_spam_protection[player.name] = game.tick
	end
	refresh_gui()
end

local function reveal_team(f)
	local m = 32
	if f == "north" then
		game.forces["south"].chart(game.surfaces["surface"], {{x = global.force_area[f].x_top-m, y = global.force_area[f].y_top-m}, {x = global.force_area[f].x_bot+m, y = global.force_area[f].y_bot+m}})
	else
		game.forces["north"].chart(game.surfaces["surface"], {{x = global.force_area[f].x_top-m, y = global.force_area[f].y_top-m}, {x = global.force_area[f].x_bot+m, y = global.force_area[f].y_bot+m}})
	end	
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]	
	if not global.horizontal_border_width then global.horizontal_border_width = 16 end		
	if not global.biter_battles_init_done then		
		local map_gen_settings = {}
		map_gen_settings.water = "none"
		map_gen_settings.starting_area = "5"	
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 12, cliff_elevation_0 = 32}		
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "0.8", size = "1", richness = "0.3"},
			["stone"] = {frequency = "0.8", size = "1", richness = "0.3"},
			["copper-ore"] = {frequency = "0.8", size = "2", richness = "0.3"},
			["iron-ore"] = {frequency = "0.8", size = "2", richness = "0.3"},
			["crude-oil"] = {frequency = "0.8", size = "2", richness = "0.4"},
			["trees"] = {frequency = "0.8", size = "0.5", richness = "0.3"},
			["enemy-base"] = {frequency = "0.8", size = "1", richness = "0.4"}			
		}
		game.create_surface("surface", map_gen_settings)
		
		game.map_settings.enemy_evolution.time_factor = 0.000004
		game.map_settings.enemy_evolution.destroy_factor = 0.0035
		game.map_settings.enemy_evolution.pollution_factor = 0.0000025
		game.map_settings.enemy_expansion.enabled = true		
		game.map_settings.enemy_expansion.min_expansion_cooldown = 18000
		game.map_settings.enemy_expansion.max_expansion_cooldown = 72000
			
		local surface = game.surfaces["surface"]		
		game.create_force("north")		
		game.create_force("south")		
		game.create_force("spectator")
		--game.create_force("map_pregen")
		global.game_lobby_active = true
		global.game_lobby_timeout = 599940
		global.biter_battle_view_players = {}	
		global.spectator_spam_protection = {}
		global.force_area = {}
		
		global.team_chosen = {}
		global.team_nerf = {}
		global.biter_rage = {}
		global.spy_fish_timeout = {}
		
		local force_names = {"north", "south"}
		for _, name in pairs(force_names) do
			game.forces[name].technologies["artillery"].enabled = false
			game.forces[name].technologies["artillery-shell-range-1"].enabled = false					
			game.forces[name].technologies["artillery-shell-speed-1"].enabled = false	
			--game.forces[name].technologies["refined-flammables-1"].enabled = false	
			--game.forces[name].technologies["refined-flammables-2"].enabled = false
			--game.forces[name].technologies["refined-flammables-3"].enabled = false
			game.forces[name].technologies["refined-flammables-4"].enabled = false
			game.forces[name].technologies["refined-flammables-5"].enabled = false
			game.forces[name].technologies["refined-flammables-6"].enabled = false
			game.forces[name].technologies["refined-flammables-7"].enabled = false
			game.forces[name].technologies["atomic-bomb"].enabled = false

			global.team_nerf[name] = 0
			global.biter_rage[name] = 0
			
			game.forces[name].set_turret_attack_modifier("flamethrower-turret", -0.5)
			--game.forces[name].set_ammo_damage_modifier("artillery-shell", -0.95)			
			game.forces[name].set_ammo_damage_modifier("shotgun-shell", 0.5)
			
			game.forces[name].research_queue_enabled = true
		end
						
		game.forces["spectator"].technologies["toolbelt"].researched=true
		
		local f = game.forces['north']
		f.set_cease_fire('player', true)
		f.set_friend('spectator', true)
		f.share_chart = true		
		f.set_spawn_position({0,-26},surface)
		local f = game.forces['south']
		f.set_cease_fire('player', true)	
		f.set_friend('spectator', true)
		f.share_chart = true
		f.set_spawn_position({0,26},surface)		
		local f = game.forces['spectator']		 
		f.set_spawn_position({0,0},surface)
		f.set_friend('north', true)
		f.set_friend('south', true)
		local f = game.forces['player']
		f.set_spawn_position({0,0},surface)
		
		global.biter_battles_init_done = true				
	end		
	if global.game_lobby_active then
		if #game.connected_players > 1 then global.game_lobby_timeout = game.tick + 7200 end
	end
		
	if player.online_time < 5 and game.surfaces["surface"].is_chunk_generated({0,0}) then 
		player.teleport(game.surfaces["surface"].find_non_colliding_position("character", {0,0}, 2, 1), "surface")
	else
		if not global.team_chosen[player.name] then player.teleport({0,0}, "surface") end
	end
	
	global.biter_battle_view_players[player.name] = false
	create_biter_battle_sprite_button(player)
	create_biter_battle_menu(player)
	refresh_gui()	
end

local function on_player_created(event)
	refresh_gui()
end

local function on_player_left_game(event)
	if game.connected_players == 1 and global.game_lobby_active == true then
		global.game_lobby_timeout = game.tick + 599940
	end
	refresh_gui()
end

local function spy_fish(player)
	local duration_per_unit = 1800 
	local i2 = player.get_inventory(defines.inventory.character_main)
	local owned_fishes = i2.get_item_count("raw-fish")
	owned_fishes = owned_fishes + i2.get_item_count("raw-fish")
	if owned_fishes == 0 then 
		player.print("You have no fish in your inventory.",{ r=0.98, g=0.66, b=0.22})
	else
		local x = i2.remove({name="raw-fish", count=1})
		if x == 0 then i2.remove({name="raw-fish", count=1}) end
		local enemy_team = "south"
		if player.force.name == "south" then enemy_team = "north" end													 
		if global.spy_fish_timeout[player.force.name] then 
			global.spy_fish_timeout[player.force.name] = global.spy_fish_timeout[player.force.name] + duration_per_unit
			player.print(math.round((global.spy_fish_timeout[player.force.name] - game.tick)/60, 0) .. " seconds of enemy vision left.",{ r=0.98, g=0.66, b=0.22})
		else
			get_border_cords(enemy_team)
			game.print(player.name .. " sent a fish to spy on " .. enemy_team .. " team!",{ r=0.98, g=0.66, b=0.22})			
			global.spy_fish_timeout[player.force.name] = game.tick + duration_per_unit							
		end		
	end
end

local function feed_the_biters(food_type,player)
	if player.force.name == "player" then return end
	if player.force.name == "spectator" then return end
	
	local surface = game.surfaces["surface"]
	local enemy_team = ""
	if player.force.name == "south" then enemy_team = "north" end
	if player.force.name == "north" then enemy_team = "south" end
	
	local i = player.get_main_inventory() 
	local food_amount = i.remove(food_type)
	while i.get_item_count(food_type) ~= 0 do
		food_amount = food_amount + i.remove(food_type)
	end
	
	if food_amount == 0 then
		local str = "You have no " .. food_names[food_type]
		str = str ..  " flask in your inventory."
		player.print(str,{ r=0.98, g=0.66, b=0.22})
	else				
		if food_amount >= 20 then
			local str = player.name .. " fed "
			str = str .. food_amount
			str = str .. " flasks of "
			str = str .. food_names[food_type]			 
			str = str .. " juice to team "
			str = str .. enemy_team
			str = str .. "´s biters!"						
			game.print(str, { r=0.98, g=0.66, b=0.22})
		else
			local str = "You fed "
			str = str .. food_amount
			str = str .. " flask"
			if food_amount > 1 then str = str .. "s" end
			str = str .. " of "
			str = str .. food_names[food_type]						
			str = str .. " juice to the enemy team´s biters."
			player.print(str, { r=0.98, g=0.66, b=0.22})			
		end					
	end		
	
	local nerf_gain = 0
	local rage_gain = 0
	if food_amount > 0 then
		nerf_gain = food_values[food_type] * food_amount
		
		--change these two numbers to your liking nerf and rage
		local nerf_multiplier = 1
		local rage_food_value = food_values[food_type] * 12500000  --10000000
		--biter rage calculation
		for x = 0, food_amount, 1 do			
			local rage_diminish_multiplier = 1/(((global.biter_rage[enemy_team]^2.9)+8000)/500)
			global.biter_rage[enemy_team] = global.biter_rage[enemy_team] + (rage_food_value*rage_diminish_multiplier)
		end
						
		global.team_nerf[enemy_team] = global.team_nerf[enemy_team] + (nerf_gain*nerf_multiplier)
								
		local lowest_possible_modifier = -0.95
		
		local ammo_types = 		{"grenade", 	"bullet",	"artillery-shell",		"flamethrower",	"cannon-shell",	"shotgun-shell","rocket",	"electric",	"laser-turret"}
		local ammo_modifier = 	{0.2, 			0.8,				0,						0.8,					0.2,					0.2,					0.2,			0.2,			1.5}
		local turret_types = 		{"flamethrower-turret", 	"gun-turret"}		
		local turret_modifier = 	{1, 								0.8}		
		local ammo_speed = 				{"bullet",	"cannon-shell",	"shotgun-shell",		"rocket",	"laser-turret"	}
		local ammo_speed_modifier = 	{0.3, 		0.3,					0.3,						0.3,			0.3,				}		
		
		-------------
		local f = game.forces[enemy_team]		
		-----------                   -!!!!!--------------
		local m = nerf_gain		
		
		local x = 1
		for _, w in pairs(ammo_types) do			
			if f.get_ammo_damage_modifier(w) - (nerf_gain * ammo_modifier[x]) < lowest_possible_modifier then
				m = lowest_possible_modifier
			else
				m = f.get_ammo_damage_modifier(w) - (nerf_gain * ammo_modifier[x])
			end
			f.set_ammo_damage_modifier(w, m)	
			x = x + 1
		end	
		
		local x = 1
		for _, w in pairs(turret_types) do			
			if f.get_turret_attack_modifier(w) - (nerf_gain * ammo_modifier[x]) < lowest_possible_modifier then
				m = lowest_possible_modifier
			else
				m = f.get_turret_attack_modifier(w) - (nerf_gain * turret_modifier[x])				
			end
			f.set_turret_attack_modifier(w, m)	
			x = x + 1
		end

		local x = 1
		for _, w in pairs(ammo_speed) do			
			if f.get_gun_speed_modifier(w) - (nerf_gain * ammo_speed_modifier[x]) < lowest_possible_modifier then
				m = lowest_possible_modifier
			else
				m = f.get_gun_speed_modifier(w) - (nerf_gain * ammo_speed_modifier[x])
			end
			f.set_gun_speed_modifier(w, m)	
			x = x + 1
		end	
		
		refresh_gui()		
	end	
end

local function on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
	local player = game.players[event.element.player_index]
	local name = event.element.name
	if (name == "biter_battle_toggle_menu_button") then
		local frame = player.gui.left["biter_battle_menu"]
		if (frame) then
			frame.destroy()
		else
			create_biter_battle_menu(player)
		end
	end
	if (name == "automation-science-pack") then feed_the_biters(name,player) end
	if (name == "logistic-science-pack") then feed_the_biters(name,player) end	
	if (name == "military-science-pack") then feed_the_biters(name,player) end
	if (name == "chemical-science-pack") then feed_the_biters(name,player) end
	if (name == "production-science-pack") then feed_the_biters(name,player) end
	if (name == "utility-science-pack") then feed_the_biters(name,player) end
	if (name == "space-science-pack") then feed_the_biters(name,player) end
	if (name == "raw-fish") then spy_fish(player) end
	if (name == "biter_battle_spectate") then
		if player.position.y < 100 and player.position.y > -100 and player.position.x < 100 and player.position.x > -100 then
			join_team(player, "spectator") 
		else
			player.print("You are too far away from spawn to spectate.",{ r=0.98, g=0.66, b=0.22})
		end
	end	
	if (name == "biter_battle_leave_spectate") and game.tick - global.spectator_spam_protection[player.name] > 1800 then join_team(player, global.team_chosen[player.name]) end
	if (name == "biter_battle_leave_spectate") and game.tick - global.spectator_spam_protection[player.name] < 1800 then player.print("Not ready to return to your team yet. Please wait " .. 30-(math.round((game.tick - global.spectator_spam_protection[player.name])/60,0)) .. " seconds.", { r=0.98, g=0.66, b=0.22}) end
	
	if (name == "biter_battle_hide_players") then
		global.biter_battle_view_players[player.name] = false
		refresh_gui()
	end
	if (name == "biter_battle_view_players") then
		global.biter_battle_view_players[player.name] = true 
		refresh_gui() 
	end
	
	if not global.terrain_init_done then player.print("Waiting for spawn to generate.", { r=0.98, g=0.66, b=0.22}) return end
	
	if (name == "join_north_button") and global.game_lobby_active == false then join_team(player, "north") end	
	if (name == "join_south_button") and global.game_lobby_active == false then join_team(player, "south") end
	if (name == "join_north_button") and global.game_lobby_active == true then player.print("Waiting for more players to join the game.", { r=0.98, g=0.66, b=0.22}) end
	if (name == "join_south_button") and global.game_lobby_active == true then player.print("Waiting for more players to join the game.", { r=0.98, g=0.66, b=0.22}) end
	if (name == "join_north_button") and global.game_lobby_active == true and player.admin == true then
		join_team(player, "north")
		game.print("Lobby disabled, admin override.", { r=0.98, g=0.66, b=0.22})
		global.game_lobby_active = false
	end
	if (name == "join_south_button") and global.game_lobby_active == true and player.admin == true then
		join_team(player, "south") 
		game.print("Lobby disabled, admin override.", { r=0.98, g=0.66, b=0.22})
		global.game_lobby_active = false
	end
end

local function create_fireworks_rocket(surface, position)
	local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
	local particle = particles[math_random(1, #particles)]
	local m = math_random(16, 36)
	local m2 = m * 0.005
				
	for i = 1, 80, 1 do 
		surface.create_entity({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end
	
	if math_random(1,16) ~= 1 then return end
	surface.create_entity({name = "explosion", position = position})
end

local function on_entity_died(event)
	if not global.rocket_silo_destroyed then 
		if event.entity == global.rocket_silo["south"] or event.entity == global.rocket_silo["north"] then 
		
			if event.entity == global.rocket_silo["south"] then
				global.rocket_silo_destroyed = "North Team Won!"
			else
				global.rocket_silo_destroyed = "South Team Won!"
			end		
			
			for _, player in pairs(game.connected_players) do
				player.play_sound{path="utility/game_won", volume_modifier=1}
			end
			
			--fireworks
			local radius = 96
			for t = 1, 18000, 1 do
				if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
				for x = 1, 4, 1 do
					global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
						func = create_fireworks_rocket,
						args = {event.entity.surface, {x = radius - math_random(0, radius * 2),y = radius - math_random(0, radius * 2)}}
					}								
				end
				t = t + 1
			end	
			
			refresh_gui()
		end
	end							
end

local function get_valid_biters(requested_amount, y_modifier, pos_x, pos_y, radius_inc)
	if not requested_amount then return end
	if not y_modifier then return end
	if not pos_x then pos_x = 0 end
	if not pos_y then pos_y = 150*y_modifier end
	local surface = game.surfaces["surface"]
	local biters_found = {}
	local valid_biters = {}
	if not radius_inc then radius_inc = 100 end
	
	for radius = radius_inc,2000,radius_inc do
		biters_found = surface.find_enemy_units({pos_x,pos_y}, radius, "player")
		local x = 1
		if y_modifier == -1 then		
			for _, biter in pairs(biters_found) do 
				if biter.position.y < 0 then
					valid_biters[x] = biter
					x = x + 1
				end
			end	
		else
			for _, biter in pairs(biters_found) do 
				if biter.position.y > 0 then
					valid_biters[x] = biter
					x = x + 1
				end
			end
		end
		if #valid_biters >= requested_amount or radius == 2000 then
			--game.print("seach radius:" .. radius .. " valid biters: " .. #valid_biters)
			break
		else			
			valid_biters = {}
		end
	end
	radius_inc = nil
	pos_x = nil
	pos_y = nil
	return valid_biters
end

local function biter_attack_silo(team, requested_amount, mode)	
	if not requested_amount then return end
	if not team then return end
	local surface = game.surfaces["surface"]
		
	local y_modifier = 1
	if team == "south" then y_modifier = 1 end
	if team == "north" then y_modifier = -1 end
	
	local biters_selected_for_attack = {}
	
	if not mode then
		--local modes = {"spread", "ball", "line"}
		local modes = {"spread", "ball"}
		mode = modes[math_random(1, #modes)]
	end
	
	if mode == "spread" then	
		local valid_biters = get_valid_biters(requested_amount, y_modifier, 0, 150*y_modifier, 500)	
		if #valid_biters < requested_amount then
			valid_biters = get_valid_biters(requested_amount, y_modifier, 0, 1500*y_modifier, 500)
		end
	
		local f = math.floor(#valid_biters/requested_amount,0)
		if f < 1 then f = 1 end
		local x = 0
		for y = f,#valid_biters,f do
			x = x + 1
			if not valid_biters[y] then break end
			if #biters_selected_for_attack >= requested_amount then break end
			biters_selected_for_attack[x] = valid_biters[y]			
		end

		if math_random(1,6) == 1 then
			for _, biter in pairs(biters_selected_for_attack) do		
				biter.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_anything})	
			end					
		else
			for _, biter in pairs(biters_selected_for_attack) do		
				biter.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_enemy})	
			end				
		end
		if global.biter_battles_debug then
			game.players[1].print(#valid_biters .. " valid biters found.")
			game.players[1].print(#biters_selected_for_attack .. " biter going for a spread attack")					
		end
	end
	
	--[[
	if mode == "line" then
		local valid_biters = get_valid_biters(requested_amount, y_modifier, 0, 150*y_modifier, 500)	
		if #valid_biters < requested_amount then
			valid_biters = get_valid_biters(requested_amount, y_modifier, 0, 1500*y_modifier, 500)
		end	
	
		local array_start = 1
		local f = math.floor(#valid_biters/requested_amount,0)
		if f >= 2 then
			array_start = requested_amount * math_random(1,f-1)
			if math_random(1,f) == 1 then array_start = 1 end
		end		
		local x = 0
		for y = array_start,#valid_biters,1 do
			x = x + 1
			if not valid_biters[y] then break end
			if #biters_selected_for_attack >= requested_amount then break end
			biters_selected_for_attack[x] = valid_biters[y]			
		end
		
		if math_random(1,3) == 1 then
			for _, biter in pairs(biters_selected_for_attack) do		
				biter.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_anything})	
			end					
		else
			for _, biter in pairs(biters_selected_for_attack) do		
				biter.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_enemy})	
			end				
		end
		
		if global.biter_battles_debug then
			game.players[1].print(#valid_biters .. " valid biters found.")
			game.players[1].print(#biters_selected_for_attack .. " going for a line attack, table start = " .. array_start)					
		end
	end	
	]]
	
	if mode == "ball" then			
		local height = 0
		local width = 0
		local c = 0
		local tolerance = 5
		local distance_to_base_modifier = 2.6
		local additional_empty_space_checks = 4		
		local additional_checks = additional_empty_space_checks
		local gathering_point_x = 0
		local gathering_point_y = 0		
		local r = math_random(1,3) --pick a random side
		if r == 1 or r == 2 then
			--- determine base height	
			for pos_y = 0, 8192*y_modifier, 32*y_modifier do
				if y_modifier == -1 then
					c = surface.count_entities_filtered{area={{-1024,pos_y-32},{1024,pos_y}},force=team}
				else
					c = surface.count_entities_filtered{area={{-1024,pos_y},{1024,pos_y+32}},force=team}
				end			
				if c <= tolerance then
					additional_checks = additional_checks - 1
					if additional_checks == 0 then
						height = pos_y - (32*(additional_empty_space_checks)*y_modifier) + (32*y_modifier)
						break
					end
				else
					additional_checks = additional_empty_space_checks
				end			
			end
			
			if height ~= 0 then
				if y_modifier == -1 then
					gathering_point_y = math_random(height, -32)
				else
					gathering_point_y = math_random(32, height)
				end
			else
				if y_modifier == -1 then
					gathering_point_y = math_random(-128, -32)
				else
					gathering_point_y = math_random(32, 128)
				end										
			end
			
			additional_empty_space_checks = 32			
			if r == 1 then
				--west attack									
				local additional_checks = additional_empty_space_checks
				for x = 0, -8192, -32 do				
					c = surface.count_entities_filtered{area={{x-32,gathering_point_y-48},{x,gathering_point_y+48}},force=team}											
					if c <= tolerance then
						additional_checks = additional_checks - 1
						if additional_checks == 0 then
							gathering_point_x = x + (32*(additional_empty_space_checks-distance_to_base_modifier))
							break
						end
					else
						additional_checks = additional_empty_space_checks
					end			
				end												
			end		
			
			if r == 2 then
				--east attack									
				local additional_checks = additional_empty_space_checks
				for x = 32, 8192, 32 do				
					c = surface.count_entities_filtered{area={{x-32,gathering_point_y-48},{x,gathering_point_y+48}},force=team}											
					if c <= tolerance then
						additional_checks = additional_checks - 1
						if additional_checks == 0 then
							gathering_point_x = x - (32*(additional_empty_space_checks-distance_to_base_modifier))
							break
						end
					else
						additional_checks = additional_empty_space_checks
					end			
				end												
			end		
		end
		
		--vertical attack	
		if r == 3 then
			--- determine base width
			additional_checks = additional_empty_space_checks
			local width_east = 0
			for pos_x = 32, 4096, 32 do
				if y_modifier == -1 then
					c = surface.count_entities_filtered{area={{pos_x - 32, -2048},{pos_x, 0}},force=team}
				else
					c = surface.count_entities_filtered{area={{pos_x - 32, 0},{pos_x, 2048}},force=team}
				end			
				if c <= tolerance then
					additional_checks = additional_checks - 1
					if additional_checks == 0 then
						width_east = pos_x - 32*additional_empty_space_checks
						break
					end
				else
					additional_checks = additional_empty_space_checks
				end			
			end
			
			additional_checks = additional_empty_space_checks
			local width_west = 0
			for pos_x = 0, -4096, -32 do
				if y_modifier == -1 then
					c = surface.count_entities_filtered{area={{pos_x - 32, -2048},{pos_x, 0}},force=team}
				else
					c = surface.count_entities_filtered{area={{pos_x - 32, 0},{pos_x, 2048}},force=team}
				end			
				if c <= tolerance then
					additional_checks = additional_checks - 1
					if additional_checks == 0 then
						width_west = (pos_x + 32*additional_empty_space_checks) - 32
						break
					end
				else
					additional_checks = additional_empty_space_checks
				end			
			end
			
			if width_west ~= 0 and width_east ~= 0 then
				gathering_point_x = math_random(width_west, width_east)
			else
				gathering_point_x = math_random(-64,64)
			end
			additional_empty_space_checks = 32			
			
			--vertical attack --
			local c = 0					
			local additional_checks = additional_empty_space_checks
			for pos_y = 0, 8192*y_modifier, 32*y_modifier do				
				c = surface.count_entities_filtered{area={{gathering_point_x-48, pos_y-32},{gathering_point_x+48, pos_y}},force=team}											
				if c <= tolerance then
					additional_checks = additional_checks - 1
					if additional_checks == 0 then
						gathering_point_y = pos_y - ((32*(additional_empty_space_checks-distance_to_base_modifier))*y_modifier)
						break
					end
				else
					additional_checks = additional_empty_space_checks
				end			
			end   												
		end	
		
		valid_biters = get_valid_biters(requested_amount, y_modifier, gathering_point_x, gathering_point_y)		
		
		local f = math.floor(#valid_biters/requested_amount,0)
		if f < 1 then f = 1 end
		local x = 0
		for y = f,#valid_biters,f do
			x = x + 1
			if not valid_biters[y] then break end
			if #biters_selected_for_attack >= requested_amount then break end
			biters_selected_for_attack[x] = valid_biters[y]			
		end
		
		--alternate attack if there is water
		local t = surface.count_tiles_filtered{area={{gathering_point_x - 8, gathering_point_y - 8}, {gathering_point_x + 8, gathering_point_y + 8}}, name={"deepwater","water", "water-green"}}
		if t > 8 then 
			if math_random(1,6) ~= 1 then
				for _, biter in pairs(biters_selected_for_attack) do		
					biter.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_enemy})	
				end					
			else
				for _, biter in pairs(biters_selected_for_attack) do		
					biter.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_anything})	
				end				
			end
			if global.biter_battles_debug then
				game.players[1].print("water found, doing alternate spread attack")					
			end
		else		
			local biter_attack_group = surface.create_unit_group({position={gathering_point_x,gathering_point_y}})
			for _, biter in pairs(biters_selected_for_attack) do		
				biter_attack_group.add_member(biter)
			end			
			biter_attack_group.set_command({type=defines.command.attack_area, destination=global.biter_attack_main_target[team], radius=12, distraction=defines.distraction.by_enemy})
			if global.biter_battles_debug then
				game.players[1].print(#valid_biters .. " valid biters found.")
				game.players[1].print(#biters_selected_for_attack .. " gathering at (x: " .. gathering_point_x .. "  y: " .. gathering_point_y .. ")")					
			end
		end			
	end															
	mode = nil
end

local function clear_corpses()
	for _, entity in pairs(game.surfaces["surface"].find_entities_filtered{type = "corpse"}) do
		if math_random(1, 3) == 1 then
			entity.destroy()
		end
	end
end

local function send_near_biter_to_silo()
	if not global.rocket_silo then return end
	game.surfaces["surface"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["north"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "enemy",
		unit_search_distance=64
		})
		
	game.surfaces["surface"].set_multi_command({
		command={
			type=defines.command.attack,
			target=global.rocket_silo["south"],
			distraction=defines.distraction.none
			},
		unit_count = 8,
		force = "enemy",
		unit_search_distance=64
		})
end

local function on_tick(event)	
	if global.rocket_silo_destroyed then
		if not global.game_restart_timeout then global.game_restart_timeout = 7200 end
		if not global.game_restart_timer_completed then			
			if game.tick % 900 == 0 then			
				if global.game_restart_timeout > 0 then
					game.print("Map will restart in " .. math.ceil(global.game_restart_timeout / 60) .. " seconds!",{ r=0.22, g=0.88, b=0.22})
				end
				global.game_restart_timeout = global.game_restart_timeout - 900
			end													
			if global.game_restart_timeout < 0 then
				global.game_restart_timer_completed = true
				game.print("Map is restarting!", { r=0.22, g=0.88, b=0.22})
				local message = 'Map is restarting! '
				Server.to_discord_bold(table.concat{'*** ', message, ' ***'})
				Server.start_scenario('Biter_Battles')
			end
		end
	end
	
	if global.spy_fish_timeout then
		if global.spy_fish_timeout["south"] then		
			if (global.spy_fish_timeout["south"] - game.tick) % 300 == 0 then
				reveal_team("north")						
			end	
			if game.tick - global.spy_fish_timeout["south"] > 0 then
				global.spy_fish_timeout["south"] = nil
			end
		end	
		if global.spy_fish_timeout["north"] then		
			if (global.spy_fish_timeout["north"] - game.tick) % 300 == 0 then
				reveal_team("south")						
			end	
			if game.tick - global.spy_fish_timeout["north"] > 0 then
				global.spy_fish_timeout["north"] = nil
			end
		end	
	end
	
	if game.tick % 12600 == 6300 then	
		clear_corpses()
		if global.biter_rage["north"] >= 1 then
			local c = math.round(global.biter_rage["north"], 0)
			if c > 999 then c = 999 end
			biter_attack_silo("north", c)			
		end				
		send_near_biter_to_silo()	
		refresh_gui()
		return
	end
	if game.tick % 12600 == 0 then
		if global.biter_rage["south"] >= 1 then
			local c = math.round(global.biter_rage["south"], 0)
			if c > 999 then c = 999 end
			biter_attack_silo("south", c)													
		end		
		send_near_biter_to_silo()				
		refresh_gui()
		return
	end
	
	if global.game_lobby_active then
		if game.tick % 60 == 0 then			
			if global.game_lobby_timeout-game.tick <= 0 then global.game_lobby_active = false end
			refresh_gui()
		end
	end
	--[[
	---creating a auto fire delay for south artillery---
	if global.spawn_artillery["south"] then
		if game.tick % 300 == 0 then
			local i = global.spawn_artillery["south"].get_inventory(defines.inventory.turret_ammo)						 
			if i.get_item_count("artillery-shell") == 0 then												
				global.spawn_artillery["south"].active = false
				global.spawn_artillery_south_activate = false
			else	
				if global.spawn_artillery_south_activate == true then
					global.spawn_artillery["south"].active = true
				end
				global.spawn_artillery_south_activate = true				
			end	
		end
	end]]--
end

local function on_chunk_generated(event)
	if global.terrain_init_done then return end
	
	local surface = game.surfaces["surface"]
	if event.surface ~= surface then return end
	
	if event.area.left_top.x > 128 then																							
		global.rocket_silo = {}
		global.rocket_silo["north"] = surface.create_entity {name="rocket-silo", position={0,(global.horizontal_border_width*3.8)*-1}, force="north"}
		global.rocket_silo["north"].minable=false		
		global.rocket_silo["south"] = surface.create_entity {name="rocket-silo", position={0,global.horizontal_border_width*3.8}, force="south"}
		global.rocket_silo["south"].minable=false
		
		global.biter_attack_main_target = {}
		global.biter_attack_main_target["north"] = global.rocket_silo["north"].position
		global.biter_attack_main_target["south"] = global.rocket_silo["south"].position
		
		biter_battles_terrain.clear_spawn_ores()
		biter_battles_terrain.generate_spawn_water_pond()
		biter_battles_terrain.generate_spawn_ores("windows")
		biter_battles_terrain.generate_market()
								
		--biter_battles_terrain.generate_artillery()	
						
		surface.regenerate_decorative()
		surface.regenerate_entity({"tree-01", "tree-02","tree-03","tree-04","tree-05","tree-06","tree-07","tree-08","tree-09","dead-dry-hairy-tree","dead-grey-trunk","dead-tree-desert","dry-hairy-tree","dry-tree","rock-big","rock-huge"})
		--surface.regenerate_entity({"dead-dry-hairy-tree","dead-grey-trunk","dead-tree-desert","dry-hairy-tree","dry-tree","rock-big","rock-huge"})
		local entities = surface.find_entities({{-10,-10},{10,10}})			
		for _, e in pairs(entities) do
			if e.type == "simple-entity" or e.type == "resource" or e.type == "tree" then e.destroy()	end
		end			
		surface.destroy_decoratives({area = {{-10,-10},{10,10}}})
		
		game.print("Spawn generation done!", { r=0.22, g=0.99, b=0.99})
			
		global.terrain_init_done = true
	end
end

----------share chat with player and spectator force-------------------
local function on_console_chat(event)
	if not event.message then return end	
	if not event.player_index then return end	
	local player = game.players[event.player_index] 
	
	local color = {}
	color = player.color
	color.r = color.r * 0.6 + 0.35
	color.g = color.g * 0.6 + 0.35
	color.b = color.b * 0.6 + 0.35
	color.a = 1	
	
	if player.force.name == "north" then
		game.forces.spectator.print(player.name .. " (north): ".. event.message, color)
		game.forces.player.print(player.name .. " (north): ".. event.message, color)			
	end
	if player.force.name == "south" then
		game.forces.spectator.print(player.name .. " (south): ".. event.message, color)
		game.forces.player.print(player.name .. " (south): ".. event.message, color)
	end
	if player.force.name == "player" then
		game.forces.north.print(player.name .. " (spawn): ".. event.message, color)
		game.forces.south.print(player.name .. " (spawn): ".. event.message, color)
		game.forces.spectator.print(player.name .. " (spawn): ".. event.message, color)
	end
	if player.force.name == "spectator" then
		game.forces.north.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.south.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.player.print(player.name .. " (spectator): ".. event.message, color)
	end
end
--------------------------------------

local function on_entity_damaged(event)
	
	--[[
	--flamethrower turret nerf
	if event.cause then
		if event.cause.name == "flamethrower-turret" and event.entity.force.name == "enemy" then
			for i = 1, 2, 1 do
				if event.cause.fluidbox[i] then					
					if event.cause.fluidbox[i].amount > 0.1 then
						local fluid_name = event.cause.fluidbox[i].name
						local new_amount = event.cause.fluidbox[i].amount - 0.25
						if new_amount < 0 then new_amount = 0 end
						event.cause.fluidbox[i] = {name = fluid_name, amount = new_amount}
					end
				end
			end
		end
	end]]

	--Biter rage damage modifier
	if event.force.name == "enemy" then
		if event.entity.force.name == "north" then 			
			local additional_damage = event.final_damage_amount  * math.round((global.biter_rage["north"]/3)/100, 2)
			event.entity.health = event.entity.health - additional_damage
			return					
		end
		if event.entity.force.name == "south" then 		
			local additional_damage = event.final_damage_amount  * math.round((global.biter_rage["south"]/3)/100, 2)
			event.entity.health = event.entity.health - additional_damage
			return					
		end
	end
	
	if event.entity.force.name == "spectator" then 					
		event.entity.health = event.entity.health + event.final_damage_amount		
		return
	end

	--Silo grief prevention
	if event.entity == global.rocket_silo["north"] then
		if event.force.name == "north" then 
			global.rocket_silo["north"].health = global.rocket_silo["north"].health + event.final_damage_amount
			return
		end		
	end
	if event.entity == global.rocket_silo["south"] then
		if event.force.name == "south" then 
			global.rocket_silo["south"].health = global.rocket_silo["south"].health + event.final_damage_amount
			return
		end		
	end

	--Biter spawner damage reduction
	if event.entity.name == "biter-spawner" or event.entity.name == "spitter-spawner" then
		if event.entity.health - event.final_damage_amount <= 0 then event.entity.die(event.force.name) end
		event.entity.health = event.entity.health + event.final_damage_amount * (game.forces["enemy"].evolution_factor * 0.8)		
		return
	end		
end

--anti construction robot cheese
local function on_robot_built_entity(event)	
	if event.robot.force.name == "north" then
		if event.created_entity.position.y >= -1*global.horizontal_border_width/2 then
			local x = event.created_entity.position.x
			local y = event.created_entity.position.y			
			event.created_entity.die("south")
			search_for_ghost = game.surfaces["surface"].find_entities({{x, y}, {x+1, y+1}})
			for _, e in pairs(search_for_ghost) do
				if e.type == "entity-ghost" then e.time_to_live = 1 end				
			end			
			event.robot.die("south")			
			game.print("Team north´s drone had an accident.",{ r=0.98, g=0.66, b=0.22})
		end		
	end
	if event.robot.force.name == "south" then
		if event.created_entity.position.y <= global.horizontal_border_width/2 then
			local x = event.created_entity.position.x
			local y = event.created_entity.position.y			
			event.created_entity.die("north")
			search_for_ghost = game.surfaces["surface"].find_entities({{x, y}, {x+1, y+1}})
			for _, e in pairs(search_for_ghost) do
				if e.type == "entity-ghost" then e.time_to_live = 1 end				
			end			
			event.robot.die("north")			
			game.print("Team south´s drone had an accident.",{ r=0.98, g=0.66, b=0.22})
		end		
	end
end

local function on_marked_for_deconstruction(event)
	if event.entity.name == "fish" then event.entity.cancel_deconstruction(game.players[event.player_index].force.name) end
end

local function on_rocket_launched(event)
	local team = " "
	if event.rocket_silo.force.name == "south" then
		team = "north"
	end
	if event.rocket_silo.force.name == "north" then
		team = "south"
	end	
	biter_attack_silo(team,250,"ball")
	biter_attack_silo(team,250,"ball")
	biter_attack_silo(team,250,"ball")	
	local str = "A rocket launch scared the biters and triggered a huge attack on team "
	str = str .. team
	str = str .. "´s silo!!"
	game.print(str,{ r=0.98, g=0.01, b=0.01})	
end

local function on_player_built_tile(event)
	local placed_tiles = event.tiles
	local player = game.players[event.player_index]	
	for _, t in pairs(placed_tiles) do			
		if t.old_tile.name == "deepwater" and t.position.y <= global.horizontal_border_width*2 and t.position.y >= global.horizontal_border_width*-1*2 then
			local str = "Team " .. player.force.name
			str = str .. "´s landfill vanished into the depths of the marianna trench."
			game.print(str,{ r=0.98, g=0.66, b=0.22})
			local tiles = {}
			table.insert(tiles, {name = "deepwater", position = t.position})														
			game.surfaces["surface"].set_tiles(tiles,true)
		end				
	end		
end

local function on_robot_built_tile(event)
	local surface = event.robot.surface
	for _, t in pairs(event.tiles) do
		if t.old_tile.name == "deepwater" and t.position.y <= global.horizontal_border_width*2 and t.position.y >= global.horizontal_border_width*-1*2 then
			local str = "Team " .. event.robot.force.name
			str = str .. "´s landfill vanished into the depths of the marianna trench."
			game.print(str,{ r=0.98, g=0.66, b=0.22})
			local tiles = {}
			table.insert(tiles, {name = "deepwater", position = t.position})														
			surface.set_tiles(tiles,true)
		end
	end
end

local function on_research_finished(event)	
	--game.forces.north.recipes["flamethrower-turret"].enabled = false
	--game.forces.south.recipes["flamethrower-turret"].enabled = false
end

event.add(defines.events.on_robot_built_tile, on_robot_built_tile)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_player_built_tile, on_player_built_tile)
event.add(defines.events.on_rocket_launched, on_rocket_launched)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_entity_died, on_entity_died)	
event.add(defines.events.on_tick, on_tick)	
event.add(defines.events.on_player_created, on_player_created)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_console_chat, on_console_chat)
