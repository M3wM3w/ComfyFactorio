--map by mewmew and kyte

require "maps.island_troopers.map_intro"
require "functions.noise_vector_path"
require "modules.shopping_chests"
require "modules.no_turrets"
require "modules.dangerous_goods"
require "modules.rpg"
require "modules.difficulty_vote"
require "maps.island_troopers.enemies"
require "maps.island_troopers.terrain"

max_island_radius = 128

local function create_stage_gui(player)
	if player.gui.top.stage_gui then return end
	local element = player.gui.top.add({type = "frame", name = "stage_gui", caption = " "})
	local style = element.style
	style.minimal_height = 38
	style.maximal_height = 38
	style.minimal_width = 140
	style.top_padding = 2
	style.left_padding = 4
	style.right_padding = 4
	style.bottom_padding = 2
	style.font_color = {r = 155, g = 85, b = 25}
	style.font = "default-large-bold"	
end

function update_stage_gui()
	if not global.stages then return end
	local caption = "Level: " .. global.current_level
	caption = caption .. "  |  Stage: "
	local stage = global.current_stage
	if stage > #global.stages - 1 then stage = #global.stages - 1 end
	caption = caption .. stage
	caption = caption .. "/"
	caption = caption .. #global.stages - 1
	caption = caption .. "  |  Bugs remaining: "
	caption = caption .. global.alive_enemies
	
	for _, player in pairs(game.connected_players) do
		if player.gui.top.stage_gui then
			player.gui.top.stage_gui.caption = caption
		end
	end
end

local function bring_players()
	local surface = game.surfaces[1]
	for _, player in pairs(game.connected_players) do
		if player.position.y < -1 then
			if player.character then
				if player.character.valid then
					local p = surface.find_non_colliding_position("character", {0, 2}, 8, 0.5)
					if not p then player.teleport({0, 2}, surface) end
					player.teleport(p, surface)
				end
			end
		end
	end
end

local function drift_corpses_toward_beach()
	local surface = game.surfaces[1]
	for _, corpse in pairs(surface.find_entities_filtered({name = "character-corpse"})) do
		if corpse.position.y < 0 then			
			if surface.get_tile(corpse.position).collides_with("resource-layer") then
				corpse.clone{position={corpse.position.x, corpse.position.y + (math.random(50, 250) * 0.01)}, surface=surface, force=corpse.force.name}
				corpse.destroy()
			end 
		end
	end
end

local function get_island_size()
	local r_min = global.current_level + 16
	if r_min > math.floor(max_island_radius * 0.5) then r_min = math.floor(max_island_radius * 0.5) end
	local r_max = global.current_level * 2 + 32
	if r_max > max_island_radius then r_max = max_island_radius end
	return math.random(r_min, r_max)
end

local function set_next_level()	
	global.alive_enemies = 0
	global.alive_boss_enemy_count = 0
	
	global.current_level = global.current_level + 1
	if global.current_level > 1 then bring_players() end
	
	global.current_stage = 1
	global.stage_amount = math.floor(global.current_level * 0.33) + 3
	if global.stage_amount > 9 then global.stage_amount = 9 end
	
	global.path_tiles = nil
	
	local island_size = get_island_size()
	
	global.stages = {}
	global.stages[1] = {
			path_length = 16 + island_size * 1.5,
			size = island_size,
		}
	
	for i = 1, global.stage_amount - 1, 1 do
		island_size = get_island_size()
		global.stages[#global.stages + 1] = {
			path_length = 16 + island_size * 1.5,
			size = island_size,
		}
	end
	global.stages[#global.stages + 1] = {
		path_length = max_island_radius * 7,
		size = false,
	}
	
	--game.print("Level " .. global.current_level)
	update_stage_gui()
	
	global.gamestate = 2
end

local function earn_credits(amount)
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/armor_insert", volume_modifier=0.85}
	end
	game.print(amount .. " credits have been transfered to the factory.", {r = 255, g = 215, b = 0})
	global.credits = global.credits + amount
end

local function slowmo()
	if not global.slowmo then global.slowmo = 0.15 end
	game.speed = global.slowmo
	global.slowmo = global.slowmo + 0.01		
	if game.speed < 1 then return end
	for _, p in pairs(game.connected_players) do
		if p.gui.left["slowmo_cam"] then p.gui.left["slowmo_cam"].destroy() end
	end
	global.slowmo = nil
	global.gamestate = 4 
end

local function wait_until_stage_is_beaten()
	if global.alive_enemies > 0 then return end
	local reward_amount = false
	local gamestate = 2
	local base_reward = 250 * global.current_level
	
	if global.stages[global.current_stage].size then
		if global.current_stage < #global.stages -1 then
			reward_amount = base_reward + global.current_stage * global.current_level * 50
		else
			reward_amount = base_reward + global.current_stage * global.current_level * 150
		end
	else
		game.print("Final Stage complete!")
		game.print("Level is collapsing !!", {r = 255, g = 0, b = 0})
		gamestate = 5
	end		
	
	if reward_amount then
		earn_credits(reward_amount) 
		update_stage_gui()
	end
	global.current_stage = global.current_stage + 1
	global.gamestate = gamestate
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	create_stage_gui(player)
	if player.gui.left["slowmo_cam"] then player.gui.left["slowmo_cam"].destroy() end
	
	update_stage_gui()
	
	if player.online_time > 0 then return end
	player.insert({name = "pistol", count = 1})
	player.insert({name = "firearm-magazine", count = 32})
end


local function on_init()
	game.create_force("enemy_spawners")	
	game.forces.enemy_spawners.set_friend("enemy", true)
	game.forces.enemy.set_friend("enemy_spawners", true)
	
	local surface = game.surfaces[1]
	surface.request_to_generate_chunks({x = 0, y = 0}, 16)
	surface.force_generate_chunk_requests()
	
	--global.tree_raffle = {}
	--for _, e in pairs(game.entity_prototypes) do
	--	if e.type == "tree" then
	--		table.insert(global.tree_raffle, e.name)
	--	end			
	--end
	
	local blacklist = {
		["dark-mud-decal"] = true,
		["sand-dune-decal"] = true,
		["light-mud-decal"] = true,
		["puberty-decal"] = true,
		["sand-decal"] = true,
		["red-desert-decal"] = true,
	}
	global.decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if not blacklist[k] then
			if v.autoplace_specification then
				global.decorative_names[#global.decorative_names+1] = k
			end
		end
	end
	
	global.difficulty_poll_closing_timeout = 3600 * 10
	global.level_vectors = {}
	global.alive_boss_enemy_entities = {}
	global.current_level = 0
	global.gamestate = 1
	
	game.forces.player.set_spawn_position({0, 2}, surface)
end

local msg = {
	"We got the brainbug!",
	"Good job troopers!",
	"I'm doing my part!",
}

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end
	
	if entity.force.name == "enemy_spawners" then
		if entity.type == "unit" then return end
		global.alive_enemies = global.alive_enemies - 1
		return
	end	
	
	if entity.force.name ~= "enemy" then return end

	global.alive_enemies = global.alive_enemies - 1
	update_stage_gui()
	
	if entity.type ~= "unit" then return end
	if not global.alive_boss_enemy_entities[entity.unit_number] then return end
	
	global.alive_boss_enemy_entities[entity.unit_number] = nil
	global.alive_boss_enemy_count = global.alive_boss_enemy_count - 1
	if global.alive_boss_enemy_count == 0 then
		for _, p in pairs(game.connected_players) do
			if p.gui.left["slowmo_cam"] then p.gui.left["slowmo_cam"].destroy() end
			local frame = p.gui.left.add({type = "frame", name = "slowmo_cam", caption = msg[math.random(1, #msg)]})
			local camera = frame.add({type = "camera", name = "mini_cam_element", position = entity.position, zoom = 1.5, surface_index = 1})
			camera.style.minimal_width = 400
			camera.style.minimal_height = 400		
		end
		global.gamestate = 8 	
	end
end

local gamestate_functions = {
	[1] = set_next_level,
	[2] = draw_path_to_next_stage,
	[3] = draw_the_island,
	[4] = wait_until_stage_is_beaten,
	[5] = kill_the_level,
	[8] = slowmo,
}

local function on_tick()	
	gamestate_functions[global.gamestate]()
	if game.tick % 150 == 0 then drift_corpses_toward_beach() end
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)

require "functions.boss_unit"