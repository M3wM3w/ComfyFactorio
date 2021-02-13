local Public = {}
local math_floor = math.floor

local Table = require 'modules.scrap_towny_ffa.table'

local biters = {
	[1] = "small-biter",
	[2] = "medium-biter",
	[3] = "big-biter",
	[4] = "behemoth-biter"
}

local spitters = {
	[1] = "small-spitter",
	[2] = "medium-spitter",
	[3] = "big-spitter",
	[4] = "behemoth-spitter"
}

local worms = {
	[1] = "small-worm-turret",
	[2] = "medium-worm-turret",
	[3] = "big-worm-turret",
	[4] = "behemoth-worm-turret"
}

-- evolution max distance in tiles
local max_evolution_distance = 1024
local max_pollution_behemoth = 256
local max_pollution_big = 64
local max_pollution_medium = 16
local max_factor = 0.8

-- technology weights (biter, spitter, worm)
local technology_weights = {
	['advanced-electronics'] = { biter = 1, spitter = 1, worm = 1 },
	['advanced-electronics-2'] = { biter = 1, spitter = 1, worm = 1 },
	['advanced-material-processing'] = { biter = 1, spitter = 1, worm = 1 },
	['advanced-material-processing-2'] = { biter = 1, spitter = 1, worm = 1 },
	['advanced-oil-processing'] = { biter = 1, spitter = 1, worm = 1 },
	['artillery']={biter=1, spitter=1, worm=1},
	['artillery-shell-range-1']={biter=1, spitter=1, worm=1},
	['artillery-shell-speed-1']={biter=1, spitter=1, worm=1},
	['atomic-bomb']={biter=1, spitter=1, worm=1},
	['automated-rail-transportation'] = { biter = 1, spitter = 1, worm = 1 },
	['automation'] = { biter = 1, spitter = 1, worm = 1 },
	['automation-2'] = { biter = 1, spitter = 1, worm = 1 },
	['automation-3'] = { biter = 1, spitter = 1, worm = 1 },
	['automobilism'] = { biter = 1, spitter = 1, worm = 1 },
	['battery'] = { biter = 1, spitter = 1, worm = 1 },
	['battery-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['battery-mk2-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['belt-immunity-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-1'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-2'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-3'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-4'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-5'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-6'] = { biter = 1, spitter = 1, worm = 1 },
	['braking-force-7'] = { biter = 1, spitter = 1, worm = 1 },
	['chemical-science-pack'] = { biter = 125, spitter = 125, worm = 125 },
	['circuit-network'] = { biter = 1, spitter = 1, worm = 1 },
	['cliff-explosives'] = { biter = 1, spitter = 1, worm = 1 },
	['coal-liquefaction'] = { biter = 1, spitter = 1, worm = 1 },
	['concrete'] = { biter = 1, spitter = 1, worm = 1 },
	['construction-robotics'] = { biter = 1, spitter = 1, worm = 1 },
	['defender'] = { biter = 1, spitter = 1, worm = 1 },
	['destroyer'] = { biter = 1, spitter = 1, worm = 1 },
	['discharge-defense-equipment'] = { biter = 5, spitter = 5, worm = 5 },
	['distractor'] = { biter = 1, spitter = 1, worm = 1 },
	['effect-transmission'] = { biter = 1, spitter = 1, worm = 1 },
	['effectivity-module'] = { biter = 1, spitter = 1, worm = 1 },
	['effectivity-module-2'] = { biter = 1, spitter = 1, worm = 1 },
	['effectivity-module-3'] = { biter = 1, spitter = 1, worm = 1 },
	['electric-energy-accumulators'] = { biter = 1, spitter = 1, worm = 1 },
	['electric-energy-distribution-1'] = { biter = 1, spitter = 1, worm = 1 },
	['electric-energy-distribution-2'] = { biter = 1, spitter = 1, worm = 1 },
	['electric-engine'] = { biter = 1, spitter = 1, worm = 1 },
	['electronics'] = { biter = 1, spitter = 1, worm = 1 },
	['energy-shield-equipment'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-shield-mk2-equipment'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-1'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-2'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-3'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-4'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-5'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-6'] = { biter = 5, spitter = 5, worm = 5 },
	['energy-weapons-damage-7'] = { biter = 5, spitter = 5, worm = 5 },
	['engine'] = { biter = 1, spitter = 1, worm = 1 },
	['exoskeleton-equipment'] = { biter = 5, spitter = 5, worm = 5 },
	['explosive-rocketry']={biter=1, spitter=1, worm=1},
	['explosives'] = { biter = 5, spitter = 5, worm = 5 },
	['fast-inserter'] = { biter = 1, spitter = 1, worm = 1 },
	['flamethrower'] = { biter = 5, spitter = 5, worm = 5 },
	['flammables'] = { biter = 1, spitter = 1, worm = 1 },
	['fluid-handling'] = { biter = 1, spitter = 1, worm = 1 },
	['fluid-wagon'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-1'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-2'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-3'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-4'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-5'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-6'] = { biter = 1, spitter = 1, worm = 1 },
	['follower-robot-count-7'] = { biter = 1, spitter = 1, worm = 1 },
	['fusion-reactor-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['gate'] = { biter = 1, spitter = 1, worm = 1 },
	['gun-turret'] = { biter = 1, spitter = 1, worm = 1 },
	['heavy-armor'] = { biter = 5, spitter = 5, worm = 5 },
	['improved-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['inserter-capacity-bonus-1'] = { biter = 1, spitter = 1, worm = 1 },
	['inserter-capacity-bonus-3'] = { biter = 1, spitter = 1, worm = 1 },
	['inserter-capacity-bonus-4'] = { biter = 1, spitter = 1, worm = 1 },
	['inserter-capacity-bonus-5'] = { biter = 1, spitter = 1, worm = 1 },
	['inserter-capacity-bonus-6'] = { biter = 1, spitter = 1, worm = 1 },
	['inserter-capacity-bonus-7'] = { biter = 1, spitter = 1, worm = 1 },
	['kovarex-enrichment-process'] = { biter = 1, spitter = 1, worm = 1 },
	['land-mine'] = { biter = 5, spitter = 5, worm = 5 },
	['landfill'] = { biter = 1, spitter = 1, worm = 1 },
	['laser'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-1'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-2'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-3'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-4'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-5'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-6'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret-speed-7'] = { biter = 5, spitter = 5, worm = 5 },
	['laser-turret'] = { biter = 5, spitter = 5, worm = 5 },
	['logistic-robotics'] = { biter = 1, spitter = 1, worm = 1 },
	['logistic-science-pack'] = { biter = 25, spitter = 25, worm = 25 },
	['logistic-system'] = { biter = 1, spitter = 1, worm = 1 },
	['logistics'] = { biter = 1, spitter = 1, worm = 1 },
	['logistics-2'] = { biter = 1, spitter = 1, worm = 1 },
	['logistics-3'] = { biter = 1, spitter = 1, worm = 1 },
	['low-density-structure'] = { biter = 1, spitter = 1, worm = 1 },
	['lubricant'] = { biter = 1, spitter = 1, worm = 1 },
	['military'] = { biter = 5, spitter = 5, worm = 5 },
	['military-2'] = { biter = 5, spitter = 5, worm = 5 },
	['military-3'] = { biter = 5, spitter = 5, worm = 51 },
	['military-4'] = { biter = 5, spitter = 5, worm = 5 },
	['military-science-pack'] = { biter = 50, spitter = 50, worm = 50 },
	['mining-productivity-1'] = { biter = 1, spitter = 1, worm = 1 },
	['mining-productivity-2'] = { biter = 1, spitter = 1, worm = 1 },
	['mining-productivity-3'] = { biter = 1, spitter = 1, worm = 1 },
	['mining-productivity-4'] = { biter = 1, spitter = 1, worm = 1 },
	['modular-armor'] = { biter = 1, spitter = 1, worm = 1 },
	['modules'] = { biter = 1, spitter = 1, worm = 1 },
	['night-vision-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['nuclear-fuel-reprocessing'] = { biter = 1, spitter = 1, worm = 1 },
	['nuclear-power'] = { biter = 1, spitter = 1, worm = 1 },
	['oil-processing'] = { biter = 1, spitter = 1, worm = 1 },
	['optics'] = { biter = 1, spitter = 1, worm = 1 },
	['personal-laser-defense-equipment'] = { biter = 5, spitter = 5, worm = 5 },
	['personal-roboport-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['personal-roboport-mk2-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['physical-projectile-damage-1'] = { biter = 5, spitter = 5, worm = 5 },
	['physical-projectile-damage-2'] = { biter = 5, spitter = 5, worm = 5 },
	['physical-projectile-damage-3'] = { biter = 5, spitter = 5, worm = 5 },
	['physical-projectile-damage-4'] = { biter = 5, spitter = 5, worm = 5 },
	['physical-projectile-damage-5'] = { biter = 5, spitter = 5, worm = 5 },
	['physical-projectile-damage-6'] = { biter = 5, spitter = 5, worm = 5 },
	['physical-projectile-damage-7'] = { biter = 5, spitter = 5, worm = 5 },
	['plastics'] = { biter = 1, spitter = 1, worm = 1 },
	['power-armor'] = { biter = 5, spitter = 5, worm = 5 },
	['power-armor-mk2'] = { biter = 5, spitter = 5, worm = 5 },
	['production-science-pack'] = { biter = 250, spitter = 250, worm = 250 },
	['productivity-module'] = { biter = 1, spitter = 1, worm = 1 },
	['productivity-module-2'] = { biter = 1, spitter = 1, worm = 1 },
	['productivity-module-3'] = { biter = 1, spitter = 1, worm = 1 },
	['rail-signals'] = { biter = 1, spitter = 1, worm = 1 },
	['railway'] = { biter = 1, spitter = 1, worm = 1 },
	['refined-flammables-1'] = { biter = 5, spitter = 5, worm = 5 },
	['refined-flammables-2'] = { biter = 5, spitter = 5, worm = 51 },
	['refined-flammables-3'] = { biter = 5, spitter = 5, worm = 5 },
	['refined-flammables-4'] = { biter = 5, spitter = 5, worm = 5 },
	['refined-flammables-5'] = { biter = 5, spitter = 5, worm = 5 },
	['refined-flammables-6'] = { biter = 5, spitter = 5, worm = 5 },
	['refined-flammables-7'] = { biter = 5, spitter = 5, worm = 51 },
	['research-speed-1'] = { biter = 1, spitter = 1, worm = 1 },
	['research-speed-2'] = { biter = 1, spitter = 1, worm = 1 },
	['research-speed-3'] = { biter = 1, spitter = 1, worm = 1 },
	['research-speed-4'] = { biter = 1, spitter = 1, worm = 1 },
	['research-speed-5'] = { biter = 1, spitter = 1, worm = 1 },
	['research-speed-6'] = { biter = 1, spitter = 1, worm = 1 },
	['robotics'] = { biter = 1, spitter = 1, worm = 1 },
	['rocket-control-unit'] = { biter = 1, spitter = 1, worm = 1 },
	['rocket-fuel'] = { biter = 1, spitter = 1, worm = 1 },
	['rocket-silo'] = { biter = 1, spitter = 1, worm = 1 },
	['rocketry']={biter=1, spitter=1, worm=1},
	['solar-energy'] = { biter = 1, spitter = 1, worm = 1 },
	['solar-panel-equipment'] = { biter = 1, spitter = 1, worm = 1 },
	['space-science-pack'] = { biter = 1000, spitter = 1000, worm = 1000 },
	['speed-module'] = { biter = 1, spitter = 1, worm = 1 },
	['speed-module-2'] = { biter = 1, spitter = 1, worm = 1 },
	['speed-module-3'] = { biter = 1, spitter = 1, worm = 1 },
	['spidertron'] = { biter = 1, spitter = 1, worm = 1 },
	['stack-inserter'] = { biter = 1, spitter = 1, worm = 1 },
	['steel-axe'] = { biter = 1, spitter = 1, worm = 1 },
	['steel-processing'] = { biter = 1, spitter = 1, worm = 1 },
	['stone-wall'] = { biter = 1, spitter = 1, worm = 1 },
	['stronger-explosives-1'] = { biter = 5, spitter = 5, worm = 5 },
	['stronger-explosives-2'] = { biter = 5, spitter = 5, worm = 5 },
	['stronger-explosives-3'] = { biter = 5, spitter = 5, worm = 5 },
	['stronger-explosives-4'] = { biter = 5, spitter = 5, worm = 5 },
	['stronger-explosives-5'] = { biter = 5, spitter = 5, worm = 5 },
	['stronger-explosives-6'] = { biter = 5, spitter = 5, worm = 5 },
	['stronger-explosives-7'] = { biter = 5, spitter = 5, worm = 51 },
	['sulfur-processing'] = { biter = 1, spitter = 1, worm = 1 },
	['tank'] = { biter = 1, spitter = 1, worm = 1 },
	['toolbelt'] = { biter = 1, spitter = 1, worm = 1 },
	['uranium-ammo'] = { biter = 1, spitter = 1, worm = 1 },
	['uranium-processing'] = { biter = 1, spitter = 1, worm = 1 },
	['utility-science-pack'] = { biter = 500, spitter = 500, worm = 500 },
	['weapon-shooting-speed-1'] = { biter = 5, spitter = 5, worm = 5 },
	['weapon-shooting-speed-2'] = { biter = 5, spitter = 5, worm = 5 },
	['weapon-shooting-speed-3'] = { biter = 5, spitter = 5, worm = 5 },
	['weapon-shooting-speed-4'] = { biter = 5, spitter = 5, worm = 5 },
	['weapon-shooting-speed-5'] = { biter = 5, spitter = 5, worm = 5 },
	['weapon-shooting-speed-6'] = { biter = 5, spitter = 5, worm = 5 },
	['worker-robots-speed-1'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-speed-2'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-speed-3'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-speed-4'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-speed-5'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-speed-6'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-storage-1'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-storage-2'] = { biter = 1, spitter = 1, worm = 1 },
	['worker-robots-storage-3'] = { biter = 1, spitter = 1, worm = 1 },
}

local max_biter_weight = 0
local max_spitter_weight = 0
local max_worm_weight = 0
for _, weight in pairs(technology_weights) do
	max_biter_weight = max_biter_weight + weight.biter
	max_spitter_weight = max_spitter_weight + weight.spitter
	max_worm_weight = max_worm_weight + weight.worm
end
max_biter_weight = max_biter_weight * max_factor
max_spitter_weight = max_spitter_weight * max_factor
max_worm_weight = max_worm_weight * max_factor

local function get_unit_size(evolution)
	-- returns a value 0-3 that represents the unit size

	-- basically evo values of:  0%,    10%,    30%,    60%,    80%,    100%
	-- small unit chances are    100%,  100%,   50%,    25%,    12.5%,  0%
	-- medium unit chances are   0%,    0%,     50%,    25%,    12.5%,  0%
	-- big unit chances are      0%,    0%,     0%,     50%,    25%,    0%
	-- behemoth unit chances are 0%,    0%,     0%,     0%,     50%,    100%
	-- and curve accordingly in between evo values

	-- magic stuff happens here
	if (evolution < 0.10) then return 1 end
	if (evolution >= 0.10 and evolution < 0.40) then
		local r = (evolution - 0.10) * 5
		if math.random() < 0.5 then return 1 end
		if math.random() < r then return 1 end
		return 2
	end
	if (evolution >= 0.30 and evolution < 0.60) then
		local r = (evolution - 0.30) * 3.3333
		if math.random() < 0.5 then
			if math.random() < 0.5 then
				return 1
			else
				if math.random() < r then return 1 else return 2 end
			end
		else
			if math.random() < r then return 2 else return 3 end
		end
	end
	if (evolution >= 0.60 and evolution < 0.80) then
		local r = (evolution - 0.60) * 5
		if math.random() < 0.5 then
			if math.random() < 0.5 then
				if math.random() < r then return 1 else return 2 end
			else
				if math.random() < r then return 2 else return 3 end
			end
		else
			if math.random() < r then return 3 else return 4 end
		end
	end
	if (evolution >= 0.80 and evolution < 1.0) then
		local r = (evolution - 0.80) * 5
		if math.random() < 0.5 then
			if math.random() < r then
				if math.random() < r then
					return 1
				else return 2 end
			else return 3 end
		else return 4 end
	end
	if (evolution >= 1.0) then return 4 end
end

local function distance_squared(pos1, pos2)
	-- calculate the distance squared
	local dx = pos1.x - pos2.x
	local dy = pos1.y - pos2.y
	local d2 = dx * dx + dy * dy
	return d2
end

local function get_relative_biter_evolution(position)
	local ffatable = Table.get_table()
	local relative_evolution = 0.0
	local max_d2 = max_evolution_distance * max_evolution_distance
	-- for all of the teams
	local teams = ffatable.town_centers
	for _, town_center in pairs(teams) do
		local market_position = town_center.market.position
		-- calculate the distance squared
		local d2 = distance_squared(position, market_position)
		if d2 < max_d2 then
			-- get the distance factor (0.0-1.0)
			local distance_factor = 1.0 - d2 / max_d2;
			-- get the evolution factor (0.0-1.0)
			if not town_center.evolution then town_center.evolution = {} end
			if town_center.evolution.biters == nil then town_center.evolution.biters = 0.0 end
			local evolution_factor = town_center.evolution.biters
			local evo = distance_factor * evolution_factor
			relative_evolution = math.max(relative_evolution, evo)
		end
	end
	return relative_evolution
end

local function get_relative_spitter_evolution(position)
	local ffatable = Table.get_table()
	local relative_evolution = 0.0
	local max_d2 = max_evolution_distance * max_evolution_distance
	-- for all of the teams
	local teams = ffatable.town_centers
	for _, town_center in pairs(teams) do
		local market_position = town_center.market.position
		-- calculate the distance squared
		local d2 = distance_squared(position, market_position)
		if d2 < max_d2 then
			-- get the distance factor (0.0-1.0)
			local distance_factor = 1.0 - d2 / max_d2;
			-- get the evolution factor (0.0-1.0)
			if not town_center.evolution then town_center.evolution = {} end
			if town_center.evolution.spitters == nil then town_center.evolution.spitters = 0.0 end
			local evolution_factor = town_center.evolution.spitters
			local evo = distance_factor * evolution_factor
			relative_evolution = math.max(relative_evolution, evo)
		end
	end
	return relative_evolution
end

local function get_relative_worm_evolution(position)
	local ffatable = Table.get_table()
	local relative_evolution = 0.0
	local max_d2 = max_evolution_distance * max_evolution_distance
	-- for all of the teams
	local teams = ffatable.town_centers
	for _, town_center in pairs(teams) do
		local market_position = town_center.market.position
		-- calculate the distance squared
		local d2 = distance_squared(position, market_position)
		if d2 < max_d2 then
			-- get the distance factor (0.0-1.0)
			local distance_factor = 1.0 - d2 / max_d2;
			-- get the evolution factor (0.0-1.0)
			if not town_center.evolution then town_center.evolution = {} end
			if town_center.evolution.worms == nil then town_center.evolution.worms = 0.0 end
			local evolution_factor = town_center.evolution.worms
			local evo = distance_factor * evolution_factor
			relative_evolution = math.max(relative_evolution, evo)
		end
	end
	return relative_evolution
end

function Public.get_evolution(position)
	return get_relative_biter_evolution(position)
end

function Public.get_biter_evolution(entity)
	return get_relative_biter_evolution(entity.position)
end

function Public.get_spitter_evolution(entity)
	return get_relative_spitter_evolution(entity.position)
end

function Public.get_worm_evolution(entity)
	return get_relative_worm_evolution(entity.position)
end

local function get_nearby_location(position, surface, radius, entity_name)
	return surface.find_non_colliding_position(entity_name, position, radius, 0.5, false)
end

local function set_biter_type(entity)
	-- checks nearby evolution levels for bases and returns an appropriately leveled type
	local position = entity.position
	local evo = get_relative_biter_evolution(position)
	local unit_size = get_unit_size(evo)
	local entity_name = biters[unit_size]
	if entity.name == entity_name then return end
	local surface = entity.surface
	local pollution = surface.get_pollution(position)
	local behemoth = math_floor(pollution / max_pollution_behemoth)
	local big = math_floor((pollution - (behemoth * max_pollution_behemoth)) / max_pollution_big)
	local medium = math_floor((pollution - (behemoth * max_pollution_behemoth) - (big * max_pollution_big)) / max_pollution_medium)
	local small = pollution - (behemoth * max_pollution_behemoth) - (big * max_pollution_big) - (medium * max_pollution_medium) + 1

	if entity.valid then
		for _ = 1, behemoth do
			local e = surface.create_entity({ name = biters[4], position = get_nearby_location(position, surface, 5, biters[4]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		for _ = 1, big do
			local e = surface.create_entity({ name = biters[3], position = get_nearby_location(position, surface, 5, biters[3]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		for _ = 1, medium do
			local e = surface.create_entity({ name = biters[2], position = get_nearby_location(position, surface, 5, biters[2]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		for _ = 1, small do
			local e = surface.create_entity({ name = biters[1], position = get_nearby_location(position, surface, 5, biters[1]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		local e = surface.create_entity({ name = entity_name, position = get_nearby_location(position, surface, 5, entity_name) })
		e.copy_settings(entity);
		e.ai_settings.allow_try_return_to_spawner = true
		entity.destroy()
		--log("spawned " .. entity_name)
	end
end

local function set_spitter_type(entity)
	-- checks nearby evolution levels for bases and returns an appropriately leveled type
	local position = entity.position
	local evo = get_relative_spitter_evolution(position)
	local unit_size = get_unit_size(evo)
	local entity_name = spitters[unit_size]
	if entity.name == entity_name then return end
	local surface = entity.surface
	local pollution = surface.get_pollution(position)
	local behemoth = math_floor(pollution / max_pollution_behemoth)
	local big = math_floor((pollution - (behemoth * max_pollution_behemoth)) / max_pollution_big)
	local medium = math_floor((pollution - (behemoth * max_pollution_behemoth) - (big * max_pollution_big)) / max_pollution_medium)
	local small = pollution - (behemoth * max_pollution_behemoth) - (big * max_pollution_big) - (medium * max_pollution_medium) + 1

	if entity.valid then
		for _ = 1, behemoth do
			local e = surface.create_entity({ name = spitters[4], position = get_nearby_location(position, surface, 5, spitters[4]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		for _ = 1, big do
			local e = surface.create_entity({ name = spitters[3], position = get_nearby_location(position, surface, 5, spitters[3]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		for _ = 1, medium do
			local e = surface.create_entity({ name = spitters[2], position = get_nearby_location(position, surface, 5, spitters[2]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		for _ = 1, small do
			local e = surface.create_entity({ name = spitters[1], position = get_nearby_location(position, surface, 5, spitters[1]) })
			e.copy_settings(entity);
			e.ai_settings.allow_try_return_to_spawner = true
		end
		local e = surface.create_entity({ name = entity_name, position = get_nearby_location(position, surface, 5, entity_name) })
		e.copy_settings(entity);
		e.ai_settings.allow_try_return_to_spawner = true
		entity.destroy()
		--log("spawned " .. entity_name)
	end
end

local function set_worm_type(entity)
	-- checks nearby evolution levels for bases and returns an appropriately leveled type
	local position = entity.position
	local evo = get_relative_worm_evolution(position)
	local unit_size = get_unit_size(evo)
	local entity_name = worms[unit_size]
	if entity.name == entity_name then return end
	local surface = entity.surface
	if entity.valid then
		entity.destroy()
		surface.create_entity({ name = entity_name, position = position })
		--log("spawned " .. entity_name)
	end
end

local function is_biter(entity)
	if entity == nil or not entity.valid then return false end
	if entity.name == 'small-biter' or entity.name == 'medium-biter' or entity.name == 'big-biter' or entity.name == 'behemoth-biter' then
		return true
	end
	return false
end

local function is_spitter(entity)
	if entity == nil or not entity.valid then return false end
	if entity.name == 'small-spitter' or entity.name == 'medium-spitter' or entity.name == 'big-spitter' or entity.name == 'behemoth-spitter' then
		return true
	end
	return false
end

local function is_worm(entity)
	if entity == nil or not entity.valid then return false end
	if entity.name == 'small-worm-turret' or entity.name == 'medium-worm-turret' or entity.name == 'big-worm-turret' or entity.name == 'behemoth-worm-turret' then
		return true
	end
	return false
end

local function update_evolution(force_name, technology)
	if technology == nil then return end
	local ffatable = Table.get_table()
	-- update evolution based on research completed (weighted)
	local town_center = ffatable.town_centers[force_name]
	-- town_center is a reference to a global table
	if not town_center then return end
	-- initialize if not already
	local evo = town_center.evolution
	-- get the weights for this technology
	local weight = technology_weights[technology]
	if weight == nil then
		log("no technology_weights for " .. technology)
		return
	end
	local biter_weight = weight.biter
	local spitter_weight = weight.spitter
	local worm_weight = weight.worm
	-- update the evolution values (0.0 to 1.0)
	local b = (biter_weight / max_biter_weight)
	local s = (spitter_weight / max_spitter_weight)
	local w = (worm_weight / max_worm_weight)
	b = b + evo.biters
	s = s + evo.spitters
	w = w + evo.worms
	evo.biters = b
	evo.spitters = s
	evo.worms = w
end

local function on_research_finished(event)
	local research = event.research
	local force_name = research.force.name
	local technology = research.name
	update_evolution(force_name, technology)
end

local function on_entity_spawned(event)
	local entity = event.entity
	-- check the unit type and handle appropriately
	if is_biter(entity) then
		set_biter_type(entity)
	end
	if is_spitter(entity) then
		set_spitter_type(entity)
	end
	if is_worm(entity) then
		set_worm_type(entity)
	end
end

local function on_biter_base_built(event)
	local entity = event.entity
	if is_worm(entity) then
		set_worm_type(entity)
	end
end

local Event = require 'utils.event'
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_entity_spawned, on_entity_spawned)
Event.add(defines.events.on_biter_base_built, on_biter_base_built)

return Public