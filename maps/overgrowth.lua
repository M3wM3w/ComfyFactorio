--overgrowth-- by mewmew --

require "on_tick_schedule"
require "modules.dynamic_landfill"
require "modules.satellite_score"
require "modules.spawners_contain_biters"
require "modules.no_deconstruction_of_neutral_entities"
require "modules.biters_yield_coins"
require "modules.rocks_yield_ore"
require "modules.ores_are_mixed"
require "modules.surrounded_by_worms"
global.average_worm_amount_per_chunk = 1.5
require "modules.biters_attack_moving_players"
require "modules.market_friendly_fire_protection"
require "modules.trees_grow"
require "modules.trees_randomly_die"

require "maps.overgrowth_map_info"

local Reset = require "functions.soft_reset"
local rpg_t = require 'modules.rpg'
local kaboom = require "functions.omegakaboom"

require "modules.difficulty_vote"

local unearthing_biters = require "functions.unearthing_biters"

local event = require 'utils.event'
local math_random = math.random

local difficulties_votes = {
	[1] = 11,
	[2] = 10,
	[3] = 9,
	[4] = 8,
	[5] = 7,
	[6] = 6,
	[7] = 5
}

local difficulties_votes_evo = {
	[1] = 0.000016,
	[2] = 0.000024,
	[3] = 0.000032,
	[4] = 0.000040,
	[5] = 0.000048,
	[6] = 0.000056,
	[7] = 0.000064
}

local starting_items = {
	["pistol"] = 1,
	["firearm-magazine"] = 8
}

local function create_particles(surface, name, position, amount, cause_position)
	local math_random = math.random

	local direction_mod = (-100 + math_random(0,200)) * 0.0004
	local direction_mod_2 = (-100 + math_random(0,200)) * 0.0004

	if cause_position then
		direction_mod = (cause_position.x - position.x) * 0.021
		direction_mod_2 = (cause_position.y - position.y) * 0.021
	end

	for i = 1, amount, 1 do
		local m = math_random(4, 10)
		local m2 = m * 0.005

		surface.create_particle({
			name = name,
			position = position,
			frame_speed = 1,
			vertical_speed = 0.130,
			height = 0,
			movement = {
				(m2 - (math_random(0, m) * 0.01)) + direction_mod,
				(m2 - (math_random(0, m) * 0.01)) + direction_mod_2
			}
		})
	end
end

local function spawn_market(surface, position)
	local market = surface.create_entity({name = "market", position = position, force = "neutral"})
	--market.destructible = false
	market.add_market_item({price = {{'coin', 1}}, offer = {type = 'give-item', item = "wood", count = 50}})
	market.add_market_item({price = {{"coin", 3}}, offer = {type = 'give-item', item = 'iron-ore', count = 50}})
	market.add_market_item({price = {{"coin", 3}}, offer = {type = 'give-item', item = 'copper-ore', count = 50}})
	market.add_market_item({price = {{"coin", 3}}, offer = {type = 'give-item', item = 'stone', count = 50}})
	market.add_market_item({price = {{"coin", 3}}, offer = {type = 'give-item', item = 'coal', count = 50}})
	market.add_market_item({price = {{"coin", 5}}, offer = {type = 'give-item', item = 'uranium-ore', count = 50}})

	market.add_market_item({price = {{'coin', 2}}, offer = {type = 'give-item', item = "raw-fish", count = 1}})
	market.add_market_item({price = {{'coin', 8}}, offer = {type = 'give-item', item = "grenade", count = 1}})
	market.add_market_item({price = {{'coin', 1}}, offer = {type = 'give-item', item = "firearm-magazine", count = 1}})
	market.add_market_item({price = {{'coin', 16}}, offer = {type = 'give-item', item = "submachine-gun", count = 1}})
	market.add_market_item({price = {{'coin', 32}}, offer = {type = 'give-item', item = "car", count = 1}})
	return market
end

local caption_style = {{"font", "default-bold"}, {"font_color",{ r=0.63, g=0.63, b=0.63}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
local stat_number_style = {{"font", "default-bold"}, {"font_color",{ r=0.77, g=0.77, b=0.77}}, {"top_padding",2}, {"left_padding",0},{"right_padding",0},{"minimal_width",0}}
local function tree_gui()
	for _, player in pairs(game.connected_players) do
		if player.gui.top["trees_defeated"] then player.gui.top["trees_defeated"].destroy() end
		local b = player.gui.top.add { type = "button", caption = '[img=entity.tree-04] : ' .. global.trees_defeated, tooltip = "Trees defeated", name = "trees_defeated" }
		b.style.font = "heading-1"
		b.style.font_color = {r=0.00, g=0.33, b=0.00}
		b.style.minimal_height = 38
	end
end

local function get_surface_settings()
	local map_gen_settings = {}
	map_gen_settings.seed = math_random(1, 1000000)
	map_gen_settings.water = math_random(15, 30) * 0.1
	map_gen_settings.starting_area = 1
	map_gen_settings.cliff_settings = {cliff_elevation_interval = math_random(4, 48), cliff_elevation_0 = math_random(4, 48)}
	map_gen_settings.autoplace_controls = {
		["coal"] = {frequency = "2", size = "1", richness = "1"},
		["stone"] = {frequency = "2", size = "1", richness = "1"},
		["copper-ore"] = {frequency = "2", size = "1", richness = "1"},
		["iron-ore"] = {frequency = "2.5", size = "1.1", richness = "1"},
		["uranium-ore"] = {frequency = "2", size = "1", richness = "1"},
		["crude-oil"] = {frequency = "3", size = "1", richness = "1.5"},
		["trees"] = {frequency = "2", size = "1", richness = "0.75"},
		["enemy-base"] = {frequency = "4", size = "1.25", richness = "1"}
	}
	return map_gen_settings
end

function reset_map()
	local rpg = rpg_t.get_table()
	global.trees_grow_chunk_next_visit = {}
	global.trees_grow_chunk_raffle = {}
	global.trees_grow_chunk_position = {}
	global.trees_grow_chunks_charted = {}
	global.trees_grow_chunks_charted_counter = 0

	global.current_surface = Reset.soft_reset_map(global.current_surface, get_surface_settings(), starting_items)

	reset_difficulty_poll()

	global.trees_defeated = 0
	tree_gui()

	global.market = spawn_market(global.current_surface, {x = 0, y = -8})

	game.map_settings.enemy_evolution.time_factor = difficulties_votes_evo[4]

	if rpg then rpg_t.rpg_reset_all_players() end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	if player.online_time == 0 then
		for item, amount in pairs(starting_items) do
			player.insert({name = item, count = amount})
		end
	end

	if global.current_surface then
		if player.surface.name ~= global.current_surface.name then
			local pos = global.current_surface.find_non_colliding_position("character", {x = 0, y = 0}, 16, 0.5)
			player.teleport(pos, global.current_surface)
		end
	end

	if not global.market and game.tick == 0 then
		global.current_surface = game.create_surface("overgrowth", get_surface_settings())
		game.forces["player"].set_spawn_position({x = 0, y = 0}, global.current_surface)
		player.teleport({0,0}, global.current_surface)
		reset_map()
	end

	tree_gui()
end

local function trap(entity)
	local r = 8
	if global.difficulty_vote_index then r = difficulties_votes[global.difficulty_vote_index] end
	if math_random(1,r) == 1 then unearthing_biters(entity.surface, entity.position, math_random(4,8)) end
end

local function on_player_mined_entity(event)
	local entity = event.entity
	if not entity.valid then return end
	if entity.type ~= "tree" then return end

	global.trees_defeated = global.trees_defeated + 1
	tree_gui()

	trap(entity)

	if event.player_index then
		create_particles(entity.surface, "wooden-particle", entity.position, 128, game.players[event.player_index].position)
		game.players[event.player_index].insert({name = "coin", count = 1})
		return
	end

	create_particles(entity.surface, "wooden-particle", entity.position, 128)

	if event.cause then
		if event.cause.force.name == "enemy" then return end
	end

	entity.surface.spill_item_stack(entity.position,{name = "coin", count = 1}, true)
end

local function on_entity_died(event)
	on_player_mined_entity(event)
	if event.entity == global.market then
		global.map_reset_timeout = game.tick + 900
		game.print("The market has been overrun.", {r = 1, g = 0, b = 0})
		kaboom(event.entity.surface, event.entity.position, "explosive-cannon-projectile", 24, 12)
		kaboom(event.entity.surface, event.entity.position, "explosive-uranium-cannon-projectile", 24, 12)
		global.market = nil
	end
end

local function attack_market()
	local c = 8
	if global.difficulty_vote_index then
		c = global.difficulty_vote_index * 2
		game.map_settings.enemy_evolution.time_factor = difficulties_votes_evo[global.difficulty_vote_index]
	end
	global.current_surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.by_enemy
			},
		unit_count = math_random(c, c * 2),
		force = "enemy",
		unit_search_distance=1024
	})
	global.current_surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.none
			},
		unit_count = math_random(1, c),
		force = "enemy",
		unit_search_distance=1024
	})
end

local function tick()
	if global.market then
		if math_random(1, 60) == 1 then
			attack_market()
		end
		return
	end
	if not global.map_reset_timeout then return end
	if game.tick < global.map_reset_timeout then return end
	reset_map()
	global.map_reset_timeout = nil
end

event.on_nth_tick(60, tick)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_entity_died, on_entity_died)
