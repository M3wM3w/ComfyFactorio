-- Deep dark dungeons by mewmew --

require "modules.mineable_wreckage_yields_scrap"
require "modules.satellite_score"

local MapInfo = require "modules.map_info"
local Room_generator = require "functions.room_generator"
local RPG = require "modules.rpg"
local BiterHealthBooster = require "modules.biter_health_booster"
local BiterRaffle = require "functions.biter_raffle"
local Functions = require "maps.dungeons.functions"
local Get_noise = require "utils.get_noise"

local Biomes = {}
Biomes.dirtlands = require "maps.dungeons.biome_dirtlands"
Biomes.desert = require "maps.dungeons.biome_desert"
Biomes.red_desert = require "maps.dungeons.biome_red_desert"
Biomes.grasslands = require "maps.dungeons.biome_grasslands"
Biomes.concrete = require "maps.dungeons.biome_concrete"
Biomes.doom = require "maps.dungeons.biome_doom"
Biomes.deepblue = require "maps.dungeons.biome_deepblue"
Biomes.glitch = require "maps.dungeons.biome_glitch"
Biomes.acid_zone = require "maps.dungeons.biome_acid_zone"
Biomes.rainbow = require "maps.dungeons.biome_rainbow"

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local table_remove = table.remove
local math_random = math.random
local math_abs = math.abs
local math_floor = math.floor
local math_round = math.round

local disabled_for_deconstruction = {
		["fish"] = true,
		["rock-huge"] = true,
		["rock-big"] = true,
		["sand-rock-big"] = true,
		["mineable-wreckage"] = true
	}

local function get_biome(position)
	--if not a then return "concrete" end
	if position.x ^ 2 + position.y ^ 2 < 6400 then return "dirtlands" end

	local seed = game.surfaces[1].map_gen_settings.seed
	local seed_addition = 100000	
	
	local a = 1	
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.66 then return "glitch" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.60 then return "doom" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.62 then return "acid_zone" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.60 then return "concrete" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.71 then return "rainbow" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.53 then return "deepblue" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.22 then return "grasslands" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.22 then return "desert" end
	a = a + 1
	if Get_noise("dungeons", position, seed + seed_addition * a) > 0.22 then return "red_desert" end
		
	return "dirtlands"
end

local function draw_depth_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top.dungeon_depth then player.gui.top.dungeon_depth.destroy() end
		local element = player.gui.top.add({type = "sprite-button", name = "dungeon_depth", caption = "~ Depth " .. global.dungeons.depth .. " ~"})
		
		element.tooltip = "Evolution: " .. Functions.get_dungeon_evolution_factor() * 100 .. "%"
		element.tooltip = element.tooltip .. "\nEnemy Health: " .. global.biter_health_boost * 100 .. "%"
		element.tooltip = element.tooltip .. "\nEnemy Damage: " .. math_round(game.forces.enemy.get_ammo_damage_modifier("melee") * 100 + 100, 1) .. "%"
		
		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 146
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 0, g = 0, b = 0}
		style.font = "default-large-bold"
	end
end

local function expand(surface, position)
	local room = Room_generator.get_room(surface, position)
	if not room then return end
	local name = get_biome(position)
	Biomes[name](surface, room)
	
	if not room.room_tiles[1] then return end
	
	local a = 2000
	
	global.dungeons.depth = global.dungeons.depth + 1
	
	local evo = Functions.get_dungeon_evolution_factor()
	
	local force = game.forces.enemy
	force.evolution_factor = evo
	
	if evo > 1 then
		global.biter_health_boost = 2 + ((evo - 1) * 2)
		local damage_mod = (evo - 1) * 0.35		
		force.set_ammo_damage_modifier("melee", damage_mod)
		force.set_ammo_damage_modifier("biological", damage_mod)
		force.set_ammo_damage_modifier("artillery-shell", damage_mod)
		force.set_ammo_damage_modifier("flamethrower", damage_mod)
		force.set_ammo_damage_modifier("laser-turret", damage_mod)
	else
		global.biter_health_boost = 1 + evo
	end
	
	global.biter_health_boost = math_round(global.biter_health_boost, 2)
	
	draw_depth_gui()
end

local function init_player(player)
	if player.character then
		player.disassociate_character(player.character)
		player.character.destroy()
	end

	player.set_controller({type=defines.controllers.god})
	player.create_character()
	
	local surface = game.surfaces["dungeons"]
	player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
	player.insert({name = "raw-fish", count = 8})	
	player.set_quick_bar_slot(1, "raw-fish")
	player.insert({name = "pistol", count = 1})
	player.insert({name = "firearm-magazine", count = 16})
end

local function on_entity_spawned(event)
	local spawner = event.spawner
	local unit = event.entity
	local surface = spawner.surface

	local spawner_tier = global.dungeons.spawner_tier
	if not spawner_tier[spawner.unit_number] then
		Functions.set_spawner_tier(spawner)
	end

	local e = Functions.get_dungeon_evolution_factor()
	for _ = 1, spawner_tier[spawner.unit_number], 1 do
		local name = BiterRaffle.roll("mixed", e)
		local non_colliding_position = surface.find_non_colliding_position(name, unit.position, 16, 1)
		local bonus_unit
		if non_colliding_position then
			bonus_unit = surface.create_entity({name = name, position = non_colliding_position, force = "enemy"})
		else
			bonus_unit = surface.create_entity({name = name, position = unit.position, force = "enemy"})
		end	
		bonus_unit.ai_settings.allow_try_return_to_spawner = true
		bonus_unit.ai_settings.allow_destroy_when_commands_fail = true
		
		if math_random(1, 256) == 1 then
			BiterHealthBooster.add_boss_unit(bonus_unit, global.biter_health_boost * 8, 0.25)
		end
	end
	
	if math_random(1, 256) == 1 then
		BiterHealthBooster.add_boss_unit(unit, global.biter_health_boost * 8, 0.25)
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "dungeons" then return end
	
	local left_top = event.area.left_top

	local tiles = {}
	local i = 1
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local position = {x = left_top.x + x, y = left_top.y + y}				
			tiles[i] = {name = "out-of-map", position = position}
			i = i + 1
		end
	end
	surface.set_tiles(tiles, true)

	local rock_positions = {}
	local set_tiles = surface.set_tiles
	local nauvis_seed = game.surfaces[1].map_gen_settings.seed
	local s = math_floor(nauvis_seed * 0.1) + 100
	for a = 1, 7, 1 do
		local b = a * s
		local c = 0.0035 + a * 0.0035
		local d = c * 0.5
		local seed = nauvis_seed + b
		if math_abs(Get_noise("dungeon_sewer", {x = left_top.x + 16, y = left_top.y + 16}, seed)) < 0.12 then
			for x = 0, 31, 1 do
				for y = 0, 31, 1 do
					local position = {x = left_top.x + x, y = left_top.y + y}
					local noise = math_abs(Get_noise("dungeon_sewer", position, seed))
					if noise < c then
						local tile_name = surface.get_tile(position).name
						if noise > d and tile_name ~= "deepwater-green" then
							set_tiles({{name = "water-green", position = position}}, true)
							if math_random(1, 320) == 1 and noise > c - 0.001 then table_insert(rock_positions, position) end
						else
							set_tiles({{name = "deepwater-green", position = position}}, true)
							if math_random(1, 64) == 1 then
								surface.create_entity({name = "fish", position = position})
							end
						end		
					end
				end
			end			
		end		
	end

	for _, p in pairs(rock_positions) do Functions.place_border_rock(surface, p) end

	if left_top.x == 160 and left_top.y == 160 then		
		Functions.draw_spawn(surface)
		for _, p in pairs(game.connected_players) do init_player(p) end
		game.forces.player.chart(surface, {{-256, -256}, {256, 256}})
	end
end

local function on_player_joined_game(event)
	draw_depth_gui()
	if game.tick == 0 then return end
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		init_player(player)
	end	
end

local function spawner_death(entity)
	local tier = global.dungeons.spawner_tier[entity.unit_number]
	
	if not tier then
		Functions.set_spawner_tier(entity)
		tier = global.dungeons.spawner_tier[entity.unit_number]
	end
	
	for _ = 1, tier * 2, 1 do
		Functions.spawn_random_biter(entity.surface, entity.position)
	end
	
	global.dungeons.spawner_tier[entity.unit_number] = nil
end

--make expansion rocks very durable against biters
local function on_entity_damaged(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force
	if math_random(1, 256) == 1 then return end
	if entity.name ~= "rock-big" then return end
	entity.health = entity.health + event.final_damage_amount
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "simple-entity" then
		Functions.mining_events(entity)
	end
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then return end	
	if entity.type == "unit-spawner" then
		spawner_death(entity)
	end
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_marked_for_deconstruction(event)	
	if disabled_for_deconstruction[event.entity.name] then
		event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
	end
end

local function on_init()
	local force = game.create_force("dungeon")
	force.set_friend("enemy", false)
	force.set_friend("player", false)

	local map_gen_settings = {
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["default_enable_all_autoplace_controls"] = false,
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
	}
	local surface = game.create_surface("dungeons", map_gen_settings)
	
	surface.request_to_generate_chunks({0,0}, 8)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.30
	
	local surface = game.surfaces[1]
	local map_gen_settings = surface.map_gen_settings
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	surface.map_gen_settings = map_gen_settings
	for chunk in surface.get_chunks() do		
		surface.delete_chunk({chunk.x, chunk.y})		
	end
	
	game.forces.player.manual_mining_speed_modifier = 0.5
	
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_cooldown = 18000
	game.map_settings.enemy_expansion.min_expansion_cooldown = 3600
	game.map_settings.enemy_expansion.settler_group_max_size = 128
	game.map_settings.enemy_expansion.settler_group_min_size = 16
	game.map_settings.enemy_expansion.max_expansion_distance = 16
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 0.50
	
	global.dungeons = {}
	global.dungeons.depth = 0
	global.dungeons.spawn_size = 42
	global.dungeons.spawner_tier = {}
	
	global.rocks_yield_ore_base_amount = 100
	global.rocks_yield_ore_distance_modifier = 0.001
	
	local T = MapInfo.Pop_info()
	T.localised_category = "dungeons"
	T.main_caption_color = {r = 0, g = 0, b = 0}
	T.sub_caption_color = {r = 150, g = 0, b = 20}
end
--[[
local function on_tick()
	if game.tick % 4 ~= 0 then return end
	
	local surface = game.surfaces["dungeons"]
	
	local entities = surface.find_entities_filtered({name = "rock-big"})
	if not entities[1] then return end
	
	local entity = entities[math_random(1, #entities)]
	
	surface.request_to_generate_chunks(entity.position, 3)
	surface.force_generate_chunk_requests()
	
	game.forces.player.chart(surface, {{entity.position.x - 32, entity.position.y - 32}, {entity.position.x + 32, entity.position.y + 32}})
	
	entity.die()
end
]]
local Event = require 'utils.event' 
Event.on_init(on_init)
--Event.add(defines.events.on_tick, on_tick)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)

require "modules.rocks_yield_ore"