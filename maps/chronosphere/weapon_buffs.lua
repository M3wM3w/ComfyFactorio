local event = require 'utils.event'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'

local function on_research_finished(event)
    local difficulty = Difficulty.get().difficulty_vote_value

	local research = event.research
	local p_force = research.force
	
    for _, e in ipairs(research.effects) do
		local t = e.type
        if t == 'ammo-damage' then
            local category = e.ammo_category
            local factor = Balance.player_ammo_damage_modifiers()[category] or 0

            if factor then
                local current_m = p_force.get_ammo_damage_modifier(category)
                local m = e.modifier
                p_force.set_ammo_damage_modifier(category, current_m + factor * m)
            end
		elseif t == 'gun-speed' then
			local category = e.ammo_category
			local factor = Balance.player_gun_speed_modifiers()[category] or 0
	
			if factor then
				local current_m = p_force.get_gun_speed_modifier(category)
				local m = e.modifier
				p_force.set_gun_speed_modifier(category, current_m + factor * m)
			end
		end
	end
	
end

local function on_entity_damaged(event)
    local difficulty = Difficulty.get().difficulty_vote_value
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

local function init_player_weapon_balance()
    for k, v in pairs(Balance.player_ammo_damage_modifiers()) do
        game.forces['player'].set_ammo_damage_modifier(k, v)
    end

    for k, v in pairs(Balance.player_gun_speed_modifiers()) do
        game.forces['player'].set_gun_speed_modifier(k, v)
    end
end

event.on_init(init_player_weapon_balance)
event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_research_finished, on_research_finished)