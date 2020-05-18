local string_sub = string.sub
local math_random = math.random
local math_round = math.round
local math_abs = math.abs
local table_insert = table.insert
local table_remove = table.remove

local balance_functions = {
	["flamethrower"] = function(force_name)
		global.combat_balance[force_name].flamethrower_damage = -0.6
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.combat_balance[force_name].flamethrower_damage)
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.combat_balance[force_name].flamethrower_damage)
	end,
	["refined-flammables"] = function(force_name)
		global.combat_balance[force_name].flamethrower_damage = global.combat_balance[force_name].flamethrower_damage + 0.05
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.combat_balance[force_name].flamethrower_damage)								
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.combat_balance[force_name].flamethrower_damage)
	end,
	["land-mine"] = function(force_name)
		if not global.combat_balance[force_name].land_mine then global.combat_balance[force_name].land_mine = -0.75 end
		game.forces[force_name].set_ammo_damage_modifier("landmine", global.combat_balance[force_name].land_mine)
	end,
	["stronger-explosives"] = function(force_name)
		if not global.combat_balance[force_name].land_mine then global.combat_balance[force_name].land_mine = -0.75 end
		global.combat_balance[force_name].land_mine = global.combat_balance[force_name].land_mine + 0.05								
		game.forces[force_name].set_ammo_damage_modifier("landmine", global.combat_balance[force_name].land_mine)
	end,
	["military"] = function(force_name)
		global.combat_balance[force_name].shotgun = 1
		game.forces[force_name].set_ammo_damage_modifier("shotgun-shell", global.combat_balance[force_name].shotgun)
	end,
}

local no_turret_blacklist = {
	["ammo-turret"] = true,
	["artillery-turret"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true
}

local landfill_biters_vectors = {{0,0}, {1,0}, {0,1}, {-1,0}, {0,-1}}
local landfill_biters = {
	["big-biter"] = true,
	["big-spitter"] = true,
	["behemoth-biter"] = true,	
	["behemoth-spitter"] = true,
}

local target_entity_types = {
	["assembling-machine"] = true,
	["boiler"] = true,
	["furnace"] = true,
	["generator"] = true,
	["lab"] = true,
	["mining-drill"] = true,
	["radar"] = true,
	["reactor"] = true,
	["roboport"] = true,
	["rocket-silo"] = true,
	["ammo-turret"] = true,
	["artillery-turret"] = true,
	["beacon"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true,
}

local Public = {}

function Public.add_target_entity(entity)
	if not entity then return end
	if not entity.valid then return end
	if not target_entity_types[entity.type] then return end
	table_insert(global.target_entities[entity.force.index], entity)
end

function Public.get_random_target_entity(force_index)
	local target_entities = global.target_entities[force_index]
	local size_of_target_entities = #target_entities
	if size_of_target_entities == 0 then return end
	for _ = 1, size_of_target_entities, 1 do
		local i = math_random(1, size_of_target_entities)
		local entity = target_entities[i]
		if entity and entity.valid then
			return entity
		else
			table_remove(target_entities, i)
			size_of_target_entities = size_of_target_entities - 1
			if size_of_target_entities == 0 then return end
		end
	end
end

function Public.get_health_modifier(force)
	if global.bb_evolution[force.name] < 1 then return 1 end
	return math_round((global.bb_evolution[force.name] - 1) * 3, 3) + 1
end

function Public.biters_landfill(entity)
	if not landfill_biters[entity.name] then return end	
	local position = entity.position
	if math_abs(position.y) < 8 then return true end
	local surface = entity.surface
	for _, vector in pairs(landfill_biters_vectors) do
		local tile = surface.get_tile({position.x + vector[1], position.y + vector[2]})
		if tile.collides_with("resource-layer") then
			surface.set_tiles({{name = "landfill", position = tile.position}})
			local particle_pos = {tile.position.x + 0.5, tile.position.y + 0.5}
			for i = 1, 50, 1 do 
				surface.create_particle({
					name = "stone-particle",
					position = particle_pos,
					frame_speed = 0.1,
					vertical_speed = 0.12,
					height = 0.01,
					movement = {-0.05 + math_random(0, 100) * 0.001, -0.05 + math_random(0, 100) * 0.001}
				})
			end
		end
	end
	return true
end

function Public.combat_balance(event)
	local research_name = event.research.name
	local force_name = event.research.force.name		
	local key
	for b = 1, string.len(research_name), 1 do
		key = string_sub(research_name, 0, b)
		if balance_functions[key] then
			if not global.combat_balance[force_name] then global.combat_balance[force_name] = {} end
			balance_functions[key](force_name)
			return
		end
	end
end

function Public.init_player(player)
	local surface = game.surfaces.biter_battles
	if player.character and player.character.valid then
		player.character.destroy()
		player.set_controller({type = defines.controllers.god})
		player.create_character()
	end	
	player.clear_items_inside()
	player.spectator = true
	player.force = game.forces.spectator
	if surface.is_chunk_generated({0,0}) then
		player.teleport(surface.find_non_colliding_position("character", {0,0}, 4, 0.5), surface)
	else
		player.teleport({0,0}, surface)
	end
	if player.character and player.character.valid then player.character.destructible = false end
	game.permissions.get_group("spectator").add_player(player)
end

function Public.no_turret_creep(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if not no_turret_blacklist[event.created_entity.type] then return end
	local surface = event.created_entity.surface				
	local spawners = surface.find_entities_filtered({type = "unit-spawner", area = {{entity.position.x - 70, entity.position.y - 70}, {entity.position.x + 70, entity.position.y + 70}}})
	if #spawners == 0 then return end
	
	local allowed_to_build = true
	
	for _, e in pairs(spawners) do
		if (e.position.x - entity.position.x)^2 + (e.position.y - entity.position.y)^2 < 4096 then
			allowed_to_build = false
			break
		end			
	end
	
	if allowed_to_build then return end
	
	if event.player_index then
		game.players[event.player_index].insert({name = entity.name, count = 1})		
	else	
		local inventory = event.robot.get_inventory(defines.inventory.robot_cargo)
		inventory.insert({name = entity.name, count = 1})													
	end
	
	surface.create_entity({
		name = "flying-text",
		position = entity.position,
		text = "Turret too close to spawner!",
		color = {r=0.98, g=0.66, b=0.22}
	})
	
	entity.destroy()
end

--share chat with player and spectator force
function Public.share_chat(event)
	if not event.message then return end	
	if not event.player_index then return end	
	local player = game.players[event.player_index] 	
	local color = player.chat_color
	
	if player.force.name == "north" then
		game.forces.spectator.print(player.name .. " (north): ".. event.message, color)
		game.forces.player.print(player.name .. " (north): ".. event.message, color)			
	end
	if player.force.name == "south" then
		game.forces.spectator.print(player.name .. " (south): ".. event.message, color)
		game.forces.player.print(player.name .. " (south): ".. event.message, color)
	end
	
	if global.tournament_mode then return end
	
	if player.force.name == "player" then
		game.forces.north.print(player.name .. " (spawn): ".. event.message, color)
		game.forces.south.print(player.name .. " (spawn): ".. event.message, color)
		game.forces.spectator.print(player.name .. " (spawn): ".. event.message, color)
	end
	if player.force.name == "spectator" then
		game.forces.north.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.south.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.player.print(player.name .. " (spectator): ".. event.message, color)
	end
end

function Public.spy_fish(player)
	if not player.character then return end
	local duration_per_unit = 2700 
	local i2 = player.get_inventory(defines.inventory.character_main)
	if not i2 then return end
	local owned_fishes = i2.get_item_count("raw-fish")
	owned_fishes = owned_fishes + i2.get_item_count("raw-fish")
	if owned_fishes == 0 then 
		player.print("You have no fish in your inventory.",{ r=0.98, g=0.66, b=0.22})
	else
		local x = i2.remove({name="raw-fish", count=1})
		if x == 0 then i2.remove({name="raw-fish", count=1}) end
		local enemy_team = "south"
		if player.force.name == "south" then enemy_team = "north" end													 
		if global.spy_fish_timeout[player.force.name] - game.tick > 0 then 
			global.spy_fish_timeout[player.force.name] = global.spy_fish_timeout[player.force.name] + duration_per_unit
			player.print(math.ceil((global.spy_fish_timeout[player.force.name] - game.tick) / 60) .. " seconds of enemy vision left.", { r=0.98, g=0.66, b=0.22})
		else			
			game.print(player.name .. " sent a fish to spy on " .. enemy_team .. " team!", {r=0.98, g=0.66, b=0.22})			
			global.spy_fish_timeout[player.force.name] = game.tick + duration_per_unit							
		end		
	end
end

function Public.create_map_intro_button(player)
	if player.gui.top["map_intro_button"] then return end
	local b = player.gui.top.add({type = "sprite-button", caption = "?", name = "map_intro_button", tooltip = "Map Info"})
	b.style.font_color = {r=0.5, g=0.3, b=0.99}
	b.style.font = "heading-1"
	b.style.minimal_height = 38
	b.style.minimal_width = 38
	b.style.top_padding = 1
	b.style.left_padding = 1
	b.style.right_padding = 1
	b.style.bottom_padding = 1
end

function Public.map_intro_click(player, element)
	if element.name == "close_map_intro_frame" then player.gui.center["map_intro_frame"].destroy() return true end	
	if element.name == "biter_battles_map_intro" then player.gui.center["map_intro_frame"].destroy() return true end	
	if element.name == "map_intro_button" then
		if player.gui.center["map_intro_frame"] then
			player.gui.center["map_intro_frame"].destroy()
			return true
		else
			if player.gui.center["map_intro_frame"] then player.gui.center["map_intro_frame"].destroy() end
			local frame = player.gui.center.add {type = "frame", name = "map_intro_frame", direction = "vertical"}
			local frame = frame.add {type = "frame"}
			local l = frame.add {type = "label", caption = {"biter_battles.map_info"}, name = "biter_battles_map_intro"}
			l.style.single_line = false
			l.style.font = "heading-2"
			l.style.font_color = {r=0.7, g=0.6, b=0.99}
			return true
		end
	end	
end

return Public