require "modules.custom_death_messages"
require "modules.flashlight_toggle_button"
require "modules.global_chat_toggle"
require "modules.worms_create_oil_patches"
require "modules.biters_yield_coins"
require "modules.scrap_towny_ffa.mining"
require "modules.scrap_towny_ffa.on_tick_schedule"
require "modules.scrap_towny_ffa.building"
require "modules.scrap_towny_ffa.town_center"
require "modules.scrap_towny_ffa.market"
require "modules.scrap_towny_ffa.slots"
require "modules.scrap_towny_ffa.wreckage_yields_scrap"
require "modules.scrap_towny_ffa.rocks_yield_ore_veins"
require "modules.scrap_towny_ffa.spawners_contain_biters"
require "modules.scrap_towny_ffa.explosives_are_explosive"
require "modules.scrap_towny_ffa.fluids_are_explosive"
require "modules.scrap_towny_ffa.trap"
require "modules.scrap_towny_ffa.turrets_drop_ammo"
require "modules.scrap_towny_ffa.combat_balance"

local Table = require "modules.scrap_towny_ffa.table"
local Nauvis = require "modules.scrap_towny_ffa.nauvis"
local Biters = require "modules.scrap_towny_ffa.biters"
local Pollution = require "modules.scrap_towny_ffa.pollution"
local Fish = require "modules.scrap_towny_ffa.fish_reproduction"
local Info = require "modules.scrap_towny_ffa.info"
local Team = require "modules.scrap_towny_ffa.team"
local Spawn = require "modules.scrap_towny_ffa.spawn"
local Radar = require "modules.scrap_towny_ffa.limited_radar"

local default_surface = "nauvis"

local function on_player_joined_game(event)
	local ffatable = Table.get_table()
	local player = game.players[event.player_index]
	local surface = game.surfaces[default_surface]

	player.game_view_settings.show_minimap = false
	player.game_view_settings.show_map_view_options = false
	player.game_view_settings.show_entity_info = true
	--player.game_view_settings.show_side_menu = false

	Info.toggle_button(player)
	Info.show(player)
	Team.set_player_color(player)
	if player.force ~= game.forces.player then return end

	-- setup outlanders
	Team.set_player_to_outlander(player)

	if player.online_time == 0 then
		player.teleport({ 0, 0 }, game.surfaces["limbo"])
		Team.give_outlander_items(player)
		Team.give_key(player)
		-- first time spawn point
		local spawn_point = Spawn.get_spawn_point(player, surface)
		Spawn.clear_spawn_point(spawn_point, surface)
		player.teleport(spawn_point, surface)
		return
	end

	if not ffatable.requests[player.index] then return end
	if ffatable.requests[player.index] ~= "kill-character" then return end
	if player.character then
		if player.character.valid then
			player.character.die()
		end
	end
	ffatable.requests[player.index] = nil
end

local function on_player_respawned(event)
	local ffatable = Table.get_table()
	local player = game.players[event.player_index]
	local surface = player.surface
	if player.force == game.forces["rogue"] then Team.set_player_to_outlander(player) end
	if player.force == game.forces["player"] then Team.give_key(player) end

	-- TODO: this needs fixing!
	-- 5 second cooldown
	--local last_respawn = ffatable.cooldowns_last_respawn[player.name]
	--if last_respawn == nil then last_respawn = 0 end
	local spawn_point = Spawn.get_spawn_point(player, surface)
	-- reset cooldown
	ffatable.cooldowns_last_respawn[player.name] = game.tick

	player.teleport(surface.find_non_colliding_position("character", spawn_point, 0, 0.5, false), surface)
end

local function on_player_died(event)
  local ffatable = Table.get_table()
	local player = game.players[event.player_index]
	ffatable.cooldowns_last_death[player.name] = game.tick
end

local function on_init()
  local ffatable = Table.get_table()
	--log("on_init")
	game.enemy_has_vision_on_land_mines = false
	game.draw_resource_selection = true
	game.disable_tutorial_triggers()

	ffatable.cooldowns_last_respawn = {}
	ffatable.cooldowns_last_death = {}

	Nauvis.initialize()
	Team.initialize()

end

local tick_actions = {
	[60 * 0] = Radar.reset,												-- each minute, at 00 seconds
	[60 * 5] = Team.update_town_chart_tags, 			-- each minute, at 05 seconds
	[60 * 10] = Team.set_all_player_colors, 			-- each minute, at 10 seconds
	[60 * 15] = Fish.reproduce, 									-- each minute, at 15 seconds
	[60 * 25] = Biters.unit_groups_start_moving, 	-- each minute, at 25 seconds
	[60 * 30] = Radar.reset,											-- each minute, at 30 seconds
	[60 * 45] = Biters.validate_swarms, 					-- each minute, at 45 seconds
	[60 * 50] = Biters.swarm, 										-- each minute, at 50 seconds
	[60 * 55] = Pollution.market_scent            -- each minute, at 55 seconds
}

local function on_nth_tick(event)
	-- run each second
	local tick = event.tick
	local seconds = tick % 3600    -- tick will recycle minute
	if not tick_actions[seconds] then return end
	tick_actions[seconds]()
end

local Event = require 'utils.event'

Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick)    -- once every second
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)


