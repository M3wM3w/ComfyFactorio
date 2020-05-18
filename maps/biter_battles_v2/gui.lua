local Public = {}
local Server = require 'utils.server'

local bb_config = require "maps.biter_battles_v2.config"
local event = require 'utils.event'
local Functions = require "maps.biter_battles_v2.functions"
local feed_the_biters = require "maps.biter_battles_v2.feeding"
local Tables = require "maps.biter_battles_v2.tables"

local wait_messages = Tables.wait_messages
local food_names = Tables.gui_foods

local math_random = math.random

require "maps.biter_battles_v2.spec_spy"

local gui_values = {
		["north"] = {force = "north", biter_force = "north_biters", c1 = bb_config.north_side_team_name, c2 = "JOIN ", n1 = "join_north_button",
		t1 = "Evolution of north side biters.",
		t2 = "Threat causes biters to attack. Reduces when biters are slain.", color1 = {r = 0.55, g = 0.55, b = 0.99}, color2 = {r = 0.66, g = 0.66, b = 0.99},
		tech_spy = "spy-north-tech", prod_spy = "spy-north-prod"},
		["south"] = {force = "south", biter_force = "south_biters", c1 = bb_config.south_side_team_name, c2 = "JOIN ", n1 = "join_south_button",
		t1 = "Evolution of south side biters.",
		t2 = "Threat causes biters to attack. Reduces when biters are slain.", color1 = {r = 0.99, g = 0.33, b = 0.33}, color2 = {r = 0.99, g = 0.44, b = 0.44},
		tech_spy = "spy-south-tech", prod_spy = "spy-south-prod"}
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

local function add_tech_button(elem, gui_value)
	local tech_button = elem.add {
		type = "sprite-button",
		name = gui_value.tech_spy,
		sprite = "item/space-science-pack"
	}
	tech_button.style.height = 25
	tech_button.style.width = 25
	tech_button.style.left_margin = 3
end

local function add_prod_button(elem, gui_value)
	local prod_button = elem.add {
		type = "sprite-button",
		name = gui_value.prod_spy,
		sprite = "item/assembling-machine-3"
	}
	prod_button.style.height = 25
	prod_button.style.width = 25
end

function Public.create_main_gui(player)
	local is_spec = player.force.name == "spectator"
	if player.gui.left["bb_main_gui"] then player.gui.left["bb_main_gui"].destroy() end

	if global.bb_game_won_by_team then return end
	if not global.chosen_team[player.name] then
		if not global.tournament_mode then
			create_first_join_gui(player)
			return
		end
	end

	local frame = player.gui.left.add { type = "frame", name = "bb_main_gui", direction = "vertical" }

	-- Science sending GUI
	if not is_spec then
		frame.add { type = "table", name = "biter_battle_table", column_count = 4 }
		local t = frame.biter_battle_table
		for food_name, tooltip in pairs(food_names) do
			local s = t.add { type = "sprite-button", name = food_name, sprite = "item/" .. food_name }
			s.tooltip = tooltip
			s.style.minimal_height = 41
			s.style.minimal_width = 41
			s.style.top_padding = 0
			s.style.left_padding = 0
			s.style.right_padding = 0
			s.style.bottom_padding = 0
		end
	end

	local first_team = true
	for k, gui_value in pairs(gui_values) do
		-- Line separator
		if not first_team then
			frame.add { type = "line", caption = "this line", direction = "horizontal" }
		else
			first_team = false
		end

		-- Team name & Player count
		local t = frame.add { type = "table", column_count = 4 }

		-- Team name
		local c = gui_value.c1
		if global.tm_custom_name[gui_value.force] then c = global.tm_custom_name[gui_value.force] end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default-bold"
		l.style.font_color = gui_value.color1
		l.style.single_line = false
		l.style.maximal_width = 102

		-- Number of players
		local l = t.add  { type = "label", caption = " - "}
		local c = #game.forces[gui_value.force].connected_players .. " Player"
		if #game.forces[gui_value.force].connected_players ~= 1 then c = c .. "s" end
		local l = t.add  { type = "label", caption = c}
		l.style.font = "default"
		l.style.font_color = { r=0.22, g=0.88, b=0.22}
		
		-- Tech button
		if is_spec then
			add_tech_button(t, gui_value)
			-- add_prod_button(t, gui_value)
		end

		-- Player list
		if global.bb_view_players[player.name] == true then
			local t = frame.add  { type = "table", column_count = 4 }
			for _, p in pairs(game.forces[gui_value.force].connected_players) do
				local l = t.add  { type = "label", caption = p.name }
				l.style.font_color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
			end
		end

		-- Statistics
		local t = frame.add { type = "table", name = "stats_" .. gui_value.force, column_count = 5 }

		-- Evolution
		local l = t.add  { type = "label", caption = "Evo:"}
		--l.style.minimal_width = 25
		local biter_force = game.forces[gui_value.biter_force]
		local tooltip = gui_value.t1 .. "\nHealth: " .. Functions.get_health_modifier(biter_force) * 100 .. "%" .. "\nDamage: " .. (biter_force.get_ammo_damage_modifier("melee") + 1) * 100 .. "%"
		
		l.tooltip = tooltip		
		
		local evo = math.floor(1000 * global.bb_evolution[gui_value.biter_force]) * 0.1
		local l = t.add  {type = "label", caption = evo .. "%"}
		l.style.minimal_width = 40
		l.style.font_color = gui_value.color2
		l.style.font = "default-bold"
		l.tooltip = tooltip

		-- Threat
		local l = t.add  {type = "label", caption = "Threat: "}
		l.style.minimal_width = 25
		l.tooltip = gui_value.t2
		local l = t.add  {type = "label", name = "threat_" .. gui_value.force, caption = math.floor(global.bb_threat[gui_value.biter_force])}
		l.style.font_color = gui_value.color2
		l.style.font = "default-bold"
		l.style.width = 50
		l.tooltip = gui_value.t2
	end

	-- Action frame
	local t = frame.add  { type = "table", column_count = 2 }

	-- Spectate / Rejoin team
	if is_spec then
		local b = t.add  { type = "sprite-button", name = "bb_leave_spectate", caption = "Join Team" }
	else
		local b = t.add  { type = "sprite-button", name = "bb_spectate", caption = "Spectate" }
	end

	-- Playerlist button
	if global.bb_view_players[player.name] == true then
		local b = t.add  { type = "sprite-button", name = "bb_hide_players", caption = "Playerlist" }
	else
		local b = t.add  { type = "sprite-button", name = "bb_view_players", caption = "Playerlist" }
	end


	local b_width = is_spec and 97 or 86
	-- 111 when prod_spy button will be there
	for _, b in pairs(t.children) do
		b.style.font = "default-bold"
		b.style.font_color = { r=0.98, g=0.66, b=0.22}
		b.style.top_padding = 1
		b.style.left_padding = 1
		b.style.right_padding = 1
		b.style.bottom_padding = 1
		b.style.maximal_height = 30
		b.style.width = b_width
	end
end

function Public.refresh()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["bb_main_gui"] then
			Public.create_main_gui(player)
		end
	end
	global.gui_refresh_delay = game.tick + 5
end

function Public.refresh_threat()
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

	if not global.training_mode and global.bb_settings.team_balancing then
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
		local p = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 8, 1)
		player.teleport(p, surface)
		player.force = game.forces[force_name]
		player.character.destructible = true
		Public.refresh()
		game.permissions.get_group("Default").add_player(player)
		local msg = table.concat({"Team ", player.force.name, " player ", player.name, " is no longer spectating."})
		game.print(msg, {r = 0.98, g = 0.66, b = 0.22})
		Server.to_discord_bold(msg)
		player.spectator = false
		return
	end
	local pos = surface.find_non_colliding_position("character", game.forces[force_name].get_spawn_position(surface), 8, 1)
	if not pos then pos = game.forces[force_name].get_spawn_position(surface) end
	player.teleport(pos)
	player.force = game.forces[force_name]
	player.character.destructible = true
	game.permissions.get_group("Default").add_player(player)
	if not forced_join then
		local c = player.force.name
		if global.tm_custom_name[player.force.name] then c = global.tm_custom_name[player.force.name] end
		local message = table.concat({player.name, " has joined team ", c, "!"})
		game.print(message, {r = 0.98, g = 0.66, b = 0.22})
		Server.to_discord_bold(message)
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
	Public.refresh()
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
		local msg = player.name .. " is spectating."
		game.print(msg, {r = 0.98, g = 0.66, b = 0.22})
		Server.to_discord_bold(msg)
	end
	game.permissions.get_group("spectator").add_player(player)
	global.spectator_rejoin_delay[player.name] = game.tick
	Public.create_main_gui(player)
	player.spectator = true
end

local function join_gui_click(name, player)
	local team = {
		["join_north_button"] = "north",
		["join_south_button"] = "south"
	}

	if not team[name] then return end

	if global.game_lobby_active then
		if player.admin then
			join_team(player, team[name])
			game.print("Lobby disabled, admin override.", { r=0.98, g=0.66, b=0.22})
			global.game_lobby_active = false
			return
		end
		player.print("Waiting for more players, " .. wait_messages[math_random(1, #wait_messages)], { r=0.98, g=0.66, b=0.22})
		return
	end
	join_team(player, team[name])
end

local spy_forces = {{"north", "south"},{"south", "north"}}
function Public.spy_fish()
	for _, f in pairs(spy_forces) do
		if global.spy_fish_timeout[f[1]] - game.tick > 0 then
			local r = 96
			local surface = game.surfaces["biter_battles"]
			for _, player in pairs(game.forces[f[2]].connected_players) do
				game.forces[f[1]].chart(surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})
			end
		else
			global.spy_fish_timeout[f[1]] = 0
		end
	end
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
			Public.create_main_gui(player)
		end
		return
	end

	if name == "join_north_button" then join_gui_click(name, player) return end
	if name == "join_south_button" then join_gui_click(name, player) return end

	if name == "raw-fish" then Functions.spy_fish(player) return end

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
		Public.create_main_gui(player)
	end
	if name == "bb_view_players" then
		global.bb_view_players[player.name] = true
		Public.create_main_gui(player)
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
	Public.create_main_gui(player)
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

return Public
