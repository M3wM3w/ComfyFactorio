--biters may revive depending of global.biter_reanimator.forces["biter force index"]
--0 = no extra life
--0.25 = 25% chance for another life
--1.5 = 1 extra life + 50% chance of another life
--3 = 3 extra lifes

local math_random = math.random

local function register_unit(unit, extra_lifes, unit_group)
	if global.biter_reanimator.units[unit.unit_number] then return end
	global.biter_reanimator.units[unit.unit_number] = {extra_lifes, unit_group}
	--game.print("bitey number " .. unit.unit_number .. ", i have " .. extra_lifes .. " extra lives left!")
end

local function reanimate(entity)
	local extra_lifes = global.biter_reanimator.units[entity.unit_number][1]
	local unit_group = global.biter_reanimator.units[entity.unit_number][2]
	
	if extra_lifes <= 0 then
		global.biter_reanimator.units[entity.unit_number] = nil
		return 
	end
	
	if extra_lifes < 1 then
		if math_random(1, 10000) > extra_lifes * 10000 then			
			global.biter_reanimator.units[entity.unit_number] = nil
			return		
		end
	end

	local revived_entity = entity.clone({position = entity.position, surface = entity.surface, force = entity.force})	
	revived_entity.health = revived_entity.prototype.max_health
	register_unit(revived_entity, extra_lifes - 1, unit_group)
	
	if unit_group then
		if unit_group.valid then
			unit_group.add_member(revived_entity)
		end
	end
	
	global.biter_reanimator.units[entity.unit_number] = nil
	entity.destroy()
end

local function on_entity_died(event)	
	local entity = event.entity
	if not entity.valid then return end
	if entity.type ~= "unit" then return end
	local extra_lifes = 0
	if global.biter_reanimator.forces[entity.force.index] then
		extra_lifes = global.biter_reanimator.forces[entity.force.index]
	end
	register_unit(entity, extra_lifes, false)	
	reanimate(entity)
end

local function on_unit_added_to_group(event)
	local unit = event.unit
	local group = event.group
	local extra_lifes = global.biter_reanimator.forces[unit.force.index]
	if extra_lifes then
		register_unit(unit, extra_lifes, group)
	else
		register_unit(unit, 0, group)
	end	
end

local function on_init()
	global.biter_reanimator = {}
	global.biter_reanimator.forces = {}
	global.biter_reanimator.units = {}
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_unit_added_to_group, on_unit_added_to_group)