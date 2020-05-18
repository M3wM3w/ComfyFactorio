require "modules.biter_reanimator"
require "maps.native_war.share_chat"
require "maps.native_war.mineable_wreckage_yields_scrap"
local Global = require 'utils.global'
local Tabs = require 'comfy_panel.main'
local Map_score = require "modules.map_score"
local Team = require "maps.native_war.team"
local Terrain = require "maps.native_war.terrain"
local Gui = require "maps.native_war.gui"
local Init = require "maps.native_war.init"
local Settings = require "maps.native_war.settings"
local Reset = require "functions.soft_reset"
local Map = require "maps.native_war.map_info"
local Team_manager = require "maps.native_war.team_manager"
local math_random = math.random
local Public = {}

local worm_turret_spawn_radius = 18

local worm_turret_vectors = {}
worm_turret_vectors.west = {}
for x = 0, worm_turret_spawn_radius, 1 do
	for y = worm_turret_spawn_radius * -1, worm_turret_spawn_radius, 1 do
		local d = math.sqrt(x ^ 2 + y ^ 2)
		if d <= worm_turret_spawn_radius and d > 3 then table.insert(worm_turret_vectors.west, {x, y}) end
	end
end
worm_turret_vectors.east = {}
for x = worm_turret_spawn_radius * -1, 0, 1 do
	for y = worm_turret_spawn_radius * -1, worm_turret_spawn_radius, 1 do
		local d = math.sqrt(x ^ 2 + y ^ 2)
		if d <= worm_turret_spawn_radius and d > 3 then table.insert(worm_turret_vectors.east, {x, y}) end
	end
end

function create_beams(surface, energy, force)
	if force == "west" then
		local beams = surface.find_entities_filtered{area = {{-140,-100},{-30,100}}, name = "electric-beam"}
		for _, e in pairs(beams) do
			e.destroy()
		end
		local beams = surface.find_entities_filtered{area = {{-30,20},{30,100}}, name = "electric-beam"}
		for _, e in pairs(beams) do
			e.destroy()
		end
		global.map_forces[force].spawn = {x=-137,y=0}
		if energy >=6 and energy < 12 then
			surface.create_entity({name = "electric-beam", position = {-120, -35}, source = {-120, -35}, target = {-137,-35}})
			surface.create_entity({name = "electric-beam", position = {-120, -35}, source = {-120, -35}, target = {-102,-35}})
			global.map_forces[force].spawn = {x=-120,y=-32}
		end
		if energy >=12 and energy < 18 then
			surface.create_entity({name = "electric-beam", position = {-120, -98}, source = {-120, -98}, target = {-137,-98}})
			surface.create_entity({name = "electric-beam", position = {-120, -98}, source = {-120, -98}, target = {-102,-98}})
				global.map_forces[force].spawn = {x=-120,y=-96}
		end
		if energy >=18 and energy < 24 then
			surface.create_entity({name = "electric-beam", position = {-60, -98}, source = {-60, -98}, target = {-77,-98}})
			surface.create_entity({name = "electric-beam", position = {-60, -98}, source = {-60, -98}, target = {-42,-98}})
				global.map_forces[force].spawn = {x=-60,y=-100}
		end
		if energy >=24 and energy < 30 then
			surface.create_entity({name = "electric-beam", position = {-60, -35}, source = {-60, -35}, target = {-77,-35}})
			surface.create_entity({name = "electric-beam", position = {-60, -35}, source = {-60, -35}, target = {-42,-35}})
				global.map_forces[force].spawn = {x=-60,y=-37}
		end
		if energy >=30 and energy < 36 then
			surface.create_entity({name = "electric-beam", position = {-60, 30}, source = {-60, 30}, target = {-77, 30}})
			surface.create_entity({name = "electric-beam", position = {-60, 30}, source = {-60, 30}, target = {-42, 30}})
				global.map_forces[force].spawn = {x=-60,y=28}
		end
		if energy >=36 and energy < 42 then
			surface.create_entity({name = "electric-beam", position = {-60, 93}, source = {-60, 93}, target = {-77,93}})
			surface.create_entity({name = "electric-beam", position = {-60, 93}, source = {-60, 93}, target = {-42,93}})
				global.map_forces[force].spawn = {x=-60,y=91}
		end
		if energy >=42 and energy < 48 then
			surface.create_entity({name = "electric-beam", position = {0, 93}, source = {0, 93}, target = {-17,93}})
			surface.create_entity({name = "electric-beam", position = {0, 93}, source = {0, 93}, target = {18,93}})
				global.map_forces[force].spawn = {x=0,y=95}
		end
		if energy >=48  then
			surface.create_entity({name = "electric-beam", position = {0, -35}, source = {0, 30}, target = {-17, 30}})
			surface.create_entity({name = "electric-beam", position = {0, -35}, source = {0, 30}, target = {18, 30}})
				global.map_forces[force].spawn = {x=0,y=-33}
		end
	elseif force == "east" then
		local beams2 = surface.find_entities_filtered{area = {{30,-100},{140,100}}, name = "electric-beam"}
		for _, e in pairs(beams2) do
			e.destroy()
		end
		local beams2 = surface.find_entities_filtered{area = {{-30,-100},{30,-20}}, name = "electric-beam"}
		for _, e in pairs(beams2) do
			e.destroy()
		end
		global.map_forces[force].spawn = {x=137,y=0}
		if energy >=6 and energy < 12 then
			surface.create_entity({name = "electric-beam", position = {120, -35}, source = {120, 30}, target = {103, 30}})
			surface.create_entity({name = "electric-beam", position = {120, -35}, source = {120, 30}, target = {138, 30}})
				global.map_forces[force].spawn = {x=120,y=32}
		end
		if energy >=12 and energy < 18 then
			surface.create_entity({name = "electric-beam", position = {120, 93}, source = {120, 93}, target = {103,93}})
			surface.create_entity({name = "electric-beam", position = {120, 93}, source = {120, 93}, target = {138,93}})
				global.map_forces[force].spawn = {x=120,y=96}
		end
		if energy >=18 and energy < 24 then
			surface.create_entity({name = "electric-beam", position = {60, 93}, source = {60, 93}, target = {43,93}})
			surface.create_entity({name = "electric-beam", position = {60, 93}, source = {60, 93}, target = {78,93}})
				global.map_forces[force].spawn = {x=60,y=100}
		end
		if energy >=24 and energy < 30 then
			surface.create_entity({name = "electric-beam", position = {60, 30}, source = {60, 30}, target = {43, 30}})
			surface.create_entity({name = "electric-beam", position = {60, 30}, source = {60, 30}, target = {78, 30}})
				global.map_forces[force].spawn = {x=60,y=37}
		end
		if energy >=30 and energy < 36 then
			surface.create_entity({name = "electric-beam", position = {60, -35}, source = {60, -35}, target = {43,-35}})
			surface.create_entity({name = "electric-beam", position = {60, -35}, source = {60, -35}, target = {78,-35}})
				global.map_forces[force].spawn = {x=60,y=-28}
		end
		if energy >=36 and energy < 42 then
			surface.create_entity({name = "electric-beam", position = {60, -98}, source = {60, -98}, target = {43,-98}})
			surface.create_entity({name = "electric-beam", position = {60, -98}, source = {60, -98}, target = {78,-98}})
				global.map_forces[force].spawn = {x=60,y=-91}
		end
		if energy >=42 and energy < 48 then
			surface.create_entity({name = "electric-beam", position = {0, -98}, source = {0, -98}, target = {-17,-98}})
			surface.create_entity({name = "electric-beam", position = {0, -98}, source = {0, -98}, target = {18,-98}})
				global.map_forces[force].spawn = {x=0,y=-95}
		end
		if energy >=48  then
			surface.create_entity({name = "electric-beam", position = {0, -35}, source = {0, -35}, target = {-17,-35}})
			surface.create_entity({name = "electric-beam", position = {0, -35}, source = {0, -35}, target = {18,-35}})
				global.map_forces[force].spawn = {x=0,y=33}
		end
	else
	end
end

local function initial_worm_turret(surface)
	for _, force_name in pairs({"west", "east"}) do
		for k , pos in pairs(global.map_forces[force_name].worm_turrets_positions) do
			surface.create_entity({name = "small-worm-turret", position = pos, force = force_name})
		end
	end
end

local function get_belts(market)
	local belts = market.surface.find_entities_filtered({
			type = "transport-belt",
			area = {{market.position.x - 2, market.position.y - 1},{market.position.x +2 , market.position.y + 1}},
			force = market.force,
		})
	return belts
end

local function eat_food_from_belt(belt)
	for i = 1, 2, 1 do
		local line = belt.get_transport_line(i)
		for _, science_name in pairs(Settings.science_pack_name) do
			--if global.map_forces[belt.force.name].unit_count > global.map_forces[belt.force.name].max_unit_count then return end
			local removed_item_count = line.remove_item({name = science_name, count = 8})
			global.map_forces[belt.force.name].ate_buffer_potion[science_name] = global.map_forces[belt.force.name].ate_buffer_potion[science_name] + removed_item_count
		end
	end
end

local function spawn_wave_from_belt(force_name)
	for _, science_name in pairs(Settings.science_pack_name) do
		local nb_science = global.map_forces[force_name].ate_buffer_potion[science_name]
		if nb_science >= Settings.wave_price[science_name].price then
				Team.on_buy_wave("native_war", force_name, Settings.science_pack[science_name].short)
				global.map_forces[force_name].ate_buffer_potion[science_name] = global.map_forces[force_name].ate_buffer_potion[science_name] - Settings.wave_price[science_name].price
				--if global.map_forces[belt.force.name].ate_buffer_potion[science_name] < 0 then global.map_forces[belt.force.name].ate_buffer_potion[science_name] =0	end
		end
	end
end

local function nom()
	local surface = game.surfaces["native_war"]
	for key, force in pairs(global.map_forces) do
		if not force.hatchery then return end
		force.hatchery.health = force.hatchery.health + 5
		local belts = get_belts(force.hatchery)
		for _, belt in pairs(belts) do
			eat_food_from_belt(belt)
		end
		spawn_wave_from_belt(key)
	end
end

local function get_units(force_name)
	local units = {}
	local count = 1
	for _, unit in pairs(global.map_forces[force_name].units) do
		if not unit.unit_group then
			--if math_random(1, 3) ~= 1 then
				units[count] = unit
				count = count + 1
		--	end
		end
	end
	return units
end

local function send_unit_groups()
	local surface = game.surfaces["native_war"]
	for key, force in pairs(global.map_forces) do
		local units = get_units(key)
		if #units > 0 then
			--alert_bubble(key, units[1])
			local vectors = worm_turret_vectors[key]
			local vector = vectors[math_random(1, #vectors)]
			local position = {x = global.map_forces[key].spawn.x + 10 + vector[1], y = global.map_forces[key].spawn.y + vector[2]}
			local unit_group = surface.create_unit_group({position = position, force = key})
			for _, unit in pairs(units) do unit_group.add_member(unit) end
			if not force.target then return end
			if not force.target.valid then return end
			--unit.ai_settings.allow_destroy_when_commands_fail = false
			--unit.ai_settings.allow_try_return_to_spawner = false
			unit_group.set_command({
				type = defines.command.compound,
				structure_type = defines.compound_command.return_last,
				commands = {
					{
						type = defines.command.attack_area,
						destination = {x = force.target.position.x, y = force.target.position.y},
						radius = 6,
						distraction = defines.distraction.by_anything
					},
					{
						type = defines.command.attack,
						target = force.target,
						distraction = defines.distraction.by_enemy,
					},
				}
			})
			unit_group.start_moving()
		end
	end
end
local function randomize_worms()
	for k, pos in pairs(global.map_forces["west"].worm_turrets_positions) do
		local vx=math.random(0, 8)-4
		local vy=math.random(0, 8)-4
		global.map_forces["west"].worm_turrets_positions[k].x = pos.x + vx
		global.map_forces["west"].worm_turrets_positions[k].y = pos.y + vy
		global.map_forces["east"].worm_turrets_positions[k].x = global.map_forces["east"].worm_turrets_positions[k].x - vx
		global.map_forces["east"].worm_turrets_positions[k].y = global.map_forces["east"].worm_turrets_positions[k].y - vy
	end
end

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if player.position.y > -175 and player.position.y < -173 and player.position.x <= 15 and player.position.x >= -15 then
		player.teleport({player.position.x , 175}, game.surfaces["native_war"])
	end
	if player.position.y < 175 and player.position.y > 173 and player.position.x <= 15 and player.position.x >= -15 then
		player.teleport({player.position.x , -175}, game.surfaces["native_war"])
	end
	if math.abs(player.position.x) > 256 then
		if player.gui.screen["market_frame"] then player.gui.screen["market_frame"].destroy() end
	end
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity.valid then	return end
	if global.game_reset_tick then return end

	if entity.type == "unit" then
		local team = global.map_forces[entity.force.name]
		team.unit_count = team.unit_count - 1
		team.units[entity.unit_number] = nil
		return
	end
	if entity.name == "radar" then global.map_forces[entity.force.name].radar[entity.unit_number] = nil end
	if entity.type ~= "market" then return end

	if entity.force.name == "east" then
		game.print("East lost their Market.", {100, 100, 100})
		game.forces.east.play_sound{path="utility/game_lost", volume_modifier=0.85}

		game.print(">>>> WEST TEAM HAS WON THE GAME!!! <<<<", {250, 120, 0})
		game.forces.west.play_sound{path="utility/game_won", volume_modifier=0.85}

		for _, player in pairs(game.forces.west.connected_players) do
			if global.map_forces.east.player_count > 0 then
				Map_score.set_score(player, Map_score.get_score(player) + 1)
			end
		end
	else
		game.print("West lost their Market.", {100, 100, 100})
		game.forces.west.play_sound{path="utility/game_lost", volume_modifier=0.85}

		game.print(">>>> EAST TEAM HAS WON THE GAME!!! <<<<", {250, 120, 0})
		game.forces.east.play_sound{path="utility/game_won", volume_modifier=0.85}

		for _, player in pairs(game.forces.east.connected_players) do
			if global.map_forces.west.player_count > 0 then
				Map_score.set_score(player, Map_score.get_score(player) + 1)
			end
		end
	end

	game.print("Next round starting in 60 seconds..", {150, 150, 150})

	game.forces.spectator.play_sound{path="utility/game_won", volume_modifier=0.85}

	global.game_reset_tick = game.tick + 3600
	game.delete_surface("mirror_terrain")

	for _, player in pairs(game.connected_players) do
		for _, child in pairs(player.gui.left.children) do child.destroy() end
		Tabs.comfy_panel_call_tab(player, "Map Scores")
	end
end

local function on_built_entity(event)
	local player = game.players[event.player_index]
	if event.created_entity.name == "radar" then
		local unit_number = event.created_entity.unit_number
		local entity = event.created_entity
		global.map_forces[player.force.name].radar[unit_number] = entity
	end
end
-- on robot build radar is elsewhere EVL


local function on_player_mined_entity(event)
	local player = game.players[event.player_index]
	if event.entity.name == "radar" then
		global.map_forces[player.force.name].radar[event.entity.unit_number] = nil
	end
end

local function on_robot_mined_entity(event)
	if event.entity.name == "radar" then
		global.map_forces[event.robot.force.name].radar[event.entity.unit_number] = nil
	end
end

local function on_player_joined_game(event)
	local surface = game.surfaces["native_war"]
	local player = game.players[event.player_index]

	if player.online_time == 0 then
		player.spectator = true
		player.force = game.forces.spectator
		if surface.is_chunk_generated({0,-190}) then
			player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 32, 0.5), surface)
		else
			player.teleport({0,-190}, surface)
		end

		player.character.destructible = false
		game.permissions.get_group("spectator").add_player(player)
	end

	Map.player_joined_game(player)
	Team_manager.draw_top_toggle_button(player)
end

local function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
	if not element then return end
	if not element.valid then return end
	if Map.gui_click(player, element) then return end
	Team_manager.gui_click(event)
end

local function reveal_map(surface, force_name)
	local actif_radar_count = 0
	local radar_range_x = 16
	if force_name == "east" then
		-- find_entities_filtered{name="radar", force="east"}
		for k, ent in pairs(global.map_forces["east"].radar) do
			if ent.energy >= 5000 then
					actif_radar_count = actif_radar_count +1
			end
		end
		if actif_radar_count == 0 then return end
		local x_east =-224+actif_radar_count*radar_range_x*-1
		game.forces.east.chart(surface, {{x_east,(x_east)*0.5},{-224  ,(-x_east)*0.5}})
	end
	if force_name == "west" then
		for k, ent in pairs(global.map_forces["west"].radar) do
				if ent.energy >= 5000 then
					actif_radar_count = actif_radar_count +1
			end
		end
		if actif_radar_count == 0 then return end
		local x_west =224+actif_radar_count*radar_range_x
		game.forces.west.chart(surface, {{224, (-x_west)*0.5 }, {x_west, (x_west)*0.5 }})
	end
end

local function reset_operable_market(surface)
	local market = surface.find_entities_filtered{position = {-197,0}, radius = 5, type = "market"}
	market[1].operable = true
	local market = surface.find_entities_filtered{position = {197,0}, radius = 5, type = "market"}
	market[1].operable = true
end

local function tick()
	local game_tick = game.tick
	if game_tick == 120 then
		randomize_worms()
		initial_worm_turret(game.surfaces["native_war"])
	end
	if game_tick % 240 == 0 then --400 ou 200
		local surface = game.surfaces["native_war"]
		reset_operable_market(surface)
		local area = {{-224, -150}, {224, 150}}
		game.forces.west.chart(surface, area)
		game.forces.east.chart(surface, area)
		Team_manager.refresh()
	end

	if game_tick % 480 == 0 then -- was 600
		local surface = game.surfaces["native_war"]
		reveal_map(surface, "east")
	end
	if (game_tick+240) % 480 == 0 then -- was +300 % 600
		local surface = game.surfaces["native_war"]
		reveal_map(surface, "west")
	end

	if game_tick % 900 == 0 then
		local surface = game.surfaces["native_war"]
		for _, force_name in pairs({"west", "east"}) do
			local structs = game.surfaces["native_war"].find_entities_filtered{position = global.map_forces[force_name].eei, radius = 5, type = "electric-energy-interface"}
			local energy = structs[1].energy/100000
			if energy < global.map_forces[force_name].energy then
				local new_global_energy = global.map_forces[force_name].energy -6
				if new_global_energy <= 0 then new_global_energy = 0 end
				game.print(force_name..' recule son beam')
				create_beams(surface, new_global_energy, force_name)
				global.map_forces[force_name].energy = new_global_energy
			end
		end
	end
	if game_tick % 1800 == 0 then
		local surface = game.surfaces["native_war"]
		for _, force_name in pairs({"west", "east"}) do
			local structs = game.surfaces["native_war"].find_entities_filtered{position = global.map_forces[force_name].eei, radius = 5, type = "electric-energy-interface"}
			local energy = structs[1].energy/100000
			if energy >= global.map_forces[force_name].energy + 6 then
				local new_global_energy = global.map_forces[force_name].energy + 6
				if new_global_energy >= 48 then new_global_energy = 48 end
				game.print(force_name..' avance son beam')
				create_beams(surface, new_global_energy, force_name)
				global.map_forces[force_name].energy = new_global_energy
			end
		end
	end
end

--Construction Robot Restriction
local robot_build_restriction = {
	["east"] = function(x,y)
		if x < 170 then return true end
		if (x-160)*(x-160) + y*y <= 40*40 then return true end
	end,
	["west"] = function(x,y)
		if x > -170 then return true end
		if (x+160)*(x+160) + y*y <= 40*40 then return true end


	end
}

local function on_robot_built_entity(event)
	if not robot_build_restriction[event.robot.force.name] then return end
	if not robot_build_restriction[event.robot.force.name](event.created_entity.position.x,event.created_entity.position.y) then
		if event.created_entity.name == "radar" then
			local unit_number = event.created_entity.unit_number
			local entity = event.created_entity
			global.map_forces[event.robot.force.name].radar[unit_number] = entity
		end
	 return
 end
	local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
	inventory.insert({name = event.created_entity.name, count = 1})
	event.robot.surface.create_entity({name = "explosion", position = event.created_entity.position})
	game.print("Team " .. event.robot.force.name .. "'s construction drone had an accident.", {r = 200, g = 50, b = 100})
	event.created_entity.destroy()
end

local function on_entity_damaged(event)
	local entity = event.entity
	local cause = event.cause
	if not entity.valid then return end
	if entity.type == "unit" or entity.type == "turret" then
		if cause.type == "unit" then
			if cause.name == "small-biter" or cause.name == "medium-biter" or cause.name == "big-biter" or cause.name == "behemoth-biter" then
				local modified_damage = event.original_damage_amount * global.map_forces[cause.force.name].modifier.damage * global.map_forces[entity.force.name].modifier.resistance
				entity.health = entity.health - modified_damage
			elseif cause.name == "small-spitter" or cause.name == "medium-spitter" or cause.name == "big-spitter" or cause.name == "behemoth-spitter" then
				local modified_damage = event.original_damage_amount * global.map_forces[cause.force.name].modifier.splash * global.map_forces[entity.force.name].modifier.resistance
				entity.health = entity.health - modified_damage
			end
		end
	end
	if entity.type ~= "market" then return end
	if cause then
		if cause.valid then
			if cause.type == "unit" then
				if math_random(1,5) == 1 then return end
			end
		end
	end
	entity.health = entity.health + event.final_damage_amount

end

local function show_color_force()
	local force_name1= "east"
	local force_name2= "west"
	for _, unit in pairs(global.map_forces[force_name1].units) do
		rendering.draw_circle{color = {255, 1, 1 }, radius = 0.1, filled = true, target = unit, target_offset = {-0.1,-0.1} ,surface = unit.surface , time_to_live = 60, only_in_alt_mode=true }
	end
	for _, unit in pairs(global.map_forces[force_name2].units) do
		rendering.draw_circle{color = {1, 1, 255 }, radius = 0.1, filled = true, target = unit, target_offset = {-0.1,-0.1} ,surface = unit.surface , time_to_live = 60, only_in_alt_mode=true }
	end
end

local function on_init()
	game.difficulty_settings.technology_price_multiplier = 1
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_expansion.enabled = false
	game.map_settings.pollution.enabled = false

	global.map_forces = {
		["west"] = {},
		["east"] = {},
	}
	Init.settings()
	Init.surface()
	Init.forces()
	kill_entities_combat_zone(surface)
end


local event = require 'utils.event'
event.on_init(on_init)
event.on_nth_tick(60, tick)
event.on_nth_tick(60, show_color_force)
event.on_nth_tick(30, nom)
event.on_nth_tick(300,send_unit_groups)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
event.add(defines.events.on_robot_mined_entity, on_robot_mined_entity)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_gui_click, on_gui_click)
