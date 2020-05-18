local event = require 'utils.event'
local math_random = math.random

local function on_player_changed_position(event)
	if not global.flame_boots then return end
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving then return end
	
	if not global.flame_boots[player.index] then global.flame_boots[player.index] = {} end
	
	if not global.flame_boots[player.index].fuel then return end	
	
	if global.flame_boots[player.index].fuel < 0 then
		player.print("Your flame boots have worn out.", {r = 0.22, g = 0.77, b = 0.44})
		global.flame_boots[player.index] = {}
		return 
	end
	
	if global.flame_boots[player.index].fuel % 500 == 0 then player.print("Fuel remaining: " .. global.flame_boots[player.index].fuel, {r = 0.22, g = 0.77, b = 0.44}) end
	
	if not global.flame_boots[player.index].step_history then global.flame_boots[player.index].step_history = {} end
	
	local elements = #global.flame_boots[player.index].step_history
	
	global.flame_boots[player.index].step_history[elements + 1] = {x = player.position.x, y = player.position.y}
	
	if elements < 50 then return end
	
	player.surface.create_entity({name = "fire-flame", position = global.flame_boots[player.index].step_history[elements - 2]})
	
	global.flame_boots[player.index].fuel = global.flame_boots[player.index].fuel - 1
end

local function on_init()
	if not global.flame_boots then global.flame_boots = {} end	
end

event.on_init(on_init)
event.add(defines.events.on_player_changed_position, on_player_changed_position)
