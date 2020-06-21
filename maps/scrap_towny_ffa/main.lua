require "modules.custom_death_messages"
require "modules.flashlight_toggle_button"
require "modules.global_chat_toggle"
require "modules.biters_yield_coins"
require "modules.worms_create_oil_patches"
require "modules.no_arti_remote"
require "modules.scrap_towny_ffa.building"
require "modules.scrap_towny_ffa.town_center"
require "modules.scrap_towny_ffa.market"
require "modules.scrap_towny_ffa.slots"
require "modules.scrap_towny_ffa.rocks_yield_ore_veins"
require "modules.scrap_towny_ffa.spawners_contain_biters"
require "modules.scrap_towny_ffa.explosives_are_explosive"
require "modules.scrap_towny_ffa.fluids_are_explosive"
require "modules.scrap_towny_ffa.trap"
require "modules.scrap_towny_ffa.turrets_drop_ammo"
require "modules.scrap_towny_ffa.combat_balance"
require "utils.time"
local Nauvis = require "modules.scrap_towny_ffa.nauvis"
local Biters = require "modules.scrap_towny_ffa.biters"
local Pollution = require "modules.scrap_towny_ffa.pollution"
local Fish = require "modules.scrap_towny_ffa.fish_reproduction"
local Info = require "modules.scrap_towny_ffa.info"
local Team = require "modules.scrap_towny_ffa.team"
local Spawn = require "modules.scrap_towny_ffa.spawn"

local default_surface = "nauvis"

local function on_player_joined_game(event)
	local player = game.players[event.player_index]
	local surface = game.surfaces[default_surface]

	Info.toggle_button(player)
	Info.show(player)
	Team.set_player_color(player)
	if player.force ~= game.forces["player"] then return end

	-- setup outlanders
	Team.set_player_to_outlander(player)	
	
	if player.online_time == 0 then
		player.teleport({0,0}, game.surfaces["limbo"])
		Team.give_outlander_items(player)
		-- first time spawn point
		local spawn_point = Spawn.get_spawn_point(player, surface)
		Spawn.clear_spawn_point(spawn_point, surface)
		player.teleport(spawn_point, surface)
		return
	end
	
	if not global.towny.requests[player.index] then return end
	if global.towny.requests[player.index] ~= "kill-character" then return end	
	if player.character then
		if player.character.valid then
			player.character.die()
		end
	end
	global.towny.requests[player.index] = nil
end

local function on_player_respawned(event)
	local player = game.players[event.player_index]
	local surface = player.surface
	if player.force == game.forces["rogue"] then Team.set_player_to_outlander(player) end
	if player.force == game.forces["player"] then Team.give_outlander_plane(player) end

	local spawn_point = {}
	-- 5 second cooldown
	local last_respawn = global.towny.cooldowns.last_respawn[player.name]
	if last_respawn == nil then last_respawn = 0 end
	spawn_point = Spawn.get_spawn_point(player, surface)
	-- reset cooldown
	global.towny.cooldowns.last_respawn[player.name] = game.tick
	player.teleport(spawn_point, surface)
end

local function on_player_died(event)
	local player = game.players[event.player_index]
	global.towny.cooldowns.last_death[player.name] = game.tick
end

local function on_init()
	--log("on_init")
	global.towny = {}
	global.towny.cooldowns = {}
	global.towny.cooldowns.last_respawn = {}
	global.towny.cooldowns.last_death = {}
	global.towny.cooldowns.requests = {}
	global.towny.cooldowns.rogue = {}
	global.towny.cooldowns.town_placement = {}
	global.towny.requests = {}
	global.towny.size_of_town_centers = 0
	global.towny.spawn_point = {}
	global.towny.swarms = {}
	global.towny.town_centers = {}
	--global.towny.chunk_generated = {}

	Nauvis.initialize()
	Team.initialize()

end

local tick_actions = {
	[60 * 5] = Team.update_town_chart_tags,			-- each minute, at 05 seconds
	[60 * 10] = Team.set_all_player_colors,			-- each minute, at 10 seconds
	[60 * 15] = Fish.reproduce,						-- each minute, at 15 seconds
	[60 * 25] = Biters.unit_groups_start_moving,	-- each minute, at 25 seconds
	[60 * 45] = Biters.validate_swarms,				-- each minute, at 45 seconds
	[60 * 50] = Biters.swarm,						-- each minute, at 50 seconds
	[60 * 55] = Pollution.market_scent  			-- each minute, at 55 seconds
}

local function on_nth_tick(event)	-- run each second
	local tick = game.tick % 3600	-- tick will recycle minute
	if not tick_actions[tick] then return end
	tick_actions[tick]()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(60, on_nth_tick)	-- once every second
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)

