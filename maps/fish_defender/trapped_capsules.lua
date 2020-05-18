local event = require 'utils.event'

local radius = 20

local whitelist = {
	["defender"] = "explosive-cannon-projectile",
	["distractor"] = "explosive-uranium-cannon-projectile",
	["destroyer"] = "explosive-uranium-cannon-projectile"
}

local function on_entity_died(event)
	if not global.trapped_capsules_unlocked then return end
	
	if not event.entity.valid then return end
	if not whitelist[event.entity.name] then return end
	
	local valid_targets = {}
	local position = event.entity.position
	
	for _, e in pairs(event.entity.surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}, force = "enemy"})) do
		if e.health then
			local distance_from_center = math.sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
			if distance_from_center <= radius then
				valid_targets[#valid_targets + 1] = e 
			end
		end
	end
	
	if not valid_targets[1] then return end
	
	event.entity.surface.create_entity({	
		name = whitelist[event.entity.name],
		position = position,
		force = "player",
		source = position,
		target = valid_targets[math.random(1, #valid_targets)].position,
		max_range = 20, 
		speed = 0.1
	})
end

event.add(defines.events.on_entity_died, on_entity_died)


