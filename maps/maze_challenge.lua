require "functions.maze"

local event = require 'utils.event'

local function init_surface()
	if game.surfaces["maze_challenge"] then return game.surfaces["maze_challenge"] end

	local map_gen_settings = {}
	map_gen_settings.water = "0"
	map_gen_settings.starting_area = "2.5"
	map_gen_settings.cliff_settings = {cliff_elevation_interval = 0, cliff_elevation_0 = 0}		
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "0", size = "7", richness = "1"},
		["stone"] = {frequency = "0", size = "2.0", richness = "0.5"},
		["iron-ore"] = {frequency = "0", size = "2.0", richness = "0.5"},
		["copper-ore"] = {frequency = "0", size = "2.0", richness = "0.5"},
		["uranium-ore"] = {frequency = "0", size = "1", richness = "0.5"},		
		["crude-oil"] = {frequency = "0", size = "1", richness = "1"},
		["trees"] = {frequency = "0", size = "0.75", richness = "1"},
		["enemy-base"] = {frequency = "0", size = "1", richness = "1"}
	}
	
	game.map_settings.enemy_expansion.enabled = false
	game.difficulty_settings.technology_price_multiplier = 2
		
	local surface = game.create_surface("maze_challenge", map_gen_settings)				
	surface.request_to_generate_chunks({x = 0, y = 0}, 2)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.7
	surface.freeze_daytime = 1
	
	game.forces["player"].set_spawn_position({0,0},game.surfaces["maze_challenge"])
	
	global.highscores = {}
	
	global.maze_size = 3
	global.grid_size = 3
	
	return surface
end

local tiles = {"sand-1", "sand-2", "sand-3", "grass-1", "grass-2", "grass-3", "grass-4", "dirt-1", "dirt-2", "dirt-3"}

local function maze(event)
	--local position = event.area.left_top
	local position = {x = event.position.x * 32, y = event.position.y * 32}
	
	if position.y ~= 0 then return end
	if position.x < 32 then return end
	
	--local surface = event.surface
	local surface = game.surfaces[event.surface_index]

	local r = global.maze_size * (global.grid_size - 1) + 8
	if surface.count_entities_filtered({force = "enemy", area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}}) ~= 0 then return end
	
	surface.request_to_generate_chunks(position, math.ceil((global.maze_size * global.grid_size * 2) / 32))
	surface.force_generate_chunk_requests()
	
	local tile_name = tiles[math.random(1, #tiles)]
	for x = global.maze_size * - 1 * (global.grid_size - 1) - 1, global.maze_size * (global.grid_size - 1) + 1, 1 do
		for y = global.maze_size * - 1 * (global.grid_size - 1) - 1, global.maze_size * (global.grid_size - 1) + 1, 1 do
			surface.set_tiles({{name = tile_name, position = {position.x + x, position.y + y}}}, true)
		end
	end
	
	create_maze(surface, position, global.maze_size, global.grid_size, "stone-wall", "enemy")
	global.maze_size = global.maze_size + 1
	
	for _, e in pairs(surface.find_entities_filtered({force = "player", name = "character", area = {{position.x - r, position.y - r}, {position.x + r, position.y + r}}})) do
		e.player.teleport(surface.find_non_colliding_position("stone-furnace", e.position, 2048, 1), "maze_challenge")
	end
end

local function on_player_joined_game(event)
	local surface = init_surface()	
	local player = game.players[event.player_index]
	
	if not global.highscores[player.index] then global.highscores[player.index] = player.position.x end
	
	if player.online_time == 0 then 
		player.teleport({0,0}, "maze_challenge")
	end	
end

local function on_player_respawned(event)	
	local player = game.players[event.player_index]
	local surface = player.surface
	
	for _, e in pairs(surface.find_entities_filtered({name = "character-corpse"})) do
		if e.character_corpse_player_index == player.index then
			player.teleport(surface.find_non_colliding_position("character", e.position, 1024, 1), "maze_challenge")
			return
		end
	end
end

local function on_chunk_generated(event)
	for _, e in pairs(event.surface.find_entities_filtered({area = event.area, force = "neutral"})) do
		e.destroy()
	end

	for _, t in pairs(event.surface.find_tiles_filtered({area = event.area})) do
		if t.position.y < -3 or t.position.y > 3 or t.position.x < -3 then
			event.surface.set_tiles({{name = "out-of-map", position = t.position}}, true)
		else
			if t.name == "water" or t.name == "deepwater" then
				event.surface.set_tiles({{name = "sand-1", position = t.position}}, true)
			end
		end
	end	
end

local function on_chunk_charted(event)
	if not global.chunks_charted then global.chunks_charted = {} end
	local position = event.position
	if global.chunks_charted[tostring(position.x) .. tostring(position.y)] then return end
	global.chunks_charted[tostring(position.x) .. tostring(position.y)] = true
	maze(event)
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving == true then return end
	
	if player.position.x > global.highscores[player.index] then
		global.highscores[player.index] = math.floor(player.position.x)
	end
end

local function tick()		
	local scores = {}
	for _, player in pairs(game.players) do		
		scores[#scores + 1] = {name = player.name, score = global.highscores[player.index]}		
	end
	
	for x = 1, #scores, 1 do
		for y = 1, #scores, 1 do			
			if not scores[y + 1] then break end
			if scores[y]["score"] < scores[y + 1]["score"] then
				local key = scores[y]
				scores[y] = scores[y + 1]
				scores[y + 1] = key
			end
		end		
	end
	
	for _, p in pairs(game.connected_players) do
		if p.gui.left.maze_score then p.gui.left.maze_score.destroy() end
		local frame = p.gui.left.add({type = "frame", caption = "Score", name = "maze_score"})
		local t = frame.add({type = "table", column_count = 2})
		for i = 1, 16, 1 do
			if scores[i] then
				local l = t.add({type = "label", caption = scores[i].name})
				local color = game.players[scores[i].name].color
				color = {r = color.r * 0.6 + 0.4, g = color.g * 0.6 + 0.4, b = color.b * 0.6 + 0.4, a = 1}
				l.style.font_color = color
				l.style.font = "default-bold"
				t.add({type = "label", caption = scores[i].score})			
			end
		end
	end
end

event.on_nth_tick(120, tick)
event.add(defines.events.on_chunk_charted, on_chunk_charted)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
