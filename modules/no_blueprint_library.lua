local event = require 'utils.event' 

local function on_player_joined_game(event)
	game.permissions.get_group("Default").set_allows_action(defines.input_action.grab_blueprint_record, false)
	game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint_string, false)
	game.permissions.get_group("Default").set_allows_action(defines.input_action.import_blueprint, false)	
end
	
event.add(defines.events.on_player_joined_game, on_player_joined_game)