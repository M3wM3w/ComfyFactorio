local radius = 3

local function splash_damage(surface, position, final_damage_amount)
	local damage = math.random(math.floor(final_damage_amount * 3), math.floor(final_damage_amount * 4))
	for _, e in pairs(surface.find_entities_filtered({area = {{position.x - radius, position.y - radius},{position.x + radius, position.y + radius}}})) do
		if e.valid and e.health then
			local distance_from_center = math.sqrt((e.position.x - position.x) ^ 2 + (e.position.y - position.y) ^ 2)
			if distance_from_center <= radius then
				local damage_distance_modifier = 1 - distance_from_center / radius
				if damage > 0 then
					if math.random(1, 3) == 1 then surface.create_entity({name = "explosion", position = e.position}) end
					e.damage(damage * damage_distance_modifier, "player", "explosion")
				end
			end
		end
	end
end

local function explosive_bullets(event)
	if math.random(1, 3) ~= 1 then return false end
	if event.damage_type.name ~= "physical" then return false end
	local player = event.cause
	if player.shooting_state.state == defines.shooting.not_shooting then return false end
	local selected_weapon = player.get_inventory(defines.inventory.character_guns)[player.selected_gun_index]
	if selected_weapon.name ~= "submachine-gun" and selected_weapon.name ~= "pistol" then return false end

	player.surface.create_entity({name = "explosion", position = event.entity.position})

	splash_damage(
		player.surface,
		event.entity.position,
		event.final_damage_amount
	)
end

return explosive_bullets
