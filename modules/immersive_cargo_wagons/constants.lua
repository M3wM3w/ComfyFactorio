local Public = {}

Public.wagon_types = {
	["cargo-wagon"] = true,
	["artillery-wagon"] = true,
	["fluid-wagon"] = true,
	["locomotive"] = true,
}

Public.wagon_areas = {
	["cargo-wagon"] = {left_top = {x = -11, y = 0}, right_bottom = {x = 11, y = 40}},
	["artillery-wagon"] = {left_top = {x = -11, y = 0}, right_bottom = {x = 11, y = 40}},
	["fluid-wagon"] = {left_top = {x = -11, y = 0}, right_bottom = {x = 11, y = 40}},
	["locomotive"] = {left_top = {x = -11, y = 0}, right_bottom = {x = 11, y = 40}},
}

return Public