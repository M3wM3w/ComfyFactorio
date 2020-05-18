local event = require 'utils.event' 

local function on_player_joined_game(event)
	game.forces["player"].technologies["logistic-system"].enabled = false
	game.forces["player"].technologies["construction-robotics"].enabled = false
	game.forces["player"].technologies["logistic-robotics"].enabled = false
	game.forces["player"].technologies["robotics"].enabled = false
	game.forces["player"].technologies["personal-roboport-equipment"].enabled = false
	game.forces["player"].technologies["personal-roboport-mk2-equipment"].enabled = false
	game.forces["player"].technologies["character-logistic-trash-slots-1"].enabled = false
	game.forces["player"].technologies["character-logistic-trash-slots-2"].enabled = false
	game.forces["player"].technologies["auto-character-logistic-trash-slots"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-1"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-2"].enabled = false
	game.forces["player"].technologies["worker-robots-storage-3"].enabled = false	
	game.forces["player"].technologies["character-logistic-slots-1"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-2"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-3"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-4"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-5"].enabled = false
	game.forces["player"].technologies["character-logistic-slots-6"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-1"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-2"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-3"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-4"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-5"].enabled = false
	game.forces["player"].technologies["worker-robots-speed-6"].enabled = false
end
	
event.add(defines.events.on_player_joined_game, on_player_joined_game)