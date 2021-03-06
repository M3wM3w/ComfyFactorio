local Public = {}

Public.mothership_teleporter_position = {x = 0, y = 12}

Public.mothership_radius = 28

Public.particle_spawn_vectors = {}
for x = Public.mothership_radius * -1 - 32, Public.mothership_radius + 32, 1 do
	for y = Public.mothership_radius * -1 - 32, Public.mothership_radius + 32, 1 do
		local position = {x = x, y = y}
		local distance = math.sqrt(position.x ^ 2 + position.y ^ 2)
		if distance > Public.mothership_radius then
			table.insert(Public.particle_spawn_vectors, {position.x, position.y})
		end		
	end
end
Public.size_of_particle_spawn_vectors = #Public.particle_spawn_vectors

Public.world_selector_width = 6
Public.world_selector_height = 8

local area = {
	left_top = {x = -3, y = math.floor(Public.mothership_radius * 0.5) * -1},
	right_bottom = {x = 3, y = math.floor(Public.mothership_radius * 0.5) * -1 + Public.world_selector_height},
}

Public.world_selector_areas = {
	[1] = {
		left_top = {x = area.left_top.x - 12, y = area.left_top.y},
		right_bottom = {x = area.left_top.x - 6, y = area.right_bottom.y},
	},
	[2] = area,
	[3] = {
		left_top = {x = area.right_bottom.x + 6, y = area.left_top.y},
		right_bottom = {x = area.right_bottom.x + 12, y = area.right_bottom.y},
	},
}

Public.world_selector_colors = {
	[1] = {r = 200, g = 200, b = 0, a = 255},
	[2] = {r = 150, g = 150, b = 255, a = 255},
	[3] = {r = 200, g = 100, b = 100, a = 255},
}

Public.mothership_messages = {
	waiting = {
		"Return to me, so we can continue the journey!",
		"Don't leave me waiting for so long. Let's continue our journey.",
		"Please return to me.",
		"Board me, so we can continue this adventure!",
	},
}

Public.mothership_gen_settings = {
	["water"] = 0,
	["starting_area"] = 1,
	["cliff_settings"] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
	["default_enable_all_autoplace_controls"] = false,
	["autoplace_settings"] = {
		["entity"] = {treat_missing_as_default = false},
		["tile"] = {treat_missing_as_default = false},
		["decorative"] = {treat_missing_as_default = false},
	},
	autoplace_controls = {
		["coal"] = {frequency = 0, size = 0, richness = 0},
		["stone"] = {frequency = 0, size = 0, richness = 0},
		["copper-ore"] = {frequency = 0, size = 0, richness = 0},
		["iron-ore"] = {frequency = 0, size = 0, richness = 0},
		["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
		["crude-oil"] = {frequency = 0, size = 0, richness = 0},
		["trees"] = {frequency = 0, size = 0, richness = 0},
		["enemy-base"] = {frequency = 0, size = 0, richness = 0}
	},
}

Public.modifiers = {	
	["cliff_settings"] = {20, 40, "Cliffs"},
	["enemy-base"] = {15, 25, "Nests"},
	["starting_area"] = {-25, -10, "Starting Area"},
	["water"] = {-30, -15, "Water"},
	["coal"] = {-20, -10, "Coal"},
	["stone"] = {-20, -10, "Stone"},
	["copper-ore"] = {-20, -10, "Copper Ore"},
	["iron-ore"] = {-20, -10, "Iron Ore"},
	["uranium-ore"] = {-20, -10, "Uranium Ore"},
	["crude-oil"] = {-20, -10, "Oil"},
	["trees"] = {-35, -15, "Trees"},
	["time_factor"] = {20, 40, "Evolution Time Factor"},
	["destroy_factor"] = {20, 40, "Evolution Destroy Factor"},
	["pollution_factor"] = {20, 40, "Evolution Pollution Factor"},
	["expansion_cooldown"] = {-30, -15, "Nest Expansion Cooldown"},
	["ageing"] = {-25, -10, "Terrain Pollution Consumption"},
	["enemy_attack_pollution_consumption_modifier"] = {-25, -10, "Nest Pollution Consumption"},
	["technology_price_multiplier"] = {5, 10, "Technology Price"},
}

Public.starter_goods_pool = {
	{"accumulator", 8, 16},
	{"big-electric-pole", 8, 16},	
	{"burner-inserter", 32, 64},
	{"burner-mining-drill", 8, 16},
	{"car", 2, 4},
	{"copper-cable", 128, 256},
	{"copper-plate", 64, 128},
	{"electric-furnace", 4, 8},
	{"electric-mining-drill", 4, 8},
	{"firearm-magazine", 64, 128},
	{"grenade", 8, 16},
	{"gun-turret", 4, 8},
	{"inserter", 32, 64},
	{"iron-gear-wheel", 64, 128},
	{"iron-plate", 64, 128},
	{"lab", 2, 4},
	{"long-handed-inserter", 32, 64},
	{"medium-electric-pole", 16, 32},
	{"pipe", 128, 256},
	{"radar", 4, 8},
	{"small-lamp", 64, 128},
	{"solar-panel", 8, 16},
	{"solid-fuel", 256, 512},
	{"stack-inserter", 8, 16},
	{"steam-turbine", 4, 8},
	{"steel-chest", 16, 32},
	{"steel-furnace", 8, 16},
	{"steel-plate", 32, 64},
	{"stone-wall", 128, 256},
	{"substation", 4, 8},
}

Public.build_type_whitelist = {
	["arithmetic-combinator"] = true,
	["constant-combinator"] = true,
	["decider-combinator"] = true,
	["electric-energy-interface"] = true,
	["electric-pole"] = true,
	["gate"] = true,
	["heat-pipe"] = true,
	["lamp"] = true,
	["pipe"] = true,
	["pipe-to-ground"] = true,
	["programmable-speaker"] = true,
	["transport-belt"] = true,	
	["wall"] = true,
}

return Public