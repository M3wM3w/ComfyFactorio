local event = require 'utils.event'
local Balance = require 'maps.chronosphere.balance'

local function on_research_finished(event)
    local difficulty = global.difficulty_vote_value
	local multiplier = Balance.damage_research_effect_on_shotgun_multipler(difficulty)

	local research = event.research
	if string.sub(research.name, 0, 26) ~= "physical-projectile-damage" then return end
	
	local modifier = game.forces[research.force.name].get_ammo_damage_modifier("shotgun-shell")
	modifier = modifier - research.effects[3].modifier
	modifier = modifier + research.effects[3].modifier * multiplier
	
	game.forces[research.force.name].set_ammo_damage_modifier("shotgun-shell", modifier)
end

local function on_entity_damaged(event)
    local difficulty = global.difficulty_vote_value
    local bonus = Balance.pistol_damage_multiplier(difficulty) - 1

	if not event.cause then return end
	if not event.cause.valid then return end
	if not event.entity then return end
	if not event.entity.valid then return end
	if event.cause.name ~= "character" then return end
	if event.damage_type.name ~= "physical" then return end

	local player = event.cause
	if player.shooting_state.state == defines.shooting.not_shooting then return end
	local weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
	local ammo = player.get_inventory(defines.inventory.character_ammo)[player.selected_gun_index]
  if not weapon.valid_for_read or not ammo.valid_for_read then return end
	if weapon.name ~= "pistol" then return end
	if ammo.name ~= "firearm-magazine" and ammo.name ~= "piercing-rounds-magazine" and ammo.name ~= "uranium-rounds-magazine" then return end
  if not event.entity.valid then return end 
	event.entity.damage(event.final_damage_amount * bonus, player.force, "impact", player)
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_research_finished, on_research_finished)