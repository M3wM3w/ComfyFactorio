local event = require 'utils.event'

local enhance_railgun = require 'maps.fish_defender_v1.railgun_enhancer'
local explosive_bullets = require 'maps.fish_defender_v1.explosive_gun_bullets'
local bouncy_shells = require 'maps.fish_defender_v1.bouncy_shells'
local boss_biter = require "maps.fish_defender_v1.boss_biters"

local function protect_market(event)
	if event.entity.name ~= "market" then return false end
	if event.cause then
		if event.cause.force.name == "enemy" then return false end
	end
	event.entity.health = event.entity.health + event.final_damage_amount
	return true
end

local function on_entity_damaged(event)
	if not event.entity then return end
	if not event.entity.valid then return end
	
	if protect_market(event) then return end
	
	if not event.cause then return end
	
	if event.cause.unit_number then
		if global.boss_biters[event.cause.unit_number] then
			boss_biter.damaged_entity(event) 
		end
	end
	
	if event.cause.name ~= "character" then return end
	
	if enhance_railgun(event) then return end
	if global.explosive_bullets_unlocked then
		if explosive_bullets(event) then return end
	end
	if global.bouncy_shells_unlocked then
		if bouncy_shells(event) then return end
	end
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)