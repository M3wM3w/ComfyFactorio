local Public = {}

Public.food_values = {
	["automation-science-pack"] =	{value = 0.001, name = "automation science", color = "255, 50, 50"},
	["logistic-science-pack"] =		{value = 0.00263, name = "logistic science", color = "50, 255, 50"},
	["military-science-pack"] =		{value = 0.00788, name = "military science", color = "105, 105, 105"},
	["chemical-science-pack"] = 		{value = 0.02121, name = "chemical science", color = "100, 200, 255"},
	["production-science-pack"] =	{value = 0.1008, name = "production science", color = "150, 25, 255"},
	["utility-science-pack"] =			{value = 0.1099, name = "utility science", color = "210, 210, 60"},
	["space-science-pack"] = 			{value = 0.4910, name = "space science", color = "255, 255, 255"},
}

Public.gui_foods = {}
for k, v in pairs(Public.food_values) do
	Public.gui_foods[k] = math.floor(v.value * 10000) .. " Mutagen strength"
end
Public.gui_foods["raw-fish"] = "Send spy"

Public.force_translation = {
	["south_biters"] = "south",
	["north_biters"] = "north"
}

Public.enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

Public.wait_messages = {
	"please get comfy.",
	"get comfy!!",
	"go and grab a drink.",
	"take a short healthy break.",
	"go and stretch your legs.",
	"please pet the cat.",
	"time to get a bowl of snacks :3",
}

Public.food_names = {
	["automation-science-pack"] = true,
	["logistic-science-pack"] = true,
	["military-science-pack"] = true,
	["chemical-science-pack"] = true,
	["production-science-pack"] = true,
	["utility-science-pack"] = true,
	["space-science-pack"] = true
}

Public.food_long_and_short = {
	[1] = {short_name= "automation", long_name = "automation-science-pack"},
	[2] = {short_name= "logistic", long_name = "logistic-science-pack"},
	[3] = {short_name= "military", long_name = "military-science-pack"},
	[4] = {short_name= "chemical", long_name = "chemical-science-pack"},
	[5] = {short_name= "production", long_name = "production-science-pack"},
	[6] = {short_name= "utility", long_name = "utility-science-pack"},
	[7] = {short_name= "space", long_name = "space-science-pack"}
}

Public.food_long_to_short = {
	["automation-science-pack"] = {short_name= "automation", indexScience = 1},
	["logistic-science-pack"] = {short_name= "logistic", indexScience = 2},
	["military-science-pack"] = {short_name= "military", indexScience = 3},
	["chemical-science-pack"] = {short_name= "chemical", indexScience = 4},
	["production-science-pack"] = {short_name= "production", indexScience = 5},
	["utility-science-pack"] = {short_name= "utility", indexScience = 6},
	["space-science-pack"] = {short_name= "space", indexScience = 7}
}
Public.forces_list = { "all teams", "north", "south" }
Public.science_list = { "all science", "very high tier (space, utility, production)", "high tier (space, utility, production, chemical)", "mid+ tier (space, utility, production, chemical, military)","space","utility","production","chemical","military", "logistic", "automation" }
Public.evofilter_list = { "all evo jump", "no 0 evo jump", "10+ only","5+ only","4+ only","3+ only","2+ only","1+ only" }
Public.food_value_table_version = { Public.food_values["automation-science-pack"].value, Public.food_values["logistic-science-pack"].value, Public.food_values["military-science-pack"].value, Public.food_values["chemical-science-pack"].value, Public.food_values["production-science-pack"].value, Public.food_values["utility-science-pack"].value, Public.food_values["space-science-pack"].value}

return Public