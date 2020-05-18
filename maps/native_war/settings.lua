local Public = {}
Public.wave_price = {
	["automation-science-pack"] ={price = 100},
	["logistic-science-pack"] ={price = 60},
	["military-science-pack"] ={price = 100},
	["chemical-science-pack"] ={price = 100},
	["production-science-pack"] ={price = 100},
	["utility-science-pack"] ={price = 80},
}
Public.upgrade_turret_price = {
	["automation-science-pack"] ={price = 200},
	["logistic-science-pack"] ={price = 120},
	["military-science-pack"] ={price = 200},
	["chemical-science-pack"] ={price = 200},
	["production-science-pack"] ={price = 200},
	["utility-science-pack"] ={price = 160},
}
Public.nb_of_waves = {1,5,10}
Public.science_pack = {
	["automation-science-pack"] = {short = "red"},
	["logistic-science-pack"] =   {short = "green"},
	["military-science-pack"] =   {short = "grey"},
	["chemical-science-pack"] =   {short = "blue"},
	["production-science-pack"] = {short = "purple"},
	["utility-science-pack"] =    {short = "yellow"},
}
Public.color = {
	["automation-science-pack"] =	{r=255, g=50, b=50},
	["logistic-science-pack"] =   {r=50, g=255, b=50},
	["military-science-pack"] =		{r=105, g=105, b=105},
	["chemical-science-pack"] = 	{r=100, g=200, b=255},
	["production-science-pack"] =	{r=150, g=25, b=255},
	["utility-science-pack"] =		{r=210, g=210, b=60},
	["space-science-pack"] = 			{r=255, g=255, b=255},
	["message"] = 								{r = 0.98, g = 0.66, b = 0.22},

}
Public.worm_dist = {"Closest","Farthest","All"}
Public.button_upgrade_name={
	["red_Closest"] = {sp = "automation-science-pack", spc = "red", dist = "Closest", type_worm = "small"},
	["green_Closest"] = {sp = "logistic-science-pack", spc = "green", dist = "Closest", type_worm = "small"},
	["grey_Closest"] = {sp = "military-science-pack", spc = "grey", dist = "Closest", type_worm = "medium"},
	["blue_Closest"] = {sp = "chemical-science-pack", spc = "blue", dist = "Closest", type_worm = "big"},
	["purple_Closest"] = {sp = "production-science-pack", spc = "purple", dist = "Closest", type_worm = "behemoth"},
	["yellow_Closest"] = {sp = "utility-science-pack", spc = "yellow", dist = "Closest", type_worm = "behemoth"},
	["red_Farthest"] = {sp = "automation-science-pack", spc = "red", dist = "Farthest", type_worm = "small"},
	["green_Farthest"] = {sp = "logistic-science-pack", spc = "green", dist = "Furthest", type_worm = "small"},
	["grey_Farthest"] = {sp = "military-science-pack", spc = "grey", dist = "Farthest", type_worm = "medium"},
	["blue_Farthest"] = {sp = "chemical-science-pack", spc = "blue", dist = "Furthest", type_worm = "big"},
	["purple_Farthest"] = {sp = "production-science-pack", spc = "purple", dist = "Farthest", type_worm = "behemoth"},
	["yellow_Farthest"] = {sp = "utility-science-pack", spc = "yellow", dist = "Furthest", type_worm = "behemoth"},
	["red_All"] = {sp = "automation-science-pack", spc = "red", dist = "All", type_worm = "small"},
	["green_All"] = {sp = "logistic-science-pack", spc = "green", dist = "All", type_worm = "small"},
	["grey_All"] = {sp = "military-science-pack", spc = "grey", dist = "All", type_worm = "medium"},
	["blue_All"] = {sp = "chemical-science-pack", spc = "blue", dist = "All", type_worm = "big"},
	["purple_All"] = {sp = "production-science-pack", spc = "purple", dist = "All", type_worm = "behemoth"},
	["yellow_All"] = {sp = "utility-science-pack", spc = "yellow", dist = "All", type_worm = "behemoth"},
}
Public.science_pack_name = {"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack", "production-science-pack", "utility-science-pack"}
return Public
