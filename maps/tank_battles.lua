--tank battles (royale)-- mewmew made this --

local event = require 'utils.event' 
local table_insert = table.insert
local math_random = math.random
local map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'
simplex_noise = simplex_noise.d2
local arena_size = 160

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function get_noise(name, pos)	
	local seed = global.noise_seed
	local noise = {}
	local noise_seed_add = 25000
	if name == "rocks" then		
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == "rocks_2" then		
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
	seed = seed + noise_seed_add
	seed = seed + noise_seed_add
	if name == "terrain" then		
		noise[1] = simplex_noise(pos.x * 0.02, pos.y * 0.02, seed)
		seed = seed + noise_seed_add
		noise[2] = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed)
		seed = seed + noise_seed_add
		local noise = noise[1] + noise[2] * 0.2
		return noise
	end
end

local function create_tank_battle_score_gui()
	for _, player in pairs (game.connected_players) do
		if player.gui.left["tank_battle_score"] then player.gui.left["tank_battle_score"].destroy() end
		local frame = player.gui.left.add({type = "frame", name = "tank_battle_score", direction = "vertical"})
				
		local l = frame.add({type = "label", caption = "Won rounds"})
		l.style.font_color = {r=0.98, g=0.66, b=0.22}
		l.style.font = "default-listbox"
		
		local t = frame.add({type = "table", column_count = 2})
		
		local scores = {}
		for _, player in pairs(game.connected_players) do
			if global.tank_battles_score[player.index] then
				table_insert(scores, {name = player.name, score = global.tank_battles_score[player.index]})
			end
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
				
		for i = 1, 8, 1 do
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

local loot = {
	--{{name = "submachine-gun", count = 1}, weight = 2},
	--{{name = "combat-shotgun", count = 1}, weight = 2},
	--{{name = "flamethrower", count = 1}, weight = 1},
	--{{name = "rocket-launcher", count = 1}, weight = 2},
	
	{{name = "flamethrower-ammo", count = 16}, weight = 2},
	{{name = "piercing-shotgun-shell", count = 16}, weight = 2},
	--{{name = "piercing-rounds-magazine", count = 16}, weight = 2},
	--{{name = "uranium-rounds-magazine", count = 8}, weight = 1},
	{{name = "explosive-rocket", count = 8}, weight = 2},
	{{name = "rocket", count = 8}, weight = 2},	
	
	{{name = "grenade", count = 16}, weight = 2},
	{{name = "cluster-grenade", count = 8}, weight = 2},
	--{{name = "poison-capsule", count = 4}, weight = 1},		 
	{{name = "defender-capsule", count = 6}, weight = 1},
	{{name = "distractor-capsule", count = 3}, weight = 1},
	--{{name = "destroyer-capsule", count = 1}, weight = 1},
			
	{{name = "cannon-shell", count = 8}, weight = 16},
	{{name = "explosive-cannon-shell", count = 8}, weight = 16},
	{{name = "uranium-cannon-shell", count = 8}, weight = 6},
	{{name = "explosive-uranium-cannon-shell", count = 8}, weight = 6},				
	
	--{{name = "light-armor", count = 1}, weight = 5},
	--{{name = "heavy-armor", count = 1}, weight = 2},
	{{name = "modular-armor", count = 1}, weight = 3},
	{{name = "power-armor", count = 1}, weight = 2},
	{{name = "power-armor-mk2", count = 1}, weight = 1},
	
	--{{name = "battery-mk2-equipment", count = 1}, weight = 2},
	{{name = "energy-shield-equipment", count = 1}, weight = 2},
	{{name = "exoskeleton-equipment", count = 1}, weight = 2},
	{{name = "fusion-reactor-equipment", count = 1}, weight = 2},
	
	{{name = "repair-pack", count = 1}, weight = 6},
	
	{{name = "coal", count = 16}, weight = 3},
	--{{name = "solid-fuel", count = 8}, weight = 2},
	{{name = "nuclear-fuel", count = 1}, weight = 1},
	
	{{name = "gate", count = 16}, weight = 2},
	{{name = "stone-wall", count = 16}, weight = 2}
}
local loot_raffle = {}
for _, item in pairs(loot) do
	for x = 1, item.weight, 1 do			
		table.insert(loot_raffle, item[1])			
	end			
end

local function get_valid_random_spawn_position(surface)
	local chunks = {}	
	for chunk in surface.get_chunks() do
		table_insert(chunks, {x = chunk.x, y = chunk.y})
	end
	chunks = shuffle(chunks)
	
	for _, chunk in pairs(chunks) do
		if chunk.x * 32 < arena_size and chunk.y * 32 < arena_size and chunk.x * 32 >= arena_size * -1 and chunk.y * 32 >= arena_size * -1 then
			local area = {{chunk.x * 32 - 64, chunk.y * 32 - 64}, {chunk.x * 32 + 64, chunk.y * 32 + 64}}			
			if surface.count_entities_filtered({name = "tank", area = area}) == 0 then
				local pos = surface.find_non_colliding_position("tank", {chunk.x * 32 + 16, chunk.y * 32 + 16}, 16, 8)
				return pos
			end
		end
	end
	
	local pos = surface.find_non_colliding_position("tank", {0, 0}, 32, 4)
	if pos then return pos end
	
	return {0, 0}
end

local function put_players_into_arena()
	for _, player in pairs(game.connected_players) do	
		local permissions_group = game.permissions.get_group("Default")	
		permissions_group.add_player(player.name)
		
		if player.character then
			player.character.destroy()
			player.character = nil
		end
		
		
		
		player.create_character()
		
		player.insert({name = "combat-shotgun", count = 1})
		player.insert({name = "rocket-launcher", count = 1})
		player.insert({name = "flamethrower", count = 1})
		
		local surface = game.surfaces["nauvis"]
		local pos = get_valid_random_spawn_position(surface)
		
		player.force.chart(surface,{{x = -1 * arena_size, y = -1 * arena_size}, {x = arena_size, y = arena_size}})
		
		player.teleport(pos, surface)
		local tank = surface.create_entity({name = "tank", force = game.forces[player.index], position = pos})
		tank.insert({name = "coal", count = 24})
		tank.insert({name = "cannon-shell", count = 16})		
		tank.set_driver(player)
	end
end

local function get_arena_layout_modifiers()
	global.arena_layout_modifiers = {}
	
	local tree_raffle = {}
	for _, e in pairs(game.entity_prototypes) do
		if e.type == "tree" then
			table.insert(tree_raffle, e.name)
		end			
	end
	global.arena_layout_modifiers.arena_tree = tree_raffle[math_random(1, #tree_raffle)]
	global.arena_layout_modifiers.arena_tree_chance = math_random(4, 20)
	global.arena_layout_modifiers.arena_tree_noise = math_random(0, 75) * 0.01
	
	local entity_raffle = {}
	local types = {"furnace", "assembling-machine", "power-switch", "programmable-speaker", "reactor"}
	for _, e in pairs(game.entity_prototypes) do
		for _, t in pairs(types) do
			if e.type == t then
				table.insert(entity_raffle, e.name)				
			end
		end
	end
	global.arena_layout_modifiers.secret_entity = entity_raffle[math_random(1, #entity_raffle)]
	
	local tile_raffle = {}
	local tile_blacklist = {
			["water"] = true,
			["deepwater"] = true,
			["water-green"] = true,
			["deepwater-green"] = true,			
			["out-of-map"] = true,
			["hazard-concrete-left"] = true,
			["hazard-concrete-right"] = true,
			["lab-dark-1"] = true,
			["lab-dark-2"] = true,
			["lab-white"] = true,
			["refined-hazard-concrete-left"] = true,
			["refined-hazard-concrete-right"] = true,			
			["tutorial-grid"] = true
		}
	for _, t in pairs(game.tile_prototypes) do		
		if not tile_blacklist[t.name] then
			table.insert(tile_raffle, t.name)
		end		
	end
	global.arena_layout_modifiers.arena_tile_1 = tile_raffle[math_random(1, #tile_raffle)]
	global.arena_layout_modifiers.arena_tile_2 = tile_raffle[math_random(1, #tile_raffle)]
end

local function regenerate_arena()
	local surface = game.surfaces["nauvis"]
	for chunk in surface.get_chunks() do
		surface.set_chunk_generated_status(chunk, defines.chunk_generated_status.custom_tiles	)
	end
	global.noise_seed = nil	
	surface.request_to_generate_chunks({0,0}, math.ceil(arena_size / 32) + 3)
		
	get_arena_layout_modifiers()
	
	surface.force_generate_chunk_requests()
	surface.daytime = 1
	surface.freeze_daytime = 1
	
	global.current_arena_size = arena_size
		
	put_players_into_arena()
	
	global.game_stage = "ongoing_game"
end

function shrink_arena()
	local surface = game.surfaces["nauvis"]	
	
	if global.current_arena_size < 0 then return end
	
	local shrink_width = 8
	local current_arena_size = global.current_arena_size
	local tiles = {}
	
	for x = arena_size * -1, arena_size, 1 do
		for y = current_arena_size * -1 - shrink_width, current_arena_size * -1, 1 do
			local pos = {x = x, y = y}
			if surface.get_tile(pos).name ~= "water" and surface.get_tile(pos).name ~= "deepwater" then
				if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then				
					if math_random(1, 3) ~= 1 then
						table_insert(tiles, {name = "water", position = pos})
					end
				end
			end
		end
	end	
		
	for x = arena_size * -1, arena_size, 1 do
		for y = current_arena_size, current_arena_size + shrink_width, 1 do
			local pos = {x = x, y = y}
			if surface.get_tile(pos).name ~= "water" and surface.get_tile(pos).name ~= "deepwater" then
				if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then				
					if math_random(1, 3) ~= 1 then
						table_insert(tiles, {name = "water", position = pos})
					end
				end
			end
		end
	end	
	
	for x = current_arena_size * -1 - shrink_width, current_arena_size * -1, 1 do
		for y = arena_size * -1, arena_size, 1 do
			local pos = {x = x, y = y}
			if surface.get_tile(pos).name ~= "water" and surface.get_tile(pos).name ~= "deepwater" then
				if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then				
					if math_random(1, 3) ~= 1 then
						table_insert(tiles, {name = "water", position = pos})
					end
				end
			end
		end
	end	
	
	for x = current_arena_size, current_arena_size + shrink_width, 1 do
		for y = arena_size * -1, arena_size, 1 do
			local pos = {x = x, y = y}
			if surface.get_tile(pos).name ~= "water" and surface.get_tile(pos).name ~= "deepwater" then
				if x > current_arena_size or y > current_arena_size or x < current_arena_size * -1 or y < current_arena_size * -1 then				
					if math_random(1, 3) ~= 1 then
						table_insert(tiles, {name = "water", position = pos})
					end
				end
			end
		end
	end	
	
	global.current_arena_size = global.current_arena_size - 1
	
	surface.set_tiles(tiles, true)
end

local function get_arena_entity(surface, pos)
	local entity = false
	local noise = get_noise("rocks", pos)
	local noise2 = get_noise("rocks_2", pos)
	
	if noise > -0.1 and noise < 0.1 and noise2 > -0.3 and noise2 < 0.3 then
		return {name = "rock-big", position = pos}
	end
	
	if math_random(1, 16) == 1 and noise2 > 0.78 then
		if surface.can_place_entity({name = "wooden-chest", position = pos, force = "enemy"}) then
			return {name = "wooden-chest", position = pos, force = "enemy"}
		end
	end
	
	if math_random(1, 16) == 1 and noise2 < -0.78 then
		if surface.can_place_entity({name = "wooden-chest", position = pos, force = "enemy"}) then
			return {name = "wooden-chest", position = pos, force = "enemy"}
		end
	end

	if math_random(1, global.arena_layout_modifiers.arena_tree_chance) == 1 and noise > global.arena_layout_modifiers.arena_tree_noise then
		return {name = global.arena_layout_modifiers.arena_tree, position = pos}		
	end
	
	if math_random(1, 1024) == 1 then
		if math_random(1, 16) == 1 then
			if surface.can_place_entity({name = global.arena_layout_modifiers.secret_entity, position = pos, force = "enemy"}) then
				return {name = global.arena_layout_modifiers.secret_entity, position = pos, force = "enemy"}
			end
		end
		if math_random(1, 64) == 1 then
			if surface.can_place_entity({name = "big-worm-turret", position = pos, force = "enemy"}) then
				return {name = "big-worm-turret", position = pos, force = "enemy"}
			end
		end
		if math_random(1, 32) == 1 then
			if surface.can_place_entity({name = "medium-worm-turret", position = pos, force = "enemy"}) then
				return {name = "medium-worm-turret", position = pos, force = "enemy"}
			end
		end
		if math_random(1, 512) == 1 then
			if surface.can_place_entity({name = "behemoth-biter", position = pos, force = "enemy"}) then
				return {name = "behemoth-biter", position = pos, force = "enemy"}
			end
		end
		if math_random(1, 64) == 1 then
			if surface.can_place_entity({name = "big-biter", position = pos, force = "enemy"}) then
				return {name = "big-biter", position = pos, force = "enemy"}
			end
		end
	end
end

local function render_arena_chunk(event)
	if not global.noise_seed then global.noise_seed = math_random(1, 2097152) end
	local surface = event.surface	
	local left_top = event.area.left_top
	
	for _, entity in pairs(surface.find_entities_filtered({area = event.area})) do
		if entity.valid then
			if entity.name ~= "character" then
				entity.destroy()
			end
		end
	end
	
	local tiles = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if pos.x > arena_size or pos.y > arena_size or pos.x < arena_size * -1 or pos.y < arena_size * -1 then
				table_insert(tiles, {name = "water", position = pos})
			else
				local noise = get_noise("terrain", pos)
				if noise > 0 then
					table_insert(tiles, {name = global.arena_layout_modifiers.arena_tile_1, position = pos})
				else
					table_insert(tiles, {name = global.arena_layout_modifiers.arena_tile_2, position = pos})
				end
				local entity = get_arena_entity(surface, pos)
				if entity then surface.create_entity(entity) end															
			end			
		end
	end
	surface.set_tiles(tiles, true)	
end

local function kill_idle_players()
	for _, player in pairs(game.connected_players) do
		if player.character then
			if player.afk_time > 600 then
				local area = {{player.position.x - 1, player.position.y - 1}, {player.position.x + 1, player.position.y + 1}}
				local water_tile_count = player.surface.count_tiles_filtered({name = {"water", "deepwater"}, area = area})
				if water_tile_count > 3 then
					player.character.die()
					game.print(player.name .. " drowned.", {r = 150, g = 150, b = 0})
				else
					if player.afk_time > 9000 then					
						player.character.die()
						game.print(player.name .. " was idle for too long.", {r = 150, g = 150, b = 0})
					end
				end
			end
		end
	end
end

local function check_for_game_over()
	local surface = game.surfaces["nauvis"]
	
	kill_idle_players()
	
	local alive_players = 0
	for _, player in pairs(game.connected_players) do
		if player.character then
			alive_players = alive_players + 1			
		end
	end		
	
	if alive_players > 1 then return end -----------------
	
	local player
	for _, p in pairs(game.connected_players) do
		if p.character then
			player = p
		end
	end
	
	if alive_players == 1 then
		if not global.tank_battles_score[player.index] then
			global.tank_battles_score[player.index] = 1
		else
			global.tank_battles_score[player.index] = global.tank_battles_score[player.index] + 1
		end
		game.print(player.name .. " has won the battle!", {r = 150, g = 150, b = 0})
		create_tank_battle_score_gui()
	end

	if alive_players == 0 then
		game.print("No alive players! Round ends in a draw!", {r = 150, g = 150, b = 0})
	end
	
	global.game_stage = "lobby"		
end

local function set_unique_player_force(player)
	if not game.forces[player.index] then
		game.create_force(player.index)
		game.forces[player.index].technologies["follower-robot-count-1"].researched = true
		game.forces[player.index].technologies["follower-robot-count-2"].researched = true
		game.forces[player.index].technologies["follower-robot-count-3"].researched = true
		game.forces[player.index].technologies["follower-robot-count-4"].researched = true
		game.forces[player.index].technologies["follower-robot-count-5"].researched = true
	end
	player.force = game.forces[player.index]	
end

local function on_player_joined_game(event)	
	local player = game.players[event.player_index]
	
	set_unique_player_force(player)	
	
	if not global.map_init_done then
			
		local spectator_permission_group = game.permissions.create_group("Spectator")
		for action_name, _ in pairs(defines.input_action) do
			spectator_permission_group.set_allows_action(defines.input_action[action_name], false)
		end
		spectator_permission_group.set_allows_action(defines.input_action.write_to_console, true)
		spectator_permission_group.set_allows_action(defines.input_action.gui_click, true)
		spectator_permission_group.set_allows_action(defines.input_action.gui_selection_state_changed, true)
		spectator_permission_group.set_allows_action(defines.input_action.start_walking, true)
		spectator_permission_group.set_allows_action(defines.input_action.open_kills_gui, true)
		spectator_permission_group.set_allows_action(defines.input_action.open_character_gui, true)
		--spectator_permission_group.set_allows_action(defines.input_action.open_equipment_gui, true)
		spectator_permission_group.set_allows_action(defines.input_action.edit_permission_group, true)	
		spectator_permission_group.set_allows_action(defines.input_action.toggle_show_entity_info, true)									
			
		get_arena_layout_modifiers()
			
		global.tank_battles_score = {}
		global.game_stage = "lobby"
		
		global.map_init_done = true
	end		
	
	if #global.tank_battles_score > 0 then
		create_tank_battle_score_gui()
	end
	
	if game.surfaces["nauvis"] then
		player.character.destroy()
		player.character = nil
		local permissions_group = game.permissions.get_group("Spectator")	
		permissions_group.add_player(player.name)			
		player.teleport({0, 0}, game.surfaces["nauvis"])
		if global.lobby_timer then global.lobby_timer = 1200 end
	end	
end

local function on_marked_for_deconstruction(event)
	event.entity.cancel_deconstruction(game.players[event.player_index].force.name)	
end

local function on_chunk_generated(event)
	render_arena_chunk(event)
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	
	local permissions_group = game.permissions.get_group("Spectator")	
	permissions_group.add_player(player.name)	
	player.character.destroy()
	player.character = nil
	
	player.print("You are now spectating.", {r = 0, g = 150, b = 150})
end

local function lobby()				
	local connected_players_count = 0
	local permissions_group = game.permissions.get_group("Default")
	
	for _, player in pairs(game.connected_players) do				
		 connected_players_count = connected_players_count + 1
	end
	
	if connected_players_count < 2 then
		--game.print("Waiting for players.", {r = 0, g = 150, b = 150})
		return
	end
	
	if not global.lobby_timer then global.lobby_timer = 1200 end
	if global.lobby_timer % 600 == 0 then
		if global.lobby_timer <= 0 then 
			game.print("Round has started!", {r = 0, g = 150, b = 150})
		else
			game.print("Round will begin in " .. global.lobby_timer / 60 .. " seconds.", {r = 0, g = 150, b = 150})
		end
	end
	global.lobby_timer = global.lobby_timer - 300
	if global.lobby_timer >= 0 then return end
	global.lobby_timer = nil
	global.game_stage = "regenerate_arena"
end

local function on_tick(event)
	if game.tick % 300 == 0 then
		if global.game_stage == "lobby" then			
			lobby()
		end
		if global.game_stage == "regenerate_arena" then
			regenerate_arena()
		end
		if global.game_stage == "ongoing_game" then
			shrink_arena()
			check_for_game_over()
		end		
	end
end

local function on_entity_died(event)
	if event.entity.name == "wooden-chest" then
		local loot = loot_raffle[math_random(1, #loot_raffle)]
		event.entity.surface.spill_item_stack(event.entity.position, loot, true)
		--event.entity.surface.create_entity({name = "flying-text", position = event.entity.position, text = loot.name, color = {r=0.98, g=0.66, b=0.22}})
	end
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	local str = " "
	if event.cause then
		if event.cause.name ~= nil then str = " by " .. event.cause.name end	
		if event.cause.name == "character" then str = " by " .. event.cause.player.name end
		if event.cause.name == "tank" then
			local driver = event.cause.get_driver()
			if driver.player then 
				str = " by " .. driver.player.name
			end
		end
	end
	for _, target_player in pairs(game.connected_players) do
		if target_player.name ~= player.name then
			player.print(player.name .. " was killed" .. str, { r=0.99, g=0.0, b=0.0})
		end
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
	
	for _, target_player in pairs(game.connected_players) do
		if target_player.name ~= player.name then
			target_player.print(player.name .. ": ".. event.message, color)
		end
	end
end

event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_console_chat, on_console_chat)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_player_died, on_player_died)
event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_chunk_generated, on_chunk_generated)