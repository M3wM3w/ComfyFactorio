local math_random = math.random
local math_min = math.min

local function on_entity_died(event)
	local entity = event.entity
	local surface = entity.surface
	if entity.type == "ammo-turret" and entity.force.name == "enemy" then
		local min = math_min(entity.get_item_count("piercing-rounds-magazine"), 20)
		if min > 0 then
			surface.spill_item_stack(entity.position, { name = "piercing-rounds-magazine", count = math_random(1, min) }, true)
		end
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_entity_died, on_entity_died)

