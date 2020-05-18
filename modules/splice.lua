-- biter splicing -- global.splice_modifier can be increased for increased difficulty -- by mewmew

local event = require 'utils.event'

local biter_fragmentation = {
		["medium-biter"] = {"small-biter", 1},
		["big-biter"] = {"medium-biter", 1},
		["behemoth-biter"] = {"big-biter", 1}
	}

local function on_entity_died(event)	
	if not event.entity.valid then return end
	if biter_fragmentation[event.entity.name] then
		local entity = event.entity
		local amount = 1
		if global.splice_modifier then amount = math.ceil(global.splice_modifier * biter_fragmentation[entity.name][2]) end
		if amount < 1 then return end
		for x = 1, amount, 1 do
			local p = entity.surface.find_non_colliding_position(biter_fragmentation[entity.name][1] , entity.position, 3, 0.5)
			if p then entity.surface.create_entity({name = biter_fragmentation[entity.name][1], position = p}) end
		end		
	end
end
	
event.add(defines.events.on_entity_died, on_entity_died)
