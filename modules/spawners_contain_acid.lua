local event = require 'utils.event'
local math_random = math.random
local radius = 16

local targets = {}
for x = radius * -1, radius, 1 do
	for y = radius * -1, radius, 1 do
		if math.sqrt(x^2 + y^2) <= radius then
			targets[#targets + 1] = {x = x, y = y}
		end
	end
end

local function on_entity_died(event)	
	if not event.entity.valid then return end
	if event.entity.type ~= "unit-spawner" then return end		
	for _ = 1, math.random(64, 128) do
		local i = math.random(1, #targets)		
		event.entity.surface.create_entity({	
			name = "acid-stream-worm-medium",
			position = event.entity.position,
			force = event.entity.force.name,
			source = event.entity.position,
			target = {x = event.entity.position.x + targets[i].x, y = event.entity.position.y + targets[i].y},
			max_range = radius, 
			speed = 0.001
		})
	end	
end
	
event.add(defines.events.on_entity_died, on_entity_died)
