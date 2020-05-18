local event = require 'utils.event'
local radius = 32

local function on_player_used_capsule(event)
	if not global.laser_pointer_unlocked then return end
	
	local player = game.players[event.player_index]
	local position = event.position
	local used_item = event.item			
	if used_item.name ~= "artillery-targeting-remote" then return end

	for _, unit in pairs(player.surface.find_enemy_units(position, radius, "player")) do
		if math.random(1,2) == 1 then
			unit.set_command({
				type = defines.command.go_to_location,
				destination = position,
				radius = 2,
				distraction = defines.distraction.none,
				pathfind_flags = {
					allow_destroy_friendly_entities = false,
					prefer_straight_paths = false,
					low_priority = false
				}	
			})
		end
	end
end

event.add(defines.events.on_player_used_capsule, on_player_used_capsule)


