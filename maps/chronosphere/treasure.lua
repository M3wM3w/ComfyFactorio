local Chrono_table = require 'maps.chronosphere.table'
local Rand = require 'maps.chronosphere.random'
local Balance = require 'maps.chronosphere.balance'
local math_random = math.random
local math_abs = math.abs
local math_max = math.max
local math_min = math.min

local Public = {}

function Public.treasure_chest(surface, position, container_name)
	local objective = Chrono_table.get_table()

	local chest_raffle = {}
	
  local jumps = 0
  if objective.chronojumps then jumps = objective.chronojumps end
	local distance_to_center =  (jumps / 40)
	if distance_to_center > 1 then distance_to_center = 1 end

	local loot_data = Balance.treasure_chest_loot()
	local loot_types, loot_weights = {}, {}
	for i = 1,#loot_data,1 do
		table.insert(loot_types, loot_data[i].loot)

		if loot_data[i].scaling then -- scale down weights away from the midpoint 'peak' (without changing the mean)
			local midpoint = (loot_data[i].d_min + loot_data[i].d_max)
			local difference = (loot_data[i].d_max - loot_data[i].d_min)
			table.insert(loot_weights,2 * loot_data[i].weight * math_max(0, 1 - math_abs(distance_to_center - midpoint) / difference))
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
	for _ = 1, math_random(2,6), 1 do
		local loot = Rand.raffle(loot_types,loot_weights)
		i.insert(loot)
	end
end

return Public.treasure_chest
