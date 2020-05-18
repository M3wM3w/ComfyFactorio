--scoreboard by mewmew

local Event = require 'utils.event'
local Global = require 'utils.global'
local Tabs = require 'comfy_panel.main'

local Public = {}
local this = {
	score_table = {},
	sort_by = {}
}

Global.register(
	this,
	function(t)
	this = t
	end
)

local sorting_symbol = {ascending = "▲", descending = "▼"}
local building_and_mining_blacklist = {
	["tile-ghost"] = true,
	["entity-ghost"] = true,
	["item-entity"] = true,
}

function Public.get_table()
	return this
end

local function init_player_table(player)
	if not player then return end
	if not this.score_table[player.force.name] then this.score_table[player.force.name] = {} end
	if not this.score_table[player.force.name].players then this.score_table[player.force.name].players = {} end
	if not this.score_table[player.force.name].players[player.name] then
		this.score_table[player.force.name].players[player.name] = {
			built_entities = 0,
			deaths = 0,
			killscore = 0,
			mined_entities = 0,
		}
	end
end

local function get_score_list(force)
	local score_force = this.score_table[force]
	local score_list = {}
	for _, p in pairs(game.connected_players) do
		if score_force.players[p.name] then
			local score = score_force.players[p.name]
			table.insert(score_list, {
				name = p.name,
				killscore = score.killscore or 0,
				deaths = score.deaths or 0,
				built_entities = score.built_entities or 0,
				mined_entities = score.mined_entities or 0,
			})
		end
	end
	return score_list
end

local function get_sorted_list(method, column_name, score_list)
	local comparators = {
		["ascending"]  = function(a,b) return a[column_name] < b[column_name] end,
		["descending"] = function(a,b) return a[column_name] > b[column_name] end
	}
	table.sort(score_list, comparators[method])
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

local function add_global_stats(frame, player)
	local score = this.score_table[player.force.name]
	local t = frame.add { type = "table", column_count = 5}

	local l = t.add { type = "label", caption = "Rockets launched: "}
	l.style.font = "default-game"
	l.style.font_color = {r = 175, g = 75, b = 255}
	l.style.minimal_width = 140

	local l = t.add { type = "label", caption = player.force.rockets_launched}
	l.style.font = "default-listbox"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 123

	local l = t.add { type = "label", caption = "Dead bugs: "}
	l.style.font = "default-game"
	l.style.font_color = { r=0.90, g=0.3, b=0.3}
	l.style.minimal_width = 100

	local l = t.add { type = "label", caption = tostring(get_total_biter_killcount(player.force))}
	l.style.font = "default-listbox"
	l.style.font_color = { r=0.9, g=0.9, b=0.9}
	l.style.minimal_width = 145

	local l = t.add { type = "checkbox", caption = "Show floating numbers", state = global.show_floating_killscore[player.name], name = "show_floating_killscore_texts"	}
	l.style.font_color = { r=0.8, g=0.8, b=0.8}
end

local show_score = (function (player, frame)
	frame.clear()

	init_player_table(player)

	-- Global stats : rockets, biters kills
	add_global_stats(frame, player)

	-- Separator
	local line = frame.add { type = "line"}
	line.style.top_margin = 8
	line.style.bottom_margin = 8
	
	-- Score per player
	local t = frame.add { type = "table", column_count = 5 }

	-- Score headers
	local headers = {
		{ name = "score_player", caption = "Player" },
		{ column = "killscore", name = "score_killscore", caption = "Killscore" },
		{ column = "deaths", name = "score_deaths", caption = "Deaths" },
		{ column = "built_entities", name = "score_built_entities", caption = "Built structures" },
		{ column = "mined_entities", name = "score_mined_entities", caption = "Mined entities" }
	}

	local sorting_pref = this.sort_by[player.name]
	for _, header in ipairs(headers) do
		local cap = header.caption

		-- Add sorting symbol if any
		if header.column and sorting_pref.column == header.column then
			local symbol = sorting_symbol[sorting_pref.method]
			cap = symbol .. cap
		end

		-- Header
		local label = t.add {
			type = "label",
			caption = cap,
			name = header.name
		}
		label.style.font = "default-listbox"
		label.style.font_color = { r=0.98, g=0.66, b=0.22 } -- yellow
		label.style.minimal_width = 150
		label.style.horizontal_align = "right"
	end

	-- Score list
	local score_list = get_score_list(player.force.name)

	if #game.connected_players > 1 then
		score_list = get_sorted_list(sorting_pref.method, sorting_pref.column, score_list)
	end

	-- New pane for scores (while keeping headers at same position)
	local scroll_pane = frame.add({ type = "scroll-pane", name = "score_scroll_pane", direction = "vertical", horizontal_scroll_policy = "never", vertical_scroll_policy = "auto"})
	scroll_pane.style.maximal_height = 400
	local t = scroll_pane.add { type = "table", column_count = 5}

	-- Score entries
	for _, entry in pairs(score_list) do
		local p = game.players[entry.name]
		local special_color = {
			r = p.color.r * 0.6 + 0.4,
			g = p.color.g * 0.6 + 0.4,
			b = p.color.b * 0.6 + 0.4,
			a = 1
		}
		local line = {
			{ caption = entry.name, color = special_color },
			{ caption = tostring(entry.killscore) },
			{ caption = tostring(entry.deaths) },
			{ caption = tostring(entry.built_entities) },
			{ caption = tostring(entry.mined_entities) }
		}
		local default_color = { r=0.9, g=0.9, b=0.9 }

		for _, column in ipairs(line) do
			local label = t.add {
				type = "label",
				caption = column.caption,
				color = column.color or default_color
			}
			label.style.font = "default"
			label.style.minimal_width = 150
			label.style.maximal_width = 150
			label.style.horizontal_align = "right"
		end -- foreach column
	end -- foreach entry
end -- show_score
)

local function refresh_score_full()
	for _, player in pairs(game.connected_players) do
		local frame = Tabs.comfy_panel_get_active_frame(player)
		if frame then
			if frame.name == "Scoreboard" then
				show_score(player, frame)
			end
		end
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	init_player_table(player)
	if not this.sort_by[player.name] then
		this.sort_by[player.name] = {method = "descending", column = "killscore"}
	end
	if not global.show_floating_killscore then global.show_floating_killscore = {} end
	if not global.show_floating_killscore[player.name] then global.show_floating_killscore[player.name] = false end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end

	local player = game.players[event.element.player_index]
	local frame = Tabs.comfy_panel_get_active_frame(player)
	if not frame then return end
	if frame.name ~= "Scoreboard" then return end
	
	local name = event.element.name

	-- Handles click on the checkbox, for floating score
	if name == "show_floating_killscore_texts" then
		global.show_floating_killscore[player.name] = event.element.state
		return
	end

	-- Handles click on a score header
	local element_to_column = {
		["score_killscore"] = "killscore",
		["score_deaths"] = "deaths",
		["score_built_entities"] = "built_entities",
		["score_mined_entities"] = "mined_entities"
	}
	local column = element_to_column[name]
	if column then
		local sorting_pref = this.sort_by[player.name]
		if sorting_pref.column == column and sorting_pref.method == "descending" then
			sorting_pref.method = "ascending"
		else
			sorting_pref.method = "descending"
			sorting_pref.column = column
		end
		show_score(player, frame)
		return
	end

	-- No more to handle
end

local function on_rocket_launched(event)
	refresh_score_full()
end

local entity_score_values = {
	["behemoth-biter"] = 100,
	["behemoth-spitter"] = 100,
	["behemoth-worm-turret"] = 300,
	["big-biter"] = 30,
	["big-spitter"] = 30,
	["big-worm-turret"] = 300,
	["biter-spawner"] = 200,
	["medium-biter"] = 15,
	["medium-spitter"] = 15,
	["medium-worm-turret"] = 150,
	["character"] = 1000,
	["small-biter"] = 5,
	["small-spitter"] = 5,
	["small-worm-turret"] = 50,
	["spitter-spawner"] = 200,
	["gun-turret"] = 50,
	["laser-turret"] = 150,
	["flamethrower-turret"] = 300,
}

local function train_type_cause(event)	
	local players = {}
	if event.cause.train.passengers then
		for _, player in pairs(event.cause.train.passengers) do
			players[#players + 1] = player
		end
	end			
	return players
end

local kill_causes = {
	["character"] = 
		function(event)
			if not event.cause.player then return end
			return {event.cause.player}
		end,
	["combat-robot"] = 
		function(event)
			if not event.cause.last_user then return end
			if not game.players[event.cause.last_user.index] then return end
			return {game.players[event.cause.last_user.index]}
		end,
	["car"] = 
		function(event)
			local players = {}
			local driver = event.cause.get_driver()
			if driver then
				if driver.player then players[#players + 1] = driver.player end
			end
			local passenger = event.cause.get_passenger()
			if passenger then
				if passenger.player then players[#players + 1] = passenger.player end
			end
			return players
		end,
	["locomotive"] = train_type_cause,
	["cargo-wagon"] = train_type_cause,
	["artillery-wagon"] = train_type_cause,
	["fluid-wagon"] = train_type_cause,
}

local function on_entity_died(event)
	if not event.entity.valid then return end
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.entity.force.index == event.cause.force.index then return end
	if not entity_score_values[event.entity.name] then return end
	if not kill_causes[event.cause.type] then return end	
	local players_to_reward = kill_causes[event.cause.type](event)
	if not players_to_reward then return end
	if #players_to_reward == 0 then return end	
	for _, player in pairs(players_to_reward) do
		init_player_table(player)		
		local score = this.score_table[player.force.name].players[player.name]		
		score.killscore = score.killscore + entity_score_values[event.entity.name]
		if global.show_floating_killscore[player.name] then
			event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = tostring(entity_score_values[event.entity.name]), color = player.chat_color})
		end
	end
end	

local function on_player_died(event)
	local player = game.players[event.player_index]
	init_player_table(player)
	local score = this.score_table[player.force.name].players[player.name]
	score.deaths = 1 + (score.deaths or 0)
end

local function on_player_mined_entity(event)
	if not event.entity.valid then return end
	if building_and_mining_blacklist[event.entity.type] then return end
	
	local player = game.players[event.player_index]	
	init_player_table(player)
	local score = this.score_table[player.force.name].players[player.name]
	score.mined_entities = 1 + (score.mined_entities or 0)
end

local function on_built_entity(event)
	if not event.created_entity.valid then return end
	if building_and_mining_blacklist[event.created_entity.type] then return end
	local player = game.players[event.player_index]
	init_player_table(player)
	local score = this.score_table[player.force.name].players[player.name]
	score.built_entities = 1 + (score.built_entities or 0)
end

comfy_panel_tabs["Scoreboard"] = {gui = show_score, admin = false}

Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_built_entity, on_built_entity)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)


return Public