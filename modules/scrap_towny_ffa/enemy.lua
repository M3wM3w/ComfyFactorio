local Public = {}

function Public.clear_enemies(position, surface, radius)
	--log("clear_enemies {" .. position.x .. "," .. position.y .. "}")
	-- clear enemies
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", type = { "unit-spawner", "unit", "turret" }, position = position, radius = radius })) do
		e.destroy()
	end
	-- clear gun turrets
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", name = { "gun-turret" }, position = position, radius = radius })) do
		e.destroy()
	end
end

function Public.clear_units(position, surface, radius)
	--log("clear_units {" .. position.x .. "," .. position.y .. "}")
	-- clear units
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", type = { "unit" }, position = position, radius = radius })) do
		e.destroy()
	end
end

function Public.clear_biters(position, surface, radius)
	--log("clear_units {" .. position.x .. "," .. position.y .. "}")
	-- clear biters
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", name = { "small-biter", "medium-biter", "big-biter", "behemoth-biter" }, position = position, radius = radius })) do
		e.destroy()
	end
end

function Public.clear_spitters(position, surface, radius)
	--log("clear_units {" .. position.x .. "," .. position.y .. "}")
	-- clear spitters
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", name = { "small-spitter", "medium-spitter", "big-spitter", "behemoth-spitter" }, position = position, radius = radius })) do
		e.destroy()
	end
end

function Public.clear_nests(position, surface, radius)
	--log("clear_unit_spawners {" .. position.x .. "," .. position.y .. "}")
	-- clear enemies
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", type = { "unit-spawner" }, position = position, radius = radius })) do
		e.destroy()
	end
end

function Public.clear_worms(position, surface, radius)
	--log("clear_turrets {" .. position.x .. "," .. position.y .. "}")
	-- clear enemies
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", type = { "turret" }, position = position, radius = radius })) do
		e.destroy()
	end
end

function Public.clear_gun_turrets(position, surface, radius)
	--log("clear_gun_turrets {" .. position.x .. "," .. position.y .. "}")
	-- clear gun turrets
	for _, e in pairs(surface.find_entities_filtered({ force = "enemy", name = { "gun-turret" }, position = position, radius = radius })) do
		e.destroy()
	end
end

return Public