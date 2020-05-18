-- forest circle --  MewMew

local function init_surface()	
	local map = {
		["seed"] = math.random(1, 1000000),
		["water"] = 0,
		["starting_area"] = 1,
		["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
		["autoplace_settings"] = {
			["entity"] = {treat_missing_as_default = false},
			["tile"] = {treat_missing_as_default = false},
			["decorative"] = {treat_missing_as_default = false},
		},
		["default_enable_all_autoplace_controls"] = false,
	}
	game.create_surface("forest_circle", map)
			
	game.map_settings.enemy_evolution.time_factor = 0
	game.map_settings.enemy_evolution.destroy_factor = 0
	game.map_settings.enemy_evolution.pollution_factor = 0
	game.map_settings.pollution.enabled = false
	
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.settler_group_min_size = 8
	game.map_settings.enemy_expansion.settler_group_max_size = 16
	game.map_settings.enemy_expansion.min_expansion_cooldown = 54000
	game.map_settings.enemy_expansion.max_expansion_cooldown = 108000
end

local function on_player_joined_game(event)	
	local surface = game.surfaces["forest_circle"]
	local player = game.players[event.player_index]	
	
	if player.gui.left["map_pregen"] then player.gui.left["map_pregen"].destroy() end
	
	if player.online_time == 0 then
		if surface.is_chunk_generated({0,0}) then
			player.teleport(surface.find_non_colliding_position("character", {0,0}, 3, 0.5), surface)
		else
			player.teleport({0,0}, surface)
		end
		player.character.destructible = false
		game.permissions.get_group("spectator").add_player(player)
	end
end

local circles = {
	[1] = "tree-01",
	[2] = "small-worm-turret",
	[3] = "biter-spawner",
	[4] = "tree-04",
	[5] = "tree-05",
	[6] = "tree-06",
}

local function process_position(surface, p)
	local distance_to_center = math.sqrt(p.x^2 + p.y^2)	
	local index = math.floor((distance_to_center / 16) % 18) + 1
	--if index == 7 then surface.create_entity({name = "rock-big", position = p}) return end
	if index % 2 == 1 then
		if math.random(1, 3) == 1 then
			surface.create_entity({name = "rock-big", position = p})
		else
			surface.create_entity({name = "tree-0" .. math.ceil(index * 0.5), position = p})
		end
		return		
	end
end

local function on_chunk_generated(event)
	local left_top = event.area.left_top
	local surface = event.surface
	
	for x = 0.5, 31.5, 1 do
		for y = 0.5, 31.5, 1 do
			p = {x = left_top.x + x, y = left_top.y + y}
			process_position(surface, p)
					
		end
	end
end

local function on_init(surface)
	init_surface()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)