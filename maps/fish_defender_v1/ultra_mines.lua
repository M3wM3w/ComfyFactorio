local event = require 'utils.event'
local radius = 8

local function damage_entities_around_target(entity, damage)
	for _, e in pairs(entity.surface.find_entities_filtered({area = {{entity.position.x - radius, entity.position.y - radius},{entity.position.x + radius, entity.position.y + radius}}})) do		
		if e.health then
			if e.force.name ~= "player" then
				local distance_from_center = math.sqrt((e.position.x - entity.position.x) ^ 2 + (e.position.y - entity.position.y) ^ 2)
				if distance_from_center <= radius then
					e.damage(damage, "player", "explosion")
				end
			end
		end
	end
end

local function on_entity_died(event)
	if not global.ultra_mines_unlocked then return end
	if not event.entity.valid then return end
	if event.entity.name ~= "land-mine" then return end
	
	event.entity.surface.create_entity({	
		name = "big-artillery-explosion",
		position = event.entity.position
	})
	
	local damage = (1 + event.entity.force.get_ammo_damage_modifier("grenade")) * 250
	
	damage_entities_around_target(event.entity, damage)
end

event.add(defines.events.on_entity_died, on_entity_died)


