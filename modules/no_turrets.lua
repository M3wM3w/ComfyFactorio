local turret_types = {
	["ammo-turret"] = true,
	["artillery-turret"] = true,
	["electric-turret"] = true,
	["fluid-turret"] = true,
}

local function destroy_turret(entity)
	if not entity.valid then return end
	if not turret_types[entity.type] then return end
	entity.die()
end

local function on_built_entity(event)
	destroy_turret(event.created_entity)
end

local function on_robot_built_entity(event)
	destroy_turret(event.created_entity)
end

local event = require 'utils.event'
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)