local radius = 9
local math_random = math.random
local math_sqrt = math.sqrt

local ammo_to_projectile_translation = {
	["shotgun-shell"] = "shotgun-pellet",
	["piercing-shotgun-shell"] = "piercing-shotgun-pellet"
}

local function create_projectile(surface, position, target, name)
	surface.create_entity({	
		name = name,
		position = position,
		force = force,
		source = position,
		target = target,
		max_range = 16, 
		speed = 0.3
	})
end

local function bounce(surface, position, ammo)
	if math_random(1,3) ~= 1 then return end
	local valid_entities = {}
	for _, e in pairs(surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})) do		
		if e.health then
			if e.force.name ~= "player" then
				--local distance_from_center = math_sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
				--if distance_from_center <= radius then
					valid_entities[#valid_entities + 1] = e
				--end
			end
		end
	end
	
	if not valid_entities[1] then return end

	for c = 1, math_random(3,6), 1 do
		create_projectile(surface, position, valid_entities[math_random(1, #valid_entities)].position, ammo)
	end
end

local function bouncy_shells(event)
	if event.damage_type.name ~= "physical" then return false end
	local player = event.cause
	if player.shooting_state.state == defines.shooting.not_shooting then return false end
	local selected_weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
	if selected_weapon.name ~= "combat-shotgun" and selected_weapon.name ~= "shotgun" then return false end
	
	local selected_ammo = player.get_inventory(defines.inventory.character_ammo)[player.selected_gun_index]
	if not selected_ammo then return end
	if not ammo_to_projectile_translation[selected_ammo.name] then return end
	
	bounce(
		player.surface,
		event.entity.position,
		ammo_to_projectile_translation[selected_ammo.name]
	)
end

return bouncy_shells


