local Public = {}
local math_random = math.random

local function create_limbo()
	game.create_surface("limbo")
end

local function initialize_nauvis()
	local surface = game.surfaces["nauvis"]

	-- this overrides what is in the map_gen_settings.json file
	local mgs = surface.map_gen_settings
	mgs.default_enable_all_autoplace_controls = true    -- don't mess with this!
	mgs.autoplace_controls = {
		coal = { frequency = "none", size = 1, richness = "normal" },
		stone = { frequency = "none", size = 1, richness = "normal" },
		["copper-ore"] = { frequency = "none", size = 1, richness = "normal" },
		["iron-ore"] = { frequency = "none", size = 1, richness = "normal" },
		["uranium-ore"] = { frequency = "none", size = 1, richness = "normal" },
		["crude-oil"] = { frequency = "none", size = 1, richness = "normal" },
		trees = { frequency = 2, size = "normal", richness = "normal" },
		["enemy-base"] = { frequency = 8, size = 1, richness = "normal" }
	}
	mgs.autoplace_settings = {
		entity = {
			settings = {
				["rock-huge"] = { frequency = 3, size = 12, richness = "very-high" },
				["rock-big"] = { frequency = 3, size = 12, richness = "very-high" },
				["sand-rock-big"] = { frequency = 3, size = 12, richness = 1, "very-high" },
			}
		},
		decorative = {
			settings = {
				["rock-tiny"] = { frequency = 10, size = "normal", richness = "normal" },
				["rock-small"] = { frequency = 5, size = "normal", richness = "normal" },
				["rock-medium"] = { frequency = 2, size = "normal", richness = "normal" },
				["sand-rock-small"] = { frequency = 10, size = "normal", richness = "normal" },
				["sand-rock-medium"] = { frequency = 5, size = "normal", richness = "normal" }
			}
		}
	}
	mgs.cliff_settings = {
		name = "cliff",
		cliff_elevation_0 = 5,
		cliff_elevation_interval = 10,
		richness = 0.4
	}
	-- water = 0 means no water allowed
	-- water = 1 means elevation is not reduced when calculating water tiles (elevation < 0)
	-- water = 2 means elevation is reduced by 10 when calculating water tiles (elevation < 0)
	--			or rather, the water table is 10 above the normal elevation
	mgs.water = 0.5
	mgs.peaceful_mode = false
	mgs.starting_area = "none"
	mgs.terrain_segmentation = 8
	mgs.width = 2048
	mgs.height = 2048
	--mgs.starting_points = {
	--	{x = 0, y = 0}
	--}
	mgs.research_queue_from_the_start = "always"
	-- here we put the named noise expressions for the specific noise-layer if we want to override them
	mgs.property_expression_names = {
		-- here we are overriding the moisture noise-layer with a fixed value of 0 to keep moisture consistently dry across the map
		-- it allows to free up the moisture noise expression
		-- low moisture
		--moisture = 0,

		-- here we are overriding the aux noise-layer with a fixed value to keep aux consistent across the map
		-- it allows to free up the aux  noise expression
		-- aux should be not sand, nor red sand
		--aux = 0.5,

		-- here we are overriding the temperature noise-layer with a fixed value to keep temperature consistent across the map
		-- it allows to free up the temperature noise expression
		-- temperature should be 20C or 68F
		--temperature = 20,

		-- here we are overriding the cliffiness noise-layer with a fixed value of 0 to disable cliffs
		-- it allows to free up the cliffiness noise expression (which may or may not be useful)
		-- disable cliffs
		--cliffiness = 0,

		-- we can disable starting lakes two ways, one by setting starting-lake-noise-amplitude = 0
		-- or by making the elevation a very large number
		-- make sure starting lake amplitude is 0 to disable starting lakes
		["starting-lake-noise-amplitude"] = 0,

		-- allow enemies to get up close on spawn
		["starting-area"] = 0,

		-- this accepts a string representing a named noise expression
		-- or number to determine the elevation based on x, y and distance from starting points
		-- we can not add a named noise expression at this point, we can only reference existing ones
		-- if we have any custom noise expressions defined from a mod, we will be able to use them here
		-- setting it to a fixed number would mean a flat map
		-- elevation < 0 means there is water unless the water table has been changed
		--elevation = -1,
		--elevation = 0,
		--elevation-persistence = 0,

		-- testing
		--["control-setting:moisture:bias"] = 0.5,
		--["control-setting:moisture:frequency:multiplier"] = 0,
		--["control-setting:aux:bias"] = 0.5,
		--["control-setting:aux:frequency:multiplier"] = 1,
		--["control-setting:temperature:bias"] = 0.01,
		--["control-setting:temperature:frequency:multiplier"] = 100,

		--["tile:water:probability"] = -1000,
		--["tile:deep-water:probability"] = -1000,

		-- a constant intensity means base distribution will be consistent with regard to distance
		["enemy-base-intensity"] = 1,

		-- adjust this value to set how many nests spawn per tile
		["enemy-base-frequency"] = 0.2,

		-- this will make and average base radius around 12 tiles
		["enemy-base-radius"] = 12
	}
	mgs.seed = math_random(10000, 99999)
	surface.map_gen_settings = mgs
	surface.peaceful_mode = false
	surface.always_day = false
	surface.freeze_daytime = false
	surface.clear(true)
	surface.regenerate_entity({ "rock-huge", "rock-big", "sand-rock-big" })
	surface.regenerate_decorative()
end

function Public.initialize()
	-- difficulty settings
	game.difficulty_settings.recipe_difficulty = defines.difficulty_settings.recipe_difficulty.normal
	game.difficulty_settings.technology_difficulty = defines.difficulty_settings.technology_difficulty.normal
	game.difficulty_settings.technology_price_multiplier = 0.50

	-- pollution settings
	game.map_settings.pollution.enabled = true
	game.map_settings.pollution.diffusion_ratio = 0.02    -- amount that is diffused to neighboring chunk each second
	game.map_settings.pollution.min_to_diffuse = 15    -- minimum number of pollution units on the chunk to start diffusing
	game.map_settings.pollution.ageing = 1    -- percent of pollution eaten by a chunk's tiles per second
	game.map_settings.pollution.expected_max_per_chunk = 150    -- anything greater than this number of pollution units is visualized similarly
	game.map_settings.pollution.min_to_show_per_chunk = 50
	game.map_settings.pollution.min_pollution_to_damage_trees = 60
	game.map_settings.pollution.pollution_with_max_forest_damage = 150
	game.map_settings.pollution.pollution_per_tree_damage = 50
	game.map_settings.pollution.pollution_restored_per_tree_damage = 10
	game.map_settings.pollution.max_pollution_to_restore_trees = 20
	game.map_settings.pollution.enemy_attack_pollution_consumption_modifier = 1

	-- enemy evolution settings
	game.map_settings.enemy_evolution.enabled = true
	game.map_settings.enemy_evolution.time_factor = 0.0    -- percent increase in the evolution factor per second
	game.map_settings.enemy_evolution.destroy_factor = 0.0    -- percent increase in the evolution factor for each spawner destroyed
	game.map_settings.enemy_evolution.pollution_factor = 0.0    -- percent increase in the evolution factor for each pollution unit

	-- enemy expansion settings
	game.map_settings.enemy_expansion.enabled = true
	game.map_settings.enemy_expansion.max_expansion_distance = 7    -- maximum distance in chunks from the nearest base (4 = 128 tiles)
	game.map_settings.enemy_expansion.friendly_base_influence_radius = 4    -- consider other nests within radius number of chunks (2 = 64 tiles)
	game.map_settings.enemy_expansion.other_base_coefficient = 2.0    -- multiply by coefficient for friendly bases
	game.map_settings.enemy_expansion.neighbouring_base_chunk_coefficient = 0.4    -- multiply by coefficient for friendly bases (^distance)
	game.map_settings.enemy_expansion.enemy_building_influence_radius = 4    -- consider player buildings within radius number of chunks
	game.map_settings.enemy_expansion.building_coefficient = 1.0    -- multiply by coefficient for player buildings
	game.map_settings.enemy_expansion.neighbouring_chunk_coefficient = 0.5    -- multiply by coefficient for player buildings (^distance)
	game.map_settings.enemy_expansion.max_colliding_tiles_coefficient = 0.9    -- percent of unbuildable tiles to not be considered a candidate
	game.map_settings.enemy_expansion.settler_group_min_size = 4    -- min size of group for building a base (multiplied by evo factor, so need evo > 0)
	game.map_settings.enemy_expansion.settler_group_max_size = 12    -- max size of group for building a base (multiplied by evo factor, so need evo > 0)
	game.map_settings.enemy_expansion.min_expansion_cooldown = 1200    -- minimum time before next expansion
	game.map_settings.enemy_expansion.max_expansion_cooldown = 3600    -- maximum time before next expansion

	-- unit group settings
	game.map_settings.unit_group.min_group_gathering_time = 600
	game.map_settings.unit_group.max_group_gathering_time = 3600
	game.map_settings.unit_group.max_wait_time_for_late_members = 3600
	game.map_settings.unit_group.max_group_radius = 30.0
	game.map_settings.unit_group.min_group_radius = 5.0
	game.map_settings.unit_group.max_member_speedup_when_behind = 1.4
	game.map_settings.unit_group.max_member_slowdown_when_ahead = 0.6
	game.map_settings.unit_group.max_group_slowdown_factor = 0.3
	game.map_settings.unit_group.max_group_member_fallback_factor = 3
	game.map_settings.unit_group.member_disown_distance = 10
	game.map_settings.unit_group.tick_tolerance_when_member_arrives = 60
	game.map_settings.unit_group.max_gathering_unit_groups = 30
	game.map_settings.unit_group.max_unit_group_size = 200

	---- steering settings
	--game.map_settings.steering.default.radius = 1.2
	--game.map_settings.steering.default.separation_force = 0.005
	--game.map_settings.steering.default.separation_factor = 1.2
	--game.map_settings.steering.default.force_unit_fuzzy_goto_behavior = false
	--game.map_settings.steering.moving.radius = 3
	--game.map_settings.steering.moving.separation_force = 0.01
	--game.map_settings.steering.moving.separation_factor = 3
	--game.map_settings.steering.moving.force_unit_fuzzy_goto_behavior = false

	create_limbo()
	initialize_nauvis()

end

return Public
