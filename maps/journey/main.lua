--[[
Journey, launch a rocket in increasingly harder getting worlds. - MewMew

	
]]--

local Constants = require 'maps.journey.constants'
local Functions = require 'maps.journey.functions'
local Map = require 'modules.map_info'
local Global = require 'utils.global'

local journey = {}
Global.register(
    journey,
    function(tbl)
        journey = tbl
    end
)

local function on_chunk_generated(event)
	local surface = event.surface
	if surface.name ~= "mothership" then return end
	Functions.on_mothership_chunk_generated(event)
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
end

local function on_player_respawned(event)
	Functions.draw_gui(journey)
    local player = game.players[event.player_index]
end

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
	Functions.draw_gui(journey)
end

local function on_entity_died(event)
    local entity = event.entity
    if not entity.valid then return end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    Functions.teleporters(journey, player)
end

local function on_nth_tick()
	Functions[journey.game_state](journey)
	Functions.mothership_message_queue(journey)
end

local function on_init()
    local T = Map.Pop_info()
    T.main_caption = 'Journey'
    T.sub_caption = ''
    T.text =
        table.concat(
        {
            'Launch a stack of nuclear fuel to the mothership to advance to the next world.\n',
			'The tooltip on the top button will information about the current world.\n',
        }
    )
    T.main_caption_color = {r = 255, g = 125, b = 55}
    T.sub_caption_color = {r = 0, g = 250, b = 150}
	
	game.map_settings.enemy_evolution.time_factor = 0.000004
	game.map_settings.enemy_evolution.destroy_factor = 0.002
	game.map_settings.enemy_evolution.pollution_factor = 0.0000009
	
	Functions.reset(journey)
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(10, on_nth_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)