-- All entities that own a unit_number of a chosen force gain damage resistance.
-- ignores entity health regeneration

-- Use Public.set_health_modifier(force_index, modifier) to modify health.
-- 1 = original health, 2 = 200% total health, 4 = 400% total health,..

local Global = require 'utils.global'
local Event = require 'utils.event'
local Public = {}

local math_round = math.round

local fhb = {}
Global.register(
    fhb,
    function(tbl)
        fhb = tbl
    end
)

function Public.set_health_modifier(force_index, modifier)
	if not game.forces[force_index] then return end
	if not modifier then return end
	if not fhb[force_index] then fhb[force_index] = {} end
	fhb[force_index].m = math_round(1 / modifier, 4)
end

function Public.reset_tables()
	for k, v in pairs(fhb) do fhb[k] = nil end
end

local function on_entity_damaged(event)
	local entity = event.entity
	if not entity and not entity.valid then return end
	local unit_number = entity.unit_number
	if not unit_number then return end

	local boost = fhb[entity.force.index]
	if not boost then return end
	if not boost[unit_number] then boost[unit_number] = entity.prototype.max_health end

	local new_health = boost[unit_number] - event.final_damage_amount * boost.m
	boost[unit_number] = new_health
	entity.health = new_health
end

local function on_entity_died(event)
	local entity = event.entity
	if not entity and not entity.valid then return end
	local unit_number = entity.unit_number
	if not unit_number then return end
	local boost = fhb[entity.force.index]
	if not boost then return end
	boost[unit_number] = nil
end

local function on_player_repaired_entity(event)
	local entity = event.entity
	if not entity and not entity.valid then return end
	local unit_number = entity.unit_number
	if not unit_number then return end
	local boost = fhb[entity.force.index]
	if not boost then return end
	boost[unit_number] = entity.health
end

local function on_init()
	Public.reset_tables()
end

Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_repaired_entity, on_player_repaired_entity)

return Public