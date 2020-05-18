local raffle = {
	["automation-science-pack"] =	{{}, 1},
	["logistic-science-pack"] = {{}, 2},
	["military-science-pack"] = {{}, 3},	
	["chemical-science-pack"] = {{}, 4},
	["production-science-pack"] = {{}, 5},
	["utility-science-pack"] = {{}, 5},	
	["space-science-pack"] = {{}, 9},
}

local function add_unit(t, size, chance)
	for _ = 1, chance, 1 do table.insert(t, size .. "-spitter") end
	for _ = 1, chance * 6, 1 do table.insert(t, size .. "-biter") end
end

local t = raffle["automation-science-pack"][1]
add_unit(t, "small", 1)

local t = raffle["logistic-science-pack"][1]
add_unit(t, "small", 5)
add_unit(t, "medium", 1)

local t = raffle["military-science-pack"][1]
add_unit(t, "small", 10)
add_unit(t, "medium", 3)
add_unit(t, "big", 1)

local t = raffle["chemical-science-pack"][1]
add_unit(t, "small", 1)
add_unit(t, "medium", 9)
add_unit(t, "big", 2)

local t = raffle["production-science-pack"][1]
add_unit(t, "medium", 1)
add_unit(t, "big", 12)
add_unit(t, "behemoth", 2)

local t = raffle["utility-science-pack"][1]
add_unit(t, "big", 5)
add_unit(t, "behemoth", 1)

local t = raffle["space-science-pack"][1]
add_unit(t, "big", 1)
add_unit(t, "behemoth", 3)

return raffle