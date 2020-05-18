-- spawners release biters on death -- by mewmew

local event = require 'utils.event'
local math_random = math.random

local biter_building_inhabitants = {
	[1] = {{"small-biter",8,16}},
	[2] = {{"small-biter",12,24}},
	[3] = {{"small-biter",8,16},{"medium-biter",1,2}},
	[4] = {{"small-biter",4,8},{"medium-biter",4,8}},
	[5] = {{"small-biter",3,5},{"medium-biter",8,12}},
	[6] = {{"small-biter",3,5},{"medium-biter",5,7},{"big-biter",1,2}},
	[7] = {{"medium-biter",6,8},{"big-biter",3,5}},
	[8] = {{"medium-biter",2,4},{"big-biter",6,8}},
	[9] = {{"medium-biter",2,3},{"big-biter",7,9}},
	[10] = {{"big-biter",4,8},{"behemoth-biter",3,4}}
}

local function on_entity_died(event)	
	if not event.entity.valid then return end
	if event.entity.type ~= "unit-spawner" then return end
	local e = math.ceil(event.entity.force.evolution_factor * 10)
	if e < 1 then e = 1 end
	for _, t in pairs(biter_building_inhabitants[e]) do		
		for x = 1, math_random(t[2],t[3]), 1 do
			local p = event.entity.surface.find_non_colliding_position(t[1] , event.entity.position, 6, 1)			
			if p then event.entity.surface.create_entity {name=t[1], position=p, force = event.entity.force.name} end
		end
	end	
end
	
event.add(defines.events.on_entity_died, on_entity_died)
