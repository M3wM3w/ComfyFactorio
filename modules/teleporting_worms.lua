-- worms will teleport to where they shoot -- by mewmew

local event = require 'utils.event'
local math_random = math.random

local function on_entity_damaged(event)	
	if not event.cause then return end
	local cause = event.cause
	if cause.type ~= "turret" then return end
	if cause.health <= 0 then return end
	local new_position = {
		x = (cause.position.x + event.entity.position.x) * 0.5,
		y = (cause.position.y + event.entity.position.y) * 0.5
		}
	new_position = {
		x = (cause.position.x + new_position.x) * 0.5,
		y = (cause.position.y + new_position.y) * 0.5
		}
	local new_turret = cause.surface.create_entity({name = cause.name, force = cause.force, position = new_position})
	cause.surface.create_entity({name = "blood-explosion-big", position = new_position})
	cause.surface.create_entity({name = "blood-explosion-big", position = cause.position})
	new_turret.health = cause.health
	cause.destroy()
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)