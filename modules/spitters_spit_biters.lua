-- spitters spit biters, because why not -- by mewmew

local event = require 'utils.event'

local radius = 3
local max_biters_in_radius = 3

local biters = {
		["big-spitter"] = "small-biter",
		["behemoth-spitter"] = "medium-biter"		
	}

local function on_entity_damaged(event)
	if not event.cause then return end
	if not event.cause.valid then return end
	if not biters[event.cause.name] then return end
	local area = {{event.entity.position.x - radius, event.entity.position.y - radius}, {event.entity.position.x + radius, event.entity.position.y + radius}}	
	if event.cause.surface.count_entities_filtered({area = area, name = biters[event.cause.name], limit = 3}) >= max_biters_in_radius then return end				
	local pos = event.cause.surface.find_non_colliding_position(biters[event.cause.name], event.entity.position, radius, 0.5)
	if pos then event.cause.surface.create_entity({name = biters[event.cause.name], position = pos}) end			
end
	
event.add(defines.events.on_entity_damaged, on_entity_damaged)
