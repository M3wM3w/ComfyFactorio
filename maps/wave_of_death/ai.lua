local biter_waves = require "maps.wave_of_death.biter_waves"
local ai = {}

ai.spawn_wave = function(surface, lane_number, wave_number, amount_modifier)	
	local is_spread_wave = true
	if amount_modifier == 1 then is_spread_wave = false end
	
	if not global.loaders[lane_number].valid then return end
	
	local x_modifier = 32 - math.random(0, 64)
	
	local spawn_position = {x = global.loaders[lane_number].position.x + x_modifier, y = global.loaders[lane_number].position.y - 288}
	
	local unit_group = surface.create_unit_group({position = spawn_position, force = "enemy"})
	
	for _, biter_type in pairs(biter_waves[wave_number]) do
		for count = 1, math.floor(biter_type.amount * amount_modifier), 1 do
			local pos = surface.find_non_colliding_position(biter_type.name, spawn_position, 96, 3)
			local biter = surface.create_entity({name = biter_type.name, position = pos, force = "enemy"})
			global.wod_biters[biter.unit_number] = {entity = biter, lane_number = lane_number, spread_wave = is_spread_wave}
			unit_group.add_member(biter)
			if not is_spread_wave then
				global.wod_lane[lane_number].alive_biters = global.wod_lane[lane_number].alive_biters + 1
			end
		end
	end
	
	unit_group.set_command({
		type = defines.command.compound,
		structure_type = defines.compound_command.return_last,
		commands = {
			{
				type = defines.command.attack_area,
				destination = {x = global.loaders[lane_number].position.x + x_modifier, y = global.loaders[lane_number].position.y},
				radius = 32,
				distraction=defines.distraction.by_enemy
			},									
			{
				type = defines.command.attack,
				target = global.loaders[lane_number],
				distraction = defines.distraction.by_enemy
			}
		}
	})
	
	if is_spread_wave then return end
	global.wod_lane[lane_number].current_wave = global.wod_lane[lane_number].current_wave + 1
	
	local m = 0.005
	if global.wod_lane[lane_number].current_wave > #biter_waves then
		m = 0.25
	end
	global.biter_evasion_health_increase_factor = global.biter_evasion_health_increase_factor + m
	
	for _, player in pairs(game.connected_players) do
		create_lane_buttons(player)
	end
end

--on_entity_died event
ai.spawn_spread_wave = function(event)  
	local entity = event.entity
	if not entity.unit_number then return end
	if not global.wod_biters[entity.unit_number] then return end
	if global.wod_biters[entity.unit_number].spread_wave then global.wod_biters[entity.unit_number] = nil return end

	local trigger_lane_number = global.wod_biters[entity.unit_number].lane_number

	global.wod_lane[trigger_lane_number].alive_biters = global.wod_lane[trigger_lane_number].alive_biters - 1
	if global.wod_lane[trigger_lane_number].alive_biters ~= 0 then return end

	for lane_number = 1, 4, 1 do
		if lane_number ~= trigger_lane_number then
			if #game.forces[lane_number].players > 0 and global.wod_lane[lane_number].game_lost == false then
				ai.spawn_wave(entity.surface, lane_number, global.wod_lane[trigger_lane_number].current_wave - 1, global.spread_amount_modifier)
			end
		end
	end

	--game.print("Lane #" .. trigger_lane_number .. " has defeated their wave.")
end

--on_entity_rotated event
ai.trigger_new_wave = function(event)
	local entity = event.entity
	if entity.name ~= "loader" then return end
	if game.tick < 18000 then entity.force.print(">> It is too early to call waves yet.", {r = 180, g = 0, b = 0}) return end
	if #game.players < 4 then entity.force.print(">> More players are required to spawn waves.", {r = 180, g = 0, b = 0}) return end
	local lane_number = tonumber(entity.force.name)
	if not global.wod_lane[lane_number] then return end
	if global.wod_lane[lane_number].alive_biters > 0 then
		entity.force.print(">> There are " .. global.wod_lane[lane_number].alive_biters .. " spawned biters left.", {r = 180, g = 0, b = 0})
		return 
	end
	
	local wave_number = global.wod_lane[lane_number].current_wave
	if not biter_waves[wave_number] then wave_number = #biter_waves end
    ai.spawn_wave(entity.surface, lane_number, wave_number, 1)
	
	local player = game.players[event.player_index]
	for _, force in pairs(game.forces) do
		if force.name == entity.force.name then
			force.print(">> " .. player.name .. " has summoned wave #" .. global.wod_lane[lane_number].current_wave - 1 .. "", {r = 0, g = 100, b = 0})
		else
			force.print(">> Lane " .. entity.force.name .. " summoned wave #" .. global.wod_lane[lane_number].current_wave - 1 .. "", {r = 0, g = 100, b = 0})
		end
	end
	
	for _, player in pairs(game.connected_players) do
		player.play_sound{path="utility/new_objective", volume_modifier=0.3}
	end		
end

ai.prevent_friendly_fire = function(event)	
	if event.cause then
		if event.cause.type == "unit" then return end		 
	end
	if event.entity.name ~= "loader" then return end		
	event.entity.health = event.entity.health + event.final_damage_amount
end

return ai