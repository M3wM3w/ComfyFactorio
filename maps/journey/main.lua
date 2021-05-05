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

local function on_player_joined_game(event)
    local player = game.players[event.player_index]
	Functions.draw_gui(journey)
	
	if player.surface.name == "mothership" then
		journey.characters_in_mothership = journey.characters_in_mothership + 1
	end
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
	Functions.draw_gui(journey)
	
	if player.surface.name == "mothership" then
		journey.characters_in_mothership = journey.characters_in_mothership - 1
	end
end

local function on_player_changed_position(event)
    local player = game.players[event.player_index]
    Functions.teleporters(journey, player)
end

local function on_built_entity(event)
    Functions.deny_building(event)
end

local function on_robot_built_entity(event)
    Functions.deny_building(event)
end

local function on_rocket_launched(event)
	local rocket_inventory = event.rocket.get_inventory(defines.inventory.rocket)
	local slot = rocket_inventory[1]
	if slot and slot.valid and slot.valid_for_read then
		if journey.mothership_cargo[slot.name] then
			journey.mothership_cargo[slot.name] = journey.mothership_cargo[slot.name] + slot.count
		else
			journey.mothership_cargo[slot.name] = slot.count
		end
	end
end

local function on_nth_tick()
	Functions[journey.game_state](journey)
	Functions.mothership_message_queue(journey)
end

local function on_init()
    local T = Map.Pop_info()
    T.main_caption = 'Journey'
    T.sub_caption = 'v 1.0'
    T.text =
        table.concat(
        {	
			'The selectors in the mothership, allow you to select a destination.\n',
			'Once enough players are on a selector, mothership will start traveling.\n',
			'Worlds will get more difficult with each jump, stacking the chosen modifiers.\n',
            'Launch a stack of nuclear fuel cells via rocket cargo, to advance to the next world.\n',
			'The tooltip on the top button has information about the current world.\n',
			'If the journey ends, an admin can fully reset the map via command "/reset-journey".\n\n',
			
			
			'How far will this journey lead?\n\n',
        }
    )
    T.main_caption_color = {r = 100, g = 20, b = 255}
    T.sub_caption_color = {r = 100, g = 100, b = 100}
	Functions.hard_reset(journey)
end

commands.add_command(
    'reset-journey',
    'Fully resets the journey map.',
    function()
		local player = game.player
        if not (player and player.valid) then
            return
        end 
        if not player.admin then
            player.print("You are not an admin!")
            return
        end
		Functions.hard_reset(journey)
		game.print(player.name .. " has reset the map.")
	end
)

local Event = require 'utils.event'
Event.on_init(on_init)
Event.on_nth_tick(10, on_nth_tick)
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_left_game, on_player_left_game)
Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_robot_built_entity, on_robot_built_entity)
Event.add(defines.events.on_built_entity, on_built_entity)