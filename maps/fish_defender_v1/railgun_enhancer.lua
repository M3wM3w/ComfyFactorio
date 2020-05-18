-- improves the damage of the railgun and adds visual effects -- by mewmew
-- laser turret research will increase it´s damage even further --

local damage_min = 400
local damage_max = 800
local math_random = math.random
local additional_visual_effects = true

local biological_target_types = {
	["unit"] = true,
	["player"] = true,
	["turret"] = true,
	["unit-spawner"] = true	
}

local function create_visuals(source_entity, target_entity)
	if not source_entity.valid then return end
	if not target_entity.valid then return end
	if not additional_visual_effects then return end
	local surface = target_entity.surface		
	surface.create_entity({name = "water-splash", position = target_entity.position})
	if biological_target_types[target_entity.type] then
		surface.create_entity({name = "blood-explosion-big", position = target_entity.position})
		for x = -8, 8, 1 do
			for y = -8, 8, 1 do
				if math_random(1, 16) == 1 then
					surface.create_entity({name = "blood-fountain", position = {target_entity.position.x + (x * 0.1), target_entity.position.y + (y * 0.1)}})
					surface.create_entity({name = "blood-fountain-big", position = {target_entity.position.x + (x * 0.1), target_entity.position.y + (y * 0.1)}})
				end
			end
		end
	else
		if math_random(1, 3) ~= 1 then
			surface.create_entity({name = "fire-flame", position = target_entity.position})
		end
		for x = -3, 3, 1 do
			for y = -3, 3, 1 do													
				if math_random(1, 3) == 1 then
					surface.create_trivial_smoke({name="smoke-fast", position={target_entity.position.x + (x * 0.35), target_entity.position.y + (y * 0.35)}})						
				end
				if math_random(1, 5) == 1 then
					surface.create_trivial_smoke({name="train-smoke", position={target_entity.position.x + (x * 0.35), target_entity.position.y + (y * 0.35)}})						
				end
			end
		end
	end			
end

local function do_splash_damage_around_entity(source_entity, player)
	if not source_entity.valid then return end
	local research_damage_bonus = player.force.get_ammo_damage_modifier("laser-turret") + 1
	local research_splash_radius_bonus = player.force.get_ammo_damage_modifier("laser-turret") * 0.5
	local splash_area = {
			{source_entity.position.x - (2.5 + research_splash_radius_bonus), source_entity.position.y - (2.5 + research_splash_radius_bonus)},
			{source_entity.position.x + (2.5 + research_splash_radius_bonus), source_entity.position.y + (2.5 + research_splash_radius_bonus)}
		}
	local entities = source_entity.surface.find_entities_filtered({area = splash_area})
	for _, entity in pairs(entities) do
		if entity.valid then
			if entity.health and entity ~= source_entity and entity ~= player then
				if additional_visual_effects then
					local surface = entity.surface
					surface.create_entity({name = "railgun-beam", position = source_entity.position, source = source_entity.position, target = entity.position})
					surface.create_entity({name = "water-splash", position = entity.position})
					if biological_target_types[entity.type] then								
						surface.create_entity({name = "blood-fountain", position = entity.position})				
					end
				end
				local damage = math_random(math.ceil((damage_min * research_damage_bonus) / 16), math.ceil((damage_max * research_damage_bonus) / 16))			
				entity.damage(damage, player.force, "physical")	
			end
		end
	end
end

local function enhance(event)
	if not global.railgun_enhancer_unlocked then return end
	if event.damage_type.name ~= "physical" then return end
	if event.original_damage_amount ~= 100 then return end
	
	local player = event.cause
	if player.shooting_state.state == defines.shooting.not_shooting then return end
	local selected_weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
	if selected_weapon.name ~= "railgun" then return end
	
	create_visuals(event.cause, event.entity)
	
	do_splash_damage_around_entity(event.entity, player)
	
	event.entity.health = event.entity.health + event.final_damage_amount
	
	local research_damage_bonus = player.force.get_ammo_damage_modifier("laser-turret") + 1	
	local damage = math_random(math.ceil(damage_min * research_damage_bonus), math.ceil(damage_max * research_damage_bonus))
	event.entity.damage(damage, player.force, "physical")
	return true
end

return enhance