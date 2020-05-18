-- nighttime is dangerous, stay near your lamps -- by mewmew

local event = require 'utils.event' 

local unearthing_worm = require "functions.unearthing_worm"
local unearthing_biters = require "functions.unearthing_biters"

local immune_tiles = {
	["concrete"] = true,
	["hazard-concrete-left"] = true,
	["hazard-concrete-right"] = true,
	["refined-concrete"] = true,
	["refined-hazard-concrete-left"] = true,
	["refined-hazard-concrete-right"] = true,
	["stone-path"] = true
}

local function on_player_changed_position(event)
	local player = game.players[event.player_index]
	if not player.character then return end
	if player.character.driving == true then return end
	if player.surface.daytime < 0.33 then return end
	if player.surface.daytime > 0.66 then return end
	if math.random(1,32) ~= 1 then return end
	
	for _, lamp in pairs(player.surface.find_entities_filtered({area={{player.position.x - 18, player.position.y - 18},{player.position.x + 18, player.position.y + 18}}, name="small-lamp"})) do
		local circuit = lamp.get_or_create_control_behavior()
		if circuit then
			if lamp.energy > 25 and circuit.disabled == false then								
				return
			end
		else
			if lamp.energy > 25 then								
				return
			end
		end
	end
	
	local positions = {}
	local r = 8
	for x = r * -1, r, 1 do
		for y = r * -1, r, 1 do
			local distance = x^2 + y^2
			if distance > 4 and distance < 49 then
				if player.surface.can_place_entity({name = "stone-furnace", position = {x = player.position.x + x, y = player.position.y + y}}) then
					if not immune_tiles[player.surface.get_tile({x = player.position.x + x, y = player.position.y + y}).name] then
						positions[#positions + 1] = {x = player.position.x + x, y = player.position.y + y}
					end
				end
			end
		end
	end
	
	if #positions == 0 then return end
	
	if math.random(1,3) == 1 then
		unearthing_biters(player.surface, positions[math.random(1, #positions)], math.random(3,9))
	else
		unearthing_worm(player.surface, positions[math.random(1, #positions)])
	end
end

event.add(defines.events.on_player_changed_position, on_player_changed_position)
