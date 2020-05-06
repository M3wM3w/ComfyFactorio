local Chrono_table = require 'maps.chronosphere.table'
local Rand = require 'maps.chronosphere.random'
local Balance = require 'maps.chronosphere.balance'
local math_random = math.random
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local math_ceil = math.ceil

local Public = {}

function Public.treasure_chest(surface, position, container_name)
	local objective = Chrono_table.get_table()

  	local jumps = 0
	if objective.chronojumps then jumps = objective.chronojumps end
	local difficulty = 1
	if global.difficulty_vote_value then difficulty = global.difficulty_vote_value end
	if jumps == 0 then difficulty = 1 end --Always treat the first level as normal difficulty

	local chest_raffle = {}

	local distance_to_center = (jumps / 40)
	if distance_to_center > 1 then distance_to_center = 1 end

	local loot_data = Balance.treasure_chest_loot(difficulty, objective.planet[1])
	local loot_types, loot_weights = {}, {}
	for i = 1,#loot_data,1 do
		table.insert(loot_types, {["name"] = loot_data[i].name, ["min_count"] = loot_data[i].min_count, ["max_count"] = loot_data[i].max_count})

		if loot_data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
			local midpoint = (loot_data[i].d_max + loot_data[i].d_min) / 2
			local difference = (loot_data[i].d_max - loot_data[i].d_min)
			table.insert(loot_weights,loot_data[i].weight * math_max(0, 1 - (math_abs(distance_to_center - midpoint) / (difference / 2))))
		else -- no scaling
			if loot_data[i].d_min <= distance_to_center and loot_data[i].d_max >= distance_to_center then
				table.insert(loot_weights, loot_data[i].weight)
			else
				table.insert(loot_weights, 0)
			end
		end
	end

	local e = surface.create_entity({name = container_name, position=position, force="neutral", create_build_effect_smoke = false})
	e.minable = false
	local i = e.get_inventory(defines.inventory.chest)
	for _ = 1, math_random(2,5), 1 do -- 20/04/04: max 5 items better than 6, so that if you observe 4 items in alt-mode the chance of an extra one is 1/2 rather than 2/3
		local loot = Rand.raffle(loot_types,loot_weights)
		log(loot.name)
		log(loot.min_count)
		log(loot.max_count)
		local difficulty_scaling = Balance.treasure_quantity_difficulty_scaling(difficulty)
		if objective.chronojumps == 0 then difficulty_scaling = 1 end
		local low = math_max(1, math_ceil(loot.min_count * difficulty_scaling))
		local high = math_max(1, math_ceil(loot.max_count * difficulty_scaling))
		local _count = math_random(low, high)
		i.insert({name = loot.name, count = _count})
	end
end

return Public.treasure_chest
