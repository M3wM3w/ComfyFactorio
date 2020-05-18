-- fish defender -- by mewmew --

require "maps.fish_defender_v1.map_intro"
require "maps.fish_defender_v1.market"
require "maps.fish_defender_v1.shotgun_buff"
require "maps.fish_defender_v1.on_entity_damaged"

require "modules.rocket_launch_always_yields_science"
require "modules.launch_fish_to_win"
require "modules.biters_yield_coins"
require "modules.dynamic_landfill"
require "modules.dangerous_goods"
require "modules.custom_death_messages"
require "modules.biter_evasion_hp_increaser"

local event = require 'utils.event'
local Server = require 'utils.server'
local boss_biter = require "maps.fish_defender.boss_biters"
local Score = require "comfy_panel.score"
require "functions.boss_unit"
local map_functions = require "tools.map_functions"
local math_random = math.random
local insert = table.insert
local enable_start_grace_period = true

local biter_count_limit = 1024	--maximum biters on the east side of the map, next wave will be delayed if the maximum has been reached
local boss_waves = {
	[50] = {{name = "big-biter", count = 3}},
	[100] = {{name = "behemoth-biter", count = 1}},
	[150] = {{name = "behemoth-spitter", count = 4}, {name = "big-spitter", count = 16}},
	[200] = {{name = "behemoth-biter", count = 4}, {name = "behemoth-spitter", count = 2}, {name = "big-biter", count = 32}},
	[250] = {{name = "behemoth-biter", count = 8}, {name = "behemoth-spitter", count = 4}, {name = "big-spitter", count = 32}},
	[300] = {{name = "behemoth-biter", count = 16}, {name = "behemoth-spitter", count = 8}}
}

local difficulties_votes = {
	[1] = {wave_interval = 5100, amount_modifier = 0.55, strength_modifier = 0.40},
	[2] = {wave_interval = 4500, amount_modifier = 0.75, strength_modifier = 0.65},
	[3] = {wave_interval = 4000, amount_modifier = 0.90, strength_modifier = 0.85},
	[4] = {wave_interval = 3600, amount_modifier = 1.00, strength_modifier = 1.00},
	[5] = {wave_interval = 3200, amount_modifier = 1.10, strength_modifier = 1.25},
	[6] = {wave_interval = 2700, amount_modifier = 1.25, strength_modifier = 1.75},
	[7] = {wave_interval = 2100, amount_modifier = 1.50, strength_modifier = 2.50}
}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math.random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function create_wave_gui(player)
	if player.gui.top["fish_defense_waves"] then player.gui.top["fish_defense_waves"].destroy() end
	local frame = player.gui.top.add({ type = "frame", name = "fish_defense_waves", tooltip = "Click to show map info"})
	frame.style.maximal_height = 38

	local wave_count = 0
	if global.wave_count then wave_count = global.wave_count end

	if not global.wave_grace_period then
		local label = frame.add({ type = "label", caption = "Wave: " .. wave_count })
		label.style.font_color = {r=0.88, g=0.88, b=0.88}
		label.style.font = "default-listbox"
		label.style.left_padding = 4
		label.style.right_padding = 4
		label.style.minimal_width = 68
		label.style.font_color = {r=0.33, g=0.66, b=0.9}

		local next_level_progress = game.tick % global.wave_interval / global.wave_interval

		local progressbar = frame.add({ type = "progressbar", value = next_level_progress})
		progressbar.style.minimal_width = 120
		progressbar.style.maximal_width = 120
		progressbar.style.top_padding = 10
	else
		local time_remaining = math.floor(((global.wave_grace_period - (game.tick % global.wave_grace_period)) / 60) / 60)
		if time_remaining <= 0 then
			global.wave_grace_period = nil
			return
		end

		local label = frame.add({ type = "label", caption = "Waves will start in " .. time_remaining .. " minutes."})
		label.style.font_color = {r=0.88, g=0.88, b=0.88}
		label.style.font = "default-listbox"
		label.style.left_padding = 4
		label.style.right_padding = 4
		label.style.font_color = {r=0.33, g=0.66, b=0.9}

		if not enable_start_grace_period then global.wave_grace_period = nil return end
	end
end

local function show_fd_stats(player)
	local gui_id = "fd-stats"
	local table_id = gui_id.."table"

	if player.gui.left[gui_id] then
		player.gui.left[gui_id].destroy()
	end

	local frame = player.gui.left.add {
		type = "frame",
		name = gui_id
	}
	local table = frame.add {
		type = "table",
		name = table_id,
		column_count = 2,
	}

	local table_header = {"Building", "Placed"..'/'.."Limit"}
	for k,v in pairs(table_header) do
		local h = table.add { type="label", caption=v }
		h.style.font = "heading-2"
	end

	for k,v in pairs(global.entity_limits) do
		local name = v.str
		local placed = v.placed
		local limit = v.limit
		local entry = {name, placed..'/'..limit}
		for k, v in pairs(entry) do
			table.add {
				type = "label",
				caption = v
			}
		end
	end
end

local function update_fd_stats()
	for _, player in pairs(game.connected_players) do
		if player.gui.left["fd-stats"] then
			show_fd_stats(player)
		end
	end
end

local function add_fd_stats_button(player)
	local button_id = "fd-stats-button"
	if player.gui.top[button_id] then
		player.gui.top[button_id].destroy()
	end
	local button = player.gui.top.add {
		type = "sprite-button",
		name = button_id,
		sprite = "item/submachine-gun"
	}
end

local function on_gui_click(event)
	if not event.element.valid then
		return
	end
	if event.element.name ~= "fd-stats-button" then
		return
	end
	local player = game.players[event.player_index]
	local frame = player.gui.left["fd-stats"]
	if frame == nil then
		show_fd_stats(player)
	else
		frame.destroy()
	end
end

local function on_market_item_purchased(event)
	update_fd_stats()
end

local threat_values = {
	["small_biter"] = 1,
	["medium_biter"] = 3,
	["big_biter"] = 5,
	["behemoth_biter"] = 10,
	["small_spitter"] = 1,
	["medium_spitter"] = 3,
	["big_spitter"] = 5,
	["behemoth_spitter"] = 10
}

local function get_biter_initial_pool()
	local biter_pool = {}
	if global.wave_count > 1750 then
		biter_pool = {
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if global.wave_count > 1500 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 1},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if global.wave_count > 1250 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 2},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if global.wave_count > 1000 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 3},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.1 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 3},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.2 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 10},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 2},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 5},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.3 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 18},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 6},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 8},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 3},
			{name = "big-biter", threat = threat_values.big_biter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.4 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 8},
			{name = "big-biter", threat = threat_values.big_biter, weight = 2},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 4},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.5 then
		biter_pool = {
			{name = "small-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 4},
			{name = "big-biter", threat = threat_values.big_biter, weight = 8},
			{name = "small-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 4}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.6 then
		biter_pool = {
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 4},
			{name = "big-biter", threat = threat_values.big_biter, weight = 8},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 4}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.7 then
		biter_pool = {
			{name = "behemoth-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 12},
			{name = "big-biter", threat = threat_values.big_biter, weight = 20},
			{name = "behemoth-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 6},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 10}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor < 0.8 then
		biter_pool = {
			{name = "behemoth-biter", threat = threat_values.small_biter, weight = 2},
			{name = "medium-biter", threat = threat_values.medium_biter, weight = 4},
			{name = "big-biter", threat = threat_values.big_biter, weight = 10},
			{name = "behemoth-spitter", threat = threat_values.small_spitter, weight = 1},
			{name = "medium-spitter", threat = threat_values.medium_spitter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 5}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor <= 0.9 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 12},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 6},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
	if game.forces.enemy.evolution_factor <= 1 then
		biter_pool = {
			{name = "big-biter", threat = threat_values.big_biter, weight = 4},
			{name = "behemoth-biter", threat = threat_values.behemoth_biter, weight = 2},
			{name = "big-spitter", threat = threat_values.big_spitter, weight = 2},
			{name = "behemoth-spitter", threat = threat_values.behemoth_spitter, weight = 1}
		}
		return biter_pool
	end
end

local function get_biter_pool()
	local surface = game.surfaces["fish_defender"]
	local biter_pool = get_biter_initial_pool()
	local biter_raffle = {}
	for _, biter_type in pairs(biter_pool) do
		for x = 1, biter_type.weight, 1 do
			insert(biter_raffle, {name = biter_type.name, threat = biter_type.threat})
		end
	end
	return biter_raffle
end

local function spawn_biter(pos, biter_pool)
	if global.attack_wave_threat < 1 then return false end
	local surface = game.surfaces["fish_defender"]
	biter_pool = shuffle(biter_pool)
	global.attack_wave_threat = global.attack_wave_threat - biter_pool[1].threat
	local valid_pos = surface.find_non_colliding_position(biter_pool[1].name, pos, 100, 2)
	local biter = surface.create_entity({name = biter_pool[1].name, position = valid_pos})
	return biter
end

local attack_group_count_thresholds = {
			{0, 1},
			{50, 2},
			{100, 3},
			{150, 4},
			{200, 5},
			{1000, 6},
			{2000, 7},
			{3000, 8}
		}

local function get_number_of_attack_groups()
	local n = 1
	for _, entry in pairs(attack_group_count_thresholds) do
		if global.wave_count >= entry[1] then
			n = entry[2]
		end
	end
	return n
end

local function clear_corpses(surface)
	if not global.wave_count then return end
	local chance = 4
	if global.wave_count > 250 then chance = 3 end
	if global.wave_count > 500 then chance = 2 end
	for _, entity in pairs(surface.find_entities_filtered{type = "corpse"}) do
		if math_random(1, chance) == 1 then
			entity.destroy()
		end
	end
end

local boss_wave_names = {
	[50] = "The Big Biter Gang",
	[100] = "Biterzilla",
	[150] = "The Spitter Squad",
	[200] = "The Wall Nibblers",
	[250] = "Conveyor Munchers",
	[300] = "Furnace Freezers",
	[350] = "Cable Chewers",
	[400] = "Power Pole Thieves",
	[450] = "Assembler Annihilators",
	[500] = "Inserter Crunchers",
	[550] = "Engineer Eaters",
	[600] = "Belt Unbalancers",
	[650] = "Turret Devourers",
	[700] = "Pipe Perforators",
	[750] = "Desync Bros",
	[800] = "Ratio Randomizers",
	[850] = "Wire Chompers",
	[900] = "The Bus Mixers",
	[950] = "Roundabout Deadlockers",
	[1000] = "Happy Tree Friends",
	[1050] = "Uranium Digesters",
	[1100] = "Bot Banishers",
	[1150] = "Chest Crushers",
	[1200] = "Cargo Wagon Scratchers",
	[1250] = "Transport Belt Surfers",
	[1300] = "Pumpjack Pulverizers",
	[1350] = "Radar Ravagers",
	[1400] = "Mall Deconstrutors",
	[1450] = "Lamp Dimmers",
	[1500] = "Roboport Disablers",
	[1550] = "Signal Spammers",
	[1600] = "Brick Tramplers",
	[1650] = "Drill Destroyers",
	[1700] = "Gearwheel Grinders",
	[1750] = "Silo Seekers",
	[1800] = "Circuit Breakers",
	[1850] = "Bullet Absorbers",
	[1900] = "Oil Guzzlers",
	[1950] = "Belt Rotators",
	[2000] = "Bluescreen Factor"
}

local function spawn_boss_units(surface)
	if boss_wave_names[global.wave_count] then
		game.print("Boss Wave " .. global.wave_count .. " - - " .. boss_wave_names[global.wave_count], {r = 0.8, g = 0.1, b = 0.1})
	else
		game.print("Boss Wave " .. global.wave_count, {r = 0.8, g = 0.1, b = 0.1})
	end

	if not boss_waves[global.wave_count] then
		boss_waves[global.wave_count] = {{name = "behemoth-biter", count = math.floor(global.wave_count / 16)}, {name = "behemoth-spitter", count = math.floor(global.wave_count / 32)}}
	end

	local position = {x = 216, y = 0}
	local biter_group = surface.create_unit_group({position = position})
	for _, entry in pairs(boss_waves[global.wave_count]) do
		for x = 1, entry.count, 1 do
			local pos = surface.find_non_colliding_position(entry.name, position, 64, 3)
			if pos then
				local biter = surface.create_entity({name = entry.name, position = pos})
				global.boss_biters[biter.unit_number] = biter
				add_boss_unit(biter, global.biter_evasion_health_increase_factor * 8 * difficulties_votes[global.difficulty_vote_index].strength_modifier, 0.70)
				biter_group.add_member(biter)
			end
		end
	end
	biter_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.logical_and,
		commands = {
					{
						type=defines.command.attack_area,
						destination={x = 160, y = 0},
						radius=16,
						distraction=defines.distraction.by_enemy
					},
					{
						type=defines.command.attack_area,
						destination={x = 128, y = 0},
						radius=16,
						distraction=defines.distraction.by_enemy
					},
					{
						type=defines.command.attack_area,
						destination={x = 96, y = 0},
						radius=16,
						distraction=defines.distraction.by_enemy
					},
					{
						type=defines.command.attack_area,
						destination={x = 64, y = 0},
						radius=16,
						distraction=defines.distraction.by_enemy
					},
					{
						type=defines.command.attack_area,
						destination={x = 32, y = 0},
						radius=16,
						distraction=defines.distraction.by_enemy
					},
					{
						type=defines.command.attack_area,
						destination={x = -32, y = 0},
						radius=16,
						distraction=defines.distraction.by_enemy
					},
					{
						type=defines.command.attack,
						target=global.market,
						distraction=defines.distraction.by_enemy
					}
			}
		})
	biter_group.start_moving()
end

local function wake_up_the_biters(surface)
	if not global.market then return end

	--if not global.wake_up_counter then global.wake_up_counter = 0 end
	--global.wake_up_counter = global.wake_up_counter + 1
	--if global.wake_up_counter % 2 == 1 then return end

	--[[
	unit_group = game.player.surface.create_unit_group({position = game.player.selected.position})
	for _, biter in pairs(game.player.surface.find_enemy_units(game.player.selected.position, 96, "player")) do
		unit_group.add_member(biter)
	end
	unit_group.set_command({
					type = defines.command.compound,
					structure_type = defines.compound_command.logical_and,
					commands = {
						{
							type=defines.command.attack_area,
							destination=global.market.position,
							radius=512,
							distraction=defines.distraction.by_anything
						}
					}
				})
	unit_group.start_moving()

	game.player.surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.none
			},
		unit_count = 128,
		force = "enemy",
		unit_search_distance=128
		})

	]]

	local nearest_player_unit = surface.find_nearest_enemy({position = {x = 256, y = 0}, max_distance=512, force="enemy"})
	if not nearest_player_unit then return end
	local target_positions = {}
	for y = -80, 80, 4 do
		insert(target_positions, {x = nearest_player_unit.position.x, y = y})
	end
	target_positions = shuffle(target_positions)

	local units = surface.find_entities_filtered({type = "unit"})
	units = shuffle(units)
	local unit_groups = {}
	for i = 1, 2, 1 do
		if not units[i] then break end
		if not units[i].valid then break end
		unit_groups[i] = surface.create_unit_group({position = {x = units[i].position.x, y = units[i].position.y}})
		local biters = surface.find_enemy_units(units[i].position, 24, "player")
		for _, biter in pairs(biters) do
			unit_groups[i].add_member(biter)
		end
	end

	for i = 1, #unit_groups, 1 do
		if unit_groups[i].valid then
			if #unit_groups[i].members > 0 then
				unit_groups[i].set_command({
					type = defines.command.compound,
					structure_type = defines.compound_command.logical_and,
					commands = {
						{
							type=defines.command.attack_area,
							destination={target_positions[i].x, target_positions[i].y},
							radius=32,
							distraction=defines.distraction.by_anything
						},
						{
							type=defines.command.attack_area,
							destination=global.market.position,
							radius=32,
							distraction=defines.distraction.by_anything
						},
						{
							type=defines.command.attack,
							target=global.market,
							distraction=defines.distraction.by_enemy
						}
					}
				})
				unit_groups[i].start_moving()
			else
				unit_groups[i].destroy()
			end
		end
	end

	--[[
	surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.by_enemy
			},
		unit_count = 16,
		force = "enemy",
		unit_search_distance=64
		})]]

	surface.set_multi_command({
		command={
			type=defines.command.attack,
			target=global.market,
			distraction=defines.distraction.none
			},
		unit_count = 16,
		force = "enemy",
		unit_search_distance=24
		})
end

local function damage_entity_outside_of_fence(e)
	if not e.health then return end
	if e.force.name == "neutral" then return end
	if e.type == "unit" or e.type == "unit-spawner" then return end

	e.surface.create_entity({name = "water-splash", position = e.position})

	if e.type == "entity-ghost" then	e.destroy() return end

	e.health = e.health - math_random(math.floor(e.prototype.max_health * 0.05), math.floor(e.prototype.max_health * 0.1))
	if e.health <= 0 then e.die("enemy") end
end

local function biter_attack_wave()
	if not global.market then return end
	if global.wave_grace_period then return end
	local surface = game.surfaces["fish_defender"]

	clear_corpses(surface)
	wake_up_the_biters(surface)

	if surface.count_entities_filtered({type = "unit"}) > biter_count_limit then
		--game.print("Biter limit reached, wave delayed.", {r = 0.7, g = 0.1, b = 0.1})
		return
	end

	if not global.wave_count then
		global.wave_count = 1
	else
		global.wave_count = global.wave_count + 1
	end
	
	local m = 0.0015
	if global.difficulty_vote_index then
		m = m * difficulties_votes[global.difficulty_vote_index].strength_modifier
	end
	game.forces.enemy.set_ammo_damage_modifier("melee", global.wave_count * m)
	game.forces.enemy.set_ammo_damage_modifier("biological", global.wave_count * m)
	global.biter_evasion_health_increase_factor = 1 + (global.wave_count * (m * 2))
	
	local m = 4
	if global.difficulty_vote_index then
		m = m * difficulties_votes[global.difficulty_vote_index].amount_modifier		
	end
	
	if global.wave_count % 50 == 0 then
		global.attack_wave_threat = math.floor(global.wave_count * m)
		spawn_boss_units(surface)
		if global.attack_wave_threat > 10000 then global.attack_wave_threat = 10000 end
	else
		global.attack_wave_threat = math.floor(global.wave_count * m)	
		if global.attack_wave_threat > 10000 then global.attack_wave_threat = 10000 end
	end
	
	local evolution = global.wave_count * 0.00125
	if evolution > 1 then evolution = 1 end
	game.forces.enemy.evolution_factor = evolution

	if game.forces.enemy.evolution_factor == 1 then
		if not global.endgame_modifier then
			global.endgame_modifier = 1
			game.print("Endgame enemy evolution reached.", {r = 0.7, g = 0.1, b = 0.1})
		else
			global.endgame_modifier = global.endgame_modifier + 1
		end
	end

	for _, e in pairs(surface.find_entities_filtered({area = {{160, -256},{360, 256}}})) do
		damage_entity_outside_of_fence(e)
	end

	local spawn_x = 242
	local target_x = -32
	local group_coords = {}
	for a = -80, 80, 16 do
		insert(group_coords, {spawn = {x = spawn_x, y = a * 2}, target = {x = target_x, y = a}})
	end
	group_coords = shuffle(group_coords)

	local unit_groups = {}
	if global.wave_count > 100 and math_random(1, 8) == 1 then
		for i = 1, #group_coords, 1 do
			unit_groups[i] = surface.create_unit_group({position = group_coords[i].spawn})
		end
	else
		for i = 1, get_number_of_attack_groups(), 1 do
			unit_groups[i] = surface.create_unit_group({position = group_coords[i].spawn})
		end
	end

	local biter_pool = get_biter_pool()
	while global.attack_wave_threat > 0 do
		for i = 1, #unit_groups, 1 do
			local biter = spawn_biter(unit_groups[i].position, biter_pool)
			if biter then
				unit_groups[i].add_member(biter)
			else
				break
			end
		end
	end

	for i = 1, #unit_groups, 1 do
		unit_groups[i].set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.logical_and,
			commands = {
				{
					type=defines.command.attack_area,
					destination={group_coords[i].target.x + 192, group_coords[i].target.y},
					radius=32,
					distraction=defines.distraction.by_anything
				},
				{
					type=defines.command.attack_area,
					destination={group_coords[i].target.x + 128, group_coords[i].target.y},
					radius=32,
					distraction=defines.distraction.by_anything
				},
				{
					type=defines.command.attack_area,
					destination={group_coords[i].target.x + 64, group_coords[i].target.y},
					radius=32,
					distraction=defines.distraction.by_anything
				},
				{
					type=defines.command.attack_area,
					destination={group_coords[i].target.x, group_coords[i].target.y},
					radius=32,
					distraction=defines.distraction.by_enemy
				},
				{
					type=defines.command.attack,
					target=global.market,
					distraction=defines.distraction.by_enemy
				}
			}
		})
		unit_groups[i].start_moving()
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

local function get_mvps()
	local get_score = Score.get_table().score_table
	if not get_score["player"] then return false end
	local score = get_score["player"]
	local score_list = {}
	for _, p in pairs(game.players) do
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
	local mvp = {}
	score_list = get_sorted_list("killscore", score_list)
	mvp.killscore = {name = score_list[1].name, score = score_list[1].killscore}
	score_list = get_sorted_list("deaths", score_list)
	mvp.deaths = {name = score_list[1].name, score = score_list[1].deaths}
	score_list = get_sorted_list("built_entities", score_list)
	mvp.built_entities = {name = score_list[1].name, score = score_list[1].built_entities}
	return mvp
end

local function is_game_lost()
	if global.market then return end

	for _, player in pairs(game.connected_players) do
		if player.gui.left["fish_defense_game_lost"] then return end
		local f = player.gui.left.add({ type = "frame", name = "fish_defense_game_lost", caption = "The fish market was overrun! The biters are having a feast :3", direction = "vertical"})
		f.style.font_color = {r = 0.65, g = 0.1, b = 0.99}

		local t = f.add({type = "table", column_count = 2})
		local l = t.add({type = "label", caption = "Survival Time >> "})
		l.style.font = "default-listbox"
		l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}

		if global.market_age >= 216000 then
			local l = t.add({type = "label", caption = math.floor(((global.market_age / 60) / 60) / 60) .. " hours " .. math.ceil((global.market_age % 216000 / 60) / 60) .. " minutes"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
		else
			local l = t.add({type = "label", caption = math.ceil((global.market_age % 216000 / 60) / 60) .. " minutes"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}
		end

		local mvp = get_mvps()
		if mvp then

			local l = t.add({type = "label", caption = "MVP Defender >> "})
			l.style.font = "default-listbox"
			l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
			local l = t.add({type = "label", caption = mvp.killscore.name .. " with a score of " .. mvp.killscore.score})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}

			local l = t.add({type = "label", caption = "MVP Builder >> "})
			l.style.font = "default-listbox"
			l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
			local l = t.add({type = "label", caption = mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}

			local l = t.add({type = "label", caption = "MVP Deaths >> "})
			l.style.font = "default-listbox"
			l.style.font_color = {r = 0.22, g = 0.77, b = 0.44}
			local l = t.add({type = "label", caption = mvp.deaths.name .. " died " .. mvp.deaths.score .. " times"})
			l.style.font = "default-bold"
			l.style.font_color = {r=0.33, g=0.66, b=0.9}

			if not global.results_sent then
				local result = {}
				insert(result, 'MVP Defender: \\n')
				insert(result, mvp.killscore.name .. " with a score of " .. mvp.killscore.score .. "\\n" )
				insert(result, '\\n')
				insert(result, 'MVP Builder: \\n')
				insert(result, mvp.built_entities.name .. " built " .. mvp.built_entities.score .. " things\\n" )
				insert(result, '\\n')
				insert(result, 'MVP Deaths: \\n')
				insert(result, mvp.deaths.name .. " died " .. mvp.deaths.score .. " times" )
				local message = table.concat(result)
				Server.to_discord_embed(message)
				global.results_sent = true
			end
		end

		for _, player in pairs(game.connected_players) do
			player.play_sound{path="utility/game_lost", volume_modifier=0.75}
		end
	end

	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_distance = 15
	game.map_settings.enemy_expansion.settler_group_min_size = 15
	game.map_settings.enemy_expansion.settler_group_max_size = 30
	game.map_settings.enemy_expansion.min_expansion_cooldown = 600
	game.map_settings.enemy_expansion.max_expansion_cooldown = 600
end

local function damage_entities_in_radius(surface, position, radius, damage)
	local entities_to_damage = surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})
	for _, entity in pairs(entities_to_damage) do
		if entity.valid then
			if entity.health and entity.name ~= "land-mine" then
				if entity.force.name ~= "enemy" then
					if entity.name == "character" then
						entity.damage(damage, "enemy")
					else
						entity.health = entity.health - damage
						if entity.health <= 0 then entity.die("enemy") end
					end
				end
			end
		end
	end
end

local function market_kill_visuals()
	local m = 32
	local m2 = m * 0.005
	for i = 1, 1024, 1 do
		global.market.surface.create_entity({
			name = "branch-particle",
			position = global.market.position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math.random(0, m) * 0.01), m2 - (math.random(0, m) * 0.01)}
		})
	end
	for x = -5, 5, 0.5 do
		for y = -5, 5, 0.5 do
			if math_random(1, 2) == 1 then
				global.market.surface.create_trivial_smoke({name="smoke-fast", position={global.market.position.x + (x * 0.35), global.market.position.y + (y * 0.35)}})
			end
			if math_random(1, 3) == 1 then
				global.market.surface.create_trivial_smoke({name="train-smoke", position={global.market.position.x + (x * 0.35), global.market.position.y + (y * 0.35)}})
			end
		end
	end
	global.market.surface.spill_item_stack(global.market.position,{name = "raw-fish", count = 1024}, true)
end

local biter_splash_damage = {
	["medium-biter"] = {visuals = {"blood-explosion-big", "big-explosion"}, radius = 1.5, damage_min = 50, damage_max = 100, chance = 8},
	["big-biter"] = {visuals = {"blood-explosion-huge", "ground-explosion"}, radius = 2, damage_min = 75, damage_max = 150, chance = 16},
	["behemoth-biter"] = {visuals = {"blood-explosion-huge", "big-artillery-explosion"}, radius = 2.5, damage_min = 100, damage_max = 200, chance = 32}
}

local function on_entity_died(event)
	if event.entity.force.name == "enemy" then
		local surface = event.entity.surface

		if global.boss_biters[event.entity.unit_number] then boss_biter.died(event)	end

		local splash = biter_splash_damage[event.entity.name]
		if splash then
			if math_random(1, splash.chance) == 1 then
				for _, visual in pairs(splash.visuals) do
					surface.create_entity({name = visual, position = event.entity.position})
				end
				damage_entities_in_radius(surface, event.entity.position, splash.radius, math_random(splash.damage_min, splash.damage_max))
				return
			end
		end

		if event.entity.name == "behemoth-biter" then
			if math_random(1, 16) == 1 then
				local p = surface.find_non_colliding_position("big-biter", event.entity.position, 3, 0.5)
				if p then surface.create_entity {name = "big-biter", position = p} end
			end
			for i = 1, math_random(1, 2), 1 do
				local p = surface.find_non_colliding_position("medium-biter", event.entity.position, 3, 0.5)
				if p then surface.create_entity {name = "medium-biter", position = p} end
			end
		end
		return
	end

	if event.entity == global.market then
		market_kill_visuals()
		global.market = nil
		global.market_age = game.tick
		is_game_lost()
	end

	if global.entity_limits[event.entity.name] then
		global.entity_limits[event.entity.name].placed = global.entity_limits[event.entity.name].placed - 1
		update_fd_stats()
	end
end

local function on_player_joined_game(event)
	local player = game.players[event.player_index]

	if not global.fish_defense_init_done then
		local map_gen_settings = {}
		map_gen_settings.water = "0.5"
		map_gen_settings.cliff_settings = {cliff_elevation_interval = 16, cliff_elevation_0 = 32}
		map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "3", size = "2", richness = "1"},
			["stone"] = {frequency = "3", size = "2", richness = "1"},
			["copper-ore"] = {frequency = "3", size = "2", richness = "1"},
			["iron-ore"] = {frequency = "3", size = "2", richness = "1"},
			["uranium-ore"] = {frequency = "2", size = "1", richness = "1"},
			["crude-oil"] = {frequency = "4", size = "1", richness = "1"},
			["trees"] = {frequency = "1.5", size = "1.5", richness = "1"},
			["enemy-base"] = {frequency = "none", size = "none", richness = "none"}
		}
		game.create_surface("fish_defender", map_gen_settings)
		local surface = game.surfaces["fish_defender"]

		local radius = 256
		game.forces.player.chart(surface, {{x = -1 * radius, y = -1 * radius}, {x = radius, y = radius}})

		game.map_settings.enemy_expansion.enabled = false
		game.map_settings.enemy_evolution.destroy_factor = 0
		game.map_settings.enemy_evolution.time_factor = 0
		game.map_settings.enemy_evolution.pollution_factor = 0
		game.map_settings.pollution.enabled = false

		game.forces["player"].technologies["atomic-bomb"].enabled = false

		global.entity_limits = {
			["gun-turret"] = {placed = 1, limit = 1, str = "gun turret", slot_price = 75},
			["laser-turret"] = {placed = 0, limit = 1, str = "laser turret", slot_price = 300},
			["artillery-turret"] = {placed = 0, limit = 1, str = "artillery turret", slot_price = 500},
			["flamethrower-turret"] =  {placed = 0, limit = 0, str = "flamethrower turret", slot_price = 50000},
			["land-mine"] =  {placed = 0, limit = 1, str = "mine", slot_price = 1}
		}

		game.create_force("decoratives")
		game.forces["decoratives"].set_cease_fire("enemy", true)
		game.forces["enemy"].set_cease_fire("decoratives", true)
		game.forces["player"].set_cease_fire("decoratives", true)

		global.comfylatron_habitat = {
			left_top = {x = -1500, y = -1500},
			right_bottom = {x = -80, y = 1500}
		}

		global.fish_defense_init_done = true
	end

	if player.online_time < 1 then
		player.insert({name = "pistol", count = 1})
		--player.insert({name = "iron-axe", count = 1})
		player.insert({name = "raw-fish", count = 3})
		player.insert({name = "firearm-magazine", count = 16})
		player.insert({name = "iron-plate", count = 32})
		if global.show_floating_killscore then global.show_floating_killscore[player.name] = false end
	end

	local surface = game.surfaces["fish_defender"]
	if player.online_time < 2 and surface.is_chunk_generated({0,0}) then
		player.teleport(surface.find_non_colliding_position("character", {-75, 4}, 50, 1), "fish_defender")
	else
		if player.online_time < 2 then
			player.teleport({-50, 0}, "fish_defender")
		end
	end

	create_wave_gui(player)
	add_fd_stats_button(player)

	if game.tick > 900 then
		is_game_lost()
	end
end

local function get_replacement_tile(surface)
	local tilename = "grass-1"
	for x = -160, 160, 1 do
		for y = -96, 90, 1 do
			local tile = surface.get_tile(x, y)
			if tile.name ~= "water" and tile.name ~= "deepwater" then
				tilename = tile.name
			end
		end
	end
	return tilename
end

local worm_raffle_table = {
		[1] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret"},
		[2] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret"},
		[3] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[4] = {"small-worm-turret", "small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret"},
		[5] = {"small-worm-turret", "small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[6] = {"small-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret"},
		[7] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[8] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret"},
		[9] = {"medium-worm-turret", "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"},
		[10] = {"medium-worm-turret", "medium-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret", "big-worm-turret"}
	}
local rock_raffle = {"sand-rock-big","sand-rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-big","rock-huge"}

local function spawn_obstacles(left_top, surface)
	if not global.obstacle_start_x then global.obstacle_start_x = math.abs(left_top.x) - 32 end
	local current_depth = math.abs(left_top.x) - global.obstacle_start_x
	local worm_amount = math.ceil(current_depth / 64)
	local i = math.ceil(current_depth / 256)
	if i > 10 then i = 10 end
	if i < 1 then i = 1 end
	local worm_raffle = worm_raffle_table[i]

	local rocks_amount = math.ceil(current_depth / 16)

	local tile_positions = {}
	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if not surface.get_tile(pos).collides_with("player-layer") then
				tile_positions[#tile_positions + 1] = pos
			end
		end
	end
	if #tile_positions == 0 then return end

	tile_positions = shuffle(tile_positions)
	for _, pos in pairs(tile_positions) do
		surface.create_entity({name = worm_raffle[math_random(1, #worm_raffle)], position = pos, force = "enemy"})
		worm_amount = worm_amount - 1
		if worm_amount < 1 then break end
	end

	tile_positions = shuffle(tile_positions)
	for _, pos in pairs(tile_positions) do
		surface.create_entity({name = rock_raffle[math_random(1, #rock_raffle)], position = pos})
		rocks_amount = rocks_amount - 1
		if rocks_amount < 1 then break end
	end
end

local map_height = 96

local function on_chunk_generated(event)
	local surface = game.surfaces["fish_defender"]

	if not surface then return end
	if surface.name ~= event.surface.name then return end

	local area = event.area
	local left_top = area.left_top

	if left_top.x <= -196 then

		local search_area = {{left_top.x - 32, left_top.y - 32}, {left_top.x + 32, left_top.y + 32}}
		if surface.count_tiles_filtered({name = "water", area = search_area}) == 0 and math_random(1, 64) == 1 then
			map_functions.draw_noise_tile_circle({x = left_top.x + math_random(1,30), y = left_top.y + math_random(1,30)}, "water", surface, math_random(6, 12))
		end

		if not global.spawn_ores_generated then

			local spawn_position_x = -76

			surface.create_entity({name = "electric-beam", position = {160, -96}, source = {160, -96}, target = {160,96}})

			local tiles = {}
			local replacement_tile = get_replacement_tile(surface)
			local water_tiles = surface.find_tiles_filtered({name = {"water", "deepwater"}})

			for _, tile in pairs(water_tiles) do
				insert(tiles, {name = replacement_tile, position = {tile.position.x, tile.position.y}})
			end
			surface.set_tiles(tiles, true)

			local entities = surface.find_entities_filtered({type = "resource", area = {{-160, -96},{160, 96}}})
			for _, entity in pairs(entities) do
				entity.destroy()
			end

			local decorative_names = {}
			for k,v in pairs(game.decorative_prototypes) do
				if v.autoplace_specification then
				  decorative_names[#decorative_names+1] = k
				end
			 end
			for x = -4, 4, 1 do
				for y = -3, 3, 1 do
					surface.regenerate_decorative(decorative_names, {{x,y}})
				end
			end

			local ore_positions = {{x = -128, y = -64},{x = -128, y = -32},{x = -128, y = 32},{x = -128, y = 64},{x = -128, y = 0}}
			ore_positions = shuffle(ore_positions)
			map_functions.draw_smoothed_out_ore_circle(ore_positions[1], "copper-ore", surface, 15, 2500)
			map_functions.draw_smoothed_out_ore_circle(ore_positions[2], "iron-ore", surface, 15, 2500)
			map_functions.draw_smoothed_out_ore_circle(ore_positions[3], "coal", surface, 15, 1500)
			map_functions.draw_smoothed_out_ore_circle(ore_positions[4], "stone", surface, 15, 1500)
			map_functions.draw_noise_tile_circle({x = -96, y = 0}, "water", surface, 16)
			map_functions.draw_oil_circle(ore_positions[5], "crude-oil", surface, 8, 200000)

			local pos = surface.find_non_colliding_position("market",{spawn_position_x, 0}, 50, 1)
			global.market = place_fish_market(surface, pos)
			
			local pos = surface.find_non_colliding_position("gun-turret",{spawn_position_x + 5, 1}, 50, 1)
			local turret = surface.create_entity({name = "gun-turret", position = pos, force = "player"})
			turret.insert({name = "firearm-magazine", count = 32})

			for x = -20, 20, 1 do
				for y = -20, 20, 1 do
					local pos = {x = global.market.position.x + x, y = global.market.position.y + y}
					local distance_to_center = math.sqrt(x^2 + y^2)
					if distance_to_center > 8 and distance_to_center < 15 then
						if math_random(1,3) == 1 and surface.can_place_entity({name = "wooden-chest", position = pos, force = "player"}) then
							local chest = surface.create_entity({name = "wooden-chest", position = pos, force = "player"})
						end
					end
				end
			end

			local area = {{x = -160, y = -96}, {x = 160, y = 96}}
			for _, tile in pairs(surface.find_tiles_filtered({name = "water", area = area})) do
				if math_random(1, 32) == 1 then
					surface.create_entity({name = "fish", position = tile.position})
				end
			end

			local pos = surface.find_non_colliding_position("character",{spawn_position_x + 1, 4}, 50, 1)
			game.forces["player"].set_spawn_position(pos, surface)
			for _, player in pairs(game.connected_players) do
				local pos = surface.find_non_colliding_position("character",{spawn_position_x + 1, 4}, 50, 1)
				player.teleport(pos, surface)
			end

			global.spawn_ores_generated = true
		end
	end

	local tiles = {}
	local hourglass_center_piece_length = 64

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}
			if pos.y >= map_height then
				if pos.y > pos.x - hourglass_center_piece_length and pos.x > 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
				if pos.y > (pos.x + hourglass_center_piece_length) * -1 and pos.x <= 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
			end
			if pos.y < map_height * -1 then
				if pos.y < (pos.x - hourglass_center_piece_length) * -1 and pos.x > 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
				if pos.y < pos.x + hourglass_center_piece_length and pos.x <= 0 then
					insert(tiles, {name = "out-of-map", position = pos})
				end
			end
		end
	end

	surface.set_tiles(tiles, false)

	for _, tile in pairs(surface.find_tiles_filtered({name = "water", area = event.area})) do
		if math_random(1, 32) == 1 then
			surface.create_entity({name = "fish", position = tile.position})
		end
	end

	if left_top.x < -2048 then
		spawn_obstacles(left_top, surface)
	end

	if left_top.x < 0 then return end

	for _, entity in pairs(surface.find_entities_filtered({area = area, type = "cliff"})) do
		entity.destroy()
	end

	if left_top.x < 160 then return end

	for _, entity in pairs(surface.find_entities_filtered({area = area, type = "tree"})) do
		entity.destroy()
	end

	for _, entity in pairs(surface.find_entities_filtered({area = area, type = "resource"})) do
		surface.create_entity({name = "uranium-ore", position = entity.position, amount = math_random(200, 8000)})
		entity.destroy()
	end

	local tiles = {}

	for x = 0, 31, 1 do
		for y = 0, 31, 1 do
			local pos = {x = left_top.x + x, y = left_top.y + y}

			local tile = surface.get_tile(pos)
			if tile.name ~= "out-of-map" then

				if pos.x > 0 then
					if pos.x > 320 then
						insert(tiles, {name = "out-of-map", position = pos})
					else
						local a = 0 + (pos.x - 160) * 0.01
						local b = (pos.x - 160) * 0.035
						local r = (pos.x - 160) * 0.015
						if a > 0.75 then a = 0.75 end
						if b > 1 then b = 1 end
						if r > 0.6 then r = 0.6 end
						rendering.draw_sprite({sprite = "tile/lab-dark-2", target = {pos.x + 0.5, pos.y + 0.5}, surface = surface, tint = {r = r, g = 0, b = b, a = a}, render_layer = "ground"})
					end

					if pos.x > 296 and pos.x < 312 and math_random(1, 128) == 1 then
						if surface.can_place_entity({name = "biter-spawner", force = "decoratives", position = pos}) then
							local entity
							if math_random(1,4) == 1 then
								entity = surface.create_entity({name = "spitter-spawner", force = "decoratives", position = pos})
							else
								entity = surface.create_entity({name = "biter-spawner", force = "decoratives", position = pos})
							end
							entity.active = false
							entity.destructible = false
						end
					end
				end
			end
		end
	end
	surface.set_tiles(tiles, true)

	local decorative_names = {}
	for k,v in pairs(game.decorative_prototypes) do
		if v.autoplace_specification then
		  decorative_names[#decorative_names+1] = k
		end
	 end
	surface.regenerate_decorative(decorative_names, {{x=math.floor(event.area.left_top.x/32),y=math.floor(event.area.left_top.y/32)}})
end

local function on_built_entity(event)
	local get_score = Score.get_table().score_table
	local entity = event.created_entity
	if not entity.valid then return end
	if global.entity_limits[entity.name] then
		local surface = entity.surface

		if global.entity_limits[entity.name].placed < global.entity_limits[entity.name].limit then
			global.entity_limits[entity.name].placed = global.entity_limits[entity.name].placed + 1
			surface.create_entity(
				{name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].placed .. " / " .. global.entity_limits[entity.name].limit .. " " .. global.entity_limits[entity.name].str .. "s", color = {r=0.98, g=0.66, b=0.22}}
				)
			update_fd_stats()
		else
			surface.create_entity({name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].str .. " limit reached.", color = {r=0.82, g=0.11, b=0.11}})
			local player = game.players[event.player_index]
			player.insert({name = entity.name, count = 1})
			if get_score then
				if get_score[player.force.name] then
					if get_score[player.force.name].players[player.name] then
						get_score[player.force.name].players[player.name].built_entities = get_score[player.force.name].players[player.name].built_entities - 1
					end
				end
			end
			entity.destroy()
		end
	end
end

local function on_robot_built_entity(event)
	local entity = event.created_entity
	if global.entity_limits[entity.name] then
		local surface = entity.surface
		if global.entity_limits[entity.name].placed < global.entity_limits[entity.name].limit then
			global.entity_limits[entity.name].placed = global.entity_limits[entity.name].placed + 1
			surface.create_entity(
				{name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].placed .. " / " .. global.entity_limits[entity.name].limit .. " " .. global.entity_limits[entity.name].str .. "s", color = {r=0.98, g=0.66, b=0.22}}
				)
			update_fd_stats()
		else
			surface.create_entity({name = "flying-text", position = entity.position, text = global.entity_limits[entity.name].str .. " limit reached.", color = {r=0.82, g=0.11, b=0.11}})
			local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
			inventory.insert({name = entity.name, count = 1})
			entity.destroy()
		end
	end
end

local function on_tick()
	if game.tick % 30 == 0 then
		if global.market then
			for _, player in pairs(game.connected_players) do
				if game.surfaces["fish_defender"].peaceful_mode == false then
					create_wave_gui(player)
				end
			end
		end
		if game.tick % 180 == 0 then
			if game.surfaces["fish_defender"] then
				game.forces.player.chart(game.surfaces["fish_defender"], {{x = -64, y = -256}, {x = 288, y = 256}})
				if global.difficulty_vote_index then
					global.wave_interval = difficulties_votes[global.difficulty_vote_index].wave_interval
				end
			end
		end

		if global.market_age then
			if not global.game_restart_timer then
				global.game_restart_timer = 10800
			else
				if global.game_restart_timer < 0 then return end
				global.game_restart_timer = global.game_restart_timer - 30
			end
			if global.game_restart_timer % 1800 == 0 then
				if global.game_restart_timer > 0 then game.print("Map will restart in " .. global.game_restart_timer / 60 .. " seconds!", { r=0.22, g=0.88, b=0.22}) end
				if global.game_restart_timer == 0 then
					game.print("Map is restarting!", { r=0.22, g=0.88, b=0.22})
					--game.write_file("commandPipe", ":loadscenario --force", false, 0)

					local message = 'Map is restarting! '
					Server.to_discord_bold(table.concat{'*** ', message, ' ***'})
					Server.start_scenario('Fish_Defender')

				end
			end
		end
	end

	if game.tick % global.wave_interval == global.wave_interval - 1 then
		if game.surfaces["fish_defender"].peaceful_mode == true then return end
		biter_attack_wave()
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if player.position.x >= 160 then
		player.teleport({player.position.x - 1, player.position.y}, game.surfaces["fish_defender"])
		if player.position.y > map_height or player.position.y < map_height * -1 then
			player.teleport({player.position.x, 0}, game.surfaces["fish_defender"])
		end
		if player.character then
			player.character.health = player.character.health - 25
			player.character.surface.create_entity({name = "water-splash", position = player.position})
			if player.character.health <= 0 then player.character.die("enemy") end
		end
	end
end

local function on_player_mined_entity(event)
	if global.entity_limits[event.entity.name] then
		global.entity_limits[event.entity.name].placed = global.entity_limits[event.entity.name].placed - 1
		update_fd_stats()
	end
end

local function on_robot_mined_entity(event)
	if global.entity_limits[event.entity.name] then
		global.entity_limits[event.entity.name].placed = global.entity_limits[event.entity.name].placed - 1
		update_fd_stats()
	end
end

local function on_research_finished(event)
	local research = event.research.name
	if research ~= "tanks" then return end
	game.forces["player"].technologies["artillery"].researched=true
	game.forces.player.recipes["artillery-wagon"].enabled = false
end

local function on_player_respawned(event)
	if not global.market_age then return end
	local player = game.players[event.player_index]
	player.character.destructible = false
end

local function on_init(event)
	global.wave_interval = 3600					--interval between waves in ticks
	global.wave_grace_period = 54000
	global.difficulty_poll_closing_timeout = 54000
	global.boss_biters = {}
	global.acid_lines_delay = {}
end

event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_market_item_purchased, on_market_item_purchased)
event.add(defines.events.on_player_respawned, on_player_respawned)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
event.add(defines.events.on_tick, on_tick)
event.on_init(on_init)

require "modules.difficulty_vote"