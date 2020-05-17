local Global = require 'utils.global'
local Event = require 'utils.event'

local offline_characters = {}
Global.register(
    offline_characters,
    function(tbl)
        offline_characters = tbl
    end
)

local function on_player_joined_game(event)
	local player = game.players[event.player_index]	
	if not offline_characters[player.index] then return end
	
	local offline_character = offline_characters[player.index]
	if not offline_character or not offline_character.valid then
		offline_characters[player.index] = nil 
		if not player.character or player.character.valid then
			player.set_controller({type = defines.controllers.god})
			player.create_character()
		end
		return 
	end
	
	local c = player.character
	if c and c.valid then	
		player.character = nil
		c.destroy()
	end
	
	player.associate_character(offline_character)
	player.set_controller({type = defines.controllers.character, character = offline_character})
	offline_characters[player.index] = nil
end

local function on_pre_player_left_game(event)
	local player = game.players[event.player_index]
	local character = player.character
	if not character or not character.valid then return end
	player.set_controller({type = defines.controllers.god})
	character.driving = false
	character.associated_player = nil
	character.color = {125, 125, 125}
	offline_characters[player.index] = character			
end

Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)