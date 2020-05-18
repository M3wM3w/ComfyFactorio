----------share chat with spectator force-------------------
local function on_console_chat(event)
	if not event.message then return end	
	if not event.player_index then return end	
	local player = game.players[event.player_index] 
	
	local color = {}
	color = player.color
	color.r = color.r * 0.6 + 0.35
	color.g = color.g * 0.6 + 0.35
	color.b = color.b * 0.6 + 0.35
	color.a = 1	
	
	if player.force.name == "west" then
		game.forces.spectator.print(player.name .. " (west): ".. event.message, color)		
	end
	if player.force.name == "east" then
		game.forces.spectator.print(player.name .. " (east): ".. event.message, color)
	end
	if player.force.name == "spectator" then
		game.forces.west.print(player.name .. " (spectator): ".. event.message, color)
		game.forces.east.print(player.name .. " (spectator): ".. event.message, color)
	end
end

local event = require 'utils.event' 
event.add(defines.events.on_console_chat, on_console_chat)