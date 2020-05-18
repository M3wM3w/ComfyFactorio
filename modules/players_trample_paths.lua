-- players trample paths, tiles change as players walk around

local event = require 'utils.event'
local math_random = math.random

local blacklisted_tiles = {	
		["concrete"] = true,
		["deepwater"] = true,
		["deepwater-green"] = true,
		["dirt-1"] = true,
		["hazard-concrete-left"] = true,
		["hazard-concrete-right"] = true,
		["lab-dark-1"] = true,
		["lab-dark-2"] = true,
		["lab-white"] = true,
		["out-of-map"] = true,
		["refined-concrete"] = true,
		["refined-hazard-concrete-left"] = true,
		["refined-hazard-concrete-right"] = true,
		["stone-path"] = true,
		["tutorial-grid"] = true,
		["water"] = true,
		["water-green"] = true	
}

local replacement_tiles = {		
		["dirt-7"] = "dirt-6",
		["dirt-6"] = "dirt-5",
		["dirt-5"] = "dirt-4",
		["dirt-4"] = "dirt-3",
		["dirt-3"] = "dirt-2",
		["dirt-2"] = "dirt-1"		
	}
	
local function on_player_changed_position(event)
	if math_random(1, 2) ~= 1 then return end
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	
	local tile = player.surface.get_tile(player.position)
	if not tile then return end
	if not tile.valid then return end
	
	if blacklisted_tiles[tile.name] then return end
	
	local new_tile = "dirt-7"	
	if replacement_tiles[tile.name] then
		new_tile = replacement_tiles[tile.name]
	end		
	
	player.surface.set_tiles({{name = new_tile, position = tile.position}}, true)	
end
	
event.add(defines.events.on_player_changed_position, on_player_changed_position)
