-- Deep dark dungeons by mewmew --

require "modules.mineable_wreckage_yields_scrap"
require "modules.satellite_score"
require 'modules.charging_station'

local MapInfo = require "modules.map_info"
local Room_generator = require "functions.room_generator"
require "modules.rpg.main"
local RPG_F = require "modules.rpg.functions"
local RPG_T = require 'modules.rpg.table'
local BiterHealthBooster = require "modules.biter_health_booster_v2"
local BiterRaffle = require "functions.biter_raffle"
local Functions = require "maps.dungeons.functions"
local Get_noise = require "utils.get_noise"
local Alert = require 'utils.alert'
local DungeonsTable = require 'maps.dungeons.table'
require 'maps.dungeons.boss_arena'

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
Biomes.treasure = require "maps.dungeons.biome_treasure"
Biomes.market = require "maps.dungeons.biome_market"
Biomes.laboratory = require "maps.dungeons.biome_laboratory"

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
		["crash-site-spaceship-wreck-small-1"] = true,
	  ["crash-site-spaceship-wreck-small-2"] = true,
	  ["crash-site-spaceship-wreck-small-3"] = true,
	  ["crash-site-spaceship-wreck-small-4"] = true,
	  ["crash-site-spaceship-wreck-small-5"] = true,
	  ["crash-site-spaceship-wreck-small-6"] = true
	}

local function get_biome(position, surface_index)
	--if not a then return "concrete" end
	if position.x ^ 2 + position.y ^ 2 < 6400 then return "dirtlands" end

	local seed = game.surfaces[surface_index].map_gen_settings.seed
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

local locked_researches = {
	[0] = "steel-axe",
	[1] = "heavy-armor",
	[2] = "military-2",
	[3] = "physical-projectile-damage-2",
	[4] = "oil-processing",
	[5] = "stronger-explosives-2",
	[6] = "military-science-pack",
	[7] = "rocketry",
	[8] = "chemical-science-pack",
	[9] = "military-3",
	[10] = "flamethrower",
	[11] = "distractor",
	[12] = "laser",
	[13] = "laser-shooting-speed-3",
	[14] = "power-armor",
	[15] = "nuclear-power",
	[16] = "production-science-pack",
	[17] = "energy-weapons-damage-3",
	[18] = "utility-science-pack",
	[19] = "kovarex-enrichment-process",
	[20] = "power-armor-mk2",
	[22] = "fusion-reactor-equipment",
	[24] = "discharge-defense-equipment",
	[30] = "atomic-bomb",
	[35] = "spidertron"
}

local function draw_arrows_gui()
	for _, player in pairs(game.connected_players) do
		if not player.gui.top.dungeon_down then
			player.gui.top.add({type = "sprite-button", name = "dungeon_down", sprite = "utility/editor_speed_down", tooltip = {"dungeons_tiered.descend"}})
		end
		if not player.gui.top.dungeon_up then
			player.gui.top.add({type = "sprite-button", name = "dungeon_up", sprite = "utility/editor_speed_up", tooltip = {"dungeons_tiered.ascend"}})
		end
	end
end

local function get_surface_research(index)
	local dungeontable = DungeonsTable.get_dungeontable()
	return locked_researches[index - dungeontable.original_surface_index]
end

local function draw_depth_gui()
	local dungeontable = DungeonsTable.get_dungeontable()
	local forceshp = BiterHealthBooster.get("biter_health_boost_forces")
	for _, player in pairs(game.connected_players) do
		local surface = player.surface
		local techs = 0
		if get_surface_research(surface.index) and game.forces.player.technologies[get_surface_research(surface.index)].enabled == false then techs = 1 end
		local enemy_force = dungeontable.enemy_forces[surface.index]
		if player.gui.top.dungeon_depth then player.gui.top.dungeon_depth.destroy() end
		if surface.name == "gulag" or surface.name == "nauvis" or surface.name == "dungeons_floor_arena" then return end
		local element = player.gui.top.add({type = "sprite-button", name = "dungeon_depth"})
		element.caption = {"dungeons_tiered.depth", surface.index - dungeontable.original_surface_index, dungeontable.depth[surface.index]}
		element.tooltip = {
			"dungeons_tiered.depth_tooltip",
			Functions.get_dungeon_evolution_factor(surface.index) * 100,
			forceshp[enemy_force.index] * 100,
			math_round(enemy_force.get_ammo_damage_modifier("melee") * 100 + 100, 1),
			Functions.get_dungeon_evolution_factor(surface.index) * 2000,
			dungeontable.treasures[surface.index],
			techs
		}

		local style = element.style
		style.minimal_height = 38
		style.maximal_height = 38
		style.minimal_width = 236
		style.top_padding = 2
		style.left_padding = 4
		style.right_padding = 4
		style.bottom_padding = 2
		style.font_color = {r = 0, g = 0, b = 0}
		style.font = "default-large-bold"
	end
end

local function unlock_researches(surface_index)
	local dungeontable = DungeonsTable.get_dungeontable()
	local tech = game.forces.player.technologies
	if get_surface_research(surface_index) and tech[get_surface_research(surface_index)].enabled == false then
		tech[get_surface_research(surface_index)].enabled = true
		game.print({"dungeons_tiered.tech_unlock", "[technology=" .. get_surface_research(surface_index) .. "]", surface_index - dungeontable.original_surface_index})
	end
end

local function expand(surface, position)
	local dungeontable = DungeonsTable.get_dungeontable()
	local forceshp = BiterHealthBooster.get("biter_health_boost_forces")
	local room
	local roll = math_random(1,100)
	if roll > 96 then
			room = Room_generator.get_room(surface, position, "big")
	elseif roll > 88 then
			room = Room_generator.get_room(surface, position, "wide")
	elseif roll > 80 then
			room = Room_generator.get_room(surface, position, "tall")
	elseif roll > 50 then
			room = Room_generator.get_room(surface, position, "rect")
	else
			room = Room_generator.get_room(surface, position, "square")
	end
	if not room then return end
	if dungeontable.treasures[surface.index] < 5 and dungeontable.surface_size[surface.index] >= 225 and math.random(1,50) == 1 then
		Biomes["treasure"](surface, room)
		if room.room_tiles[1] then
			dungeontable.treasures[surface.index] = dungeontable.treasures[surface.index] + 1
			game.print({"dungeons_tiered.treasure_room", surface.index - dungeontable.original_surface_index}, {r = 0.88, g = 0.22, b = 0})
		end
	elseif dungeontable.surface_size[surface.index] >= 225 and math.random(1,50) == 1 and get_surface_research(surface.index) and game.forces.player.technologies[get_surface_research(surface.index)].enabled == false then
		Biomes["laboratory"](surface, room)
		if room.room_tiles[1] then
			unlock_researches(surface.index)
		end
	elseif math_random(1,256) == 1 then
		Biomes["market"](surface, room)
	else
		local name = get_biome(position, surface.index)
		Biomes[name](surface, room)
	end

	if not room.room_tiles[1] then return end

	dungeontable.depth[surface.index] = dungeontable.depth[surface.index] + 1
	dungeontable.surface_size[surface.index] = 200 + (dungeontable.depth[surface.index] - 100 * (surface.index - dungeontable.original_surface_index)) / 4

	local evo = Functions.get_dungeon_evolution_factor(surface.index)

	local force = dungeontable.enemy_forces[surface.index]
	force.evolution_factor = evo

	if evo > 1 then
		forceshp[force.index] = 3 + ((evo - 1) * 4)
		local damage_mod = (evo - 1) * 0.35
		force.set_ammo_damage_modifier("melee", damage_mod)
		force.set_ammo_damage_modifier("biological", damage_mod)
		force.set_ammo_damage_modifier("artillery-shell", damage_mod)
		force.set_ammo_damage_modifier("flamethrower", damage_mod)
		force.set_ammo_damage_modifier("laser", damage_mod)
	else
		forceshp[force.index] = 1 + evo * 2
	end

	forceshp[force.index] = math_round(forceshp[force.index], 2)
	draw_depth_gui()
end

local function draw_light(player)
	if not player.character then return end
	local rpg = RPG_T.get("rpg_t")
	local magicka = rpg[player.index].magicka
	local scale = 1
	if magicka < 50 then return end
	if magicka >= 100 then scale = 2 end
	if magicka >= 150 then scale = 3 end
	if magicka >= 200 then scale = 4 end
	rendering.draw_light({
		sprite = "utility/light_medium", scale = scale * 5, intensity = scale, minimum_darkness = 0,
		oriented = false, color = {255,255,255}, target = player.character,
		surface = player.surface, visible = true, only_in_alt_mode = false,
	})
	if player.character.is_flashlight_enabled() then
		player.character.disable_flashlight()
	end
end

local function init_player(player, surface)
	if surface == game.surfaces["dungeons_floor0"] then
		if player.character then
			player.disassociate_character(player.character)
			player.character.destroy()
		end

		player.set_controller({type=defines.controllers.god})
		player.create_character()

		player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
		player.insert({name = "raw-fish", count = 8})
		player.set_quick_bar_slot(1, "raw-fish")
		player.insert({name = "pistol", count = 1})
		player.insert({name = "firearm-magazine", count = 16})
	else
		if player.surface == surface then
			player.teleport(surface.find_non_colliding_position("character", {0,0}, 50, 0.5), surface)
		end
	end
end

local function on_entity_spawned(event)
	local dungeontable = DungeonsTable.get_dungeontable()
	local forceshp = BiterHealthBooster.get("biter_health_boost_forces")
	local spawner = event.spawner
	local unit = event.entity
	local surface = spawner.surface
	local force = unit.force

	local spawner_tier = dungeontable.spawner_tier
	if not spawner_tier[spawner.unit_number] then
		Functions.set_spawner_tier(spawner, surface.index)
	end

	local e = Functions.get_dungeon_evolution_factor(surface.index)
	for _ = 1, spawner_tier[spawner.unit_number], 1 do
		local name = BiterRaffle.roll("mixed", e)
		local non_colliding_position = surface.find_non_colliding_position(name, unit.position, 16, 1)
		local bonus_unit
		if non_colliding_position then
			bonus_unit = surface.create_entity({name = name, position = non_colliding_position, force = force})
		else
			bonus_unit = surface.create_entity({name = name, position = unit.position, force = force})
		end
		bonus_unit.ai_settings.allow_try_return_to_spawner = true
		bonus_unit.ai_settings.allow_destroy_when_commands_fail = true

		if math_random(1, 256) == 1 then
			BiterHealthBooster.add_boss_unit(bonus_unit, forceshp[force.index] * 8, 0.25)
		end
	end

	if math_random(1, 256) == 1 then
		BiterHealthBooster.add_boss_unit(unit, forceshp[force.index] * 8, 0.25)
	end
end

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name == "nauvis" or surface.name == "gulag" or surface.name == "dungeons_floor_arena" then return end

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
	local nauvis_seed = game.surfaces[surface.index].map_gen_settings.seed
	local s = math_floor(nauvis_seed * 0.1) + 100
	-- for a = 1, 7, 1 do
	-- 	local b = a * s
	-- 	local c = 0.0035 + a * 0.0035
	-- 	local d = c * 0.5
	-- 	local seed = nauvis_seed + b
	-- 	if math_abs(Get_noise("dungeon_sewer", {x = left_top.x + 16, y = left_top.y + 16}, seed)) < 0.12 then
	-- 		for x = 0, 31, 1 do
	-- 			for y = 0, 31, 1 do
	-- 				local position = {x = left_top.x + x, y = left_top.y + y}
	-- 				local noise = math_abs(Get_noise("dungeon_sewer", position, seed))
	-- 				if noise < c then
	-- 					local tile_name = surface.get_tile(position).name
	-- 					if noise > d and tile_name ~= "deepwater-green" then
	-- 						set_tiles({{name = "water-green", position = position}}, true)
	-- 						if math_random(1, 320) == 1 and noise > c - 0.001 then table_insert(rock_positions, position) end
	-- 					else
	-- 						set_tiles({{name = "deepwater-green", position = position}}, true)
	-- 						if math_random(1, 64) == 1 then
	-- 							surface.create_entity({name = "fish", position = position})
	-- 						end
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end

	for _, p in pairs(rock_positions) do Functions.place_border_rock(surface, p) end

	if left_top.x == 32 and left_top.y == 32 then
		Functions.draw_spawn(surface)
		for _, p in pairs(game.connected_players) do init_player(p, surface) end
		game.forces.player.chart(surface, {{-128, -128}, {128, 128}})
	end
end

local function on_player_joined_game(event)
	draw_arrows_gui()
	draw_depth_gui()
	if game.tick == 0 then return end
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		init_player(player, game.surfaces["dungeons_floor0"])
	end
	draw_light(player)
end

local function spawner_death(entity)
	local dungeontable = DungeonsTable.get_dungeontable()
	local tier = dungeontable.spawner_tier[entity.unit_number]

	if not tier then
		Functions.set_spawner_tier(entity, entity.surface.index)
		tier = dungeontable.spawner_tier[entity.unit_number]
	end

	for _ = 1, tier * 2, 1 do
		Functions.spawn_random_biter(entity.surface, entity.position)
	end

	dungeontable.spawner_tier[entity.unit_number] = nil
end

--make expansion rocks very durable against biters
local function on_entity_damaged(event)
	local dungeontable = DungeonsTable.get_dungeontable()
	local entity = event.entity
	if not entity.valid then return end
	if entity.surface.name == "nauvis" or entity.surface.name == "dungeons_floor_arena" then return end
	local size = dungeontable.surface_size[entity.surface.index]
	if size < math.abs(entity.position.y) or size < math.abs(entity.position.x) then
		if entity.name == "rock-big" then
			entity.health = entity.health + event.final_damage_amount
		end
		return
	end
	if entity.force.index ~= 3 then return end --Neutral Force
	if not event.cause then return end
	if not event.cause.valid then return end
	if event.cause.force.index ~= 2 then return end --Enemy Force
	if math_random(1, 256) == 1 then return end
	if entity.name ~= "rock-big" then return end
	entity.health = entity.health + event.final_damage_amount
end

local function on_player_mined_entity(event)
	local dungeontable = DungeonsTable.get_dungeontable()
	local entity = event.entity
	if not entity.valid then return end
	local player = game.players[event.player_index]
	if entity.name == "rock-big" then
		local size = dungeontable.surface_size[entity.surface.index]
		if size < math.abs(entity.position.y) or size < math.abs(entity.position.x) then
			entity.surface.create_entity({name = entity.name, position = entity.position})
			entity.destroy()
			RPG_F.gain_xp(player, -10)
			Alert.alert_player_warning(player, 30, {"dungeons_tiered.too_small"}, {r=0.98,g=0.22,b=0})
			event.buffer.clear()
			return
		end
	end
	if entity.type == "simple-entity" then
		Functions.mining_events(entity)
		Functions.rocky_loot(event)
	end
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_entity_died(event)
	local rpg_extra = RPG_T.get("rpg_extra")
	local hp_units = BiterHealthBooster.get('biter_health_boost_units')
	local entity = event.entity
	if not entity.valid then return end
	if entity.type == "unit-spawner" then
		spawner_death(entity)
	end
	if entity.name ~= "rock-big" then return end
	expand(entity.surface, entity.position)
end

local function on_marked_for_deconstruction(event)
	if event.entity and event.entity.valid then
		if disabled_for_deconstruction[event.entity.name] then
			event.entity.cancel_deconstruction(game.players[event.player_index].force.name)
		end
	end
end

local function map_gen_settings()
	local map_gen_settings = {
		["seed"] = math_random(1, 1000000),
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
	return map_gen_settings
end

local function get_lowest_safe_floor(player)
	local dungeontable = DungeonsTable.get_dungeontable()
	local rpg = RPG_T.get("rpg_t")
	local level = rpg[player.index].level
	local sizes = dungeontable.surface_size
	local safe = dungeontable.original_surface_index
	for key, size in pairs(sizes) do
		if size > 215 and level >= (key + 1 - dungeontable.original_surface_index) * 10 and game.surfaces[key + 1] then
			safe = key + 1
		else
			break
		end
	end
	if safe >= dungeontable.original_surface_index + 50 then safe = dungeontable.original_surface_index + 50 end
	return safe
end

local function descend(player, button, shift)
	local dungeontable = DungeonsTable.get_dungeontable()
	local rpg = RPG_T.get("rpg_t")
	if player.surface.index >= dungeontable.original_surface_index + 50 then
		player.print({"dungeons_tiered.max_depth"})
		return
	end
	if player.position.x^2 + player.position.y^2 > 400 then
		player.print({"dungeons_tiered.only_on_spawn"})
		return
	end
	if rpg[player.index].level < (player.surface.index - dungeontable.original_surface_index) * 10 + 10 then
		player.print({"dungeons_tiered.level_required", (player.surface.index - dungeontable.original_surface_index) * 10 + 10})
		return
	end
	local surface = game.surfaces[player.surface.index + 1]
	if not surface then
		if dungeontable.surface_size[player.surface.index] < 215 then
			player.print({"dungeons_tiered.floor_size_required"})
			return
		end
		surface = game.create_surface("dungeons_floor" .. player.surface.index - dungeontable.original_surface_index + 1, map_gen_settings())
		if surface.index % 5 == dungeontable.original_surface_index then dungeontable.spawn_size = 60 else dungeontable.spawn_size = 42 end
		surface.request_to_generate_chunks({0,0}, 2)
		surface.force_generate_chunk_requests()
		surface.daytime = 0.25 + 0.30 * (surface.index / (dungeontable.original_surface_index + 50))
		surface.freeze_daytime = true
		surface.min_brightness = 0
		surface.brightness_visual_weights = {1, 1, 1}
		dungeontable.surface_size[surface.index] = 200
		dungeontable.treasures[surface.index] = 0
		game.print({"dungeons_tiered.first_visit", player.name, rpg[player.index].level, surface.index - dungeontable.original_surface_index}, {r = 0.8, g = 0.5, b = 0})
		--Alert.alert_all_players(15, {"dungeons_tiered.first_visit", player.name, rpg[player.index].level, surface.index - 2}, {r=0.8,g=0.2,b=0},"recipe/artillery-targeting-remote", 0.7)

	end
	if button == defines.mouse_button_type.right then surface = game.surfaces[math.min(get_lowest_safe_floor(player), player.surface.index + 5)] end
	if shift then surface = game.surfaces[get_lowest_safe_floor(player)] end
	player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
	--player.print({"dungeons_tiered.travel_down"})
end

local function ascend(player, button, shift)
	local dungeontable = DungeonsTable.get_dungeontable()
	if player.surface.index <= dungeontable.original_surface_index then
		player.print({"dungeons_tiered.min_depth"})
		return
	end
	if player.position.x^2 + player.position.y^2 > 400 then
		player.print({"dungeons_tiered.only_on_spawn"})
		return
	end
	local surface = game.surfaces[player.surface.index - 1]
	if button == defines.mouse_button_type.right then surface = game.surfaces[math.max(dungeontable.original_surface_index, player.surface.index - 5)] end
	if shift then surface = game.surfaces[dungeontable.original_surface_index] end
	player.teleport(surface.find_non_colliding_position("character", {0, 0}, 50, 0.5), surface)
	--player.print({"dungeons_tiered.travel_up"})
end

local function on_built_entity(event)
	local dungeontable = DungeonsTable.get_dungeontable()
	local entity = event.created_entity
	if not entity or not entity.valid then return end
	if entity.name == "spidertron" then
		if entity.surface.index < dungeontable.original_surface_index + 20 then
			local player = game.players[event.player_index]
			local try_mine = player.mine_entity(entity, true)
			if not try_mine then
				if entity.valid then
					entity.destroy()
					player.insert({name = "spidertron", count = 1})
				end
			end
			Alert.alert_player_warning(player, 8, {"dungeons_tiered.spidertron_not_allowed"})
		end
	end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local button = event.button
	local shift = event.shift
	local player = game.players[event.element.player_index]
	if event.element.name == "dungeon_down" then
		descend(player, button, shift)
		return
	elseif event.element.name == "dungeon_up" then
		ascend(player, button, shift)
		return
	end
end

local function on_surface_created(event)
	local dungeontable = DungeonsTable.get_dungeontable()
	local forceshp = BiterHealthBooster.get("biter_health_boost_forces")
	local force = game.create_force("enemy" .. event.surface_index)
	dungeontable.enemy_forces[event.surface_index] = force
	forceshp[force.index] = 1
	dungeontable.depth[event.surface_index] = 100 * event.surface_index - (dungeontable.original_surface_index * 100)
	BiterHealthBooster.set_surface_activity(game.surfaces[event.surface_index].name, true)
end

local function on_player_changed_surface(event)
	draw_depth_gui()
	draw_light(game.players[event.player_index])
end

local function on_player_respawned(event)
	draw_light(game.players[event.player_index])
end

-- local function on_player_changed_position(event)
--   local player = game.players[event.player_index]
--   local position = player.position
-- 	local surface = player.surface
-- 	if surface.index < 2 then return end
-- 	local size = dungeontable.surface_size[surface.index]
-- 	if (size >= math.abs(player.position.y) and size < math.abs(player.position.y) + 1) or (size >= math.abs(player.position.x) and size < math.abs(player.position.x) + 1) then
--       Alert.alert_player_warning(player, 30, {"dungeons_tiered.too_small"}, {r=0.98,g=0.22,b=0})
--   end
-- end

local function transfer_items(surface_index)
	local dungeontable = DungeonsTable.get_dungeontable()
	if surface_index > dungeontable.original_surface_index then
		local inputs = dungeontable.transport_chests_inputs[surface_index]
		local outputs = dungeontable.transport_chests_outputs[surface_index - 1]
		for i = 1, 2, 1 do
			if inputs[i].valid and outputs[i].valid then
				local input_inventory = inputs[i].get_inventory(defines.inventory.chest)
				local output_inventory = outputs[i].get_inventory(defines.inventory.chest)
				input_inventory.sort_and_merge()
				output_inventory.sort_and_merge()
				for ii = 1, #input_inventory, 1 do
					if input_inventory[ii].valid_for_read then
						local count = output_inventory.insert(input_inventory[ii])
						input_inventory[ii].count = input_inventory[ii].count - count
					end
				end
			end
		end
	end
end

local function transfer_signals(surface_index)
	local dungeontable = DungeonsTable.get_dungeontable()
	if surface_index > dungeontable.original_surface_index then
		local inputs = dungeontable.transport_poles_inputs[surface_index - 1]
		local outputs = dungeontable.transport_poles_outputs[surface_index]
		for i = 1, 2, 1 do
			if inputs[i].valid and outputs[i].valid then
				local signals = inputs[i].get_merged_signals(defines.circuit_connector_id.electric_pole)
				local combi = outputs[i].get_or_create_control_behavior()
				for ii = 1, 15, 1 do
					if signals and signals[ii] then
						combi.set_signal(ii, signals[ii])
					else
						combi.set_signal(ii, nil)
					end
				end
			end
		end
	end
end

-- local function setup_magic()
-- 	local rpg_spells = RPG_T.get("rpg_spells")
-- end


local function on_init()
	local dungeontable = DungeonsTable.get_dungeontable()
	local forceshp = BiterHealthBooster.get("biter_health_boost_forces")
	local force = game.create_force("dungeon")
	force.set_friend("enemy", false)
	force.set_friend("player", false)

	local surface = game.create_surface("dungeons_floor0", map_gen_settings())

	surface.request_to_generate_chunks({0,0}, 2)
	surface.force_generate_chunk_requests()
	surface.daytime = 0.25
	surface.freeze_daytime = true

	local nauvis = game.surfaces[1]
	nauvis.daytime = 0.25
	nauvis.freeze_daytime = true
	local map_gen_settings = nauvis.map_gen_settings
	map_gen_settings.height = 3
	map_gen_settings.width = 3
	nauvis.map_gen_settings = map_gen_settings
	for chunk in nauvis.get_chunks() do
		nauvis.delete_chunk({chunk.x, chunk.y})
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
	game.difficulty_settings.technology_price_multiplier = 3

	dungeontable.tiered = true
	dungeontable.depth[surface.index] = 0
	dungeontable.depth[nauvis.index] = 0
	dungeontable.surface_size[surface.index] = 200
	dungeontable.treasures[surface.index] = 0
	dungeontable.item_blacklist = true
	dungeontable.original_surface_index = surface.index
	dungeontable.enemy_forces[nauvis.index] = game.forces.enemy
	dungeontable.enemy_forces[surface.index] = game.create_force("enemy" .. surface.index)
	forceshp[game.forces.enemy.index] = 1
	forceshp[dungeontable.enemy_forces[surface.index].index] = 1
	BiterHealthBooster.set_surface_activity('dungeons_floor0', true)

	game.forces.player.technologies["land-mine"].enabled = false
	game.forces.player.technologies["landfill"].enabled = false
	game.forces.player.technologies["cliff-explosives"].enabled = false
	--recipes to be unlocked through playing--
	for _, tech in pairs(locked_researches) do
		game.forces.player.technologies[tech].enabled = false
	end
	RPG_T.set_surface_name("dungeons_floor")
	local rpg_table = RPG_T.get("rpg_extra")
	rpg_table.personal_tax_rate = 0
	-- rpg_table.enable_mana = true
	-- setup_magic()

	local T = MapInfo.Pop_info()
	T.localised_category = "dungeons_tiered"
	T.main_caption_color = {r = 0, g = 0, b = 0}
	T.sub_caption_color = {r = 150, g = 0, b = 20}
end

local function on_tick()
	local dungeontable = DungeonsTable.get_dungeontable()
	if #dungeontable.transport_surfaces > 0 then
		for _,surface_index in pairs(dungeontable.transport_surfaces) do
			transfer_items(surface_index)
			transfer_signals(surface_index)
		end
	end
	--[[
	if game.tick % 4 ~= 0 then return end

	local surface = game.surfaces["dungeons"]

	local entities = surface.find_entities_filtered({name = "rock-big"})
	if not entities[1] then return end

	local entity = entities[math_random(1, #entities)]

	surface.request_to_generate_chunks(entity.position, 3)
	surface.force_generate_chunk_requests()

	game.forces.player.chart(surface, {{entity.position.x - 32, entity.position.y - 32}, {entity.position.x + 32, entity.position.y + 32}})

	entity.die()
	]]
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(60, on_tick)
Event.add(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_built_entity, on_built_entity)
-- Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_surface_created, on_surface_created)
Event.add(defines.events.on_gui_click, on_gui_click)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_respawned, on_player_respawned)
