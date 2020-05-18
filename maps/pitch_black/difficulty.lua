local Public = {}

local math_abs = math.abs

local score_values = {
	["small-spitter"] = 1,
	["small-biter"] = 1,
	["medium-spitter"] = 3,
	["medium-biter"] = 3,
	["big-spitter"] = 5,
	["big-biter"] = 5,
	["behemoth-spitter"] = 10,
	["behemoth-biter"] = 10,
	["small-worm-turret"] = 4,
	["medium-worm-turret"] = 6,
	["big-worm-turret"] = 8,
	["behemoth-worm-turret"] = 10,
	["biter-spawner"] = 16,
	["spitter-spawner"] = 16
}

function Public.set_daytime_difficulty(surface, tick)
	local daytime = surface.daytime
	if daytime < 0.30 then
		surface.peaceful_mode = true
	else
		surface.peaceful_mode = false
	end
end

function Public.set_biter_difficulty()
	local daytime = global.daytime
	
	local daytime_extra_life_modifier = (-0.30 + daytime) * 2
	if daytime_extra_life_modifier < 0 then daytime_extra_life_modifier = 0 end
	
	local extra_lifes = global.map_score * 0.0001 * daytime + daytime_extra_life_modifier
	global.biter_reanimator.forces[2] = extra_lifes
end

function Public.add_score(entity)
	local value = score_values[entity.name]
	if not value then return end
	global.map_score = global.map_score + value
end

function Public.fleeing_biteys(entity, cause)
	local surface = entity.surface
	if not surface.peaceful_mode then return end
	
	if not cause then return end
	if not cause.valid then return end	
	if entity.type ~= "unit" then return end
	
	local unit_groups = {}
	local position = entity.position
	local units = surface.find_entities_filtered({type = "unit", force = "enemy", area = {{position.x - 16, position.y - 16}, {position.x + 16, position.y + 16}}})
	
	for _, unit in pairs(units) do
		local unit_group = unit.unit_group
		if unit_group then
			if unit_group.valid then
				if not unit_groups[unit_group.group_number] then
					unit_groups[unit_group.group_number] = unit_group
				end				
			end
		else
			unit.set_command({
				type = defines.command.flee,
				from = cause,
				distraction = defines.distraction.none
			})	
		end
	end
	
	for _, group in pairs(unit_groups) do
		group.set_command({
			type = defines.command.flee,
			from = cause,
			distraction = defines.distraction.none
		})
	end
end

return Public