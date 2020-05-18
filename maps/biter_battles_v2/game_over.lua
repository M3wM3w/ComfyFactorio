local Functions = require "maps.biter_battles_v2.functions"
local Gui = require "maps.biter_battles_v2.gui"
local Init = require "maps.biter_battles_v2.init"
local Score = require "comfy_panel.score"
local Server = require 'utils.server'

local math_random = math.random

local Public = {}

local gui_values = {
		["north"] = {c1 = "Team North", color1 = {r = 0.55, g = 0.55, b = 0.99}},
		["south"] = {c1 = "Team South", color1 = {r = 0.99, g = 0.33, b = 0.33}}
	}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

function Public.reveal_map()
	for _, f in pairs({"north", "south", "player", "spectator"}) do
		local r = 768
		game.forces[f].chart(game.surfaces["biter_battles"], {{r * -1, r * -1}, {r, r}})
	end
end

local function create_victory_gui(player)	
	local values = gui_values[global.bb_game_won_by_team]
	local c = values.c1
	if global.tm_custom_name[global.bb_game_won_by_team] then c = global.tm_custom_name[global.bb_game_won_by_team] end
	local frame = player.gui.left.add {type = "frame", name = "bb_victory_gui", direction = "vertical", caption = c .. " won!" }
	frame.style.font = "heading-1"
	frame.style.font_color = values.color1	
	
	local l = frame.add {type = "label", caption = global.victory_time}
	l.style.font = "heading-2"
	l.style.font_color = {r = 0.77, g = 0.77, b = 0.77}
end
--[[
local function create_fireworks_rocket(surface, position)
	local particles = {"coal-particle", "copper-ore-particle", "iron-ore-particle", "stone-particle"}
	local particle = particles[math.random(1, #particles)]
	local m = math.random(16, 36)
	local m2 = m * 0.005
				
	for i = 1, 60, 1 do 
		surface.create_particle({
			name = particle,
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
		})
	end
	
	if math.random(1,10) ~= 1 then return end
	surface.create_entity({name = "explosion", position = position})
end

local function fireworks(surface)
	local radius = 48
	local center_pos = global.rocket_silo[global.bb_game_won_by_team].position
	
	local positions = {}
	for x = -80, 80, 1 do
		for y = -80, 80, 1 do
			local pos = {x = center_pos.x + x, y = center_pos.y + y}
			local distance_to_center = math.sqrt((pos.x - center_pos.x)^2 + (pos.y - center_pos.y)^2)
			if distance_to_center <= radius then
				positions[#positions + 1] = pos
			end
		end
	end		
	if #positions == 0 then return end
		
	for t = 1, 7200, 1 do
		if t % 2 == 0 then
			if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
			local pos = positions[math.random(1, #positions)]
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = create_fireworks_rocket,
				args = {
					surface,
					{x = pos.x, y = pos.y}
				}
			}
		end
	end
end
]]
local function silo_kaboom(entity)
	local surface = entity.surface
	local center_position = entity.position
	local force = entity.force
	local r = 32
	local square_distance = r ^ 2
	local shells_square_distance = square_distance * 0.75
	local kabooms = {"explosive-cannon-projectile", "explosive-cannon-projectile", "artillery-projectile"}
	local size_of_kabooms = #kabooms
	for x = r * -1, r, 0.5 do
		for y = r * -1, r, 0.5 do
			local position = {x = center_position.x + x, y = center_position.y + y}
			local square_distance_to_center_position = (position.x - center_position.x) ^ 2 + (position.y - center_position.y) ^ 2
			if square_distance_to_center_position < shells_square_distance and math_random(1, 16) == 1 then
				surface.create_entity({	
					name = kabooms[math_random(1, size_of_kabooms)],
					position = center_position,
					force = force,
					source = center_position,
					target = position,
					max_range = r, 
					speed = 0.1
				})	
			end
			if square_distance_to_center_position < square_distance and math_random(1, 16) == 1 then
				surface.create_entity({	
					name = "rocket",
					position = center_position,
					force = force,
					source = center_position,
					target = position,
					max_range = r, 
					speed = 0.01
				})	
			end
		end
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
			table.insert(result, 'NORTH: \\n')
			table.insert(result, 'MVP Defender: \\n')
			table.insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Builder: \\n')
			table.insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Deaths: \\n')
			table.insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
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
			table.insert(result, 'SOUTH: \\n')
			table.insert(result, 'MVP Defender: \\n')
			table.insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Builder: \\n')
			table.insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
			table.insert(result, '\\n')
			table.insert(result, 'MVP Deaths: \\n')
			table.insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )		
			local message = table.concat(result)
			Server.to_discord_embed(message)
			global.results_sent_south = true
		end
	end
end

local enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

function Public.server_restart()
	if not global.server_restart_timer then return end
	global.server_restart_timer = global.server_restart_timer - 5
	if global.server_restart_timer == 150 then return end
	if global.server_restart_timer == 10 then game.delete_surface(game.surfaces.bb_source) return end
	if global.server_restart_timer == 5 then Init.source_surface() return end
	
	if global.server_restart_timer == 0 then
		game.print("Map is restarting!", {r=0.22, g=0.88, b=0.22})
		local message = 'Map is restarting! '
		Server.to_discord_bold(table.concat{'*** ', message, ' ***'})
		--Server.start_scenario('Biter_Battles')	
		Init.tables()
		Init.forces()
		Init.load_spawn()		
		for _, player in pairs(game.players) do
			Functions.init_player(player)
			for _, e in pairs(player.gui.left.children) do e.destroy() end		
			Gui.create_main_gui(player)
		end
		game.surfaces.biter_battles.clear(true)
		game.reset_time_played()
		global.server_restart_timer = nil
		return
	end
	if global.server_restart_timer % 30 == 0 then
		game.print("Map will restart in " .. global.server_restart_timer .. " seconds!", {r=0.22, g=0.88, b=0.22})
	end
end

local function set_victory_time()
	local tick = game.ticks_played
	local minutes = tick % 216000
	local hours = tick - minutes
	minutes = math.floor(minutes / 3600)
	hours = math.floor(hours / 216000)
	if hours > 0 then hours = hours .. " hours and " else hours = "" end
	global.victory_time = "Time - " .. hours
	global.victory_time = global.victory_time .. minutes
	global.victory_time = global.victory_time .. " minutes"
end

local function freeze_all_biters(surface)
	for _, e in pairs(surface.find_entities_filtered({force = "north_biters"})) do e.active = false end
	for _, e in pairs(surface.find_entities_filtered({force = "south_biters"})) do e.active = false end
end

function Public.silo_death(event)
	if not event.entity.valid then return end
	if event.entity.name ~= "rocket-silo" then return end
	if global.bb_game_won_by_team then return end
	if event.entity == global.rocket_silo.south or event.entity == global.rocket_silo.north then
		global.bb_game_won_by_team = enemy_team_of[event.entity.force.name]
		
		set_victory_time()
		
		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_won", volume_modifier=1}
			if player.gui.left["bb_main_gui"] then player.gui.left["bb_main_gui"].visible = false end
			create_victory_gui(player)
			show_mvps(player)
		end

		global.spy_fish_timeout["north"] = game.tick + 999999
		global.spy_fish_timeout["south"] = game.tick + 999999
		global.server_restart_timer = 150			
		
		local c = gui_values[global.bb_game_won_by_team].c1
		if global.tm_custom_name[global.bb_game_won_by_team] then c = global.tm_custom_name[global.bb_game_won_by_team] end
		
		Server.to_discord_embed(c .. " has won!")
		Server.to_discord_embed(global.victory_time)
		
		silo_kaboom(event.entity)
		
		freeze_all_biters(event.entity.surface)
	end
end

return Public