local function deny_building(event)
	local entity = event.created_entity
	if not entity.valid then return end
	if entity.type ~= "solar-panel" then return end
	local surface = entity.surface
	local name = entity.name
	local position = {entity.position.x, entity.position.y}
	entity.destroy()
	surface.create_entity({name = "flying-text",	position = position, text = name .. " can not be placed.", color = {r=0.77, g=0.00, b=0.00}})
	surface.spill_item_stack(position,{name = name, count = 1}, true)
end

local function on_built_entity(event)
	deny_building(event)
end

local function on_robot_built_entity(event)
	deny_building(event)
end

local event = require 'utils.event'
event.add(defines.events.on_built_entity, on_built_entity)
event.add(defines.events.on_robot_built_entity, on_robot_built_entity)