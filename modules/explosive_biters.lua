-- biters explode --  by mewmew

local event = require 'utils.event'

local biter_values = {
		["medium-biter"] = {"blood-explosion-big", 20, 1.5},
		["big-biter"] = {"blood-explosion-huge", 40, 2},
		["behemoth-biter"] = {"blood-explosion-huge", 60, 2.5}
	}

local function damage_entities_in_radius(surface, position, radius, damage)
	local entities_to_damage = surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})
	for _, entity in pairs(entities_to_damage) do
		if entity.health and entity.name ~= "land-mine" then
			if entity.force.name ~= "enemy" then
				if entity.name == "character" then
					entity.damage(damage, "enemy")
				else
					entity.health = entity.health - damage					
					if entity.health <= 0 then entity.die("enemy") end
				end
			end
		end
	end
end
	
local function on_entity_died(event)
	if not event.entity.valid then return end
	if biter_values[event.entity.name] then
		local entity = event.entity
		entity.surface.create_entity({name = biter_values[entity.name][1], position = entity.position})
		damage_entities_in_radius(
			entity.surface,
			entity.position,
			biter_values[entity.name][3],
			math.random(math.ceil(biter_values[entity.name][2] * 0.75), math.ceil(biter_values[entity.name][2] * 1.25))
		)		
	end
end
	
event.add(defines.events.on_entity_died, on_entity_died)
