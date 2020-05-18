-- clear the player respawn from enemies with a kaboom --  by mewmew
local event = require 'utils.event'

local function damage_entities_in_radius(surface, position, radius)
	local entities_to_damage = surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})
	for _, entity in pairs(entities_to_damage) do
		if entity.health and entity.force.name == "enemy" then
			entity.surface.create_entity({name = "big-explosion", position = entity.position})
			entity.destroy()
		end
	end
end
	
local function on_player_respawned(event)
	local player = game.players[event.player_index]	
	player.surface.create_entity({name = "uranium-cannon-shell-explosion", position = player.position})
	damage_entities_in_radius(player.surface, player.position, 11)
end

event.add(defines.events.on_player_respawned, on_player_respawned)