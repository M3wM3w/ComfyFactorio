-- Map by Kyte & MewMew

require "maps.wave_of_death.intro"
require "modules.biter_evasion_hp_increaser"
require "modules.custom_death_messages"
require "modules.dangerous_goods"

local event = require 'utils.event'
require 'utils.table'
local init = require "maps.wave_of_death.init"
local on_chunk_generated = require "maps.wave_of_death.terrain"
local ai = require "maps.wave_of_death.ai"
local game_status = require "maps.wave_of_death.game_status"

function soft_teleport(player, destination)
	local surface = game.surfaces["wave_of_death"]
	local pos = surface.find_non_colliding_position("character", destination, 8, 0.5)
	if not pos then player.teleport(destination, surface) end
	player.teleport(pos, surface)
end

local function spectate_button(player)
	if player.gui.top.spectate_button then return end
	local button = player.gui.top.add({type = "button", name = "spectate_button", caption = "Spectate"})
	button.style.font = "default-bold"
	button.style.font_color = {r = 0.0, g = 0.0, b = 0.0}
	button.style.minimal_height = 38
	button.style.minimal_width = 38
	button.style.top_padding = 2
	button.style.left_padding = 4
	button.style.right_padding = 4
	button.style.bottom_padding = 2
end

local function create_spectate_confirmation(player)
	if player.gui.center.spectate_confirmation_frame then return end
	local frame = player.gui.center.add({type = "frame", name = "spectate_confirmation_frame", caption = "Are you sure you want to spectate? This can not be undone."})
	frame.style.font = "default"
	frame.style.font_color = {r = 0.3, g = 0.65, b = 0.3}
	frame.add({type = "button", name = "confirm_spectate", caption = "Spectate"})
	frame.add({type = "button", name = "cancel_spectate", caption = "Cancel"})
end

local button_colors = {
	[1] = {r = 0.0, g = 0.0, b = 0.38},
	[2] = {r = 0.38, g = 0.0, b = 0.0},
	[3] = {r = 0.0, g = 0.38, b = 0.0},
	[4] = {r = 0.25, g = 0.0, b = 0.35}
}

function create_lane_buttons(player)
	for i = 1, 4, 1 do
		if player.gui.top["button_lane_" .. i] then player.gui.top["button_lane_" .. i].destroy() end
		local caption = "Wave #" .. global.wod_lane[i].current_wave - 1
		if global.wod_lane[i].game_lost == true then caption = "Out" end
		local button = player.gui.top.add({type = "button", name = "button_lane_" .. i, caption = caption, tooltip = "Lane " .. i .. " stats"})
		button.style.font = "default-bold"
		button.style.font_color = button_colors[i]
		button.style.minimal_height = 38
		button.style.minimal_width = 70
		button.style.top_padding = 2
		button.style.left_padding = 4
		button.style.right_padding = 4
		button.style.bottom_padding = 2
	end
end

local function create_lane_info_frame(player, lane_number)
	
end

local function autojoin_lane(player)
	local lowest_player_count = 256
	local lane_number
	local lane_numbers = {1,2,3,4}
	table.shuffle_table(lane_numbers)
		
	for _, number in pairs(lane_numbers) do
		if #game.forces[number].connected_players < lowest_player_count and global.wod_lane[number].game_lost == false then
			lowest_player_count = #game.forces[number].connected_players
			lane_number = number
		end
	end
	
	player.force = game.forces[lane_number]
	soft_teleport(player, game.forces[player.force.name].get_spawn_position(game.surfaces["wave_of_death"]))
	player.insert({name = "pistol", count = 1})
	player.insert({name = "firearm-magazine", count = 16})
	player.insert({name = "iron-plate", count = 128})
	player.insert({name = "iron-gear-wheel", count = 32})
end

local function on_player_joined_game(event)
	init()
		
	local player = game.players[event.player_index]
	spectate_button(player)
	create_lane_buttons(player)
	
	if global.lobby_active and #game.connected_players < 4 then
		if game.tick ~= 0 then soft_teleport(player, game.forces.player.get_spawn_position(game.surfaces["wave_of_death"])) end
		game.print("Waiting for " .. 4 - #game.connected_players .. " more players to join.", {r = 0, g = 170, b = 0}) 
		return
	end
	
	if global.lobby_active then		
		for _, p in pairs(game.connected_players) do
			autojoin_lane(p)
		end
		global.lobby_active = false
		return
	end
	
	if player.online_time == 0 then autojoin_lane(player) return end
	
	if global.wod_lane[tonumber(player.force.name)].game_lost == true then
		player.character.die()
	end
end

local function on_entity_damaged(event)
	ai.prevent_friendly_fire(event)
end

local function on_entity_died(event)
	if not event.entity.valid then return end
	ai.spawn_spread_wave(event)
	game_status.has_lane_lost(event)
end

local function on_player_rotated_entity(event)
	ai.trigger_new_wave(event)
end

local function on_tick(event)
	if game.tick % 300 ~= 0 then return end
	
	for i = 1, 4, 1 do
		game.forces[i].chart(game.surfaces["wave_of_death"], {{-288, -420}, {352, 64}})
	end
	
	game_status.restart_server()
	
	if game.tick == 300 then
		for _, p in pairs(game.connected_players) do
			soft_teleport(p, game.forces.player.get_spawn_position(game.surfaces["wave_of_death"]))
		end
	end
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "cancel_spectate" then player.gui.center["spectate_confirmation_frame"].destroy() return end
	if event.element.name == "confirm_spectate" then
		player.gui.center["spectate_confirmation_frame"].destroy()
		game.permissions.get_group("spectator").add_player(player)
		if player.force.name == "player" then return end
		player.force = game.forces.player
		if player.character then player.character.die() end
		return 
	end
	if event.element.name == "spectate_button" then
		if player.gui.center["spectate_confirmation_frame"] then
			player.gui.center["spectate_confirmation_frame"].destroy()
		else
			create_spectate_confirmation(player)
		end
		return
	end
end

--Flamethrower Turret Nerf
local function on_research_finished(event)
	local research = event.research
	local force_name = research.force.name
	if research.name == "flamethrower" then
		if not global.flamethrower_damage then global.flamethrower_damage = {} end
		global.flamethrower_damage[force_name] = -0.25
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])						
	end
	
	if string.sub(research.name, 0, 18) == "refined-flammables" then
		global.flamethrower_damage[force_name] = global.flamethrower_damage[force_name] + 0.05
		game.forces[force_name].set_turret_attack_modifier("flamethrower-turret", global.flamethrower_damage[force_name])								
		game.forces[force_name].set_ammo_damage_modifier("flamethrower", global.flamethrower_damage[force_name])
	end	
end

event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_tick, on_tick)
event.add(defines.events.on_chunk_generated, on_chunk_generated)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_entity_died, on_entity_died)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_rotated_entity, on_player_rotated_entity)
