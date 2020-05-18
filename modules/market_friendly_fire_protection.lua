local event = require 'utils.event'

local function on_entity_damaged(event)
	if event.entity.name ~= "market" then return false end
	if event.cause then
		if event.cause.force.name == "enemy" then return false end
	end
	event.entity.health = event.entity.health + event.final_damage_amount
	return true
end
	
event.add(defines.events.on_entity_damaged, on_entity_damaged)