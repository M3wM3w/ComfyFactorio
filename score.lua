--scoreboard by mewmew

local event = require 'utils.event'
local sorting_symbol = {ascending = "▲", descending = "▼"}

local function create_score_button(player)
	if not player.gui.top.score then
		local button = player.gui.top.add({ type = "sprite-button", name = "score", sprite = "item/rocket-silo" })		
		button.style.minimal_height = 38
		button.style.minimal_width = 38
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function get_sorted_list(method, column_name, score_list)
	if method == "ascending" then 
		for x = 1, #score_list, 1 do
			for y = 1, #score_list, 1 do			
				if not score_list[y + 1] then break end
				if score_list[y][column_name] > score_list[y + 1][column_name] then
					local key = score_list[y]
					score_list[y] = score_list[y + 1]
					score_list[y + 1] = key
				end
			end		
		end
	end
	if method == "descending" then 
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
	end
	return score_list
end

local biters = {"small-biter", "medium-biter", "big-biter", "behemoth-biter", "small-spitter", "medium-spitter", "big-spitter", "behemoth-spitter"}
local function get_total_biter_killcount(force)
	local count = 0
	for _, biter in pairs(biters) do
		count = count + force.kill_count_statistics.get_input_count(biter)
	end
	return count
end

local function show_score(player)
	if player.gui.left["score_panel"] then player.gui.left["score_panel"].destroy() end
	local score = global.score[player.force.name]
		
	local frame = player.gui.left.add { type = "frame", name = "score_panel", direction = "vertical" }
		
	local t = frame.add { type = "table", column_count = 5}
	
	local l = t.add { type = "label", caption = "Rockets launched: "}	
	l.style.font = "default-game"			
	l.style.font_color = {r = 175, g = 75, b = 255}
	l.style.minimal_width = 140
	
	local str = "0"
	if score.rocket_launches then str = tostring(score.rocket_launches) end
	local l = t.add { type = "label", caption = str}
	l.style.font = "default-frame"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 123

	local l = t.add { type = "label", caption = "Dead biters: "}	
	l.style.font = "default-game"			
	l.style.font_color = { r=0.90, g=0.3, b=0.3}
	l.style.minimal_width = 100
	
	local l = t.add { type = "label", caption = tostring(get_total_biter_killcount(player.force))}
	l.style.font = "default-frame"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 145
	
	local l = t.add { type = "checkbox", caption = "Show floating numbers", state = global.show_floating_killscore[player.name], name = "show_floating_killscore_texts"	}
	l.style.font_color = { r=0.8, g=0.8, b=0.8}	
	
	local l = frame.add { type = "label", caption = "---------------------------------------------------------------------------------------------------------------"}
	l.style.font_color = { r=0.9, g=0.9, b=0.9}

	local t = frame.add { type = "table", column_count = #global.score_columns + 1}
	
	local l = t.add { type = "label", caption = "Player"}	
	l.style.font = "default-listbox"			
	l.style.font_color = { r=0.98, g=0.66, b=0.22}
	l.style.minimal_width = 140

	local function add_label(column, label, id)
		local str = ""
		if global.score_sort_by[player.name].column == column then str = sorting_symbol[global.score_sort_by[player.name].method] .. " " end
		local l = t.add { type = "label", caption = str .. label, name = id}
		l.style.font = "default-listbox"
		l.style.font_color = { r=0.98, g=0.66, b=0.22}
		l.style.minimal_width = 140
	end

	for _, column in pairs(global.score_columns) do
		add_label(column.prop, column.label, "score_" .. column.prop)
	end

	local score_list = {}
	for _, p in pairs(game.connected_players) do
		row = {}
		row.name = p.name
		for _, column in pairs(global.score_columns) do
			if score.players[p.name][column.prop] then
				row[column.prop] = score.players[p.name][column.prop]
			else
				row[column.prop] = 0
			end
		end
		table.insert(score_list, row)
	end

	if #game.connected_players > 1 then
		score_list = get_sorted_list(global.score_sort_by[player.name].method, global.score_sort_by[player.name].column, score_list)
	end

	local scroll_pane = frame.add({ type = "scroll-pane", name = "score_scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	scroll_pane.style.maximal_height = 400
	local t = scroll_pane.add { type = "table", column_count = #global.score_columns + 1}

	for _, entry in pairs(score_list) do
		local l = t.add { type = "label", caption = entry.name}
		l.style.font = "default"
		local p = game.players[entry.name]
		local color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
		l.style.font_color = color
		l.style.minimal_width = 140
		l.style.maximal_width = 140

		for _, column in pairs(global.score_columns) do
			local l = t.add { type = "label", caption = tostring(entry[column.prop])}
			l.style.font = "default"
			l.style.font_color = { r=0.9, g=0.9, b=0.9}
			l.style.minimal_width = 140
			l.style.maximal_width = 140
		end
	end
end

local function refresh_score_full()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["score_panel"] then
			show_score(player)
		end
	end
end

local function refresh_score()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["score_panel"] then
			if global.score[player.force.name].rocket_launches then player.gui.left["score_panel"].children[1].children[2].caption = global.score[player.force.name].rocket_launches end
			player.gui.left["score_panel"].children[1].children[4].caption = get_total_biter_killcount(player.force)
			local score = global.score[player.force.name]
			local score_list = {}
			for _, p in pairs(game.connected_players) do
				row = {}
				row.name = p.name
				for _, column in pairs(global.score_columns) do
					if score.players[p.name][column.prop] then
						row[column.prop] = score.players[p.name][column.prop]
					else
						row[column.prop] = 0
					end
				end
				table.insert(score_list, row)
			end
			if #game.connected_players > 1 then
				score_list = get_sorted_list(global.score_sort_by[player.name].method, global.score_sort_by[player.name].column, score_list)
			end
			for i, entry in pairs(score_list) do
				player.gui.left["score_panel"].children[4].children[1].children[i].caption = entry.name
				local p = game.players[entry.name]
				local color = {r = p.color.r * 0.6 + 0.4, g = p.color.g * 0.6 + 0.4, b = p.color.b * 0.6 + 0.4, a = 1}
				player.gui.left["score_panel"].children[4].children[1].children[i].style.font_color = color
				for i, column in pairs(global.score_columns) do
					player.gui.left["score_panel"].children[4].children[1].children[i + 1].caption = tostring(entry[column.prop])
				end
			end
		end
	end
end

local function init_player_table(player)
	if not global.score_columns then global.score_columns = {
			{["prop"] = "killscore",      ["label"] = "Killscore"},
			{["prop"] = "deaths",         ["label"] = "Deaths"},
			{["prop"] = "built_entities", ["label"] = "Entities Built"},
			{["prop"] = "mined_entities", ["label"] = "Entities Mined"},}
	end
	if not global.score[player.force.name] then global.score[player.force.name] = {} end
	if not global.score[player.force.name].players then global.score[player.force.name].players = {} end
	if not global.score[player.force.name].players[player.name] then global.score[player.force.name].players[player.name] = {} end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if not global.score then global.score = {} end
	init_player_table(player)	
	if not global.score_sort_by then global.score_sort_by = {} end
	if not global.score_sort_by[player.name] then
		global.score_sort_by[player.name] = {method = "descending", column = "killscore"}
	end
	if not global.show_floating_killscore then global.show_floating_killscore = {} end
	if not global.show_floating_killscore[player.name] then global.show_floating_killscore[player.name] = false end	
		
	create_score_button(player)
	refresh_score_full()
end

local function on_player_left_game(event)
	refresh_score_full()
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	
	local player = game.players[event.element.player_index]
	local name = event.element.name		
	
	if name == "score" then			
		if player.gui.left["score_panel"] then
			player.gui.left["score_panel"].destroy()
		else
			global.score_sort_by[player.name].get_sorted_list = true
			show_score(player)
		end
		return
	end	
	
	if name == "show_floating_killscore_texts" then
		if event.element.state == true then
			global.show_floating_killscore[player.name] = true			
		else
			global.show_floating_killscore[player.name] = false			
		end
		return
	end

	local int_sort_columns = {"score_killscore", "killscore", "score_deaths", "deaths", "score_built_entities", "built_entities", "score_mined_entities", "mined_entities"}
	for _, column in pairs(global.score_columns) do
		if name:sub(-#column.prop) == column.prop then
			if global.score_sort_by[player.name].column == column.prop then
				if global.score_sort_by[player.name].method == "ascending" then
					global.score_sort_by[player.name].method = "descending"
				else
					global.score_sort_by[player.name].method = "ascending"
				end
			else
				global.score_sort_by[player.name] = {method = "descending", column = column.prop}
			end
			show_score(player)
			break
		end
	end
end

local function on_rocket_launched(event)
	local force_name = event.rocket_silo.force.name
	if not global.score[force_name] then global.score[force_name] = {} end
	if not global.score[force_name].rocket_launches then
		global.score[force_name].rocket_launches = 1		
	else
		global.score[force_name].rocket_launches = global.score[force_name].rocket_launches + 1
	end	
	game.print ("A rocket has been launched!", {r=0.98, g=0.66, b=0.22})		
	refresh_score()
end

local score_table = {
	["small-biter"] = 5,
	["medium-biter"] = 15,
	["big-biter"] = 30,
	["behemoth-biter"] = 100,
	["small-spitter"] = 5,
	["medium-spitter"] = 15,
	["big-spitter"] = 30,
	["behemoth-spitter"] = 100,
	["biter-spawner"] = 200,
	["spitter-spawner"] = 200,
	["small-worm-turret"] = 50,
	["medium-worm-turret"] = 150,
	["big-worm-turret"] = 300,
	["player"] = 1000
}

local function on_entity_died(event)
	local player = false
	local passenger = false
	local train_passengers = false
	local proximity_list = {}

	-- Handles worm kills with no cause
	if event.entity.type == "turret" then           --------------
		local radius = 24
		local position = event.entity.position
		local insert = table.insert
		--Since we cannot reliably get the player who killed the worm, get all players in a radius and award them xp
		for _, p in pairs(game.connected_players) do
			if p.position.x < position.x + radius and p.position.x > position.x - radius and p.position.y < position.y + radius and p.position.y > position.y - radius then
				insert(proximity_list, {player = p})
			end
		end
	end
	
	-- Unit/Spawner Kills
	if event.entity.type == "unit" or  event.entity.type == "unit-spawner" then
		if event.cause then
		
			if event.cause.name == "player" then player = event.cause.player end
		
			--Check for passengers
			if event.cause.type == "car" then
				player = event.cause.get_driver()
				passenger = event.cause.get_passenger()
				if player then player = player.player end
				if passenger then passenger = passenger.player end
			end
			if event.cause.type == "locomotive" then
			player = event.cause.get_driver()
			train_passengers = event.cause.train.passengers
			end
			
			if not train_passengers and not passenger and not player then return end
			if event.cause.force.name == event.entity.force.name then return end
			init_player_table(player)
			if not global.score[event.force.name] then global.score[event.force.name] = {} end
			if not global.score[event.force.name].players then global.score[event.force.name].players = {} end
			if not global.score[event.force.name].players then global.score[event.force.name].players[player.name] = {} end
		end
	end

	if score_table[event.entity.name] then
		if not global.score[event.force.name].kills then
			global.score[event.force.name].kills = 1
		else
			global.score[event.force.name].kills = global.score[event.force.name].kills + 1
		end		
		
		local show_floating_text = false
		
		--Award all players near a worm score
		 if #proximity_list > 0 then
			for i=1, #proximity_list, 1 do
				player = proximity_list[i].player
				if player then
					if global.show_floating_killscore[player.name] == true then show_floating_text = true end
					if not global.score[event.force.name].players[player.name].killscore then
						global.score[event.force.name].players[player.name].killscore = score_table[event.entity.name]
					else
						global.score[event.force.name].players[player.name].killscore = global.score[event.force.name].players[player.name].killscore + score_table[event.entity.name]
					end
				end
			end
		else
			if player then
				if global.show_floating_killscore[player.name] == true then show_floating_text = true end
				if not global.score[event.force.name].players[player.name].killscore then
					global.score[event.force.name].players[player.name].killscore = score_table[event.entity.name]
				else
					global.score[event.force.name].players[player.name].killscore = global.score[event.force.name].players[player.name].killscore + score_table[event.entity.name]
				end
			end
		end
			
		if passenger then
			if not global.score[event.force.name].players[passenger.name].killscore then
				global.score[event.force.name].players[passenger.name].killscore = score_table[event.entity.name]
			else
				global.score[event.force.name].players[passenger.name].killscore = global.score[event.force.name].players[passenger.name].killscore + score_table[event.entity.name]
			end
		end
		
		if train_passengers then
			for _, player in pairs(train_passengers) do
				if global.show_floating_killscore[player.name] == true then show_floating_text = true end
				if not global.score[event.force.name].players[player.name].killscore then
					global.score[event.force.name].players[player.name].killscore = score_table[event.entity.name]
				else
					global.score[event.force.name].players[player.name].killscore = global.score[event.force.name].players[player.name].killscore + score_table[event.entity.name]
				end
			end
		end
		
		if show_floating_text == true then
			event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = tostring(score_table[event.entity.name]), color = {r=0.98, g=0.66, b=0.22}})
		end
	end
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	init_player_table(player)
	if not global.score[player.force.name].players[player.name].deaths then
		global.score[player.force.name].players[player.name].deaths = 1
	else
		global.score[player.force.name].players[player.name].deaths = global.score[player.force.name].players[player.name].deaths + 1
	end	
end

local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	init_player_table(player)
	if not global.score[player.force.name].players[player.name].mined_entities then
		global.score[player.force.name].players[player.name].mined_entities = 1
	else
		global.score[player.force.name].players[player.name].mined_entities = global.score[player.force.name].players[player.name].mined_entities + 1
	end	
end

local function on_built_entity(event)	
	local player = game.players[event.player_index]
	init_player_table(player)
	if not global.score[player.force.name].players[player.name].built_entities then
		global.score[player.force.name].players[player.name].built_entities = 1
	else
		global.score[player.force.name].players[player.name].built_entities = global.score[player.force.name].players[player.name].built_entities + 1
	end		
end

local function on_tick(event)
	if game.tick % 300 == 0 then
		refresh_score()
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_player_died, on_player_died)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_rocket_launched, on_rocket_launched)
